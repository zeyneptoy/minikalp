<?php

namespace App\Core;

/**
 * Veritabanı değerlerini istemcinin beklediği JSON türlerine çevirir.
 *
 * Tarih-saatler saat dilimi eki olmadan "2026-11-01T10:20:30" biçiminde
 * döner; Flutter bunu yerel saat olarak okur, yani gönderdiği değerle aynı
 * anı geri alır.
 */
class Format
{
    public static function dateTime(?string $value): ?string
    {
        return $value === null ? null : str_replace(' ', 'T', $value);
    }

    public static function bool(mixed $value): bool
    {
        return (bool) $value;
    }

    public static function float(mixed $value): ?float
    {
        return $value === null ? null : (float) $value;
    }

    /** Bebeğin doğumdan bu yana tamamladığı ay sayısı (0 tabanlı). */
    public static function ageInMonths(string $birthDate, ?\DateTimeInterface $at = null): int
    {
        $diff = (new \DateTime($birthDate))->diff($at ?? new \DateTime('today'));
        return $diff->invert ? 0 : $diff->y * 12 + $diff->m;
    }
}
