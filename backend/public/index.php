<?php

/**
 * MiniKalp API — ön denetleyici. Tüm istekler buradan geçer.
 *
 * Geliştirme:  php -S 0.0.0.0:8000 -t public public/index.php
 * Adres:       http://127.0.0.1:8000/api
 */

declare(strict_types=1);

use App\Core\Database;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;

$root = dirname(__DIR__);

spl_autoload_register(function (string $class) use ($root) {
    if (str_starts_with($class, 'App\\')) {
        $file = $root . '/src/' . str_replace('\\', '/', substr($class, 4)) . '.php';
        if (is_file($file)) {
            require $file;
        }
    }
});

$configFile = $root . '/config/config.php';
if (!is_file($configFile)) {
    Response::send(Response::message('config/config.php bulunamadı (config.example.php dosyasını kopyalayın).', 500));
    exit;
}
$config = require $configFile;
$GLOBALS['config'] = $config;

date_default_timezone_set($config['timezone'] ?? 'Europe/Istanbul');
ini_set('display_errors', '0');

header('Access-Control-Allow-Origin: ' . ($config['cors_origin'] ?? '*'));
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Authorization, Content-Type, Accept');
header('X-Content-Type-Options: nosniff');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

try {
    Database::connect($config['db']);
    $router = require $root . '/src/routes.php';
    $response = $router->dispatch(Request::fromGlobals());
} catch (HttpException $e) {
    $body = ['message' => $e->getMessage()];
    if ($e->errors !== null) {
        $body['errors'] = $e->errors;
    }
    $response = Response::raw($body, $e->status);
} catch (\Throwable $e) {
    error_log('[minikalp] ' . $e);
    $body = ['message' => 'Sunucu hatası.'];
    if (!empty($config['debug'])) {
        $body['exception'] = get_class($e);
        $body['detail'] = $e->getMessage();
        $body['at'] = $e->getFile() . ':' . $e->getLine();
    }
    $response = Response::raw($body, 500);
}

Response::send($response);
