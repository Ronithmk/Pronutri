# ProNutri v2.0 - Complete Setup Guide

## What's New in v2.0
- ✅ Onboarding (3 beautiful screens)
- ✅ Register (3-step: Account → Body → Goals)
- ✅ BMI Calculator during registration
- ✅ Auto calorie/macro goals (Mifflin-St Jeor equation)
- ✅ Email OTP Verification on registration
- ✅ Login with demo account
- ✅ Exercise Timer (sets, rest countdown, step tracker)
- ✅ Complete UI overhaul (Inter font, minimal modern)
- ✅ Dark/Light mode across all screens
- ✅ SHA-256 password hashing
- ✅ Per-user data isolation

---

## STEP 1 — Replace your project files

Copy the ENTIRE contents of this ZIP into your existing D:\nutritrack folder.
Replace all existing files when prompted.

Or open PowerShell and run:
```powershell
# Copy all files from extracted zip to your project
xcopy /E /Y "C:\path\to\extracted\pronutri\*" "D:\nutritrack\"
```

---

## STEP 2 — Create app icon files (run in PowerShell)

```powershell
$folders = @("mipmap-mdpi","mipmap-hdpi","mipmap-xhdpi","mipmap-xxhdpi","mipmap-xxxhdpi")
$sizes = @{mipmap-mdpi=48;mipmap-hdpi=72;mipmap-xhdpi=96;mipmap-xxhdpi=144;mipmap-xxxhdpi=192}
Add-Type -AssemblyName System.Drawing
foreach ($f in $sizes.Keys) {
    $s = $sizes[$f]
    New-Item -Path "D:\nutritrack\android\app\src\main\res\$f" -ItemType Directory -Force | Out-Null
    $bmp = New-Object System.Drawing.Bitmap($s,$s)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::FromArgb(0,200,150))
    $g.Dispose()
    $bmp.Save("D:\nutritrack\android\app\src\main\res\$f\ic_launcher.png",[System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}
Write-Host "Icons created!"
```

---

## STEP 3 — Configure Email OTP (optional but recommended)

Open: `D:\nutritrack\lib\services\otp_service.dart`

Replace these two lines:
```dart
static const String _senderEmail = 'your.app.email@gmail.com';
static const String _appPassword = 'your_16_char_app_password';
```

### How to get a Gmail App Password:
1. Go to https://myaccount.google.com
2. Click "Security" in the left menu
3. Under "How you sign in to Google" → click "2-Step Verification" (must be enabled)
4. Scroll to bottom → "App passwords"
5. Select app: "Mail", device: "Windows Computer"
6. Click "Generate" → copy the 16-character password
7. Paste it as `_appPassword` in otp_service.dart

> If you DON'T configure email, the app still works!
> The OTP will be displayed on-screen in a yellow box (dev mode).
> This is perfect for testing — just enter the shown code.

---

## STEP 4 — Configure NutriBot AI (optional)

Open: `D:\nutritrack\lib\services\claude_service.dart`

Replace:
```dart
static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY_HERE';
```

Get your key from: https://console.anthropic.com

> Without the key, NutriBot uses smart fallback responses — still works great!

---

## STEP 5 — Build and run

```powershell
cd D:\nutritrack
flutter clean
flutter pub get
flutter run -d chrome    # Test in browser first
```

If Chrome works, build the APK:
```powershell
flutter build apk --release --split-per-abi
```

Rename and install:
```powershell
Remove-Item "D:\nutritrack\build\app\outputs\flutter-apk\ProNutri.apk" -Force -ErrorAction SilentlyContinue
Rename-Item "D:\nutritrack\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" "ProNutri_v2.apk"
```

Send `ProNutri_v2.apk` via WhatsApp or Telegram to your phone.

---

## Demo Account (always works)
- Email: demo@pronutri.com
- Password: demo123

---

## App Flow
```
Launch
  │
  ├── First time → Onboarding (3 screens) → Register → OTP Email → Home
  │
  ├── Returning → Login → Home
  │
  └── Demo → "Try Demo Account" button → Home
```

---

## Troubleshooting

| Error | Fix |
|-------|-----|
| `pin_code_fields not found` | Run `flutter pub get` |
| `mailer not found` | Run `flutter pub get` |
| OTP not received | Check spam folder, or use dev mode (OTP shown on screen) |
| Build failed | Run `flutter clean` then `flutter pub get` |
| APK won't install | Enable "Install Unknown Apps" in phone settings |
