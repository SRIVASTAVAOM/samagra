# SAMAGRA agent guidance

## Scope and privacy
- Work only on the requested SAMAGRA task in this repository and its explicitly connected project services.
- Do not inspect or modify personal files outside this repository, browser profiles, other projects, SSH keys, or global credentials/configuration. Standard installed tools and their documentation may be used.
- Never print, copy into chat, or commit secret values. Do not read `.env` files, signing keys, or `mobile/android/key.properties` unless a specific task requires it and the user authorizes it. Prefer environment variable names and presence-only checks.
- Preserve existing user edits. Do not reset, discard, force-push, or delete unrelated work.
- Routine project edits and relevant checks can proceed. General setup authorization is not authorization to deploy, alter production data, run migrations/seeds against production, incur charges, or broaden account permissions.

## Repository map
- `backend/`: Express + TypeScript + PostgreSQL. Domain code: `src/modules/`; migrations: `src/db/migrations/`; tests: `tests/`.
- `web-admin/`: Next.js + React. Follow its nested `AGENTS.md` and installed Next.js documentation.
- `mobile/`: Flutter application. `web-mobile/` contains generated Flutter web output; change source in `mobile/` first.
- `render.yaml`: backend deployment configuration. Web deployment uses Vercel according to the handoff; verify remote state before changing it.
- `PROJECT_HANDOFF.md`: historical architecture reference. Search relevant sections only; verify claims against current code and connected services.

## Efficient workflow
- Keep user-facing updates and final answers concise; use Hinglish when the user does.
- Start with git status and targeted file searches. Read only relevant files and excerpts; avoid dumping the repository, lockfiles, generated assets, dependencies, or large logs.
- Make the smallest complete change. Avoid unrelated refactors or dependency upgrades.
- Use a single agent unless the user explicitly requests delegation.
- Reuse verified findings in the current chat. Run focused checks once; repeat only after relevant changes or failures.
- Report what changed, verification results, and any actual blocker. Never claim a connection or deployment is complete without verification.

## Commands and validation
- Backend: `cd backend && npm run dev`; compile with `npx tsc --noEmit`; targeted tests with `npm test -- --runTestsByPath tests/<file>.test.ts`.
- Web: `cd web-admin && npm run dev`; lint relevant files with `npx eslint <paths>`; production build with `npm run build` when warranted.
- Mobile: `cd mobile && flutter run`; use `flutter analyze` and targeted `flutter test test/<file>_test.dart` for relevant changes.
- Check database/test configuration before integration tests. Do not run migration or seed scripts as a setup probe.
- Documentation-only changes need diff review, not application builds.
