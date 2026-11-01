<?php

namespace App\Core;

/**
 * Bearer token doğrulaması. Token yalnızca oluşturulduğunda düz metin olarak
 * istemciye verilir; veritabanında SHA-256 özeti saklanır.
 */
class Auth
{
    public static function user(Request $request): array
    {
        $token = $request->bearerToken();
        if ($token === null) {
            throw HttpException::unauthenticated();
        }

        $row = Database::one(
            'SELECT t.id AS token_id, u.id, u.name, u.email, u.created_at
               FROM api_tokens t
               JOIN users u ON u.id = t.user_id
              WHERE t.token_hash = ?',
            [hash('sha256', $token)],
        );
        if ($row === null) {
            throw HttpException::unauthenticated();
        }

        Database::query('UPDATE api_tokens SET last_used_at = NOW() WHERE id = ?', [$row['token_id']]);
        return $row;
    }

    /** Yeni bir token üretir, özetini kaydeder ve düz halini döner. */
    public static function issueToken(int $userId, ?string $deviceName): string
    {
        $token = bin2hex(random_bytes(32));
        Database::insert('api_tokens', [
            'user_id'     => $userId,
            'token_hash'  => hash('sha256', $token),
            'device_name' => $deviceName,
        ]);
        return $token;
    }

    public static function revoke(Request $request): void
    {
        $token = $request->bearerToken();
        if ($token !== null) {
            Database::query('DELETE FROM api_tokens WHERE token_hash = ?', [hash('sha256', $token)]);
        }
    }

    /**
     * Bebeğin istekteki kullanıcıya ait olduğunu doğrular. Başkasının bebeği
     * için "yok" yanıtı verilir; böylece kimlikler tahmin edilerek veri sızmaz.
     */
    public static function ownedBaby(Request $request, string $param = 'baby'): array
    {
        $baby = Database::one(
            'SELECT * FROM babies WHERE id = ? AND user_id = ?',
            [$request->param($param), $request->userId()],
        );
        if ($baby === null) {
            throw HttpException::notFound('Bebek bulunamadı.');
        }
        return $baby;
    }
}
