# burhaniguardsapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

## Running on Your Physical Device (Debug Mode)

To run this app on your physical phone in debug mode (instead of installing an APK):

### Prerequisites:

1. **Enable USB Debugging and Install via USB on your phone:**

   - Go to Settings → About Phone
   - Tap "Build Number" 7 times to enable Developer Options
   - Go back to Settings → Developer Options
   - Enable "USB Debugging"
   - **Enable "Install via USB"** (or "USB Installation" / "Install apps via USB") - This prevents the installation prompt from appearing
   - Some phones may also have "Verify apps over USB" - you can disable this if it causes issues

2. **Connect your phone via USB** to your computer

3. **Verify your device is connected:**
   ```bash
   flutter devices
   ```
   You should see your phone listed.

### Running the App:

**Option 1: Using the provided script (Windows)**

```bash
run-on-phone.bat
```

**Option 2: Using Flutter command directly**

```bash
flutter run
```

This will:

- Build the app in debug mode
- Install it on your connected phone (without showing installation prompts if "Install via USB" is enabled)
- Keep it running with hot reload capabilities
- Allow you to make changes and see them instantly

**Note:** Even though `flutter run` installs the app, it's a temporary debug installation that works like an emulator with hot reload. The app will be removed when you disconnect or can be uninstalled normally.

### Hot Reload:

While the app is running, press `r` in the terminal to hot reload, or `R` for a full restart.

### Stopping the App:

Press `q` in the terminal to quit the app.

### Troubleshooting:

**If you see an "Install Application" prompt on your phone:**

- Make sure "Install via USB" is enabled in Developer Options
- When the prompt appears, tap "Allow" or "Install" - this is a one-time permission
- If you keep denying it, the app won't install and you'll get an ADB error

**If ADB shows exit code 1:**

- Check that USB Debugging is enabled
- Check that "Install via USB" is enabled
- Try unplugging and reconnecting your USB cable
- Run `flutter doctor` to verify your setup

---

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
