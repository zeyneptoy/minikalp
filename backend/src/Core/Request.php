<?php

namespace App\Core;

/**
 * Gelen HTTP isteği: yöntem, yol, sorgu, JSON gövdesi, rota parametreleri ve
 * kimliği doğrulanmış kullanıcı.
 */
class Request
{
    public array $params = [];
    public ?array $user = null;

    private ?array $body = null;

    public function __construct(
        public readonly string $method,
        public readonly string $path,
        public readonly array $query,
        private readonly string $rawBody,
        private readonly array $headers,
    ) {
    }

    public static function fromGlobals(): self
    {
        $uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';

        // Her şeyi "/api" önekinden sonrasına indirger; böylece API ister kök
        // dizinde ister bir alt klasörde (ör. /minikalp/backend/public/api)
        // çalışsın, rotalar aynı kalır.
        $pos = strpos($uri, '/api');
        $path = $pos === false ? $uri : substr($uri, $pos + 4);
        $path = '/' . trim($path, '/');

        $headers = [];
        foreach ($_SERVER as $key => $value) {
            if (str_starts_with($key, 'HTTP_')) {
                $headers[strtolower(str_replace('_', '-', substr($key, 5)))] = $value;
            }
        }
        // Bazı Apache kurulumları Authorization'ı yalnızca bu anahtarda verir.
        if (!isset($headers['authorization']) && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            $headers['authorization'] = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        }

        return new self(
            strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET'),
            $path,
            $_GET,
            file_get_contents('php://input') ?: '',
            $headers,
        );
    }

    public function bearerToken(): ?string
    {
        $header = $this->headers['authorization'] ?? '';
        if (preg_match('/^Bearer\s+(\S+)$/i', $header, $m)) {
            return $m[1];
        }
        return null;
    }

    public function body(): array
    {
        if ($this->body === null) {
            if ($this->rawBody === '') {
                $this->body = [];
            } else {
                $decoded = json_decode($this->rawBody, true);
                if (!is_array($decoded)) {
                    throw new HttpException(400, 'Geçersiz JSON gövdesi.');
                }
                $this->body = $decoded;
            }
        }
        return $this->body;
    }

    public function has(string $key): bool
    {
        return array_key_exists($key, $this->body());
    }

    public function param(string $name): int
    {
        return (int) $this->params[$name];
    }

    public function userId(): int
    {
        return (int) $this->user['id'];
    }

    /** Gövdeyi kurallara göre doğrular; yalnızca gönderilen alanları döner. */
    public function validate(array $rules): array
    {
        return Validator::validate($this->body(), $rules);
    }

    /** Sorgu parametrelerini doğrular. */
    public function validateQuery(array $rules): array
    {
        return Validator::validate($this->query, $rules);
    }
}
