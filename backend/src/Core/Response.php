<?php

namespace App\Core;

/**
 * Denetleyicilerin döndürdüğü yanıt. Gövde her zaman JSON'dur.
 */
class Response
{
    public static function data(mixed $data, int $status = 200): array
    {
        return ['status' => $status, 'body' => ['data' => $data]];
    }

    public static function message(string $message, int $status = 200): array
    {
        return ['status' => $status, 'body' => ['message' => $message]];
    }

    public static function raw(array $body, int $status = 200): array
    {
        return ['status' => $status, 'body' => $body];
    }

    public static function noContent(): array
    {
        return ['status' => 204, 'body' => null];
    }

    public static function send(array $response): void
    {
        http_response_code($response['status']);
        if ($response['body'] !== null) {
            header('Content-Type: application/json; charset=utf-8');
            echo json_encode(
                $response['body'],
                JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRESERVE_ZERO_FRACTION,
            );
        }
    }
}
