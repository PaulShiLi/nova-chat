#!/bin/bash

check_command() {
    local key="$1"
    # Split the command into command and arguments
    local cmd=$(echo "$key" | awk '{print $1}')
    local args=$(echo "$key" | awk '{$1=""; print $0}' | sed 's/^ //')

    if [ -z "$args" ]; then
        # No arguments, check command directly
        if command -v "$cmd" &>/dev/null; then
            return 0  # Command exists (true)
        else
            return 1  # Command does not exist (false)
        fi
    else
        # Check command with arguments
        if "$cmd" $args &>/dev/null; then
            return 0  # Command and arguments exist (true)
        else
            return 1  # Command or arguments do not exist (false)
        fi
    fi
}

printNotInstalled() {
    echo "$1 is not installed"
}

printAlreadyInstalled() {
    echo "$1 is already installed"
}

# Example usage:
commands=("git lfs" "docker" "kubectl")
missingDeps=()

for cmd in "${commands[@]}"; do
    if check_command "$cmd"; then
        printAlreadyInstalled "$cmd"
    else
        printNotInstalled "$cmd"
        missingDeps+=("$cmd")
    fi
done

# Print missing dependencies
if [ ${#missingDeps[@]} -ne 0 ]; then
    echo "Missing dependencies: ${missingDeps[@]}"
else
    echo "All dependencies are installed."
fi