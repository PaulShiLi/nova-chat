#!/bin/bash

#######################################

OS=$(uname -s)
curDir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
rootDir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
USER=$(whoami)

#######################################
# Color Codes

# Reset
Color_Off='\033[0m' # Text Reset

# Regular Colors
Red='\033[0;31m'    # Red
Green='\033[0;32m'  # Green
Yellow='\033[0;33m' # Yellow
Cyan='\033[0;36m'   # Cyan
White='\033[0;37m'  # White
Grey='\033[0;90m'   # Grey

#######################################

# Functions

print() {
    if [[ $OS == "Darwin" ]]; then
        echo -e $1
    else
        echo $1
    fi
}

printSection() {
    print "\n==============================\n"
}

# Function to accept a string parameter to set color
setColor() {
    printf "${1}"
}

printHeader() {
    setColor $Cyan
    toPrint=$1
    noNewLines=false

    # Loop through parameters and see if there are any flags and skip 1st parameter and if there are no parameters, print a new line
    for var in "${@:2}"; do
        if [[ $var == "no lines" ]]; then
            toPrint+=""
            noNewLines=true
        elif [[ $var == "section" ]]; then
            toPrint="\n\n${toPrint}"
        fi
    done
    if [[ $noNewLines == false ]]; then
        toPrint+="\n"
    fi
    
    print "${toPrint}"
    setColor $Color_Off
}

printAlreadyInstalled() {
    setColor $Yellow
    if [[ -z $2 ]]; then
        echo "[=] $1 is already installed"
    else
        echo "[=] $1 $2"
    fi
    setColor $Color_Off
}

printInstalled() {
    setColor $Green
    if [[ -z $2 ]]; then
        echo "[+] $1 installed"
    else
        echo "[+] $1 $2"
    fi
    setColor $Color_Off
}

printNotInstalled() {
    setColor $Red
    if [[ -z $2 ]]; then
        echo "[!] $1 not found"
    else
        echo "[!] $1 $2"
    fi
    setColor $Color_Off
}

printInProgress() {
    setColor $White
    if [[ -z $2 ]]; then
        echo "[.] $1 in progress"
    else
        echo "[.] $1 $2"
    fi
    setColor $Color_Off
}

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

#######################################

printSection
printHeader "Current configurations:" "no lines"
echo "OS: $OS"
echo "Root directory: $rootDir"
echo "Current path: $curDir"

#######################################

printSection
printHeader "Checking execution environment and privileges:" "no lines"

# Check if script is running as root
if [[ $EUID -ne 0 || $OS != "Darwin" ]]; then
    printAlreadyInstalled "Script not running as root" " "
else
    printNotInstalled "Please don't run this script as root!" " "
    exit 1
fi

#######################################

# Check if flag of -d or --docker is passed

if [[ $1 == "-d" || $1 == "--docker" ]]; then
    inDocker=true
else
    inDocker=false
fi

#######################################

printSection
printHeader "Loading dependencies..."

depPath="$rootDir/assets/dependencies.json"

# Get dependencies from dependencies.json
deps=$(cat $depPath | jq .)
KeyOS=""

if [[ $OS == "Darwin" ]]; then
    KeyOS="Darwin"
elif [[ $OS == "Linux" ]]; then
    KeyOS="Linux"
fi

echo "Dependencies loaded"

#######################################

printSection
printHeader "Updating and upgrading existing packages..."

setColor $Grey

if [[ $OS == "Darwin" ]]; then
    brew update && brew upgrade
elif [[ $OS == "Linux" ]]; then
    sudo apt update && sudo apt upgrade -y
fi

setColor $Color_Off

