<#
.SYNOPSIS
  TDSE API Test Suite for Windows
.DESCRIPTION
  Tests public endpoints, JWT validation, protected endpoints, and error cases.
.EXAMPLE
  .\test_api.ps1
.EXAMPLE
  .\test_api.ps1 -Token "eyJhbG..."
.EXAMPLE
  .\test_api.ps1 -ApiUrl "http://custom-url:8080"
#>

param (
    [string]$Token = "",
    [string]$ApiUrl = ""
)

$ErrorActionPreference = "Stop"

# ─── Counters ─────────────────────────────────────────────────────────────────
$script:PASSED = 0
$script:FAILED = 0

# ─── Load .env.test if present ────────────────────────────────────────────────
if (Test-Path ".env.test") {
    Write-Host "Loading .env.test..." -ForegroundColor Cyan
    Get-Content ".env.test" | Where-Object { $_ -match "^([^#=]+)=(.*)$" } | ForEach-Object {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim().Trim('"', "'")
        [Environment]::SetEnvironmentVariable($name, $value)
    }
}

# ─── Set Defaults (overridden by .env.test or CLI flags) ──────────────────────
$envApiUrl = [Environment]::GetEnvironmentVariable("API_URL")
if ([string]::IsNullOrEmpty($ApiUrl)) {
    $ApiUrl = if (![string]::IsNullOrEmpty($envApiUrl)) { $envApiUrl } else { "http://localhost:8080" }
}

$AUTH0_DOMAIN = [Environment]::GetEnvironmentVariable("AUTH0_DOMAIN")
$AUTH0_CLIENT_ID = [Environment]::GetEnvironmentVariable("AUTH0_CLIENT_ID")
$AUTH0_CLIENT_SECRET = [Environment]::GetEnvironmentVariable("AUTH0_CLIENT_SECRET")
$AUTH0_AUDIENCE = [Environment]::GetEnvironmentVariable("AUTH0_AUDIENCE")

# ─── Helpers ──────────────────────────────────────────────────────────────────
function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan -NoNewline; Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
}

function Assert-Status {
    param([string]$Label, [int]$Expected, [int]$Actual, [string]$Body = "")
    if ($Actual -eq $Expected) {
        Write-Host "  ✅ PASS  " -ForegroundColor Green -NoNewline; Write-Host "$Label -> HTTP $Actual"
        $script:PASSED++
    } else {
        Write-Host "  ❌ FAIL  " -ForegroundColor Red -NoNewline; Write-Host "$Label -> expected HTTP $Expected, got HTTP $Actual"
        if (![string]::IsNullOrWhiteSpace($Body)) {
            $truncated = if ($Body.Length -gt 300) { $Body.Substring(0, 300) + "..." } else { $Body }
            Write-Host "         Response: $truncated" -ForegroundColor Yellow
        }
        $script:FAILED++
    }
}

function Invoke-Http {
    param([string]$Method, [string]$Path, [hashtable]$Headers = @{}, [string]$Body = "")
    $Uri = "$ApiUrl$Path"

    $reqParameters = @{
        Uri = $Uri
        Method = $Method
        Headers = $Headers
        UseBasicParsing = $true
    }

    if (![string]::IsNullOrEmpty($Body)) {
        $reqParameters.Body = [System.Text.Encoding]::UTF8.GetBytes($Body)
        $reqParameters.ContentType = "application/json"
    }

    try {
        $response = Invoke-WebRequest @reqParameters
        return @{ StatusCode = [int]$response.StatusCode; Content = $response.Content }
    } catch {
        if ($_.Exception.Response) {
            $resp = $_.Exception.Response
            $stream = $resp.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $content = $reader.ReadToEnd()
            return @{ StatusCode = [int]$resp.StatusCode; Content = $content }
        } else {
            return @{ StatusCode = 0; Content = $_.Exception.Message }
        }
    }
}

# ─── Prerequisites ─────────────────────────────────────────────────────────────
Write-Section "Prerequisites"

Write-Host "  Checking backend at $ApiUrl..."
try {
    $null = Invoke-WebRequest -Uri "$ApiUrl/actuator/health" -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
    $backendUp = $true
} catch {
    try {
        $null = Invoke-WebRequest -Uri "$ApiUrl/api/posts" -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
        $backendUp = $true
    } catch {
        $backendUp = $false
    }
}

