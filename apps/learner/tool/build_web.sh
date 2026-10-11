#!/usr/bin/env bash
set -euo pipefail
academy_flutter_dir="$(mktemp -d)"
curl --fail --location --retry 2 https://storage.googleapis.com/flutter_infra_release/flutter/abaf9c523780a608bd46686fd5e53740a07077f8/flutter_linux_3.47.7-stable.tar.xz -o "$academy_flutter_dir/flutter.tar.xz"
tar -xf "$academy_flutter_dir/flutter.tar.xz" -C "$academy_flutter_dir"
export PATH="$academy_flutter_dir/flutter/bin:$PATH"
flutter config --no-analytics
flutter create --platforms=web --org=com.bajinka --project-name=bajinka_academy .
flutter pub get
flutter build web --release
