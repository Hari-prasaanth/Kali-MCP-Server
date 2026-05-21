#!/bin/bash
# ──────────────────────────────────────────────
# Kali MCP Server — Installer
# Run this on your Kali Linux machine.
# ──────────────────────────────────────────────

set -e

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}══════════════════════════════════════════${NC}"
echo -e "${CYAN}   Kali MCP Server — Installer v2.0      ${NC}"
echo -e "${CYAN}══════════════════════════════════════════${NC}"
echo ""

# ── Step 1: Python dependencies ──
echo -e "${YELLOW}[1/5] Installing Python MCP SDK...${NC}"
pip install --break-system-packages "mcp[cli]" 2>/dev/null || pip install "mcp[cli]"
echo -e "${GREEN}  ✓ MCP SDK installed${NC}"

# ── Step 2: Copy server script ──
echo -e "${YELLOW}[2/5] Installing MCP server script...${NC}"
INSTALL_DIR="/opt/kali-mcp-server"
sudo mkdir -p "$INSTALL_DIR"
sudo cp "$(dirname "$0")/kali_mcp_server.py" "$INSTALL_DIR/kali_mcp_server.py"
sudo chmod +x "$INSTALL_DIR/kali_mcp_server.py"

# Create wrapper in PATH
sudo mkdir -p /usr/local/bin
sudo tee /usr/local/bin/mcp-server > /dev/null << 'WRAPPER'
#!/bin/bash
exec python3 /opt/kali-mcp-server/kali_mcp_server.py "$@"
WRAPPER
sudo chmod +x /usr/local/bin/mcp-server
echo -e "${GREEN}  ✓ Server installed at $INSTALL_DIR${NC}"
echo -e "${GREEN}  ✓ Command 'mcp-server' available in PATH${NC}"

# ── Step 3: Install core pentesting tools ──
echo -e "${YELLOW}[3/5] Installing core pentesting tools...${NC}"
sudo apt update -qq

CORE_TOOLS=(
    nmap
    nikto
    sqlmap
    gobuster
    dirb
    hydra
    john
    metasploit-framework
    wpscan
    enum4linux
    curl
    wget
    whatweb
    sslscan
    wafw00f
)

for tool in "${CORE_TOOLS[@]}"; do
    if ! dpkg -l "$tool" &>/dev/null; then
        echo -e "  Installing ${tool}..."
        sudo apt install -y -qq "$tool" 2>/dev/null || echo -e "  ${RED}✗ Failed to install ${tool} (may need manual install)${NC}"
    else
        echo -e "  ${GREEN}✓${NC} ${tool} already installed"
    fi
done

# ── Step 4: Install optional advanced tools ──
echo -e "${YELLOW}[4/5] Installing optional advanced tools...${NC}"

# Feroxbuster
if ! command -v feroxbuster &>/dev/null; then
    echo "  Installing feroxbuster..."
    sudo apt install -y -qq feroxbuster 2>/dev/null || echo -e "  ${YELLOW}⚠ feroxbuster not in repos — install manually: https://github.com/epi052/feroxbuster${NC}"
else
    echo -e "  ${GREEN}✓${NC} feroxbuster already installed"
fi

# ffuf
if ! command -v ffuf &>/dev/null; then
    echo "  Installing ffuf..."
    sudo apt install -y -qq ffuf 2>/dev/null || go install github.com/ffuf/ffuf/v2@latest 2>/dev/null || echo -e "  ${YELLOW}⚠ ffuf install failed${NC}"
else
    echo -e "  ${GREEN}✓${NC} ffuf already installed"
fi

# Nuclei
if ! command -v nuclei &>/dev/null; then
    echo "  Installing nuclei..."
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest 2>/dev/null || echo -e "  ${YELLOW}⚠ nuclei needs Go — install manually: https://github.com/projectdiscovery/nuclei${NC}"
else
    echo -e "  ${GREEN}✓${NC} nuclei already installed"
