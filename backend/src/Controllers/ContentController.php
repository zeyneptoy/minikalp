<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Database;
use App\Core\Format;
use App\Core\Request;
use App\Core\Response;

/**
 * Yönetici tarafından doldurulan içerik: sürüm ayarı ve yazılar.
 */
class ContentController
{
    /** Açılış ekranının zorunlu güncelleme kontrolü (kimlik gerekmez). */
    public function appConfig(Request $req): array
    {
        $c = Database::one('SELECT * FROM app_config WHERE id = 1') ?? [];

        return Response::data([
            'latest_version'       => $c['latest_version'] ?? '1.0.0',
            'min_required_version' => $c['min_required_version'] ?? '1.0.0',
            'force_update'         => Format::bool($c['force_update'] ?? false),
            'android_store_url'    => $c['android_store_url'] ?? null,
            'ios_store_url'        => $c['ios_store_url'] ?? null,
        ]);
    }

    /** Ana sayfa "Bilgilendirmeler" (kimlik gerekmez). */
    public function infoArticles(Request $req): array
    {
        $rows = Database::all(
            'SELECT id, title, excerpt, body, image_url
               FROM info_articles
              WHERE is_active = 1
              ORDER BY sort_order, id DESC',
        );
        return Response::data($rows);
    }

    /** Bebeğin bulunduğu aya uygun yazı; o ay için yoksa en yakın önceki ay. */
    public function articleForBaby(Request $req): array
    {
        $baby = Auth::ownedBaby($req);
        $month = Format::ageInMonths($baby['birth_date']);

        $row = Database::one(
            'SELECT id, month, title, body
               FROM month_articles
              WHERE month <= ?
              ORDER BY month DESC
              LIMIT 1',
            [$month],
        );
        return Response::data($row);
    }
}
