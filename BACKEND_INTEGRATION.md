# Backend bağlantısı (MinikNot API)

Uygulama yerel depolamanın yanında **MiniKalp API**'sine (saf PHP + PDO +
MySQL, `backend/` klasörü) bağlı çalışır. Tüm yazma işlemleri optimistic
(anında yerelde) uygulanır ve arka planda sunucuya işlenir; aktif bebek
değiştiğinde veriler sunucudan çekilir.

## 1. Sunucu adresi

Varsayılan: **`https://minikalp.seydidemir.com/api`**
(`lib/core/api/api_config.dart` → `productionBaseUrl`).

## 2. Yerel geliştirme

```bash
cd backend
php -S 0.0.0.0:8000 -t public public/index.php
```

Uygulamayı yerel sunucuya yönlendirmek için adresi çalışırken geçin (ya da
Profil → Ayarlar → Sunucu adresi; boş kaydedilirse varsayılana döner):

```bash
# Android emülatör (host loopback)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Gerçek telefon (bilgisayarın LAN IP'si)
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api
```

> Android debug build'inde düz HTTP'ye izin verildi
> (`android/app/src/debug/AndroidManifest.xml` → `usesCleartextTraffic`).
> iOS, localhost'a varsayılan olarak izin verir. Release build'ler HTTPS
> kullanır; `INTERNET` izni ana manifest'tedir.

## 3. Kimlik doğrulama (otomatik)

Uygulamada giriş ekranı yoktur. İlk açılışta **cihaza özel bir hesap** sessizce
oluşturulur; e-posta/parola ve token cihazda saklanır, sonraki açılışlarda aynı
backend kullanıcısı kullanılır (`ApiClient.ensureAuthenticated`).

## Mimari

| Katman | Dosya |
|---|---|
| Bağlantı ayarı | `lib/core/api/api_config.dart` |
| HTTP + token + sessiz auth + tüm uç metodları | `lib/core/api/api_client.dart` |
| `apiClientProvider`, `currentBabyIdProvider` | `lib/core/api/api_providers.dart` |
| Kayıt ↔ API gövde dönüşümü | `lib/core/api/record_mapper.dart` |

Mevcut Riverpod sağlayıcıları backend'e bağlandı (durum tipleri değişmedi, UI'a
dokunulmadı):

- `babies_provider` → bebek oluştur/güncelle (`remoteId` saklanır)
- `records_provider` → kayıtlar + sağılmış süt stoğu + ilaç hatırlatıcıları
- `development_provider` → büyüme, kilometre taşları, diş, anılar, albüm, ruh hali
- `settings_provider` → kullanıcı ayarları

Her yazma işlemi önce yerelde uygulanır, sonra API'ye gönderilir. Ağ hatasında
yerel durum korunur ve bir sonraki senkronizasyonda tekrar denenir.
