# PowerShell Seeder Script to Sync Firebase Auth & Realtime Database
# Created by Antigravity for HoangThaNHty/Do_An_MobileUngDungThuePhongTro

$ErrorActionPreference = "Stop"
$apiKey = "AIzaSyB4WBPJHmADW5lo1Q-tTykBYGm7avpysZ8"
$dbUrl = "https://doannhomdomchua-default-rtdb.asia-southeast1.firebasedatabase.app/.json"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "[START] STARTING FIREBASE AUTH SYNCHRONIZATION AND RTDB SEEDING" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Define demo users with their roles and template placeholders
$mockUsers = @(
    @{ email = "admin.demo@email.com"; placeholder = "ADMIN_DEMO_UID"; role = "Admin System Supervisor" },
    @{ email = "chutro.demo@email.com"; placeholder = "LANDLORD_DEMO_UID"; role = "Landlord Nguyen Van An" },
    @{ email = "khang.demo@email.com"; placeholder = "TENANT_KHANG_UID"; role = "New Tenant Tran Minh Khang" },
    @{ email = "mai.demo@email.com"; placeholder = "TENANT_MAI_UID"; role = "New Tenant Le Ngoc Mai" }
)

$uidMap = @{}
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

# Ensure all 4 demo accounts have been mapped
if ($uidMap.Count -lt 4) {
    Write-Host "[WARN] Warning: Not all demo accounts were successfully synced or created. Database placeholders will not be fully replaced." -ForegroundColor Yellow
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
    Write-Host "[SUCCESS] SUCCESS! Firebase Realtime Database has been seeded with clean presentation demo data." -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "[CREDENTIALS] DEMO CREDENTIALS (PASSWORD: 123456 FOR ALL):" -ForegroundColor White
    Write-Host "   1. Admin he thong:            admin.demo@email.com" -ForegroundColor White
    Write-Host "   2. Chu tro Nguyen Van An:     chutro.demo@email.com" -ForegroundColor White
    Write-Host "   3. Nguoi thue moi Minh Khang: khang.demo@email.com" -ForegroundColor White
    Write-Host "   4. Nguoi thue moi Ngoc Mai:   mai.demo@email.com" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    Write-Host "[DATA] Rooms: 6 available rooms. Chats/Rentals/Bills/Reviews: empty for a clean demo flow." -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to seed Realtime Database! Error: $_" -ForegroundColor Red
    exit 1
}
