<?php

declare(strict_types=1);

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Support\Env;

$app = Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        commands: __DIR__.'/../routes/console.php',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();

// Configure storage path for embedded FrankenPHP binary
$storagePath = array_key_exists('LARAVEL_STORAGE_PATH', $_ENV)
    ? Env::get('LARAVEL_STORAGE_PATH')
    : (getenv('LARAVEL_STORAGE_PATH') ?: '/tmp/laravel-storage');
if ($storagePath && is_string($storagePath)) {
    // Ensure the storage path exists
    if (! is_dir($storagePath)) {
        @mkdir($storagePath, 0755, true);
    }

    // Set up required subdirectories
    $subdirs = ['logs', 'framework/cache', 'framework/sessions', 'framework/views', 'app'];
    foreach ($subdirs as $subdir) {
        $fullPath = $storagePath.'/'.$subdir;
        if (! is_dir($fullPath)) {
            @mkdir($fullPath, 0755, true);
        }
    }

    $app->useStoragePath($storagePath);
}

return $app;
