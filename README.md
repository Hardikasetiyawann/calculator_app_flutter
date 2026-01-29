# Calculator Vault - Secured & Functional

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

A modern, professional-grade **Scientific Calculator** built with Flutter that doubles as a **Secured Vault**. Protect your private documents, media, and notes behind a familiar calculator interface.

---

## Features

### Smart Scientific Calculator
- **Modern UI/UX**: Clean, responsive design with dark mode support.
- **Temporary Results**: Real-time calculation previews as you type.
- **Full Scientific Support**: Trignometry (Sin, Cos, Tan), Logarithms, Square Roots, and Constants (π, e).
- **History Management**: Easily clear expressions with 'AC' or delete characters with backspace.

### Stealth Vault (Hidden Storage)
- **Secret Trigger**: Access the vault by long-pressing the `=` button for a few seconds.
- **Multi-Level Storage**:
  - **Documents**: Store PDF, DOCX, and XLS files with type-specific badges.
  - **Media**: Private gallery for images and videos with immersive previews.
  - **Notes**: Minimalist workspace for secured text notes.
- **AES-256 Encryption**: Every file is encrypted using industry-standard AES-256-CBC before storage.
- **Glassmorphism Design**: Professional dashboard interface with modern aesthetic cards.

---

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Encryption**: `encrypt` (AES-CBC 256-bit)
- **Math Parser**: `math_expressions`
- **Media Support**: `image_picker`, `video_player`
- **File Handling**: `file_picker`, `path_provider`, `open_filex`
- **Security**: `flutter_secure_storage` for key management.

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.
- An IDE (VS Code or Android Studio).

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Hardikasetiyawann/calculator_app_flutter.git
   ```
2. Navigate to the project directory:
   ```bash
   cd calculator_app_flutter
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

---

## Usage

1. **Calculate**: Use it as your daily driver for math.
2. **Access Vault**: Long-press the `=` button.
3. **Store**: Add files, photos, or notes inside the vault. They are encrypted and hidden from the system gallery/file manager.

---

## Security Note
This app uses AES-256-CBC for file encryption. The encryption keys are managed by `flutter_secure_storage` (Keychain on iOS, KeyStore on Android), providing a robust layer of security for your data.

