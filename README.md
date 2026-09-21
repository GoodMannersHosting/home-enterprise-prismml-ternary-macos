# PrismML Ternary Bonsai 2 27B on macOS

Running the **PrismML fork of llama.cpp** with the **Ternary-Bonsai-2-27B model** on Apple Silicon (M4 Mac) as a persistent system service.

## What was done

1. **Downloaded and installed** the PrismML fork of llama.cpp (release `prism-b10709-9a9394a`) to `/opt/llama-cpp-prism/`
2. **Downloaded the model** `Ternary-Bonsai-2-27B-PQ2_0.gguf` (~7.2GB) - the 2-bit ternary quantized version
3. **Created a LaunchDaemon** at `/Library/LaunchDaemons/llamacpp.plist` that runs `llama-server` persistently
4. **Configured the server** to bind to `0.0.0.0:8080` with optimal parameters for a 27B model
5. **Removed the previous Ollama setup** that was on this machine

## Server configuration

| Parameter | Value |
|-----------|-------|
| Model | `Ternary-Bonsai-2-27B-PQ2_0.gguf` (2-bit ternary, ~7.2GB) |
| Host | `0.0.0.0` (all interfaces) |
| Port | `8080` |
| Context | 32768 tokens |
| Flash attention | ON |
| Temperature | 0.5 |
| Top-p | 0.85 |
| Top-k | 20 |
| Parallel slots | 1 |

## Stand up from scratch

### 1. Download and install the binary

```bash
# Create install directory
sudo mkdir -p /opt/llama-cpp-prism
sudo chown $(whoami):staff /opt/llama-cpp-prism

# Download the binary (macOS Apple Silicon)
curl -L -f -o /opt/llama-cpp-prism/llama-prism.tar.gz \
  "https://github.com/PrismML-Eng/llama.cpp/releases/download/prism-b10709-9a9394a/llama-prism-b10709-9a9394a-bin-macos-arm64.tar.gz"

# Extract
cd /opt/llama-cpp-prism
tar -xzf llama-prism.tar.gz
rm llama-prism.tar.gz

# Create symlink for easy management
sudo ln -sf /opt/llama-cpp-prism/llama-prism-b10709-9a9394a/llama-server /opt/llama-cpp-prism/llama-server
```

### 2. Download the model

```bash
mkdir -p /opt/llama-cpp-prism/models

# Download the PQ2_0 (2-bit ternary) version
curl -L -f -o /opt/llama-cpp-prism/models/Ternary-Bonsai-2-27B-PQ2_0.gguf \
  "https://huggingface.co/prism-ml/Ternary-Bonsai-2-27B-gguf/resolve/main/Ternary-Bonsai-2-27B-PQ2_0.gguf"

# Verify the download (should be ~7.2GB)
ls -la /opt/llama-cpp-prism/models/Ternary-Bonsai-2-27B-PQ2_0.gguf
```

### 3. Create the LaunchDaemon

```bash
cat <<'EOF' > /tmp/llamacpp.plist
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>llama.cpp</string>

    <key>UserName</key>
    <string>danmanners</string>

    <key>WorkingDirectory</key>
    <string>/opt/llama-cpp-prism</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>METAL_DEVICE_WRAPPER_TYPE</key>
        <string>1</string>
    </dict>

    <key>ProgramArguments</key>
    <array>
        <string>/opt/llama-cpp-prism/llama-server</string>
        <string>-m</string>
        <string>/opt/llama-cpp-prism/models/Ternary-Bonsai-2-27B-PQ2_0.gguf</string>
        <string>--host</string>
        <string>0.0.0.0</string>
        <string>--port</string>
        <string>8080</string>
        <string>-c</string>
        <string>32768</string>
        <string>-fa</string>
        <string>on</string>
        <string>--temp</string>
        <string>0.5</string>
        <string>--top-p</string>
        <string>0.85</string>
        <string>--top-k</string>
        <string>20</string>
        <string>--min-p</string>
        <string>0</string>
        <string>--parallel</string>
        <string>1</string>
        <string>--jinja</string>
        <string>--no-perf</string>
    </array>

    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/opt/llama-cpp-prism/llama-server.log</string>
    <key>StandardErrorPath</key>
    <string>/opt/llama-cpp-prism/llama-server.log</string>
</dict>
</plist>
EOF

sudo cp /tmp/llamacpp.plist /Library/LaunchDaemons/llamacpp.plist
sudo chown root:wheel /Library/LaunchDaemons/llamacpp.plist
sudo chmod 644 /Library/LaunchDaemons/llamacpp.plist
```

### 4. Start the service

```bash
# Start the server
sudo launchctl bootstrap system /Library/LaunchDaemons/llamacpp.plist

# Check it's running
sleep 30
curl -s http://localhost:8080/health
# Expected: {"status":"ok"}
```

### 5. Test it

```bash
curl -s http://0.0.0.0:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"Ternary-Bonsai-2-27B-PQ2_0","messages":[{"role":"user","content":"What is the capital of France?"}],"max_tokens":50}' | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print(d['choices'][0]['message']['content'])"
```

## Managing the service

```bash
# Check status
sudo launchctl print system/llama.cpp

# View logs
tail -f /opt/llama-cpp-prism/llama-server.log

# Restart
sudo launchctl kickstart -k system/llama.cpp

# Stop
sudo launchctl bootout system/llama.cpp

# Start again
sudo launchctl bootstrap system /Library/LaunchDaemons/llamacpp.plist
```

## Troubleshooting

- **Port already in use**: Check with `lsof -i :8080` and free up the port
- **Model download incomplete**: Verify file size is ~7.2GB (7206168928 bytes)
- **Metal issues**: Ensure `METAL_DEVICE_WRAPPER_TYPE=1` is set in the environment
- **Log file permissions**: If the server can't write logs, run `sudo chown danmanners:staff /opt/llama-cpp-prism/llama-server.log`
- **Exit code 78 (EX_CONFIG)**: Usually indicates a configuration error; check the log file for details

## Files on disk

| Path | Description |
|------|-------------|
| `/opt/llama-cpp-prism/` | Installation directory |
| `/opt/llama-cpp-prism/llama-prism-b10709-9a9394a/` | Binary release directory |
| `/opt/llama-cpp-prism/llama-server` | Symlink to the server binary |
| `/opt/llama-cpp-prism/models/Ternary-Bonsai-2-27B-PQ2_0.gguf` | The model file (~7.2GB) |
| `/opt/llama-cpp-prism/llama-server.log` | Server log output |
| `/Library/LaunchDaemons/llamacpp.plist` | The LaunchDaemon configuration |
