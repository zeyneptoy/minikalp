<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Database;
use App\Core\Format;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;

/**
 * Sağlık: ilaç hatırlatıcıları, aşılar, randevular ve e-posta raporu.
 */
class HealthController
{
    private const REMINDER_RULES = [
        'name'           => 'required|string|max:190',
        'schedule_label' => 'nullable|string|max:100',
        'remind_at'      => 'nullable|time',
        'notify'         => 'nullable|bool',
    ];

    private const VACCINE_RULES = [
        'name'      => 'required|string|max:190',
        'age_label' => 'nullable|string|max:100',
        'status'    => 'nullable|in:upcoming,done,late',
        'due_date'  => 'nullable|date',
        'notify'    => 'nullable|bool',
    ];

    private const APPOINTMENT_RULES = [
        'title'        => 'required|string|max:190',
        'doctor'       => 'nullable|string|max:190',
        'hospital'     => 'nullable|string|max:190',
        'scheduled_at' => 'nullable|datetime',
        'notify'       => 'nullable|bool',
    ];

    // -- İlaç hatırlatıcıları -----------------------------------------------

    public function reminders(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $rows = Database::all('SELECT * FROM medicine_reminders WHERE baby_id = ? ORDER BY remind_at IS NULL, remind_at, id', [$baby['id']]);
        return Response::data(array_map([self::class, 'reminderJson'], $rows));
    }

    public function storeReminder(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $in = $req->validate(self::REMINDER_RULES);
        $in['schedule_label'] ??= 'Her gün';
        $in['notify'] ??= 0;
        $row = $this->create('medicine_reminders', $baby['id'], $in);
        return Response::data(self::reminderJson($row), 201);
    }

    /** "Verildi" işaretini tersine çevirir. */
    public function toggleReminder(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $row = $this->findChild('medicine_reminders', $req->param('reminder'), $baby['id']);
        Database::query('UPDATE medicine_reminders SET done = NOT done WHERE id = ?', [$row['id']]);
        $row = Database::one('SELECT * FROM medicine_reminders WHERE id = ?', [$row['id']]);
        return Response::data(self::reminderJson($row));
    }

    public function destroyReminder(Request $req): array
    {
        return $this->destroy($req, 'medicine_reminders', 'reminder');
    }

    private static function reminderJson(array $r): array
    {
        return [
            'id'             => (int) $r['id'],
            'name'           => $r['name'],
            'schedule_label' => $r['schedule_label'],
            'remind_at'      => $r['remind_at'],
            'notify'         => Format::bool($r['notify']),
            'done'           => Format::bool($r['done']),
        ];
    }

    // -- Aşılar ---------------------------------------------------------------

    public function vaccines(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $rows = Database::all('SELECT * FROM vaccines WHERE baby_id = ? ORDER BY due_date IS NULL, due_date, id', [$baby['id']]);
        return Response::data(array_map([self::class, 'vaccineJson'], $rows));
    }

    public function storeVaccine(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $in = $req->validate(self::VACCINE_RULES);
        $in['age_label'] ??= '';
        $in['status'] ??= 'upcoming';
        $in['notify'] ??= 0;
        $row = $this->create('vaccines', $baby['id'], $in);
        return Response::data(self::vaccineJson($row), 201);
    }

    public function updateVaccine(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $row = $this->findChild('vaccines', $req->param('vaccine'), $baby['id']);
        $in = $req->validate(self::partial(self::VACCINE_RULES));
        $row = $this->patch('vaccines', $row['id'], $in);
        return Response::data(self::vaccineJson($row));
    }

    public function destroyVaccine(Request $req): array
    {
        return $this->destroy($req, 'vaccines', 'vaccine');
    }

    private static function vaccineJson(array $v): array
    {
        return [
            'id'        => (int) $v['id'],
            'name'      => $v['name'],
            'age_label' => $v['age_label'],
            'status'    => $v['status'],
            'due_date'  => $v['due_date'],
            'notify'    => Format::bool($v['notify']),
        ];
    }

    // -- Randevular -----------------------------------------------------------

    public function appointments(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $rows = Database::all('SELECT * FROM appointments WHERE baby_id = ? ORDER BY scheduled_at IS NULL, scheduled_at, id', [$baby['id']]);
        return Response::data(array_map([self::class, 'appointmentJson'], $rows));
    }

    public function storeAppointment(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $in = $req->validate(self::APPOINTMENT_RULES);
        $in['notify'] ??= 0;
        $row = $this->create('appointments', $baby['id'], $in);
        return Response::data(self::appointmentJson($row), 201);
    }

    public function updateAppointment(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $row = $this->findChild('appointments', $req->param('appointment'), $baby['id']);
        $in = $req->validate(self::partial(self::APPOINTMENT_RULES));
        $row = $this->patch('appointments', $row['id'], $in);
        return Response::data(self::appointmentJson($row));
    }

    public function destroyAppointment(Request $req): array
    {
        return $this->destroy($req, 'appointments', 'appointment');
    }

    private static function appointmentJson(array $a): array
    {
        return [
            'id'           => (int) $a['id'],
            'title'        => $a['title'],
            'doctor'       => $a['doctor'],
            'hospital'     => $a['hospital'],
            'scheduled_at' => Format::dateTime($a['scheduled_at']),
            'notify'       => Format::bool($a['notify']),
        ];
    }

