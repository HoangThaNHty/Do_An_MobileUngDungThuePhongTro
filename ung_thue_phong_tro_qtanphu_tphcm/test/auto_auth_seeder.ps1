# PowerShell Seeder Script to Sync Firebase Auth & Realtime Database
# Created by Antigravity for HoangThaNHty/Do_An_MobileUngDungThuePhongTro

$ErrorActionPreference = "Stop"
$apiKey = "AIzaSyB4WBPJHmADW5lo1Q-tTykBYGm7avpysZ8"
$dbUrl = "https://doannhomdomchua-default-rtdb.asia-southeast1.firebasedatabase.app/.json"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "[START] STARTING FIREBASE AUTH SYNCHRONIZATION AND RTDB SEEDING" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Define mock users with their roles and templates
$mockUsers = @(
    @{ email = "annguyen@email.com"; placeholder = "LANDLORD_AN_UID"; role = "Landlord Nguyen Van An" },
    @{ email = "bichtran@email.com"; placeholder = "LANDLORD_BICH_UID"; role = "Landlord Tran Thi Bich" },
    @{ email = "namle@email.com"; placeholder = "TENANT_NAM_UID"; role = "Tenant Le Hoang Nam" },
    @{ email = "lanpham@email.com"; placeholder = "TENANT_LAN_UID"; role = "Tenant Pham Thi Lan" }
)

$uidMap = @{
    "ZL5CO8QAieRspg3OkLLhZbuCZb2" = "ZL5CO8QAieRspg3OkLLhZbuCZb2" # Keep Google login static UID
}
$password = "123456"

foreach ($user in $mockUsers) {
    $email = $user.email
    $role = $user.role
    $placeholder = $user.placeholder
    
    Write-Host "[USER] Processing $role ($email)..." -ForegroundColor Yellow
    
    # 1. Try to sign up via public Google Identity Toolkit REST API
    $signUpUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey"
    $body = @{
        email = $email
        password = $password
        returnSecureToken = $true
    } | ConvertTo-Json
    
    $uid = $null
    
    try {
        $response = Invoke-RestMethod -Uri $signUpUrl -Method Post -Body $body -ContentType "application/json"
        $uid = $response.localId
        Write-Host "   [SUCCESS] Successfully CREATED new Auth account. UID: $uid" -ForegroundColor Green
    } catch {
        # Check if the error is because the email already exists
        $errStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errStream)
        $errText = $reader.ReadToEnd()
        
        if ($errText -like "*EMAIL_EXISTS*") {
            Write-Host "   [INFO] Account already exists. Retrieving UID via sign-in..." -ForegroundColor Cyan
            
            # 2. Try to sign in to get the existing UID
            $signInUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey"
            try {
                $response = Invoke-RestMethod -Uri $signInUrl -Method Post -Body $body -ContentType "application/json"
                $uid = $response.localId
                Write-Host "   [SUCCESS] Retrieved existing Auth account. UID: $uid" -ForegroundColor Green
            } catch {
                Write-Host "   [ERROR] Failed to sign in to existing account! Error: $_" -ForegroundColor Red
                continue
            }
        } else {
            Write-Host "   [ERROR] Failed to create account! Error: $errText" -ForegroundColor Red
            continue
        }
    }
    
    if ($uid) {
        $uidMap[$placeholder] = $uid
    }
}

Write-Host ""
Write-Host "[MAP] Sync Summary & Mapping:" -ForegroundColor Cyan
foreach ($placeholder in $uidMap.Keys) {
    Write-Host "   $placeholder ==> $($uidMap[$placeholder])" -ForegroundColor Gray
}

# Ensure all 4 accounts have been mapped
if ($uidMap.Count -lt 5) {
    Write-Host "[WARN] Warning: Not all mock accounts were successfully synced or created. Database placeholders will not be fully replaced." -ForegroundColor Yellow
}

# 3. Read the firebase_seed_template.json
$templatePath = Join-Path $PSScriptRoot "firebase_seed_template.json"
if (-not (Test-Path $templatePath)) {
    Write-Host "[ERROR] Error: Could not find template file at $templatePath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[READ] Reading seed template from $templatePath..." -ForegroundColor Yellow
$templateContent = Get-Content -Path $templatePath -Raw -Encoding Utf8

# 4. Perform replacements
Write-Host "[REPLACE] Replacing placeholders with real Firebase Auth UIDs..." -ForegroundColor Yellow
foreach ($placeholder in $uidMap.Keys) {
    $realUid = $uidMap[$placeholder]
    $templateContent = $templateContent.Replace($placeholder, $realUid)
}

# 5. Save the finalized JSON
$seedPath = Join-Path $PSScriptRoot "firebase_seed.json"
Write-Host "[SAVE] Saving synchronized seed data to $seedPath..." -ForegroundColor Yellow
$templateContent | Out-File -FilePath $seedPath -Encoding utf8 -Force

# 6. Seed directly to Realtime Database via REST API PUT request
Write-Host ""
Write-Host "[SEED] Seeding synchronized data to Firebase Realtime Database ($dbUrl)..." -ForegroundColor Yellow
try {
    # Send PUT request to replace all database nodes
    $response = Invoke-RestMethod -Uri $dbUrl -Method Put -Body $templateContent -ContentType "application/json; charset=utf-8"
    Write-Host "[SUCCESS] SUCCESS! Firebase Realtime Database has been successfully seeded and is perfectly in-sync with Authentication!" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "[CREDENTIALS] TEST CREDENTIALS (PASSWORD: 123456 FOR ALL):" -ForegroundColor White
    Write-Host "   1. Landlord An:  annguyen@email.com" -ForegroundColor White
    Write-Host "   2. Landlord Bich: bichtran@email.com" -ForegroundColor White
    Write-Host "   3. Tenant Nam:   namle@email.com" -ForegroundColor White
    Write-Host "   4. Tenant Lan:   lanpham@email.com" -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to seed Realtime Database! Error: $_" -ForegroundColor Red
    exit 1
}
