# pdf_reader

A premium, fast, and native-looking PDF reader for Flutter. Built for performance and modern UI.

## Features

- 🚀 **Fast Rendering**: Powered by native PDF engines for smooth performance.
- 🎨 **Modern UI**: Clean, native-looking interface with Lucide icons and Inter typography.
- 🌓 **Dark Mode**: Built-in support for light and dark themes.
- 🔍 **Text Search**: Full-text search with navigation between results.
- 📑 **Table of Contents**: Support for PDF outlines/bookmarks.
- 🔢 **Page Navigation**: Quick jump to any page by tapping the page indicator.
- 🔍 **Zoom Controls**: Easy pinch-to-zoom and explicit zoom controls.
- 📤 **Share**: Easy document sharing built-in.
- 🔗 **Link Support**: Clickable links within PDF documents.
- 📱 **Full Screen**: Toggle UI visibility with a single tap for immersive reading.

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  pdf_reader:
    git: https://github.com/your-repo/pdf_reader.git # Or local path
```

## Usage

```dart
import 'package:pdf_reader/pdf_reader.dart';

// ...
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => PdfReaderView(
      filePath: '/path/to/your/document.pdf',
      title: 'My Document', // Optional
    ),
  ),
);
```

## License

This project is licensed under the MIT License.