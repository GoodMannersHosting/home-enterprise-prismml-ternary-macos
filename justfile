# Justfile for PrismML Ternary Bonsai 2 27B on macOS
# Install just: https://just.systems/

PRISM_VERSION := "prism-b10709-9a9394a"
INSTALL_DIR := "/opt/llama-cpp-prism"
MODEL_DIR := "{{INSTALL_DIR}}/models"
MODEL_FILE := "{{INSTALL_DIR}}/models/Ternary-Bonsai-2-27B-PQ2_0.gguf"
MODEL_URL := "https://huggingface.co/prism-ml/Ternary-Bonsai-2-27B-gguf/resolve/main/Ternary-Bonsai-2-27B-PQ2_0.gguf"
PLIST_FILE := "/Library/LaunchDaemons/llamacpp.plist"

check-just:
    @echo "Just is working. Run 'just --list' to see all tasks."

init:
    @echo "Creating install directory..."
    sudo mkdir -p {{INSTALL_DIR}}
    sudo chown $(whoami):staff {{INSTALL_DIR}}
    mkdir -p {{MODEL_DIR}}

download-binary:
    @echo "Downloading llama.cpp binary ({{PRISM_VERSION}})..."
    curl -L -f -o {{INSTALL_DIR}}/llama-prism.tar.gz \
        "https://github.com/PrismML-Eng/llama.cpp/releases/download/{{PRISM_VERSION}}/llama-prism-{{PRISM_VERSION}}-bin-macos-arm64.tar.gz"
    cd {{INSTALL_DIR}} && tar -xzf llama-prism.tar.gz && rm llama-prism.tar.gz
    sudo ln -sf {{INSTALL_DIR}}/llama-prism-{{PRISM_VERSION}}/llama-server {{INSTALL_DIR}}/llama-server
    @echo "Binary downloaded and symlinked."

download-model:
    @echo "Downloading Ternary-Bonsai-2-27B-PQ2_0 (~7.2GB)..."
    curl -L -f -o {{MODEL_FILE}} "{{MODEL_URL}}"
    @echo "Model downloaded."

verify-model:
    @echo "Verifying model file..."
    ls -la {{MODEL_FILE}}
    @echo "Expected size: ~7.2GB (7206168928 bytes)"

