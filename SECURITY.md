# Security Policy

## Supported Versions

VIDMARK STUDIO is pre-1.0. Security fixes target the latest public branch and release.

## Reporting A Vulnerability

Please report vulnerabilities through GitHub Security Advisories for this repository when available.

If advisories are unavailable, open a minimal public issue that says a private security report is needed, without publishing exploit details.

## Scope

Security-sensitive issues include:

- Unexpected local file disclosure
- Unsafe handling of user-selected media paths
- Accidental inclusion of private project files in exported packages
- Unsafe shell command construction in helper engines
- Build or packaging behavior that could execute unexpected files

Do not include private videos, private paths, or account material in reports.
