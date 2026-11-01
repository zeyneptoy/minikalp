<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Database;
use App\Core\Format;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;

/**
 * Takip kayıtları (emzirme, mama, ek gıda, kaka, bez, kusma, uyku, ateş, ilaç).
 * Alan adları lib/core/api/record_mapper.dart ile birebir aynıdır.
 */
class RecordController
{
    /** Her türün kabul ettiği alanlar. */
    private const TYPE_RULES = [
        'breastfeeding' => [
            'side'             => 'required|in:left,right,both',
            'duration_seconds' => 'required|int|min:0|max:86400',
        ],
        'formula' => [
            'milk_type' => 'required|in:breast_milk,formula',
            'amount_ml' => 'required|int|min:0|max:5000',
        ],
        'solid_food' => [
            'food_name' => 'required|string|max:190',
            'reaction'  => 'nullable|in:none,rash,vomit,stool_change',
        ],
        'stool' => [
            'stool_color'       => 'required|in:yellow,green,brown,black,red,white_gray',
            'stool_consistency' => 'required|in:watery,soft,normal,hard,lumpy',
            'note'              => 'nullable|string|max:2000',
            'photo_path'        => 'nullable|string|max:500',
        ],
        'diaper' => [
            'diaper_kind' => 'required|in:wet,dirty,both',
        ],
        'vomit' => [
            'vomit_kind'   => 'required|in:spit_up,forceful',
            'vomit_amount' => 'required|in:low,medium,high',
            'symptoms'     => 'nullable|array|max:10',
            'color_note'   => 'nullable|string|max:255',
        ],
        'sleep' => [
            'duration_seconds' => 'required|int|min:0|max:86400',
            'day_night'        => 'required|in:day,night',
            'quality'          => 'nullable|int|min:1|max:5',
        ],
        'fever' => [
            'temperature'  => 'required|numeric|min:30|max:45',
            'fever_method' => 'nullable|string|max:30',
        ],
        'medicine' => [
            'medicine_name' => 'required|string|max:190',
        ],
    ];

    private const SYMPTOMS = ['fever', 'restlessness', 'fatigue'];

    public function index(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $q = $req->validateQuery([
            'type' => 'nullable|in:' . implode(',', array_keys(self::TYPE_RULES)),
            'date' => 'nullable|date',
            'from' => 'nullable|date',
            'to'   => 'nullable|date',
        ]);

        $sql = 'SELECT * FROM records WHERE baby_id = ?';
        $params = [$baby['id']];

        if (!empty($q['type'])) {
            $sql .= ' AND type = ?';
            $params[] = $q['type'];
        }
        if (!empty($q['date'])) {
            $sql .= ' AND recorded_at >= ? AND recorded_at < ? + INTERVAL 1 DAY';
            array_push($params, $q['date'], $q['date']);
        }
        // from dahil, to hariç: [from, to)
        if (!empty($q['from'])) {
            $sql .= ' AND recorded_at >= ?';
            $params[] = $q['from'];
        }
        if (!empty($q['to'])) {
            $sql .= ' AND recorded_at < ?';
            $params[] = $q['to'];
        }
        $sql .= ' ORDER BY recorded_at DESC, id DESC';

        return Response::data(array_map([self::class, 'toJson'], Database::all($sql, $params)));
    }

    public function store(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $base = $req->validate([
            'type'        => 'required|in:' . implode(',', array_keys(self::TYPE_RULES)),
            'recorded_at' => 'required|datetime',
        ]);
        $fields = $req->validate(self::TYPE_RULES[$base['type']]);

        if (isset($fields['symptoms'])) {
            $symptoms = array_values(array_unique(array_map('strval', $fields['symptoms'])));
            $unknown = array_diff($symptoms, self::SYMPTOMS);
            if ($unknown !== []) {
                throw HttpException::validation(['symptoms' => ['Geçersiz belirti: ' . implode(', ', $unknown)]]);
            }
            $fields['symptoms'] = json_encode($symptoms);
        }

        $id = Database::insert('records', ['baby_id' => $baby['id']] + $base + $fields);
        return Response::data(self::toJson(Database::one('SELECT * FROM records WHERE id = ?', [$id])), 201);
    }

    public function destroy(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $stmt = Database::query(
            'DELETE FROM records WHERE id = ? AND baby_id = ?',
            [$req->param('record'), $baby['id']],
        );
        if ($stmt->rowCount() === 0) {
            throw HttpException::notFound();
        }
        return Response::noContent();
    }

    /** Yalnızca kaydın türüne ait alanları döner (record_mapper ile uyumlu). */
    public static function toJson(array $r): array
    {
        $json = [
            'id'          => (int) $r['id'],
            'type'        => $r['type'],
            'recorded_at' => Format::dateTime($r['recorded_at']),
        ];

        foreach (array_keys(self::TYPE_RULES[$r['type']]) as $field) {
            $value = $r[$field];
            $json[$field] = match ($field) {
                'symptoms'    => $value === null ? [] : json_decode($value, true),
                'temperature' => Format::float($value),
                default       => $value,
            };
        }
        return $json;
    }
}
