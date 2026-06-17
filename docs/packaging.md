# Packaging

tokenmanager supports three local packaging paths.

## App Bundle

```sh
./script/package_app.sh
```

Output:

```text
dist/tokenmanager.app
```

The app bundle includes:

- `Contents/MacOS/tokenmanager`
- `Contents/MacOS/tokenmanagerctl`
- `Contents/Info.plist`

The local build is ad-hoc signed with `codesign -` when available.

## Installer Package

```sh
./script/make_pkg.sh
```

Output:

```text
dist/tokenmanager-0.1.0.pkg
```

The package installs `tokenmanager.app` into `/Applications`.

## Disk Image

```sh
./script/make_dmg.sh
```

Output:

```text
dist/tokenmanager-0.1.0.dmg
```

The DMG contains `tokenmanager.app` and an `/Applications` shortcut.

## npm

The npm package exposes:

- `tokenmanager`: build, launch, or install the app bundle.
- `tokenmanagerctl`: run the Swift CLI helper.

This first version is source-build oriented. Release automation can replace this with prebuilt artifacts later.