install-plist:
    @echo "Installing LaunchDaemon..."
    @echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' > /tmp/llamacpp.plist
    @echo '<plist version="1.0">' >> /tmp/llamacpp.plist
    @echo '<dict>' >> /tmp/llamacpp.plist
    @echo '    <key>Label</key>' >> /tmp/llamacpp.plist
    @echo '    <string>llama.cpp</string>' >> /tmp/llamacpp.plist
    @echo '    <key>UserName</key>' >> /tmp/llamacpp.plist
    @echo '    <string>danmanners</string>' >> /tmp/llamacpp.plist
    @echo '    <key>WorkingDirectory</key>' >> /tmp/llamacpp.plist
    @echo '    <string>/opt/llama-cpp-prism</string>' >> /tmp/llamacpp.plist
    @echo '    <key>EnvironmentVariables</key>' >> /tmp/llamacpp.plist
    @echo '    <dict>' >> /tmp/llamacpp.plist
    @echo '        <key>METAL_DEVICE_WRAPPER_TYPE</key>' >> /tmp/llamacpp.plist
    @echo '        <string>1</string>' >> /tmp/llamacpp.plist
    @echo '    </dict>' >> /tmp/llamacpp.plist
    @echo '    <key>ProgramArguments</key>' >> /tmp/llamacpp.plist
    @echo '    <array>' >> /tmp/llamacpp.plist
    @echo '        <string>/opt/llama-cpp-prism/llama-server</string>' >> /tmp/llamacpp.plist
    @echo '        <string>-m</string>' >> /tmp/llamacpp.plist
    @echo '        <string>/opt/llama-cpp-prism/models/Ternary-Bonsai-2-27B-PQ2_0.gguf</string>' >> /tmp/llamacpp.plist
    @echo '        <string>--host</string>' >> /tmp/llamacpp.plist
    @echo '        <string>0.0.0.0</string>' >> /tmp/llamacpp.plist
    @echo '        <string>--port</string>' >> /tmp/llamacpp.plist
    @echo '        <string>8080</string>' >> /tmp/llamacpp.plist
    @echo '        <string>-c</string>' >> /tmp/llamacpp.plist
    @echo '        <string>32768</string>' >> /tmp/llamacpp.plist
    @echo '        <string>-fa</string>' >> /tmp/llamacpp.plist
    @echo '        <string>on</string>' >> /tmp/llamacpp.plist
    @echo '        <string>--temp</string>' >> /tmp/llamacpp.plist
    @echo '        <string>0.5</string>' >> /tmp/llamacpp.plist
    @echo '        <string>--top-p</string>' >> /tmp/llamacpp.plist
    @echo '        <string>0.85</string>' >> /tmp/llamacpp.plist
    @echo '        <string>--top-k</string>' >> /tmp/llamacpp.plist
    @echo '        <string>20</string>' >> /tmp/llamacpp.plist
    @echo '        <string>--min-p</string>' >> /tmp/llamacpp.plist
    @echo '        <string>0</string>' >> /tmp/llamacpp.plist
    @echo '        <string>--parallel</string>' >> /tmp/llamacpp.plist
    @echo '        <string>1</string>' >> /tmp/llamacpp.plist
    @echo '        <string>--jinja</string>' >> /tmp/llamacpp.plist
    @echo '        <string>--no-perf</string>' >> /tmp/llamacpp.plist
    @echo '    </array>' >> /tmp/llamacpp.plist
    @echo '    <key>RunAtLoad</key>' >> /tmp/llamacpp.plist
    @echo '    <true/>' >> /tmp/llamacpp.plist
    @echo '    <key>KeepAlive</key>' >> /tmp/llamacpp.plist
    @echo '    <true/>' >> /tmp/llamacpp.plist
    @echo '    <key>StandardOutPath</key>' >> /tmp/llamacpp.plist
    @echo '    <string>/opt/llama-cpp-prism/llama-server.log</string>' >> /tmp/llamacpp.plist
    @echo '    <key>StandardErrorPath</key>' >> /tmp/llamacpp.plist
    @echo '    <string>/opt/llama-cpp-prism/llama-server.log</string>' >> /tmp/llamacpp.plist
    @echo '</dict>' >> /tmp/llamacpp.plist
    @echo '</plist>' >> /tmp/llamacpp.plist
    sudo cp /tmp/llamacpp.plist {{PLIST_FILE}}
    sudo chown root:wheel {{PLIST_FILE}}
    sudo chmod 644 {{PLIST_FILE}}
    @echo "LaunchDaemon installed."

start:
    @echo "Starting llama-server service..."
    sudo launchctl bootstrap system {{PLIST_FILE}}
    @echo "Service started. Waiting for model to load (~30s)..."
    sleep 30
    @echo "Checking health..."
    curl -s http://localhost:8080/health
    @echo ""
    @echo "Service is running."

stop:
    @echo "Stopping llama-server service..."
    sudo launchctl bootout system/llama.cpp
    @echo "Service stopped."

restart: stop start

status:
    @echo "Checking service status..."
    sudo launchctl print system/llama.cpp 2>&1 | grep "state\|exit code"
    @echo ""
    ps aux | grep "llama-server.*Ternary-Bonsai" | grep -v grep
    @echo ""
    curl -s http://localhost:8080/health
    @echo ""

logs:
    tail -f {{INSTALL_DIR}}/llama-server.log

test:
    @echo "Testing model with simple query..."
    curl -s --max-time 60 http://0.0.0.0:8080/v1/chat/completions \
        -H "Content-Type: application/json" \
        -d '{"model":"Ternary-Bonsai-2-27B-PQ2_0","messages":[{"role":"user","content":"What is the capital of France? Answer in one word."}],"max_tokens":50}' | \
        python3 -c "import sys,json; d=json.load(sys.stdin); print(d['choices'][0]['message']['content'])"

setup: init download-binary download-model install-plist start

verify: verify-model status test

cleanup: stop
    sudo rm {{PLIST_FILE}}
    sudo rm -rf {{INSTALL_DIR}}/llama-prism-{{PRISM_VERSION}}
    rm -f {{INSTALL_DIR}}/llama-server

clean-all: cleanup
    sudo rm -rf {{INSTALL_DIR}}
