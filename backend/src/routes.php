<?php

use App\Controllers\AuthController;
use App\Controllers\BabyController;
use App\Controllers\ContentController;
use App\Controllers\DevelopmentController;
use App\Controllers\DiaryController;
use App\Controllers\GrowthController;
use App\Controllers\HealthController;
use App\Controllers\RecordController;
use App\Controllers\UserController;
use App\Core\Router;

// Uç noktalar lib/core/api/api_client.dart ile birebir eşleşir.
// Üçüncü parametre false olan rotalar kimlik doğrulaması istemez.

$r = new Router();

// Kimlik
$r->post('/register', [AuthController::class, 'register'], false);
$r->post('/login', [AuthController::class, 'login'], false);
$r->post('/logout', [AuthController::class, 'logout']);
$r->get('/user', [AuthController::class, 'me']);

// Açık içerik
$r->get('/app/config', [ContentController::class, 'appConfig'], false);
$r->get('/info-articles', [ContentController::class, 'infoArticles'], false);

// Bebekler
$r->get('/babies', [BabyController::class, 'index']);
$r->post('/babies', [BabyController::class, 'store']);
$r->put('/babies/{baby}', [BabyController::class, 'update']);
$r->delete('/babies/{baby}', [BabyController::class, 'destroy']);
$r->get('/babies/{baby}/article', [ContentController::class, 'articleForBaby']);
$r->get('/babies/{baby}/dashboard', [BabyController::class, 'dashboard']);
$r->get('/babies/{baby}/summary', [BabyController::class, 'summary']);
$r->get('/babies/{baby}/expressed-milk', [BabyController::class, 'expressedMilk']);
$r->put('/babies/{baby}/expressed-milk', [BabyController::class, 'updateExpressedMilk']);

// Kayıtlar
$r->get('/babies/{baby}/records', [RecordController::class, 'index']);
$r->post('/babies/{baby}/records', [RecordController::class, 'store']);
$r->delete('/babies/{baby}/records/{record}', [RecordController::class, 'destroy']);

// Büyüme
$r->get('/babies/{baby}/growth', [GrowthController::class, 'index']);
$r->get('/babies/{baby}/growth/latest', [GrowthController::class, 'latest']);
$r->post('/babies/{baby}/growth', [GrowthController::class, 'store']);

// Gelişim
$r->get('/babies/{baby}/milestones', [DevelopmentController::class, 'milestones']);
$r->post('/babies/{baby}/milestones/toggle', [DevelopmentController::class, 'toggleMilestone']);
$r->get('/babies/{baby}/teeth', [DevelopmentController::class, 'teeth']);
$r->post('/babies/{baby}/teeth/toggle', [DevelopmentController::class, 'toggleTooth']);
$r->get('/babies/{baby}/memories', [DevelopmentController::class, 'memories']);
$r->post('/babies/{baby}/memories', [DevelopmentController::class, 'storeMemory']);
$r->put('/babies/{baby}/memories/{memory}', [DevelopmentController::class, 'updateMemory']);
$r->delete('/babies/{baby}/memories/{memory}', [DevelopmentController::class, 'destroyMemory']);
$r->get('/babies/{baby}/photos', [DevelopmentController::class, 'photos']);
$r->post('/babies/{baby}/photos', [DevelopmentController::class, 'storePhoto']);
$r->delete('/babies/{baby}/photos/{photo}', [DevelopmentController::class, 'destroyPhoto']);

// Sağlık
$r->get('/babies/{baby}/medicine-reminders', [HealthController::class, 'reminders']);
$r->post('/babies/{baby}/medicine-reminders', [HealthController::class, 'storeReminder']);
$r->post('/babies/{baby}/medicine-reminders/{reminder}/toggle', [HealthController::class, 'toggleReminder']);
$r->delete('/babies/{baby}/medicine-reminders/{reminder}', [HealthController::class, 'destroyReminder']);
$r->get('/babies/{baby}/vaccines', [HealthController::class, 'vaccines']);
$r->post('/babies/{baby}/vaccines', [HealthController::class, 'storeVaccine']);
$r->put('/babies/{baby}/vaccines/{vaccine}', [HealthController::class, 'updateVaccine']);
$r->delete('/babies/{baby}/vaccines/{vaccine}', [HealthController::class, 'destroyVaccine']);
$r->get('/babies/{baby}/appointments', [HealthController::class, 'appointments']);
$r->post('/babies/{baby}/appointments', [HealthController::class, 'storeAppointment']);
$r->put('/babies/{baby}/appointments/{appointment}', [HealthController::class, 'updateAppointment']);
$r->delete('/babies/{baby}/appointments/{appointment}', [HealthController::class, 'destroyAppointment']);
$r->post('/babies/{baby}/send-report', [HealthController::class, 'sendReport']);

// Günlük
$r->get('/babies/{baby}/diary', [DiaryController::class, 'index']);
$r->post('/babies/{baby}/diary', [DiaryController::class, 'store']);
$r->put('/babies/{baby}/diary/{entry}', [DiaryController::class, 'update']);
$r->delete('/babies/{baby}/diary/{entry}', [DiaryController::class, 'destroy']);

// Kullanıcı
$r->get('/mood', [UserController::class, 'mood']);
$r->post('/mood', [UserController::class, 'storeMood']);
$r->get('/settings', [UserController::class, 'settings']);
$r->put('/settings', [UserController::class, 'updateSettings']);

return $r;
