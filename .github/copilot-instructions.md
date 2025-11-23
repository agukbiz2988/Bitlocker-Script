# Copilot / AI Agent Instructions for Bitlocker-Script

Purpose: Help AI coding agents be immediately productive in this small Windows PowerShell repository that provides an interactive BitLocker management script.

**Quick Context**
- Single-file project: `bitlocker.ps1` (interactive PowerShell menu). See `README.md` for a curl/iex install hint.
- Intended runtime: Windows PowerShell (requires administrative privileges). Uses built-in BitLocker cmdlets and the `manage-bde` CLI.

**How to run locally (reproducible steps)**
- Open an elevated PowerShell (Run as Administrator).
- From the repository root run: `.itlocker.ps1` or follow the README one-liner: `iwr tinyurl.com/bitlockerukbit | iex`.

**Major components / data flow**
- `showMenu` — interactive menu loop that calls the following functions based on user choice.
- `enableBitlocker(volume)` — calls `Enable-BitLocker` then writes key file via `getVolumeKey` and optionally calls `sendEmailWithKey`.
- `disableBitlocker(volume)` — calls `Disable-BitLocker`.
- `checkBitlocker()` — runs `manage-bde -status` and prints output.
- `getVolumeKey(volume)` — creates directory `X:\Bitlocker\` and writes key info to `X:\Bitlocker\BitLockerKey_<COMPUTERNAME>.txt` using `manage-bde -protectors -get C:` (see caveat below).
- `sendEmailWithKey(to, volume)` — writes the same key file and sends it using `Send-MailMessage` with SMTP settings (defaults to `smtp.gmail.com` + port 587). Prompts for credentials using `Get-Credential` (expects app-specific password for Gmail).

**Important, discoverable conventions & pitfalls (do not assume otherwise)**
- The script is interactive and expects typed input (drive letters, Y/N, email addresses).
- The script creates a folder at `<drive>:\Bitlocker\` and stores key files as `BitLockerKey_<COMPUTERNAME>.txt`.
- Hardcoded volume usage: `getVolumeKey` and `sendEmailWithKey` call `manage-bde -protectors -get C:` — this is a concrete behavior: the command always queries `C:` regardless of the `-volume` parameter. If you change behavior, update these lines accordingly.
- Email sending: `sendEmailWithKey` uses `Send-MailMessage` and `Get-Credential` with `-UseSSL`. It hardcodes `-From bitlocker88@gmail.com` — avoid committing real credentials and avoid storing secrets in repository files.
- Required platform/tools: `Enable-BitLocker`, `Disable-BitLocker` PowerShell cmdlets (BitLocker feature), and the `manage-bde` CLI must be present on the machine running the script.

**Common, safe edit patterns (examples)**
- Make `manage-bde` volume-respecting (example change):

  Replace:
  ```powershell
  manage-bde -protectors -get C:
  ```
  With:
  ```powershell
  manage-bde -protectors -get ($volume + ":")
  ```

- When adding non-interactive automation, add parameter flags to `bitlocker.ps1` and maintain interactive fallback by checking for the presence of arguments (use `param()` at top of script or check `$args`).

**Testing and debugging tips**
- To debug locally, run functions interactively in an elevated PowerShell session. Example:
  - Launch PowerShell as admin, dot-source the script: `. .\bitlocker.ps1` then call `getVolumeKey -volume "D"` to test the exporter logic without running the full menu.
- `Write-Host` and `Write-Warning` are used for user-facing messages — preserve them when editing user flows.

**Security and PR conventions**
- Do not add real credentials, SMTP passwords, or private keys to the repository. Use placeholders and document how to supply secrets at runtime (e.g., `Get-Credential`, environment variables, or a secrets store).
- If a change affects how keys are saved or emailed, include a short security note in the PR description describing where key files are written and how they are protected.

**Files to reference while coding**
- `bitlocker.ps1` — primary script; read top-to-bottom to understand interactive flow and functions.
- `README.md` — contains the one-liner used for remote install; note that `iwr | iex` downloads and executes code (review before running in production).

**When you modify behavior**
- If you change where keys are written or alter email behavior, update `README.md` and add a short example in the script comments: how to test the new behavior locally (dot-sourcing and calling the function).

If any part of the environment (e.g., expected Windows version, module availability, or intended operational model—local admin use vs. managed deployment) is missing or ambiguous, tell me which details you need and I will update this file accordingly.