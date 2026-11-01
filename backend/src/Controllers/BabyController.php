<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Database;
use App\Core\Format;
use App\Core\Request;
use App\Core\Response;

class BabyController
{
    /** Yeni bebeğe eklenen varsayılan "ilk"ler (uygulamadaki listeyle aynı). */
    private const DEFAULT_MEMORIES = [
        'İlk gülümseme',
        'İlk diş',
        'İlk oturma',
        'İlk emekleme',
        'İlk kelime',
        'İlk adım',
    ];

    private const RULES = [
        'name'       => 'required|string|max:120',
        'birth_date' => 'required|date',
        'gender'     => 'nullable|in:girl,boy,unspecified',
        'photo_path' => 'nullable|string|max:500',
    ];

    public function index(Request $req): array
    {
        $rows = Database::all('SELECT * FROM babies WHERE user_id = ? ORDER BY id', [$req->userId()]);
        return Response::data(array_map([self::class, 'toJson'], $rows));
    }

    public function store(Request $req): array
    {
        $in = $req->validate(self::RULES);
        $in['gender'] ??= 'unspecified';
        $in['user_id'] = $req->userId();

        $pdo = Database::pdo();
        $pdo->beginTransaction();
        try {
            $id = Database::insert('babies', $in);
            foreach (self::DEFAULT_MEMORIES as $i => $title) {
                Database::insert('memories', ['baby_id' => $id, 'title' => $title, 'sort_order' => $i]);
            }
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        $baby = Database::one('SELECT * FROM babies WHERE id = ?', [$id]);
        return Response::data(self::toJson($baby), 201);
    }

    public function update(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $rules = array_map(fn ($r) => str_replace('required|', '', $r), self::RULES);
        $in = $req->validate($rules);
        if (array_key_exists('gender', $in) && $in['gender'] === null) {
            $in['gender'] = 'unspecified';
        }

        Database::update('babies', $baby['id'], $in);
        $baby = Database::one('SELECT * FROM babies WHERE id = ?', [$baby['id']]);
        return Response::data(self::toJson($baby));
    }

    public function destroy(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        Database::query('DELETE FROM babies WHERE id = ?', [$baby['id']]);
        return Response::noContent();
    }

    // -- Sağılmış süt stoğu --------------------------------------------------

    public function expressedMilk(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        return Response::data(['stock_ml' => (int) $baby['expressed_milk_ml']]);
    }

    /** stock_ml ile değeri doğrudan ayarlar ya da delta ile artırır/azaltır. */
    public function updateExpressedMilk(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $in = $req->validate([
            'stock_ml' => 'nullable|int|min:0|max:100000',
            'delta'    => 'nullable|int|min:-100000|max:100000',
        ]);

        if (isset($in['stock_ml'])) {
            Database::query('UPDATE babies SET expressed_milk_ml = ? WHERE id = ?', [$in['stock_ml'], $baby['id']]);
        }
        if (isset($in['delta'])) {
            Database::query(
                'UPDATE babies SET expressed_milk_ml = GREATEST(0, expressed_milk_ml + ?) WHERE id = ?',
                [$in['delta'], $baby['id']],
            );
        }

        $stock = Database::one('SELECT expressed_milk_ml FROM babies WHERE id = ?', [$baby['id']]);
        return Response::data(['stock_ml' => (int) $stock['expressed_milk_ml']]);
    }

    // -- Özet ----------------------------------------------------------------

    /** Bebek + bugünün özeti + son ölçüm + süt stoğu. */
    public function dashboard(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $latestGrowth = Database::one(
            'SELECT * FROM growth_measurements WHERE baby_id = ? ORDER BY measured_at DESC, id DESC LIMIT 1',
            [$baby['id']],
        );

        return Response::data([
            'baby'          => self::toJson($baby),
            'age_months'    => Format::ageInMonths($baby['birth_date']),
            'today'         => self::daySummary($baby['id'], date('Y-m-d')),
            'latest_growth' => $latestGrowth ? GrowthController::toJson($latestGrowth) : null,
            'expressed_milk_ml' => (int) $baby['expressed_milk_ml'],
        ]);
    }

    /** Tek bir günün (varsayılan bugün) kayıt özeti. */
    public function summary(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $q = $req->validateQuery(['date' => 'nullable|date']);
        return Response::data(self::daySummary($baby['id'], $q['date'] ?? date('Y-m-d')));
    }

    private static function daySummary(int $babyId, string $date): array
    {
        $row = Database::one(
            "SELECT
                SUM(type = 'breastfeeding')                                   AS breastfeeding_count,
                COALESCE(SUM(CASE WHEN type = 'breastfeeding' THEN duration_seconds END), 0) AS breastfeeding_seconds,
                SUM(type = 'formula')                                         AS formula_count,
                COALESCE(SUM(CASE WHEN type = 'formula' THEN amount_ml END), 0) AS formula_ml,
                SUM(type = 'solid_food')                                      AS solid_food_count,
                SUM(type = 'stool')                                           AS stool_count,
                SUM(type = 'diaper' AND diaper_kind IN ('wet','both'))        AS wet_diaper_count,
                SUM(type = 'diaper' AND diaper_kind IN ('dirty','both'))      AS dirty_diaper_count,
                SUM(type = 'vomit')                                           AS vomit_count,
                COALESCE(SUM(CASE WHEN type = 'sleep' THEN duration_seconds END), 0) AS sleep_seconds,
                MAX(CASE WHEN type = 'fever' THEN temperature END)            AS max_temperature,
                SUM(type = 'medicine')                                        AS medicine_count
               FROM records
              WHERE baby_id = ? AND recorded_at >= ? AND recorded_at < ? + INTERVAL 1 DAY",
            [$babyId, $date, $date],
        );

        $summary = ['date' => $date];
        foreach ($row as $key => $value) {
            $summary[$key] = $key === 'max_temperature' ? Format::float($value) : (int) $value;
        }
        return $summary;
    }

    public static function toJson(array $b): array
    {
        return [
            'id'         => (int) $b['id'],
            'name'       => $b['name'],
            'birth_date' => $b['birth_date'],
            'gender'     => $b['gender'],
            'photo_path' => $b['photo_path'],
            'created_at' => Format::dateTime($b['created_at']),
            'updated_at' => Format::dateTime($b['updated_at']),
        ];
    }
}