#######################################
printSection
printHeader "Checking for dependencies..."
if [[ $inDocker = false ]]; then
    # Access each dependency under the key Darwin and print each key and value
    # List of missing dependencies
    missingDeps=()

    echo $deps | jq -r ".$KeyOS | keys | .[]" | while read key; do
        value=$(echo $deps | jq -r ".$KeyOS.\"$key\"")

        if check_command "$key"; then
            printAlreadyInstalled "$key"
        else
            printNotInstalled "$key"
            missingDeps+=("$key")
        fi

    done

    # If there are missing dependencies, install them
    if [ ${#missingDeps[@]} -eq 0 ]; then
        printHeader "All dependencies are installed" "section"
    else
        printHeader "Installing missing dependencies..." "section"
        for dep in "${missingDeps[@]}"; do
            # Access each dependency under the key Darwin, and each value have a list of commands of installing the dependency and iterate through each command
            python3 - <<EOF > commands.txt
import json

json_path = "$depPath"
key_os = "$KeyOS"
dep = "$dep"

with open(json_path, 'r') as file:
    deps = json.load(file)

commands = deps[key_os].get(dep, [])
for cmd in commands:
    print(cmd)
EOF
            # Execute the commands
            while IFS= read -r cmd; do
                echo "Installing $dep..."
                eval "$cmd"
            done < commands.txt

            # Clean up
            rm commands.txt            
        done
    fi
fi

#######################################
# Check for local environment

printSection
printHeader "Installing Python packages..."

# Fetch Packages from requirements.txt
setColor $Grey
pip install -r $rootDir/requirements.txt

packageList=()

# Install packages if command not found
for package in "${packageList[@]}"; do
    if ! command -v "$package" &>/dev/null; then
        printNotInstalled $package
        pip install $package
    else
        printAlreadyInstalled $package
    fi
done

setColor $Color_Off

print "\n- Python packages installed"

#######################################

if [[ $inDocker = false ]]; then
    printSection
    printHeader "Building Docker..."
    networkName="novaNetwork"

    # Check if network exists
    if docker network ls --format '{{.Name}}' | grep -wq "$networkName"; then
        printAlreadyInstalled "Docker network" $networkName
    else
        printNotInstalled "Docker network" $networkName
        setColor $Cyan
        print "Building Docker network...\n"
        setColor $Color_Off

        setColor $Grey
        sudo docker network create novaNetwork
        setColor $Color_Off

        print "\n- Docker network built"
    fi

    printHeader

    setColor $Cyan
    print "Building Docker container...\n"
    # sudo DOCKER_BUILDKIT=1 docker compose -f docker-compose.yml build
    setColor $Color_Off

    print "- Docker container built"

fi

#######################################
printSection
printHeader "Preloading models..."

modelList_path="$rootDir/assets/models.json"
modelPath="$rootDir/assets/models"

# Get models from models.json
models=$(cat $modelList_path | jq .)

# Access each model under key called text and print each key and value
echo $models | jq -r ".text | keys | .[]" | while read key; do
    value=$(echo $models | jq -r ".text.\"$key\"")

    # Lowercase the key and replace spaces with dashes
    name=$(echo $key | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
    file=$(echo $value | jq -r ".file")

    # If file exists, model is already installed
    if [ -f "$modelPath/text/$name/$file" ]; then
        printAlreadyInstalled "$key"
    else
        origin=$(echo $value | jq -r ".origin")

        printNotInstalled "$key"
        printInProgress "Downloading $key..."

        cd $modelPath/text

        if [ -d "tmp" ]; then
            rm -rf "tmp"
        fi

        git init "tmp"
        cd "tmp"

        git remote add origin $origin
        git pull origin main

        # Remove everything except the model
        rm -rf $(ls | grep -v $file)

        git lfs install
        git lfs pull -I $file

        # Move the model to the models directory
        if [ ! -d "$name" ]; then
            mkdir ../$name
        fi
        mv $file $modelPath/text/$name
        cd ../$name
        rm -rf ../tmp
        

        cd $rootDir

    fi


done

echo $models | jq -r ".embed | keys | .[]" | while read key; do
    value=$(echo $models | jq -r ".embed.\"$key\"")

    # Lowercase the key and replace spaces with dashes
    name=$(echo $key | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

    # If file exists, model is already installed
    if [ -f "$modelPath/embed/$name" ]; then
        printAlreadyInstalled "$key"
    else
        origin=$(echo $value | jq -r ".origin")

        printNotInstalled "$key"
        printInProgress "Downloading $key..."

        git lfs install
        git clone $origin $modelPath/embed/$name

    fi


done