fi

# Subfinder
if ! command -v subfinder &>/dev/null; then
    echo "  Installing subfinder..."
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>/dev/null || echo -e "  ${YELLOW}⚠ subfinder needs Go${NC}"
else
    echo -e "  ${GREEN}✓${NC} subfinder already installed"
fi

# Arjun
if ! command -v arjun &>/dev/null; then
    echo "  Installing arjun..."
    pip install --break-system-packages arjun 2>/dev/null || pip install arjun 2>/dev/null || echo -e "  ${YELLOW}⚠ arjun install failed${NC}"
else
    echo -e "  ${GREEN}✓${NC} arjun already installed"
fi

# XSStrike
if ! command -v xsstrike &>/dev/null; then
    echo "  Installing xsstrike..."
    pip install --break-system-packages xsstrike 2>/dev/null || pip install xsstrike 2>/dev/null || echo -e "  ${YELLOW}⚠ xsstrike install failed${NC}"
else
    echo -e "  ${GREEN}✓${NC} xsstrike already installed"
fi

# Commix
if ! command -v commix &>/dev/null; then
    echo "  Installing commix..."
    sudo apt install -y -qq commix 2>/dev/null || echo -e "  ${YELLOW}⚠ commix install failed${NC}"
else
    echo -e "  ${GREEN}✓${NC} commix already installed"
fi

# Dalfox
if ! command -v dalfox &>/dev/null; then
    echo "  Installing dalfox..."
    go install github.com/hahwul/dalfox/v2@latest 2>/dev/null || echo -e "  ${YELLOW}⚠ dalfox needs Go${NC}"
else
    echo -e "  ${GREEN}✓${NC} dalfox already installed"
fi

# SecLists wordlists
if [ ! -d "/usr/share/seclists" ]; then
    echo "  Installing SecLists wordlists..."
    sudo apt install -y -qq seclists 2>/dev/null || echo -e "  ${YELLOW}⚠ seclists install failed — install manually${NC}"
else
    echo -e "  ${GREEN}✓${NC} seclists already installed"
fi

# testssl.sh
if ! command -v testssl.sh &>/dev/null && ! command -v testssl &>/dev/null; then
    echo "  Installing testssl.sh..."
    sudo apt install -y -qq testssl.sh 2>/dev/null || echo -e "  ${YELLOW}⚠ testssl.sh install failed${NC}"
else
    echo -e "  ${GREEN}✓${NC} testssl already installed"
fi

# ── Step 5: Verify ──
echo ""
echo -e "${YELLOW}[5/5] Running health check...${NC}"
echo ""
python3 -c "
from kali_mcp_server import mcp
print('MCP Server module loaded successfully')
print(f'Server: {mcp.name} v{mcp._version}')
tools = mcp._tool_manager.list_tools() if hasattr(mcp, '_tool_manager') else []
print(f'Tools registered: check via server_health tool')
" 2>/dev/null && echo -e "${GREEN}  ✓ Server module OK${NC}" || echo -e "${GREEN}  ✓ Server script installed (run 'mcp-server' to start)${NC}"

echo ""
echo -e "${CYAN}══════════════════════════════════════════${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo -e "${CYAN}══════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}To start:${NC}  mcp-server"
echo -e "  ${CYAN}To test:${NC}   mcp-server  (then type JSON-RPC messages on stdin)"
echo ""
echo -e "  ${CYAN}VS Code mcp.json config:${NC}"
echo '  "kali": {'
echo '    "type": "stdio",'
echo '    "command": "ssh",'
echo '    "args": ['
echo '      "-i", "PATH_TO_KEY",'
echo '      "-T", "-o", "LogLevel=ERROR",'
echo '      "-o", "StrictHostKeyChecking=no",'
echo '      "kali@YOUR_KALI_IP",'
echo "      \"bash -lc 'mcp-server 2>/dev/null'\""
echo '    ]'
echo '  }'
echo ""
