> Creator: whjeong<br>
> Created on: 2026-10-13<br>
> https://maduinos.blogspot.com/

# AMD FPGA MCP distribution

Linux x86_64 requires Python 3.12 and its venv module. Ubuntu 24.04:
`sudo apt install python3.12 python3.12-venv`

Run `bash install.sh`. Dependencies are installed offline from the bundled wheelhouse.
Each release has its own environment. Existing versions are never overwritten.
The installer checks all bundled files and verifies an actual MCP handshake and 96 tools.

Windows 10/11 x86_64 uses **WSL2**, not native Windows Python.
Install and initialize Ubuntu 24.04 using `wsl --install -d Ubuntu-24.04`.
Install the Python requirements inside Ubuntu, then run `powershell -ExecutionPolicy Bypass -File .\install.ps1`.
The wrapper forwards installation to the selected WSL2 distribution.
Use Linux AMD toolchains inside WSL, or connect to a remote hardware server.
USB/JTAG forwarding, vendor tools inside WSL and particular boards require separate validation.

MCP configuration (replace the Linux user and version):
```json
{"mcpServers":{"amd-fpga":{"command":"/home/<linux-user>/.local/share/amd-fpga-mcp/0.7.0/bin/amd-fpga-mcp","args":[]}}}
```
Windows configuration:
```json
{"mcpServers":{"amd-fpga":{"command":"wsl.exe","args":["-d","Ubuntu-24.04","--","/home/<linux-user>/.local/share/amd-fpga-mcp/0.7.0/bin/amd-fpga-mcp"]}}}
```
Restart your MCP client after changing configuration. No AMD tools or licenses are included.
Start by asking the client to call `get_server_info`, inspect toolchains and list board profiles.
Use a project directory inside Linux, especially for WSL performance and path consistency.
Persistent run state defaults to `~/.local/state/amd-fpga-mcp`; override with `AMD_FPGA_MCP_STATE_DIR`.
Update by installing another release and switching the configured command. Roll back by restoring the previous command.
To uninstall, remove only the selected version environment after stopping its jobs.

Source provenance is in `release.json`. File integrity is in `MANIFEST.sha256`.
Archive integrity is published separately in `SHA256SUMS`.
See https://maduinos.github.io/amd-fpga-mcp-releases/ for support boundaries and workflow examples.
