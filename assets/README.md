# AgriSupply Assets

This folder contains all static assets for the AgriSupply mobile app.

## 📁 Folder Structure

```
assets/
├── icon/
│   └── app_icon.png          # App launcher icon (1024x1024px)
├── images/
│   ├── logo.png              # App logo for README/marketing
│   ├── placeholder.png       # Product image placeholder
│   ├── avatar_placeholder.png
│   └── ...
├── icons/
│   └── (category icons, payment icons, etc.)
└── screenshots/
    └── (app screenshots for documentation)
```

## 🎨 Current Assets

### App Icon
- **File:** `icon/app_icon.png`
- **Design:** Handshake with plant (farmer-buyer connection)
- **Colors:** Blue-to-purple gradient
- **Size:** 1024x1024px
- **Status:** ✅ Ready to use

## 📝 Assets Needed

### High Priority
- [ ] `images/placeholder.png` - For missing product photos
- [ ] `images/avatar_placeholder.png` - For user profiles
- [ ] `icon/app_icon.png` - Save your provided icon here

### Medium Priority  
- [ ] `images/logo.png` - For README header
- [ ] `images/empty_cart.png` - Empty state illustration
- [ ] `images/empty_orders.png` - No orders illustration
- [ ] `screenshots/*` - App screenshots for documentation

### Optional
- [ ] Payment method icons (MTN, Airtel, Cash)
- [ ] Category icons (vegetables, fruits, etc.)
- [ ] Social media icons

## 🚀 How to Add Your Icon

1. Save your app icon image as: `icon/app_icon.png`
2. Make sure it's 1024x1024 pixels
3. Run from mobile directory:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

See `../SETUP_APP_ICON.md` for detailed instructions.

## 📸 Screenshot Requirements

For app store and README:
- Device: iPhone 14 Pro or Samsung Galaxy S23
- Resolution: 1080px width minimum
- Format: PNG
- Screens needed: Home, Products, Cart, Orders, Profile, Admin

## 🎯 Brand Colors (for new assets)

- Primary Green: `#2E7D32`
- Light Green: `#4CAF50`
- Orange Accent: `#FF9800`
- Background: `#FFFFFF`
- Text: `#212121`
