# MiniKalp API (saf PHP + PDO + MySQL)

Flutter uygulamasının (`lib/core/api/api_client.dart`) beklediği uç noktaların
çatısız (framework'süz) PHP karşılığı. Gereksinim: PHP 8.1+ (`pdo_mysql`),
MySQL 8 (veya MariaDB 10.5+).

## Kurulum

```bash
cd backend
mysql -u root -p < database/schema.sql
cp config/config.example.php config/config.php   # DB bilgilerini girin
php -S 0.0.0.0:8000 -t public public/index.php
```

Uygulamanın varsayılan adresi `http://127.0.0.1:8000/api` olduğundan ek ayar
gerekmez. Android emülatörde `http://10.0.2.2:8000/api`, gerçek cihazda
bilgisayarın LAN IP'si kullanılır (bkz. `../BACKEND_INTEGRATION.md`).

Apache'de belge kökü `public/` ya da `backend/` olabilir; iki durumda da adres
`https://alanadi.com/api/...` olur. Kök `backend/` ise kök dizindeki
`.htaccess` istekleri `public/` altına yönlendirir ve `config/`, `src/`,
`database/` klasörlerini dışarıya kapatır.

## Yapı

```
public/index.php          ön denetleyici: autoload, CORS, hata → JSON
src/routes.php            tüm rotalar (api_client.dart ile birebir)
src/Core/                 Database (PDO), Router, Request, Validator, Auth, Response, Format
src/Controllers/          Auth, Content, Baby, Record, Growth, Development, Health, Diary, User
database/schema.sql       tablolar
```

## Sözleşme

- Başarılı yanıtlar `{"data": ...}`; `/register` ve `/login` `{"token", "user"}` döner.
- Hatalar `{"message", "errors"?}` — doğrulama 422, yetkisiz 401, bulunamadı 404.
- Kimlik: `Authorization: Bearer <token>`. Token veritabanında SHA-256 özeti olarak saklanır.
- Bir kullanıcı yalnızca kendi bebeklerine erişebilir; başkasının bebeği 404 döner.
- Tarih-saatler saat dilimi eki olmadan `YYYY-MM-DDTHH:MM:SS` döner (sunucu saat dilimi `config.php` → `timezone`).
- `GET /records?from=&to=` aralığı `[from, to)` şeklindedir.

## İçerik yönetimi

Yönetim paneli yoktur; şu tablolar doğrudan doldurulur:

| Tablo | Kullanıldığı yer |
|---|---|
| `app_config` (tek satır, id=1) | Açılış ekranı zorunlu güncelleme kontrolü |
| `info_articles` | Ana sayfa "Bilgilendirmeler" |
| `month_articles` | Bebeğin ayına göre yazı (o ay yoksa en yakın önceki ay) |

## Notlar

- `POST /babies/{id}/send-report` PHP `mail()` kullanır; sunucuda e-posta
  gönderimi (sendmail/SMTP) yapılandırılmamışsa 500 döner.
- Bebek silindiğinde ona bağlı tüm kayıtlar `ON DELETE CASCADE` ile silinir.
- Fotoğraf yolları (`photo_path`, `path`) cihazdaki dosya yollarıdır; dosya
  yükleme bu API'de yoktur.