    // -- E-posta raporu ---------------------------------------------------------

    /** Son 30 günün özetini ve sağlık bilgilerini düz metin e-posta ile yollar. */
    public function sendReport(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $in = $req->validate(['email' => 'required|email|max:190']);

        $body = $this->buildReport($baby);
        $subject = '=?UTF-8?B?' . base64_encode("MiniKalp raporu – {$baby['name']}") . '?=';
        $from = $GLOBALS['config']['mail_from'] ?? 'no-reply@example.com';
        $headers = implode("\r\n", [
            "From: $from",
            'MIME-Version: 1.0',
            'Content-Type: text/plain; charset=UTF-8',
            'Content-Transfer-Encoding: 8bit',
        ]);

        if (!@mail($in['email'], $subject, $body, $headers)) {
            throw new HttpException(500, 'Rapor gönderilemedi. Sunucunun e-posta ayarını kontrol edin.');
        }
        return Response::message('Rapor gönderildi.');
    }

    private function buildReport(array $baby): string
    {
        $since = date('Y-m-d', strtotime('-30 days'));
        $counts = Database::all(
            'SELECT type, COUNT(*) AS n FROM records WHERE baby_id = ? AND recorded_at >= ? GROUP BY type ORDER BY type',
            [$baby['id'], $since],
        );
        $growth = Database::one(
            'SELECT * FROM growth_measurements WHERE baby_id = ? ORDER BY measured_at DESC, id DESC LIMIT 1',
            [$baby['id']],
        );
        $fevers = Database::all(
            "SELECT recorded_at, temperature FROM records
              WHERE baby_id = ? AND type = 'fever' AND recorded_at >= ?
              ORDER BY recorded_at DESC LIMIT 10",
            [$baby['id'], $since],
        );
        $vaccines = Database::all('SELECT * FROM vaccines WHERE baby_id = ? ORDER BY due_date', [$baby['id']]);

        $lines = [
            "MiniKalp sağlık raporu",
            "Bebek: {$baby['name']} (doğum: {$baby['birth_date']}, " . Format::ageInMonths($baby['birth_date']) . ' aylık)',
            "Dönem: $since – " . date('Y-m-d'),
            '',
            'Son 30 gün kayıt sayıları:',
        ];
        foreach ($counts as $c) {
            $lines[] = "  - {$c['type']}: {$c['n']}";
        }
        if ($counts === []) {
            $lines[] = '  (kayıt yok)';
        }

        $lines[] = '';
        $lines[] = 'Son ölçüm:';
        $lines[] = $growth
            ? sprintf('  %s — kilo: %s kg, boy: %s cm, baş: %s cm', $growth['measured_at'], $growth['weight_kg'] ?? '-', $growth['height_cm'] ?? '-', $growth['head_cm'] ?? '-')
            : '  (ölçüm yok)';

        if ($fevers !== []) {
            $lines[] = '';
            $lines[] = 'Ateş ölçümleri:';
            foreach ($fevers as $f) {
                $lines[] = "  - {$f['recorded_at']}: {$f['temperature']} °C";
            }
        }

        if ($vaccines !== []) {
            $lines[] = '';
            $lines[] = 'Aşılar:';
            foreach ($vaccines as $v) {
                $lines[] = "  - {$v['name']} ({$v['age_label']}): {$v['status']}" . ($v['due_date'] ? ", {$v['due_date']}" : '');
            }
        }

        $lines[] = '';
        $lines[] = 'Bu rapor bilgilendirme amaçlıdır; tıbbi değerlendirme yerine geçmez.';
        return implode("\n", $lines);
    }

    // -- Ortak yardımcılar -----------------------------------------------------

    /** Güncellemede zorunlu alanlar isteğe bağlı olur. */
    private static function partial(array $rules): array
    {
        return array_map(fn ($r) => str_replace('required|', '', $r), $rules);
    }

    private function create(string $table, int $babyId, array $data): array
    {
        $id = Database::insert($table, ['baby_id' => $babyId] + $data);
        return Database::one("SELECT * FROM `$table` WHERE id = ?", [$id]);
    }

    private function patch(string $table, int $id, array $data): array
    {
        // NOT NULL sütunlara null gelirse varsayılan değer yazılır.
        $defaults = ['notify' => 0, 'status' => 'upcoming', 'age_label' => ''];
        foreach ($defaults as $key => $default) {
            if (array_key_exists($key, $data) && $data[$key] === null) {
                $data[$key] = $default;
            }
        }
        Database::update($table, $id, $data);
        return Database::one("SELECT * FROM `$table` WHERE id = ?", [$id]);
    }

    private function destroy(Request $req, string $table, string $param): array
    {
        $baby = Auth::ownedBaby($req);
        $row = $this->findChild($table, $req->param($param), $baby['id']);
        Database::query("DELETE FROM `$table` WHERE id = ?", [$row['id']]);
        return Response::noContent();
    }

    private function findChild(string $table, int $id, int $babyId): array
    {
        $row = Database::one("SELECT * FROM `$table` WHERE id = ? AND baby_id = ?", [$id, $babyId]);
        if ($row === null) {
            throw HttpException::notFound();
        }
        return $row;
    }
}
