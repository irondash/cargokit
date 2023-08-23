[![GitHub License](https://img.shields.io/github/license/irondash/cargokit)](https://github.com/irondash/cargokit/blob/main/LICENSE)

# CARGOKIT

Experimental repository to provide glue for seamlessly integrating cargo build
with flutter plugins and packages.

## Tutorial

See https://matejknopp.com/post/flutter_plugin_in_rust_with_no_prebuilt_binaries/
for a tutorial on how to use Cargokit.

## Example

Example plugin available at [hello_rust_ffi_plugin](https://github.com/irondash/hello_rust_ffi_plugin).

## Characteristic

| Target      | Toolchains | Type              | Suffix | armv7        | arm64 | x86          | x86_64 |
| ----------- | ---------- | ----------------- | ------ | ------------ | ----- | ------------ | ------ |
| **Android** | Gradle     | C Dynamic Library | .so    | ✅           | ✅    | ✅           | ✅     |
| **iOS**     | Cocoapods  | Static Library    | .a     | ✅           | ✅    | -            | ✅     |
| **macOS**   | Cocoapods  | Static Library    | .a     | ✅           | ✅    | -            | ✅     |
| **Linux**   | cmake      | C Dynamic Library | .so    | ✅(Untested) | ✅    | ✅(Untested) | ✅     |
| **Windows** | cmake      | C Dynamic Library | .dll   | -            | -     | ✅(Untested) | ✅     |
