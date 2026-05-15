<?php

return [
    'credentials_path' => env(
        'FIREBASE_CREDENTIALS',
        storage_path('app/firebase-service-account.json')
    ),
];