if (!$backendUp) {
    Write-Host "  ✗ Backend not reachable at $ApiUrl. Is the server running?" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ Backend reachable at $ApiUrl" -ForegroundColor Green

# ─── Token acquisition ────────────────────────────────────────────────────────
Write-Section "Token Acquisition"

$WorkingToken = ""

if (![string]::IsNullOrEmpty($Token)) {
    $WorkingToken = $Token
    Write-Host "  ✓ Using manually provided token (-Token flag)" -ForegroundColor Green
} elseif (![string]::IsNullOrEmpty($AUTH0_DOMAIN) -and ![string]::IsNullOrEmpty($AUTH0_CLIENT_ID) -and ![string]::IsNullOrEmpty($AUTH0_CLIENT_SECRET) -and ![string]::IsNullOrEmpty($AUTH0_AUDIENCE)) {
    Write-Host "  Fetching M2M token from Auth0 ($AUTH0_DOMAIN)..."

    $authBody = @{
        client_id = $AUTH0_CLIENT_ID
        client_secret = $AUTH0_CLIENT_SECRET
        audience = $AUTH0_AUDIENCE
        grant_type = "client_credentials"
    } | ConvertTo-Json

    try {
        $tokenRes = Invoke-RestMethod -Uri "https://$AUTH0_DOMAIN/oauth/token" -Method Post -Body $authBody -ContentType "application/json"
        $WorkingToken = $tokenRes.access_token
        Write-Host "  ✓ Token acquired from Auth0" -ForegroundColor Green
        $preview = $WorkingToken.Substring(0, [math]::Min(40, $WorkingToken.Length)) + "..."
        Write-Host "    Token preview: $preview" -ForegroundColor Cyan
    } catch {
        Write-Host "  ✗ Failed to fetch token from Auth0: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Protected endpoint tests will be skipped." -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠ No Auth0 credentials found in .env.test and no -Token provided." -ForegroundColor Yellow
    Write-Host "    Protected endpoint tests will be skipped." -ForegroundColor Yellow
}

# ─── Test 1: Public Endpoints ─────────────────────────────────────────────────
Write-Section "1. Public Endpoints (no token required)"

$res = Invoke-Http -Method "GET" -Path "/api/posts"
Assert-Status "GET /api/posts returns 200" 200 $res.StatusCode $res.Content

$resStream = Invoke-Http -Method "GET" -Path "/api/stream"
Assert-Status "GET /api/stream returns 200" 200 $resStream.StatusCode $resStream.Content

# Verify JSON Array
$jsonArray = $res.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
if (($jsonArray -is [array]) -or ($null -ne $jsonArray.content)) {
    Write-Host "  ✅ PASS  " -ForegroundColor Green -NoNewline; Write-Host "GET /api/posts returns a JSON list"
    $script:PASSED++
} else {
    $preview = if ($res.Content.Length -gt 200) { $res.Content.Substring(0,200) } else { $res.Content }
    Write-Host "  ❌ FAIL  " -ForegroundColor Red -NoNewline; Write-Host "GET /api/posts did not return a JSON list — got: $preview"
    $script:FAILED++
}

# ─── Test 2: Unauthenticated Access ───────────────────────────────────────────
Write-Section "2. Protected Endpoints — No Token (expect 401)"

$res = Invoke-Http -Method "GET" -Path "/api/me"
Assert-Status "GET /api/me without token -> 401" 401 $res.StatusCode $res.Content

$res = Invoke-Http -Method "POST" -Path "/api/posts" -Body '{"content":"Unauthorized post attempt"}'
Assert-Status "POST /api/posts without token -> 401" 401 $res.StatusCode $res.Content

# ─── Test 3: Invalid Token ────────────────────────────────────────────────────
Write-Section "3. Invalid Token Handling (expect 401)"

$res = Invoke-Http -Method "GET" -Path "/api/me" -Headers @{ "Authorization" = "Bearer this.is.not.a.jwt" }
Assert-Status "GET /api/me with garbage token -> 401" 401 $res.StatusCode $res.Content

$FAKE_JWT = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmYWtlIiwiYXVkIjoiaHR0cHM6Ly90ZHNlYXBwLmFwaSIsImlzcyI6Imh0dHBzOi8vZmFrZS5hdXRoMC5jb20vIn0.invalidsignature"
$res = Invoke-Http -Method "GET" -Path "/api/me" -Headers @{ "Authorization" = "Bearer $FAKE_JWT" }
Assert-Status "GET /api/me with invalid signature -> 401" 401 $res.StatusCode $res.Content

# ─── Tests 4 & 5: Authenticated Actions ───────────────────────────────────────
if (![string]::IsNullOrEmpty($WorkingToken)) {
    $authHeader = @{ "Authorization" = "Bearer $WorkingToken" }

    Write-Section "4. Protected Endpoints — Valid Token"

    $res = Invoke-Http -Method "GET" -Path "/api/me" -Headers $authHeader
    Assert-Status "GET /api/me with valid token -> 200" 200 $res.StatusCode $res.Content

    if ($res.StatusCode -eq 200) {
        $meJson = $res.Content | ConvertFrom-Json -ErrorAction SilentlyContinue
        if (($null -ne $meJson.userId) -or ($null -ne $meJson.id)) {
            Write-Host "  ✅ PASS  " -ForegroundColor Green -NoNewline; Write-Host "/api/me response contains user identifier field"
            $script:PASSED++
        } else {
            $preview = if ($res.Content.Length -gt 200) { $res.Content.Substring(0,200) } else { $res.Content }
            Write-Host "  ❌ FAIL  " -ForegroundColor Red -NoNewline; Write-Host "/api/me response missing 'userId'/'id' field — got: $preview"
            $script:FAILED++
        }
    }

    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $POST_CONTENT = "Test post from automated suite $timestamp"
    $bodyObj = @{ content = $POST_CONTENT } | ConvertTo-Json

    $res = Invoke-Http -Method "POST" -Path "/api/posts" -Headers $authHeader -Body $bodyObj
    Assert-Status "POST /api/posts with valid token -> 201" 201 $res.StatusCode $res.Content

    if ($res.StatusCode -eq 201) {
        Start-Sleep -Seconds 1
        $feed = Invoke-Http -Method "GET" -Path "/api/posts"
        $feedJson = $feed.Content | ConvertFrom-Json -ErrorAction SilentlyContinue

        $found = $false
        if ($feedJson -is [array]) {
            $found = ($null -ne ($feedJson | Where-Object { $_.content -eq $POST_CONTENT }))
        } elseif ($null -ne $feedJson.content) {
            $found = ($null -ne ($feedJson.content | Where-Object { $_.content -eq $POST_CONTENT }))
        }

        if ($found) {
            Write-Host "  ✅ PASS  " -ForegroundColor Green -NoNewline; Write-Host "New post appears in GET /api/posts feed"
            $script:PASSED++
        } else {
            Write-Host "  ⚠ INFO   " -ForegroundColor Yellow -NoNewline; Write-Host "Could not confirm post in feed (pagination may hide it)"
        }
    }

    Write-Section "5. Business Rules"

    $LONG_POST = "x" * 141
    $bodyObj = @{ content = $LONG_POST } | ConvertTo-Json
    $res = Invoke-Http -Method "POST" -Path "/api/posts" -Headers $authHeader -Body $bodyObj
    Assert-Status "POST /api/posts with 141-char content -> 400" 400 $res.StatusCode $res.Content

    $EXACT_POST = "x" * 140
    $bodyObj = @{ content = $EXACT_POST } | ConvertTo-Json
    $res = Invoke-Http -Method "POST" -Path "/api/posts" -Headers $authHeader -Body $bodyObj
    Assert-Status "POST /api/posts with exactly 140 chars -> 201" 201 $res.StatusCode $res.Content

    $bodyObj = @{ content = "" } | ConvertTo-Json
    $res = Invoke-Http -Method "POST" -Path "/api/posts" -Headers $authHeader -Body $bodyObj
    Assert-Status "POST /api/posts with empty content -> 400" 400 $res.StatusCode $res.Content

} else {
    Write-Host "`n  ⚠ Skipping Tests 4 & 5 — no valid token available." -ForegroundColor Yellow
    Write-Host "    See .env.test.example to configure Auth0 M2M credentials." -ForegroundColor Yellow
}

# ─── Summary ──────────────────────────────────────────────────────────────────
Write-Section "Test Summary"
Write-Host "  Passed: $script:PASSED" -ForegroundColor Green
Write-Host "  Failed: $script:FAILED" -ForegroundColor Red
$TOTAL = $script:PASSED + $script:FAILED
Write-Host "  Total:  $TOTAL`n"

if ($script:FAILED -eq 0) {
    Write-Host "  All tests passed. ✓" -ForegroundColor Green
    exit 0
} else {
    Write-Host "  Some tests failed. See output above." -ForegroundColor Red
    exit 1
}