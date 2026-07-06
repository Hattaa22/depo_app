<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme' => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'midtrans' => [
        'client_key' => env('MIDTRANS_CLIENT_KEY'),
        'server_key' => env('MIDTRANS_SERVER_KEY'),
        'is_production' => (bool) env('MIDTRANS_IS_PRODUCTION', false),
        'is_sanitized' => (bool) env('MIDTRANS_IS_SANITIZED', true),
        'is_3ds' => (bool) env('MIDTRANS_IS_3DS', true),
        'snap_base_url' => env('MIDTRANS_SNAP_BASE_URL'),
        'api_base_url' => env('MIDTRANS_API_BASE_URL'),
        'allow_simulation' => (bool) env('MIDTRANS_ALLOW_SIMULATION', false),
    ],

    'jwt' => [
        'secret' => env('JWT_SECRET'),
    ],

];
