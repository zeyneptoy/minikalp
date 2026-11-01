<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Database;
use App\Core\Format;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;

/**
 * Gelişim: kilometre taşları, dişler, "ilk"ler (anılar) ve fotoğraf albümü.
 */
class DevelopmentController
{
    // -- Kilometre taşları (anahtar kümesi) --------------------------------

    public function milestones(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        return Response::data(self::milestoneKeys($baby['id']));
    }

    /** Anahtar işaretliyse kaldırır, değilse ekler; güncel kümeyi döner. */
    public function toggleMilestone(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $in = $req->validate(['key' => 'required|string|max:100']);

        $removed = Database::query(
            'DELETE FROM milestones WHERE baby_id = ? AND milestone_key = ?',
            [$baby['id'], $in['key']],
        )->rowCount();
        if ($removed === 0) {
            Database::insert('milestones', ['baby_id' => $baby['id'], 'milestone_key' => $in['key']]);
        }
        return Response::data(self::milestoneKeys($baby['id']));
    }

    private static function milestoneKeys(int $babyId): array
    {
        return array_column(
            Database::all('SELECT milestone_key FROM milestones WHERE baby_id = ? ORDER BY created_at', [$babyId]),
            'milestone_key',
        );
    }

    // -- Dişler (0–19 indeks kümesi) ----------------------------------------

    public function teeth(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        return Response::data(self::toothIndices($baby['id']));
    }

    public function toggleTooth(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $in = $req->validate(['index' => 'required|int|min:0|max:19']);

        $removed = Database::query(
            'DELETE FROM teeth WHERE baby_id = ? AND tooth_index = ?',
            [$baby['id'], $in['index']],
        )->rowCount();
        if ($removed === 0) {
            Database::insert('teeth', ['baby_id' => $baby['id'], 'tooth_index' => $in['index']]);
        }
        return Response::data(self::toothIndices($baby['id']));
    }

    private static function toothIndices(int $babyId): array
    {
        return array_map(
            'intval',
            array_column(Database::all('SELECT tooth_index FROM teeth WHERE baby_id = ? ORDER BY tooth_index', [$babyId]), 'tooth_index'),
        );
    }

    // -- Anılar ("ilk"ler) ---------------------------------------------------

    public function memories(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $rows = Database::all('SELECT * FROM memories WHERE baby_id = ? ORDER BY sort_order, id', [$baby['id']]);
        return Response::data(array_map([self::class, 'memoryJson'], $rows));
    }

    public function storeMemory(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $in = $req->validate([
            'title'      => 'required|string|max:190',
            'photo_path' => 'nullable|string|max:500',
        ]);
        $max = Database::one('SELECT COALESCE(MAX(sort_order), -1) AS m FROM memories WHERE baby_id = ?', [$baby['id']]);
        $in['sort_order'] = (int) $max['m'] + 1;
        $in['baby_id'] = $baby['id'];

        $id = Database::insert('memories', $in);
        return Response::data(self::memoryJson(Database::one('SELECT * FROM memories WHERE id = ?', [$id])), 201);
    }

    public function updateMemory(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $memory = $this->findChild('memories', $req->param('memory'), $baby['id']);
        $in = $req->validate([
            'title'      => 'string|max:190',
            'photo_path' => 'nullable|string|max:500',
        ]);
        Database::update('memories', $memory['id'], $in);
        return Response::data(self::memoryJson(Database::one('SELECT * FROM memories WHERE id = ?', [$memory['id']])));
    }

    public function destroyMemory(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $memory = $this->findChild('memories', $req->param('memory'), $baby['id']);
        Database::query('DELETE FROM memories WHERE id = ?', [$memory['id']]);
        return Response::noContent();
    }

    private static function memoryJson(array $m): array
    {
        return [
            'id'         => (int) $m['id'],
            'title'      => $m['title'],
            'photo_path' => $m['photo_path'],
            'created_at' => Format::dateTime($m['created_at']),
        ];
    }

    // -- Fotoğraf albümü -----------------------------------------------------

    public function photos(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $q = $req->validateQuery(['month' => 'nullable|int|min:0|max:255']);

        $sql = 'SELECT * FROM photos WHERE baby_id = ?';
        $params = [$baby['id']];
        if (isset($q['month'])) {
            $sql .= ' AND month = ?';
            $params[] = $q['month'];
        }
        $rows = Database::all($sql . ' ORDER BY created_at DESC, id DESC', $params);
        return Response::data(array_map([self::class, 'photoJson'], $rows));
    }

    public function storePhoto(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $in = $req->validate([
            'path'  => 'required|string|max:500',
            'month' => 'nullable|int|min:0|max:255',
        ]);
        $in['baby_id'] = $baby['id'];

        $id = Database::insert('photos', $in);
        return Response::data(self::photoJson(Database::one('SELECT * FROM photos WHERE id = ?', [$id])), 201);
    }

    public function destroyPhoto(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $photo = $this->findChild('photos', $req->param('photo'), $baby['id']);
        Database::query('DELETE FROM photos WHERE id = ?', [$photo['id']]);
        return Response::noContent();
    }

    private static function photoJson(array $p): array
    {
        return [
            'id'         => (int) $p['id'],
            'path'       => $p['path'],
            'month'      => $p['month'] === null ? null : (int) $p['month'],
            'created_at' => Format::dateTime($p['created_at']),
        ];
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
