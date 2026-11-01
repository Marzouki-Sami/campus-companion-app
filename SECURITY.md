# Security policy

## Reporting a vulnerability

Please do **not** open a public issue for security problems. Use GitHub's
[private vulnerability reporting](https://github.com/Marzouki-Sami/campus-companion-app/security/advisories/new)
and include steps to reproduce. You can expect an acknowledgement within a few days.

## Scope

The app talks to Supabase using the **publishable** key only; access control is enforced
by Row Level Security (see the *Security model* section of the README). Never put a
`secret` or `service_role` key in the app or in this repository.

## Automated checks

- Row Level Security, storage policies and database limits are attacked by the pgTAP suite on every pull request.
- A from-scratch docker-compose smoke test confirms the Edge Function rejects unauthenticated calls.
- [gitleaks](.github/workflows/secret-scan.yml) scans the code and history for secrets.
- [Dependabot](.github/dependabot.yml) proposes dependency and GitHub Actions updates weekly.
