# Contributing

Thanks for helping improve VIDMARK STUDIO.

The project is intentionally small: a focused macOS app plus local helper engines for video review, assembly, and reframing. Contributions should keep the app simple, local-first, and useful for real creator workflows.

## Good First Contributions

- Fix a crash or build issue
- Improve review-note exports
- Improve keyboard navigation or accessibility
- Improve FFmpeg manifest handling
- Improve smart reframing quality
- Add focused tests or sample manifests
- Clarify documentation

## Development Setup

```bash
swift build
./script/build_and_run.sh --verify
```

For media helpers:

```bash
brew install ffmpeg python
python3 -m pip install Pillow
```

## Project Boundaries

Do not commit private media, local creator assets, provider access files, account material, build artifacts, or generated project folders.

Keep the app generic. Avoid project-specific branding, private production language, and provider-specific assumptions in the core app.

## Change Protocol

Every app change should leave a clear GitHub trail:

1. Make a focused change.
2. Run the most relevant local check.
3. Commit with a clear message.
4. Push to GitHub.
5. Open a pull request for review when collaborating.

## Pull Request Expectations

Pull requests should describe:

- What changed
- Why it changed
- How it was tested
- Any known limitations

Small, practical pull requests are preferred.
