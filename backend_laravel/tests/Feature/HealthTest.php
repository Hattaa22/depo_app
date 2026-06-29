<?php

namespace Tests\Feature;

use Tests\TestCase;

class HealthTest extends TestCase
{
    public function test_health_endpoint_returns_service_status(): void
    {
        $this->getJson('/api/v1/health')
            ->assertOk()
            ->assertJson([
                'status' => 'ok',
                'service' => 'depo-laravel-api',
            ]);
    }
}
