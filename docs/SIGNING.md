# Code signing — MSIX and EXE installers

Windows blocks or warns on installers that aren’t signed by a trusted certificate. The MSIX built by the `msix` package uses a **self-signed test certificate** by default, so Windows (and SmartScreen) may block it. This doc explains your options and how to sign MSIX and the EXE installer.

---

## Why you’re being blocked

- **MSIX:** The default build uses a test/self-signed certificate. Windows does not trust it for install unless users manually install that cert (not practical for distribution).
- **EXE installer:** The setup.exe produced by Inno Setup is unsigned by default, so SmartScreen may show “Unknown publisher” or block it.

To get a smooth, trusted install you need **code signing** with a certificate that Windows trusts.

---

## Options for trusted installs

| Option | Best for | Cost | Effort |
|--------|----------|------|--------|
| **Buy a code signing certificate** | Public distribution (MSIX + EXE) | ~\$100–\$400+/year | Buy cert, then sign MSIX and/or EXE |
| **Microsoft Trusted Signing** | Cloud signing, no hardware token | Varies (check Azure/Partner Center) | Set up account, sign via cloud |
| **EXE installer (Inno Setup)** | Users who prefer “setup.exe” | Same cert as above to sign | Already set up; build with `dart run inno_bundle` |
| **Portable zip** | No install, “run exe from folder” | Sign exe for less SmartScreen friction | Sign `clipboard_typer.exe` with same cert |

You can combine: e.g. one **purchased or Trusted Signing certificate** to sign **both** the MSIX and the EXE installer (and optionally the portable exe).

---

## 1. Signing the MSIX

Once you have a **.pfx** code signing certificate (from a CA like DigiCert, Sectigo, or from Microsoft Trusted Signing exported as PFX):

1. Add to `pubspec.yaml` under `msix_config` (use real path and password, or env vars):

   ```yaml
   msix_config:
     # ... existing keys ...
     certificate_path: C:\path\to\your.pfx
     certificate_password: your_cert_password
     install_certificate: false
   ```

   Set `install_certificate: false` so the tool doesn’t try to install your real cert on the build machine.

2. Build the MSIX:

   ```powershell
   flutter build windows
   echo N | dart run msix:create
   ```

The resulting `.msix` will be signed with your cert. If the cert is from a trusted CA (and not revoked), Windows should allow install without the previous block.

**Getting a certificate:** Buy a “code signing” certificate from a trusted CA (DigiCert, Sectigo, etc.) or use [Microsoft Trusted Signing](https://learn.microsoft.com/en-us/windows/security/threat-protection/windows-defender-application-control/microsoft-trusted-signing) if you prefer cloud signing.

---

## 2. Building and signing the EXE installer

We use **Inno Setup** via the `inno_bundle` package. The installer is a single **setup.exe** that users run; it doesn’t depend on the Store and behaves like a classic Windows installer.

### Build the EXE installer (unsigned)

From the project root:

```powershell
flutter build windows
dart run inno_bundle
```

Output is typically under `build/windows/x64/runner/Release/` or as specified by inno_bundle (e.g. a `Setup ClipboardTyper 1.0.0.exe` or similar in the build/output folder). Check the CLI output for the exact path.

### Sign the EXE installer

You need **signtool.exe** (from Windows SDK / Visual Studio) and the same **.pfx** code signing certificate.

1. Ensure `signtool.exe` is on your PATH (e.g. from `C:\Program Files (x86)\Windows Kits\10\bin\...`).
2. Run inno_bundle with signing parameters (one line, replace path and password):

   ```powershell
   dart run inno_bundle --sign-tool-params "signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /f `"C:\path\to\your.pfx`" /p `"YourPassword`" /v $f"
   ```

   Use your real `.pfx` path and password. The `$f` is replaced by inno_bundle with the file to sign.

After signing, the setup.exe will show your publisher and reduce or remove SmartScreen warnings once the cert has reputation.

---

## 3. Signing the portable EXE (optional)

To reduce SmartScreen warnings when users run the portable `clipboard_typer.exe` from the zip:

```powershell
signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /f "C:\path\to\your.pfx" /p "YourPassword" /v build\windows\x64\runner\Release\clipboard_typer.exe
```

Then re-zip the contents of `build\windows\x64\runner\Release\` for the portable package.

---

## Summary

- **MSIX blocked:** Default build uses a test cert; Windows doesn’t trust it. Add `certificate_path` and `certificate_password` (and `install_certificate: false`) to `msix_config`, then rebuild the MSIX.
- **EXE installer:** Build with `dart run inno_bundle`, then sign the resulting setup.exe with `signtool` (or via `--sign-tool-params`). Use the same code signing cert for best results.
- **Trusted cert:** Get a code signing certificate from a trusted CA (or Microsoft Trusted Signing), then use it for both MSIX and EXE (and optionally the portable exe) so Windows and SmartScreen allow or allow-with-one-click installs.
