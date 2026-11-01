<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Database;
use App\Core\Format;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;

/**
 * Annenin bebek için aylık günlüğü. month gönderilmezse bebeğin şu anki ayı
 * kullanılır.
 */
class DiaryController
{
    public function index(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $q = $req->validateQuery(['month' => 'nullable|int|min:0|max:255']);

        $sql = 'SELECT * FROM diary_entries WHERE baby_id = ?';
        $params = [$baby['id']];
        if (isset($q['month'])) {
            $sql .= ' AND month = ?';
            $params[] = $q['month'];
        }
        $rows = Database::all($sql . ' ORDER BY created_at DESC, id DESC', $params);
        return Response::data(array_map([self::class, 'toJson'], $rows));
    }

    public function store(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $in = $req->validate([
            'body'  => 'required|string|max:10000',
            'month' => 'nullable|int|min:0|max:255',
        ]);
        $in['month'] ??= Format::ageInMonths($baby['birth_date']);
        $in['baby_id'] = $baby['id'];

        $id = Database::insert('diary_entries', $in);
        return Response::data(self::toJson(Database::one('SELECT * FROM diary_entries WHERE id = ?', [$id])), 201);
    }

    public function update(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $entry = $this->find($req->param('entry'), $baby['id']);
        $in = $req->validate(['body' => 'required|string|max:10000']);

        Database::update('diary_entries', $entry['id'], $in);
        return Response::data(self::toJson(Database::one('SELECT * FROM diary_entries WHERE id = ?', [$entry['id']])));
    }

    public function destroy(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $entry = $this->find($req->param('entry'), $baby['id']);
        Database::query('DELETE FROM diary_entries WHERE id = ?', [$entry['id']]);
        return Response::noContent();
    }

    private function find(int $id, int $babyId): array
    {
        $row = Database::one('SELECT * FROM diary_entries WHERE id = ? AND baby_id = ?', [$id, $babyId]);
        if ($row === null) {
            throw HttpException::notFound();
        }
        return $row;
    }

    private static function toJson(array $d): array
    {
        return [
            'id'         => (int) $d['id'],
            'month'      => (int) $d['month'],
            'body'       => $d['body'],
            'created_at' => Format::dateTime($d['created_at']),
            'updated_at' => Format::dateTime($d['updated_at']),
        ];
    }
}
