<?php

namespace App\Controllers;

use App\Core\Database;
use App\Core\Format;
use App\Core\Request;
use App\Core\Response;

/**
 * Kullanıcıya bağlı veriler: annenin ruh hali ve uygulama ayarları.
 */
class UserController
{
    public function mood(Request $req): array
    {
        $rows = Database::all(
            'SELECT * FROM mood_entries WHERE user_id = ? ORDER BY recorded_at DESC, id DESC',
            [$req->userId()],
        );
        return Response::data(array_map([self::class, 'moodJson'], $rows));
    }

    public function storeMood(Request $req): array
    {
        $in = $req->validate([
            'score'       => 'required|int|min:1|max:5',
            'note'        => 'nullable|string|max:2000',
            'recorded_at' => 'nullable|datetime',
        ]);
        $in['recorded_at'] ??= date('Y-m-d H:i:s');
        $in['user_id'] = $req->userId();

        $id = Database::insert('mood_entries', $in);
        return Response::data(self::moodJson(Database::one('SELECT * FROM mood_entries WHERE id = ?', [$id])), 201);
    }

    private static function moodJson(array $m): array
    {
        return [
            'id'          => (int) $m['id'],
            'score'       => (int) $m['score'],
            'note'        => $m['note'],
            'recorded_at' => Format::dateTime($m['recorded_at']),
        ];
    }

    public function settings(Request $req): array
    {
        return Response::data($this->loadSettings($req->userId()));
    }

    public function updateSettings(Request $req): array
    {
        $in = $req->validate([
            'notifications' => 'bool',
            'volume_unit'   => 'in:ml,oz',
            'weight_unit'   => 'in:kg,lb',
            'language'      => 'in:tr,en',
        ]);

        $this->loadSettings($req->userId()); // satır yoksa oluşturur
        if ($in !== []) {
            $set = implode(', ', array_map(fn ($c) => "`$c` = :$c", array_keys($in)));
            Database::query("UPDATE user_settings SET $set WHERE user_id = :uid", $in + ['uid' => $req->userId()]);
        }
        return Response::data($this->loadSettings($req->userId()));
    }

    private function loadSettings(int $userId): array
    {
        $row = Database::one('SELECT * FROM user_settings WHERE user_id = ?', [$userId]);
        if ($row === null) {
            Database::query('INSERT IGNORE INTO user_settings (user_id) VALUES (?)', [$userId]);
            $row = Database::one('SELECT * FROM user_settings WHERE user_id = ?', [$userId]);
        }
        return [
            'notifications' => Format::bool($row['notifications']),
            'volume_unit'   => $row['volume_unit'],
            'weight_unit'   => $row['weight_unit'],
            'language'      => $row['language'],
        ];
    }
}
