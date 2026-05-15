<?php

namespace App\Services;

use GuzzleHttp\Client;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class FirebaseCloudMessagingService
{
    private Client $client;

    public function __construct()
    {
        $this->client = new Client([
            'timeout' => 20,
        ]);
    }

    public function sendToToken(string $fcmToken, string $title, string $body, array $data = []): bool
    {
        $credentials = $this->getCredentials();
        if (!$credentials) {
            Log::warning('FCM credentials tidak ditemukan. Push notification dilewati.');
            return false;
        }

        $accessToken = $this->getAccessToken($credentials);
        if (!$accessToken) {
            return false;
        }

        try {
            $this->client->post(
                'https://fcm.googleapis.com/v1/projects/' . $credentials['project_id'] . '/messages:send',
                [
                    'headers' => [
                        'Authorization' => 'Bearer ' . $accessToken,
                        'Content-Type' => 'application/json',
                    ],
                    'json' => [
                        'message' => [
                            'token' => $fcmToken,
                            'notification' => [
                                'title' => $title,
                                'body' => $body,
                            ],
                            'data' => array_map(
                                fn ($value) => (string) $value,
                                $data
                            ),
                            'android' => [
                                'priority' => 'high',
                                'notification' => [
                                    'channel_id' => 'chat_messages_channel',
                                ],
                            ],
                        ],
                    ],
                ]
            );

            return true;
        } catch (\Throwable $e) {
            Log::error('Gagal mengirim FCM', [
                'message' => $e->getMessage(),
            ]);
            return false;
        }
    }

    private function getCredentials(): ?array
    {
        $path = config('firebase.credentials_path');
        if (!$path || !file_exists($path)) {
            return null;
        }

        $decoded = json_decode(file_get_contents($path), true);
        if (!is_array($decoded)) {
            return null;
        }

        return $decoded;
    }

    private function getAccessToken(array $credentials): ?string
    {
        return Cache::remember('firebase_access_token', 3300, function () use ($credentials) {
            try {
                $now = time();
                $header = $this->base64UrlEncode(json_encode([
                    'alg' => 'RS256',
                    'typ' => 'JWT',
                ]));

                $claims = $this->base64UrlEncode(json_encode([
                    'iss' => $credentials['client_email'],
                    'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                    'aud' => $credentials['token_uri'] ?? 'https://oauth2.googleapis.com/token',
                    'iat' => $now,
                    'exp' => $now + 3600,
                ]));

                $signatureInput = $header . '.' . $claims;
                openssl_sign(
                    $signatureInput,
                    $signature,
                    $credentials['private_key'],
                    'sha256WithRSAEncryption'
                );

                $jwt = $signatureInput . '.' . $this->base64UrlEncode($signature);

                $response = $this->client->post(
                    $credentials['token_uri'] ?? 'https://oauth2.googleapis.com/token',
                    [
                        'form_params' => [
                            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                            'assertion' => $jwt,
                        ],
                    ]
                );

                $data = json_decode((string) $response->getBody(), true);
                return $data['access_token'] ?? null;
            } catch (\Throwable $e) {
                Log::error('Gagal mendapatkan access token Firebase', [
                    'message' => $e->getMessage(),
                ]);
                return null;
            }
        });
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
