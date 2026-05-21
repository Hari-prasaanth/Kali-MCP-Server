# Kali MCP Server

A Model Context Protocol (MCP) server that exposes Kali Linux penetration testing tools as MCP tools, enabling AI-powered security testing workflows through VS Code, GitHub Copilot, or any MCP-compatible client.

![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue)
![MCP Protocol](https://img.shields.io/badge/protocol-MCP%20(stdio)-green)
![License](https://img.shields.io/badge/license-MIT-orange)

## Overview

This server runs on a Kali Linux machine and communicates over stdio (typically tunneled via SSH). It wraps 27 pentesting tools with proper argument handling, timeout enforcement, output capping, and input sanitization.

### Supported Tools

| Category | Tools |
|----------|-------|
| **Reconnaissance** | Nmap, WhatWeb, Subfinder, Nuclei |
| **Web Scanning** | Nikto, WPScan, SSLScan/testssl.sh |
| **Directory Discovery** | Gobuster, Dirb, Feroxbuster, ffuf |
| **Injection Testing** | SQLMap, Commix, XSStrike, Dalfox |
| **Brute-forcing** | Hydra, Hashcat, John the Ripper |
| **Exploitation** | Metasploit Framework, Searchsploit |
| **Network Enum** | Enum4Linux, CrackMapExec/NetExec |
| **Utilities** | cURL, Arjun, wafw00f |
| **General** | Raw command execution, Health check |

---

## Prerequisites

- **Kali Linux** (2023.x or later recommended) — physical, VM, or WSL2
- **Python 3.10+** with pip
- **SSH server** enabled on the Kali machine (for remote access)
- **VS Code** with GitHub Copilot Chat (or any MCP-compatible client)

---

## Installation

### Quick Install (Recommended)

Clone the repository on your Kali machine and run the installer:

```bash
git clone https://github.com/YOUR_USERNAME/kali-mcp-server.git
cd kali-mcp-server
chmod +x install.sh
./install.sh
```

The installer will:
1. Install the Python MCP SDK (`mcp[cli]`)
2. Copy the server to `/opt/kali-mcp-server/` and create `mcp-server` in PATH
3. Install core pentesting tools via apt
4. Install optional advanced tools (ffuf, nuclei, subfinder, etc.)
5. Run a health check

### Manual Install

```bash
# 1. Install MCP SDK
pip install "mcp[cli]"

# 2. Copy the server script
sudo mkdir -p /opt/kali-mcp-server
sudo cp kali_mcp_server.py /opt/kali-mcp-server/
sudo chmod +x /opt/kali-mcp-server/kali_mcp_server.py

# 3. Create wrapper command
sudo tee /usr/local/bin/mcp-server > /dev/null << 'EOF'
#!/bin/bash
exec python3 /opt/kali-mcp-server/kali_mcp_server.py "$@"
EOF
sudo chmod +x /usr/local/bin/mcp-server

# 4. Install pentesting tools (install what you need)
sudo apt update
sudo apt install -y nmap nikto sqlmap gobuster dirb hydra john \
    metasploit-framework wpscan enum4linux curl wget whatweb \
    sslscan wafw00f feroxbuster ffuf commix seclists
```

### Verify Installation

```bash
mcp-server
```

You should see the startup banner listing all detected tools. The server then waits for JSON-RPC messages on stdin.

---

## Configuration

### SSH Setup (Kali Machine)

Ensure SSH is running on your Kali machine:

```bash
sudo systemctl start ssh
sudo systemctl enable ssh
```

Set up key-based authentication (from your client machine):

```bash
# Generate key (if you don't have one)
ssh-keygen -t ed25519 -f ~/.ssh/kali_key

# Copy to Kali machine
ssh-copy-id -i ~/.ssh/kali_key kali@<KALI_IP>

# Test connection
ssh -i ~/.ssh/kali_key kali@<KALI_IP> "mcp-server --help"
```

### VS Code Configuration

Add the following to your VS Code `mcp.json` (located at `~/.vscode/` or your user settings folder):

```json
{
  "servers": {
    "kali": {
      "type": "stdio",
      "command": "ssh",
      "args": [
        "-i", "C:/Users/YOUR_USER/.ssh/kali_key",
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

**Key SSH flags explained:**
- `-i` — Path to your SSH private key
- `-T` — Disable pseudo-terminal allocation (required for stdio transport)
- `-o LogLevel=ERROR` — Suppress SSH info messages that would corrupt the JSON-RPC stream
- `-o StrictHostKeyChecking=no` — Skip host key confirmation (use with caution)
- `2>/dev/null` — Redirect server banner/stderr so only JSON-RPC stdout reaches the client

### Linux/macOS Client Configuration

```json
{
  "servers": {
    "kali": {
      "type": "stdio",
      "command": "ssh",
      "args": [
        "-i", "/home/user/.ssh/kali_key",
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

### Local Mode (Kali as Client)

If running VS Code directly on the Kali machine:

```json
{
  "servers": {
    "kali": {
      "type": "stdio",
      "command": "mcp-server"
    }
  }
}
```

---

## Usage

Once configured, the MCP tools appear in your AI assistant (e.g., GitHub Copilot). You can invoke them through natural language:

### Example Prompts

```
Scan 192.168.1.1 for open ports and services
```

```
Run a nikto scan against http://target.com
```

```
Check if http://target.com/login is vulnerable to SQL injection
```

```
Brute-force SSH on 10.0.0.5 with the rockyou wordlist
```

```
Search for known exploits for Apache 2.4.49
```

### Direct Tool Usage

Each tool can also be called programmatically via MCP JSON-RPC:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "nmap_scan",
    "arguments": {
      "target": "192.168.1.1",
      "scan_type": "-sV -sC",
      "ports": "1-1000"
    }
  }
}
```

---

## Tool Reference

### `server_health`
Check server status and list installed tools.

### `nmap_scan`
Network scanning with full Nmap feature support.
```
target: "192.168.1.0/24"
scan_type: "-sV" | "-sS" | "-sC" | "-A" | "-sn"
ports: "80,443" | "1-1000" | "-"
scripts: "vuln" | "http-enum" | "ssl-enum-ciphers"
```

### `nikto_scan`
Web server vulnerability scanning.
```
target: "http://example.com"
ssl: true/false
tuning: "1234589abc"
```

### `sqlmap_scan`
SQL injection detection and exploitation.
```
url: "http://site.com/page?id=1"
level: 1-5
risk: 1-3
technique: "BEUSTQ"
extra_args: "--dump" | "--tables" | "--os-shell"
```

### `gobuster_scan`
Directory/DNS/vhost brute-forcing.
```
target: "http://example.com"
mode: "dir" | "dns" | "vhost" | "fuzz"
wordlist: "/usr/share/wordlists/dirb/common.txt"
extensions: "php,html,txt,bak"
```

### `hydra_attack`
Network login brute-forcing.
```
target: "192.168.1.1"
service: "ssh" | "http-post-form" | "ftp" | "mysql"
username_file: "/path/to/users.txt"
password_file: "/usr/share/wordlists/rockyou.txt"
```

### `metasploit_run`
Run Metasploit modules non-interactively.
```
module: "auxiliary/scanner/http/http_version"
options: {"RHOSTS": "192.168.1.1", "RPORT": 443}
payload: "cmd/unix/reverse_bash"
```

### `ffuf_fuzz`
Fast web fuzzing with FUZZ keyword.
```
url: "http://example.com/FUZZ"
wordlist: "/usr/share/seclists/Discovery/Web-Content/raft-medium-words.txt"
filter_code: "404,403"
```

### `nuclei_scan`
Template-based vulnerability scanning.
```
target: "http://example.com"
tags: "cve,rce,xss,sqli"
severity: "critical,high"
```

### `execute_command`
Run any arbitrary command on Kali.
```
command: "searchsploit apache 2.4"
working_directory: "/tmp"
timeout: 120
```

*See full parameter documentation in the tool docstrings within `kali_mcp_server.py`.*

---

## Architecture

```
┌──────────────────┐         SSH (stdio)         ┌──────────────────────┐
│                  │ ◄──────────────────────────► │                      │
│   VS Code +      │       JSON-RPC 2.0          │   Kali Linux         │
│   GitHub Copilot │                              │   mcp-server         │
│                  │                              │   (Python + FastMCP) │
└──────────────────┘                              └──────────┬───────────┘
                                                             │
                                                    ┌────────▼────────┐
                                                    │  Shell Commands  │
                                                    │  nmap, sqlmap,   │
                                                    │  hydra, etc.     │
                                                    └─────────────────┘
```

- **Transport:** stdio over SSH
- **Protocol:** JSON-RPC 2.0 (MCP standard)
- **Output cap:** 100KB per tool call
- **Default timeout:** 10 minutes (configurable per tool)
- **Process isolation:** Each command runs in its own process group with SIGKILL on timeout

---

## Security Considerations

- **Input sanitization:** All target/argument inputs are validated and shell-escaped via `shlex.quote()`
- **Target validation:** Regex-based validation prevents command injection through target parameters
- **Output capping:** Prevents memory exhaustion from large outputs
- **Process groups:** Timed-out processes are killed with SIGKILL to the entire process group
- **No credential storage:** The server does not store or log credentials

> **⚠️ Warning:** This tool is intended for authorized penetration testing only. Ensure you have proper authorization before scanning any target. Unauthorized access to computer systems is illegal.

---

## Troubleshooting

### Server won't start

```bash
# Check Python version
python3 --version  # Needs 3.10+

# Check MCP SDK installed
python3 -c "from mcp.server.fastmcp import FastMCP; print('OK')"

# Run directly for error output
python3 /opt/kali-mcp-server/kali_mcp_server.py
```

### SSH connection issues

```bash
# Test SSH directly
ssh -i /path/to/key -T kali@KALI_IP "echo hello"

# Test mcp-server via SSH
ssh -i /path/to/key -T -o LogLevel=ERROR kali@KALI_IP "bash -lc 'which mcp-server'"

# Check SSH service on Kali
sudo systemctl status ssh
```

### Tools not found

```bash
# Run health check
mcp-server &
# Then send health check via JSON-RPC, or use the AI assistant

# Install missing tools
sudo apt update && sudo apt install -y <tool-name>
```

### Output truncation

Large scan results are capped at 100KB. To get full output:
- Save results to a file using tool-specific output flags (e.g., Nmap's `-oN`)
- Then retrieve with `execute_command` using `cat`

### Timeout errors

Increase the timeout parameter for long-running scans:
```
nmap_scan(target="10.0.0.0/24", scan_type="-A", timeout=900)
```

---

## Project Structure

```
kali-mcp-server/
├── kali_mcp_server.py   # Main MCP server (all tool definitions)
├── install.sh           # Automated installer script
└── README.md            # This documentation
```

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-tool`)
3. Add your tool following the existing pattern (decorator + async function + `_run()`)
4. Test on a Kali machine
5. Submit a pull request

### Adding a New Tool

```python
@mcp.tool()
async def my_tool(
    target: str,
    extra_args: Optional[str] = None,
    timeout: int = 120,
) -> str:
    """
    Description of what the tool does.

    Args:
        target: Target description
        extra_args: Additional CLI arguments
        timeout: Command timeout in seconds
    """
    target = _sanitize_target(target)
    cmd = f"mytool {_sanitize_arg(target)}"

    if extra_args:
        cmd += f" {extra_args}"

    result = await _run(cmd, timeout=timeout)
    return json.dumps(result, indent=2)
```

---

## License

MIT License — See [LICENSE](LICENSE) for details.

---

## Disclaimer

This tool is provided for **authorized security testing and educational purposes only**. The authors are not responsible for misuse or damage caused by this software. Always obtain proper written authorization before conducting penetration tests.
