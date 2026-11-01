<?php

namespace App\Core;

/**
 * Laravel tarzı, küçük bir doğrulayıcı.
 *
 * Kurallar: required, nullable, string, int, numeric, bool, date, datetime,
 * time, email, array, min:n, max:n, in:a,b,c
 *
 * Gönderilmeyen ve "required" olmayan alanlar sonuçta yer almaz; böylece aynı
 * kurallar hem oluşturma hem kısmi güncelleme için kullanılabilir. Değerler
 * veritabanına yazılacak biçime çevrilir (bool → 0/1, datetime → Y-m-d H:i:s).
 */
class Validator
{
    public static function validate(array $input, array $rules): array
    {
        $out = [];
        $errors = [];

        foreach ($rules as $field => $ruleString) {
            $ruleList = explode('|', $ruleString);
            $present = array_key_exists($field, $input);
            $value = $present ? $input[$field] : null;
            $isEmpty = $value === null || $value === '';

            if (in_array('required', $ruleList, true) && $isEmpty) {
                $errors[$field][] = "$field alanı zorunludur.";
                continue;
            }
            if (!$present) {
                continue;
            }
            if ($isEmpty) {
                if (in_array('nullable', $ruleList, true)) {
                    $out[$field] = null;
                } else {
                    $errors[$field][] = "$field alanı boş olamaz.";
                }
                continue;
            }

            $error = null;
            foreach ($ruleList as $rule) {
                [$name, $arg] = array_pad(explode(':', $rule, 2), 2, null);
                $error = self::apply($name, $arg, $field, $value);
                if ($error !== null) {
                    break;
                }
            }

            if ($error !== null) {
                $errors[$field][] = $error;
            } else {
                $out[$field] = $value;
            }
        }

        if ($errors !== []) {
            throw HttpException::validation($errors);
        }
        return $out;
    }

    /** Kuralı uygular; geçerse null döner ve gerekirse $value'yu dönüştürür. */
    private static function apply(string $name, ?string $arg, string $field, mixed &$value): ?string
    {
        switch ($name) {
            case 'required':
            case 'nullable':
                return null;

            case 'string':
                if (!is_string($value)) {
                    return "$field metin olmalıdır.";
                }
                $value = trim($value);
                return null;

            case 'int':
                if (is_int($value) || (is_string($value) && preg_match('/^-?\d+$/', $value))) {
                    $value = (int) $value;
                    return null;
                }
                if (is_float($value) && floor($value) === $value) {
                    $value = (int) $value;
                    return null;
                }
                return "$field tam sayı olmalıdır.";

            case 'numeric':
                if (!is_numeric($value)) {
                    return "$field sayı olmalıdır.";
                }
                $value = (float) $value;
                return null;

            case 'bool':
                $parsed = filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
                if ($parsed === null) {
                    return "$field true/false olmalıdır.";
                }
                $value = $parsed ? 1 : 0;
                return null;

            case 'date':
                $d = is_string($value) ? \DateTime::createFromFormat('!Y-m-d', substr($value, 0, 10)) : false;
                if (!$d) {
                    return "$field geçerli bir tarih olmalıdır (YYYY-AA-GG).";
                }
                $value = $d->format('Y-m-d');
                return null;

            case 'datetime':
                // Flutter toIso8601String(): "2026-11-01T10:20:30.123456" (yerel saat).
                // Saat dilimi bilgisi gelirse sunucunun saat dilimine çevrilir.
                try {
                    if (!is_string($value)) {
                        throw new \Exception();
                    }
                    $d = new \DateTime($value);
                    $d->setTimezone(new \DateTimeZone(date_default_timezone_get()));
                } catch (\Exception) {
                    return "$field geçerli bir tarih-saat olmalıdır.";
                }
                $value = $d->format('Y-m-d H:i:s');
                return null;

            case 'time':
                if (!is_string($value) || !preg_match('/^([01]\d|2[0-3]):[0-5]\d$/', $value)) {
                    return "$field SS:DD biçiminde olmalıdır.";
                }
                return null;

            case 'email':
                if (!is_string($value) || !filter_var($value, FILTER_VALIDATE_EMAIL)) {
                    return "$field geçerli bir e-posta olmalıdır.";
                }
                $value = strtolower(trim($value));
                return null;

            case 'array':
                return is_array($value) ? null : "$field bir liste olmalıdır.";

            case 'min':
            case 'max':
                $limit = (float) $arg;
                $size = is_string($value) ? mb_strlen($value) : (is_array($value) ? count($value) : $value);
                if ($name === 'min' && $size < $limit) {
                    return "$field en az $arg olmalıdır.";
                }
                if ($name === 'max' && $size > $limit) {
                    return "$field en fazla $arg olabilir.";
                }
                return null;

            case 'in':
                $allowed = explode(',', (string) $arg);
                return in_array((string) $value, $allowed, true)
                    ? null
                    : "$field şu değerlerden biri olmalıdır: " . implode(', ', $allowed) . '.';

            default:
                throw new \LogicException("Bilinmeyen doğrulama kuralı: $name");
        }
    }
}
