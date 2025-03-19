#!/bin/bash

# Update package lists and upgrade existing packages
sudo apt update && sudo apt upgrade -y

# Install necessary dependencies
sudo apt install -y curl wget git build-essential

# Define the t3rn directory path
T3RN_DIR="$HOME/t3rn"

# Remove previous t3rn installations if they exist
if [ -d "$T3RN_DIR" ]; then
    echo "Removing existing t3rn installation..."
    rm -rf "$T3RN_DIR"
fi

# Recreate the t3rn directory
echo "Creating t3rn directory..."
mkdir -p "$T3RN_DIR"

# Install nvm (Node Version Manager)
if ! command -v nvm &> /dev/null; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    source "$HOME/.nvm/nvm.sh"
else
    echo "NVM is already installed."
fi

# Install Node.js using nvm
echo "Installing Node.js..."
nvm install --lts
nvm use --lts

# Install direnv
if ! command -v direnv &> /dev/null; then
    echo "Installing direnv..."
    curl -sfL https://direnv.net/install.sh | bash
    echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
    source ~/.bashrc
else
    echo "direnv is already installed."
fi

# Install pnpm (package manager)
if ! command -v pnpm &> /dev/null; then
    echo "Installing pnpm..."
    npm install -g pnpm
else
    echo "pnpm is already installed."
fi

# Clone the t3rn executor repository
echo "Cloning the t3rn executor repository..."
git clone https://github.com/t3rn/executor.git "$T3RN_DIR/executor"

# Navigate to the executor directory
cd "$T3RN_DIR/executor" || exit

# Install project dependencies
echo "Installing project dependencies..."
pnpm install

# Prompt user for private key
read -sp "Enter your private key: " PRIVATE_KEY_LOCAL
echo
export PRIVATE_KEY_LOCAL

# Prompt user for preferred maximum gas price
read -p "Enter your preferred maximum gas price in gwei (default is 100): " EXECUTOR_MAX_L3_GAS_PRICE
EXECUTOR_MAX_L3_GAS_PRICE=${EXECUTOR_MAX_L3_GAS_PRICE:-100}
export EXECUTOR_MAX_L3_GAS_PRICE

# Set environment variables
export ENVIRONMENT=testnet
export LOG_LEVEL=debug
export LOG_PRETTY=false
export EXECUTOR_PROCESS_BIDS_ENABLED=true
export EXECUTOR_PROCESS_ORDERS_ENABLED=true
export EXECUTOR_PROCESS_CLAIMS_ENABLED=true
export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn'
export RPC_ENDPOINTS='{
    "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
    "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
    "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
    "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]
}'
export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true

# Install screen if not installed
if ! command -v screen &> /dev/null; then
    echo "Installing screen..."
    sudo apt install -y screen
fi

# Start the executor inside a screen session
screen -dmS t3rn-executor bash -c 'pnpm start:executor; exec bash'

echo "t3rn Executor is running in the background. Use 'screen -r t3rn-executor' to view the session."
