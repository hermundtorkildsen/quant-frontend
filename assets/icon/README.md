# App Icon Setup

## How to Change the App Icon

1. **Create your icon image:**
   - Size: 1024x1024 pixels (square)
   - Format: PNG with transparency
   - Name it: `icon.png`
   - Place it in this folder: `assets/icon/icon.png`

2. **Generate all icon sizes:**
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

3. **Rebuild your app:**
   ```bash
   flutter clean
   flutter run
   ```

## Icon Design Tips

- Use a simple, recognizable design that works at small sizes
- Ensure important elements are centered (Android adaptive icons may crop edges)
- Test on both light and dark backgrounds
- The background color is set to `#f7f4ef` (Quant's off-white theme color)

## Current Configuration

- **Android**: Generates all required mipmap sizes + adaptive icon
- **iOS**: Generates all required AppIcon sizes
- **Background color**: `#f7f4ef` (for Android adaptive icon)




