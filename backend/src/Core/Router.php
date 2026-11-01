<?php

namespace App\Core;

/**
 * Küçük bir rota eşleyici. Yollar "{id}" biçiminde sayısal parametre alır.
 * Her rota bir [ControllerSınıfı, 'metot'] çiftine ve isteğe bağlı olarak
 * kimlik doğrulama gereksinimine bağlanır.
 */
class Router
{
    /** @var array<int, array{method:string, regex:string, handler:array, auth:bool}> */
    private array $routes = [];

    public function get(string $path, array $handler, bool $auth = true): void
    {
        $this->add('GET', $path, $handler, $auth);
    }

    public function post(string $path, array $handler, bool $auth = true): void
    {
        $this->add('POST', $path, $handler, $auth);
    }

    public function put(string $path, array $handler, bool $auth = true): void
    {
        $this->add('PUT', $path, $handler, $auth);
    }

    public function delete(string $path, array $handler, bool $auth = true): void
    {
        $this->add('DELETE', $path, $handler, $auth);
    }

    private function add(string $method, string $path, array $handler, bool $auth): void
    {
        $regex = preg_replace('#\{(\w+)\}#', '(?P<$1>\d+)', rtrim($path, '/') ?: '/');
        $this->routes[] = [
            'method'  => $method,
            'regex'   => '#^' . $regex . '$#',
            'handler' => $handler,
            'auth'    => $auth,
        ];
    }

    public function dispatch(Request $request): array
    {
        $method = $request->method === 'PATCH' ? 'PUT' : $request->method;
        $pathMatched = false;

        foreach ($this->routes as $route) {
            if (!preg_match($route['regex'], $request->path, $m)) {
                continue;
            }
            $pathMatched = true;
            if ($route['method'] !== $method) {
                continue;
            }

            $request->params = array_filter($m, 'is_string', ARRAY_FILTER_USE_KEY);
            if ($route['auth']) {
                $request->user = Auth::user($request);
            }

            [$class, $action] = $route['handler'];
            return (new $class())->$action($request);
        }

        throw $pathMatched
            ? new HttpException(405, 'Bu yöntem desteklenmiyor.')
            : new HttpException(404, 'Uç nokta bulunamadı.');
    }
}
