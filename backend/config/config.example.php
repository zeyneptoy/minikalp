<?php
// Bu dosyayı config.php olarak kopyalayıp kendi değerlerinizi girin.
// config.php git'e eklenmez (.gitignore).

return [
    'db' => [
        'host'     => '127.0.0.1',
        'port'     => 3306,
        'database' => 'minikalp',
        'username' => 'root',
        'password' => '',
        'charset'  => 'utf8mb4',
    ],

    // Hata ayrıntıları yalnızca geliştirmede gösterilir.
    'debug' => false,

    'timezone' => 'Europe/Istanbul',

    // İzin verilen CORS kaynağı ('*' = hepsi). Mobil uygulama CORS kullanmaz;
    // yalnızca web build için önemlidir.
    'cors_origin' => '*',

    // Rapor e-postasının gönderen adresi (PHP mail() kullanılır).
    'mail_from' => 'no-reply@example.com',
];
