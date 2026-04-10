# TestFlight Upload Checklist

Pre-archive checklist for uploading iOS apps to TestFlight. Learned from AquaLog's first upload (2026-04-10).

Run through this before the **first archive** of any new app.

---

## 1. Code Signing

- [ ] **Do NOT hardcode `CODE_SIGN_IDENTITY`** in project.pbxproj. Remove any `CODE_SIGN_IDENTITY = "iPhone Developer"` lines. With `CODE_SIGN_STYLE = Automatic`, Xcode picks the right identity (development for debug, distribution for archive).

- [ ] **Set `DEVELOPMENT_TEAM` on every target** — the main app may inherit from project-level settings, but extension targets (widgets, watch, etc.) often don't. Add it explicitly to each target's Debug and Release configs.

- [ ] **Register at least one device** in [Apple Developer portal](https://developer.apple.com/account/resources/devices/list) before first archive. Xcode's automatic signing needs a registered device to generate provisioning profiles.

## 2. Info.plist Requirements

- [ ] **`CFBundleDisplayName` in all extension Info.plist files** — extensions with `GENERATE_INFOPLIST_FILE = NO` need this key in their actual Info.plist file, not just in build settings.

- [ ] **iPad orientations must include all 4** — if `TARGETED_DEVICE_FAMILY` includes iPad (`1,2`), set:
  ```
  INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
  ```
  The `~ipad` suffix override doesn't work reliably. Use all 4 in the base key.

## 3. App Icon

- [ ] **No alpha channel** — App Store rejects icons with transparency. Check with:
  ```bash
  sips -g hasAlpha path/to/AppIcon.png
  ```
  Fix with Python:
  ```python
  from PIL import Image
  img = Image.open("AppIcon.png")
  bg = Image.new("RGB", img.size, (255, 255, 255))
  bg.paste(img, mask=img.split()[3])
  bg.save("AppIcon.png")
  ```

## 4. Known Warnings (Non-Blocking)

- **Sentry dSYM warning** — "Upload Symbols Failed" for `Sentry.framework` is about Sentry's own crash symbolication, not your app's. The upload still succeeds. Ignore this.

## 5. Upload Flow

1. **Product > Archive** in Xcode (destination: "Any iOS Device")
2. **Distribute App** in the Organizer window
3. Choose **App Store Connect**
4. Follow prompts — Xcode handles signing
5. Build appears in TestFlight on App Store Connect within 10-30 minutes
