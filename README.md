# Structured PDF Builder (Flutter web)

Browser-first PDF studio: fill a form, tweak branding, upload a logo or custom font, add a QR/link, and export a polished PDF. Runs entirely as a static site (great for GitHub Pages).

[![Flutter](https://img.shields.io/badge/flutter-3.32.4-blue?logo=flutter)](https://flutter.dev)
[![Tests](https://img.shields.io/badge/tests-pass-brightgreen?logo=githubactions)](./.github/workflows/gh-pages.yml)
[![Coverage](https://img.shields.io/badge/coverage-~30%25-yellow)](coverage/lcov.info)

## What it does
- Form-driven content: title, subtitle, intro, bullets, table, notes, QR/link.
- Branding/layout: accent color hex, margins, optional signature block with editable name/date, logo upload, custom font upload (ttf/otf).
- Live preview + print/download using `printing` + `pdf`.
- Uses built-in Helvetica/Courier by default—no assets required.

## Stack
- Flutter 3.32.4 (stable), Dart 3.8.1
- Packages: `pdf`, `printing`, `file_picker`

## License
MIT License — free to use, modify, and deploy. Include the LICENSE file when distributing forks/derivatives.
