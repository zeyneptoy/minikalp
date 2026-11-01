<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Database;
use App\Core\Format;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;

class GrowthController
{
    public function index(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $rows = Database::all(
            'SELECT * FROM growth_measurements WHERE baby_id = ? ORDER BY measured_at DESC, id DESC',
            [$baby['id']],
        );
        return Response::data(array_map([self::class, 'toJson'], $rows));
    }

    public function latest(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $row = Database::one(
            'SELECT * FROM growth_measurements WHERE baby_id = ? ORDER BY measured_at DESC, id DESC LIMIT 1',
            [$baby['id']],
        );
        return Response::data($row ? self::toJson($row) : null);
    }

    public function store(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $in = $req->validate([
            'weight_kg'   => 'nullable|numeric|min:0|max:100',
            'height_cm'   => 'nullable|numeric|min:0|max:250',
            'head_cm'     => 'nullable|numeric|min:0|max:100',
            'measured_at' => 'nullable|datetime',
        ]);

        if (($in['weight_kg'] ?? null) === null && ($in['height_cm'] ?? null) === null && ($in['head_cm'] ?? null) === null) {
            throw HttpException::validation(['weight_kg' => ['En az bir ölçüm girilmelidir.']]);
        }
        $in['measured_at'] ??= date('Y-m-d H:i:s');
        $in['baby_id'] = $baby['id'];

        $id = Database::insert('growth_measurements', $in);
        $row = Database::one('SELECT * FROM growth_measurements WHERE id = ?', [$id]);
        return Response::data(self::toJson($row), 201);
    }

    public static function toJson(array $g): array
    {
        return [
            'id'          => (int) $g['id'],
            'weight_kg'   => Format::float($g['weight_kg']),
            'height_cm'   => Format::float($g['height_cm']),
            'head_cm'     => Format::float($g['head_cm']),
            'measured_at' => Format::dateTime($g['measured_at']),
        ];
    }
}
