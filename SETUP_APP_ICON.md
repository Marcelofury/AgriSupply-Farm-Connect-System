# App Icon Setup Instructions

## 📱 Your AgriSupply App Icon

You have a beautiful app icon showing:
- Two people shaking hands (farmer & buyer connection)
- A plant/seedling above (agriculture)
- Gradient: Blue to Purple/Red (modern, professional)

## 🎯 Steps to Add Your Icon

### 1. Save the Icon File
Save your app icon image as:
```
mobile/assets/icon/app_icon.png
```

**Requirements:**
- Size: 1024x1024 pixels (minimum)
- Format: PNG with transparent background OR white background
- Quality: High resolution

### 2. Install Flutter Launcher Icons Package

The package is already in your `pubspec.yaml`. Just run:

```bash
cd mobile
flutter pub get
```

### 3. Generate App Icons

Run this command to generate all platform-specific icons:

```bash
flutter pub run flutter_launcher_icons
```

This will automatically create:
- ✅ Android icons (all densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- ✅ Android adaptive icons
- ✅ iOS icons (all sizes)
- ✅ Web icons
- ✅ Windows icons

### 4. Verify Generated Icons

Check that icons were created in:
- `android/app/src/main/res/mipmap-*/` (Android)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (iOS)
- `web/icons/` (Web)

### 5. Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

## 📁 Directory Structure

Make sure you have this structure:

```
mobile/
├── assets/
│   └── icon/
│       └── app_icon.png          ← Save your icon here
├── flutter_launcher_icons.yaml   ← Already created
└── pubspec.yaml                  ← Already configured
```

## 🎨 Icon Specifications

### For Best Results:
- **Size:** 1024x1024px
- **Safe Zone:** Keep important elements within center 80%
- **Format:** PNG-24 with transparency
- **Color:** Already perfect with your gradient!

### Platform-Specific Requirements:

#### Android
- Adaptive icon support included
- Background: White (#FFFFFF)
- Foreground: Your icon image

#### iOS
- Rounded corners applied automatically
- All required sizes generated
- No transparency (will be removed)

#### Web
- PWA icon support
- Favicon generated
- Theme color: #2E7D32 (your primary green)

## 🚀 Usage in Code

The icon is automatically used when you build/run the app. No code changes needed!

## 🔧 Troubleshooting

### Icon not showing after generation?
```bash
# Clean everything
flutter clean
cd android && ./gradlew clean && cd ..
cd ios && pod deintegrate && pod install && cd ..  # macOS only

# Rebuild
flutter pub get
flutter run
```

### Want to update the icon later?
1. Replace `mobile/assets/icon/app_icon.png` with new image
2. Run `flutter pub run flutter_launcher_icons` again
3. Clean and rebuild

## 📝 Additional Files You Can Create

### Logo Variations (Optional)
Save these in `assets/images/`:
- `logo_horizontal.png` - For splash screen
- `logo_text_only.png` - For loading states
- `logo_white.png` - For dark backgrounds

## ✅ Checklist

- [ ] Save icon as `mobile/assets/icon/app_icon.png` (1024x1024px)
- [ ] Run `flutter pub get`
- [ ] Run `flutter pub run flutter_launcher_icons`
- [ ] Verify icons generated in platform folders
- [ ] Run `flutter clean`
- [ ] Run `flutter run` to test
- [ ] Check app icon appears on device/emulator

## 🎉 Next Steps

After setting up the icon:
1. Update README.md with actual logo image
2. Create splash screen with same branding
3. Take app screenshots for store listings
4. Prepare app store assets (feature graphics, etc.)

---

**Note:** Your current icon design is excellent for:
- ✅ Agricultural marketplace theme
- ✅ Connection/partnership message
- ✅ Modern gradient style
- ✅ Professional appearance
- ✅ Clear at small sizes
