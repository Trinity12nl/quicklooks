# Changelog

## Unreleased

- **FIX** `build-quicklooks.sh` failed when the checkout path contained a space:
  source paths are now passed to `swiftc` as an array.
