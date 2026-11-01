<?php

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Database;
use App\Core\HttpException;
use App\Core\Request;
use App\Core\Response;

/**
 * Uygulamada giriş ekranı yoktur: ilk açılışta cihaza özel bir hesap sessizce
 * /register ile açılır, sonraki açılışlarda /login ile token yenilenir.
 */
class AuthController
{
    public function register(Request $req): array
    {
        $in = $req->validate([
            'name'        => 'required|string|max:120',
            'email'       => 'required|email|max:190',
            'password'    => 'required|string|min:8|max:255',
            'device_name' => 'nullable|string|max:120',
        ]);

        if (Database::one('SELECT id FROM users WHERE email = ?', [$in['email']])) {
            throw HttpException::validation(['email' => ['Bu e-posta zaten kayıtlı.']]);
        }

        $pdo = Database::pdo();
        $pdo->beginTransaction();
        try {
            $userId = Database::insert('users', [
                'name'          => $in['name'],
                'email'         => $in['email'],
                'password_hash' => password_hash($in['password'], PASSWORD_DEFAULT),
            ]);
            Database::insert('user_settings', ['user_id' => $userId]);
            $token = Auth::issueToken($userId, $in['device_name'] ?? null);
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        return Response::raw(['token' => $token, 'user' => $this->userJson($userId)], 201);
    }

    public function login(Request $req): array
    {
        $in = $req->validate([
            'email'       => 'required|email',
            'password'    => 'required|string',
            'device_name' => 'nullable|string|max:120',
        ]);

        $user = Database::one('SELECT id, password_hash FROM users WHERE email = ?', [$in['email']]);
        if ($user === null || !password_verify($in['password'], $user['password_hash'])) {
            throw HttpException::validation(['email' => ['E-posta veya parola hatalı.']]);
        }

        if (password_needs_rehash($user['password_hash'], PASSWORD_DEFAULT)) {
            Database::update('users', $user['id'], [
                'password_hash' => password_hash($in['password'], PASSWORD_DEFAULT),
            ]);
        }

        $token = Auth::issueToken($user['id'], $in['device_name'] ?? null);
        return Response::raw(['token' => $token, 'user' => $this->userJson($user['id'])]);
    }

    public function logout(Request $req): array
    {
        Auth::revoke($req);
        return Response::message('Çıkış yapıldı.');
    }

    public function me(Request $req): array
    {
        return Response::raw($this->userJson($req->userId()));
    }

    private function userJson(int $id): array
    {
        $u = Database::one('SELECT id, name, email, created_at FROM users WHERE id = ?', [$id]);
        $u['created_at'] = \App\Core\Format::dateTime($u['created_at']);
        return $u;
    }
}
