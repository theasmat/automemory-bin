# AutoMemory Binary Distribution

Official binary distributions and universal installation scripts for [AutoMemory](https://github.com/theasmat/automemory).

---

## ⚡ Quick Install

### macOS & Linux
```bash
curl -fsSL https://raw.githubusercontent.com/theasmat/automemory-bin/main/install.sh | bash
```

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/theasmat/automemory-bin/main/install.ps1 | iex
```

---

## 📦 What It Does
1. Automatically detects your operating system and CPU architecture.
2. Downloads and verifies the latest standalone binary from [Releases](https://github.com/theasmat/automemory-bin/releases).
3. Installs `automemory` into `~/.cargo/bin` or `%USERPROFILE%\.cargo\bin`.
4. Runs full health diagnostics (`automemory doctor`).
5. Automatically configures all **20 supported AI coding agents** globally (`automemory connect all -g`).

---

## 🚀 Quick Verification
After installation, test your environment:
```bash
# Verify health diagnostics
automemory doctor

# Start local web console and background daemon
automemory serve --port 4545
```
Open **[http://127.0.0.1:4545](http://127.0.0.1:4545)** to view your memory explorer, review proposals, and AST code graph.
