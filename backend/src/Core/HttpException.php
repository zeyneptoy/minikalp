<?php

namespace App\Core;

/**
 * Bir istek sırasında fırlatılan, doğrudan JSON hata yanıtına dönüşen istisna.
 * Gövde Flutter istemcisinin beklediği biçimdedir: {message, errors?}.
 */
class HttpException extends \RuntimeException
{
    public function __construct(
        public readonly int $status,
        string $message,
        public readonly ?array $errors = null,
    ) {
        parent::__construct($message, $status);
    }

    public static function notFound(string $message = 'Kayıt bulunamadı.'): self
    {
        return new self(404, $message);
    }

    public static function unauthenticated(): self
    {
        return new self(401, 'Unauthenticated.');
    }

    /** @param array<string, string[]> $errors */
    public static function validation(array $errors): self
    {
        $first = reset($errors)[0] ?? 'Geçersiz veri.';
        return new self(422, $first, $errors);
    }
}
