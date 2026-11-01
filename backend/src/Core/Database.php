<?php

namespace App\Core;

use PDO;

/**
 * Tek PDO bağlantısı ve küçük yardımcılar. Tüm sorgular hazırlanmış ifade
 * (prepared statement) kullanır; kullanıcı verisi asla SQL'e birleştirilmez.
 */
class Database
{
    private static ?PDO $pdo = null;

    public static function connect(array $cfg): void
    {
        $dsn = sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=%s',
            $cfg['host'],
            $cfg['port'] ?? 3306,
            $cfg['database'],
            $cfg['charset'] ?? 'utf8mb4',
        );

        self::$pdo = new PDO($dsn, $cfg['username'], $cfg['password'], [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
            PDO::ATTR_STRINGIFY_FETCHES  => false,
        ]);

        // NOW() ve CURRENT_TIMESTAMP, PHP ile aynı saat diliminde çalışsın.
        self::$pdo->exec("SET time_zone = '" . date('P') . "'");
    }

    public static function pdo(): PDO
    {
        if (self::$pdo === null) {
            throw new \LogicException('Database::connect() çağrılmadı.');
        }
        return self::$pdo;
    }

    public static function query(string $sql, array $params = []): \PDOStatement
    {
        $stmt = self::pdo()->prepare($sql);
        $stmt->execute($params);
        return $stmt;
    }

    public static function one(string $sql, array $params = []): ?array
    {
        $row = self::query($sql, $params)->fetch();
        return $row === false ? null : $row;
    }

    public static function all(string $sql, array $params = []): array
    {
        return self::query($sql, $params)->fetchAll();
    }

    /** Satır ekler ve yeni id'yi döner. Sütun adları koddan gelir, değerler bağlanır. */
    public static function insert(string $table, array $data): int
    {
        $cols = array_keys($data);
        $sql = sprintf(
            'INSERT INTO `%s` (%s) VALUES (%s)',
            $table,
            implode(', ', array_map(fn ($c) => "`$c`", $cols)),
            implode(', ', array_map(fn ($c) => ":$c", $cols)),
        );
        self::query($sql, $data);
        return (int) self::pdo()->lastInsertId();
    }

    /** Verilen id'li satırı günceller. */
    public static function update(string $table, int $id, array $data): void
    {
        if ($data === []) {
            return;
        }
        $set = implode(', ', array_map(fn ($c) => "`$c` = :$c", array_keys($data)));
        $data['__id'] = $id;
        self::query("UPDATE `$table` SET $set WHERE id = :__id", $data);
    }
}
