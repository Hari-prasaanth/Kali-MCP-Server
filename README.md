# Kali MCP Server

MCP server that exposes Kali Linux pentesting tools to AI assistants (VS Code + GitHub Copilot) over stdio/SSH.

## Why This Over Others?

The most popular Kali MCP server ([Wh0am123/MCP-Kali-Server](https://github.com/Wh0am123/MCP-Kali-Server)) exposes ~10 tools via an HTTP API and requires a separate client + SSH tunnel setup. Here's how we compare:

| Feature | MCP-Kali-Server (popular) | This Server |
|---------|--------------------------|-------------|
| Dedicated tool wrappers | 10 | **27** |
| Transport | HTTP API + SSH tunnel | **Native stdio over SSH** (zero config) |
| Input sanitization | Basic | **Regex validation + shlex escaping** |
| Timeout handling | None | **Per-tool configurable + process group kill** |
| Output management | Raw | **100KB cap with truncation notice** |
| Setup complexity | venv + client + server + tunnel | **Single `install.sh`, one mcp.json entry** |
| XSS/Command Injection tools | None | **XSStrike, Dalfox, Commix** |
| Fuzzing tools | None | **ffuf, Feroxbuster, Arjun** |
| Password cracking | John only | **John + Hashcat** |
| Vuln scanning | None | **Nuclei, SSLScan, wafw00f** |
| Recon/OSINT | None | **Subfinder, WhatWeb, Searchsploit** |

## Tools (27 MCP Tools)

| Category | Tools |
|----------|-------|
| Reconnaissance | Nmap, WhatWeb, Subfinder, Nuclei |
| Web Scanning | Nikto, WPScan, SSLScan/testssl.sh |
| Directory Discovery | Gobuster, Dirb, Feroxbuster, ffuf |
| Injection Testing | SQLMap, Commix, XSStrike, Dalfox |
| Brute-forcing | Hydra, Hashcat, John the Ripper |
| Exploitation | Metasploit Framework, Searchsploit |
| Network Enum | Enum4Linux, CrackMapExec/NetExec |
| Utilities | cURL, Arjun, wafw00f |
| General | Raw command execution, Health check |

## Install

On your Kali machine:

```bash
git clone https://github.com/YOUR_USERNAME/kali-mcp-server.git
cd kali-mcp-server
chmod +x install.sh
./install.sh
```

This installs the MCP SDK, copies the server to `/opt/kali-mcp-server/`, installs pentesting tools, and creates the `mcp-server` command.

## Run

```bash
mcp-server
```

Or directly with Python:

```bash
python3 kali_mcp_server.py
```

## VS Code Setup

Enable SSH on Kali (`sudo systemctl enable --now ssh`), then add to your VS Code `mcp.json`:

```json
{
  "servers": {
    "kali": {
      "type": "stdio",
      "command": "ssh",
      "args": [
        "-i", "PATH_TO_KEY",
        "-T",
        "-o", "LogLevel=ERROR",
        "-o", "StrictHostKeyChecking=no",
        "kali@YOUR_KALI_IP",
        "bash -lc 'mcp-server 2>/dev/null'"
      ]
    }
  }
}
```

## Disclaimer

For **authorized security testing only**. Obtain proper written authorization before scanning any target.
