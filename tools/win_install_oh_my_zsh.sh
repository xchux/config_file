#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

log() {
	printf '[%s] %s\n' "$SCRIPT_NAME" "$*"
}

fail() {
	printf '[%s] ERROR: %s\n' "$SCRIPT_NAME" "$*" >&2
	exit 1
}

need_cmd() {
	command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

is_wsl() {
	grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null
}

run_in_wsl() {
	local distro="${1:-}"
	local shell_cmd

	shell_cmd=$(cat <<'EOF'
set -euo pipefail

if ! command -v curl >/dev/null 2>&1; then
	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update
		sudo apt-get install -y curl
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y curl
	elif command -v yum >/dev/null 2>&1; then
		sudo yum install -y curl
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -Sy --noconfirm curl
	elif command -v zypper >/dev/null 2>&1; then
		sudo zypper --non-interactive install curl
	else
		echo 'Unable to install curl automatically. Please install curl manually and rerun.' >&2
		exit 1
	fi
fi

if ! command -v git >/dev/null 2>&1; then
	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update
		sudo apt-get install -y git
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y git
	elif command -v yum >/dev/null 2>&1; then
		sudo yum install -y git
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -Sy --noconfirm git
	elif command -v zypper >/dev/null 2>&1; then
		sudo zypper --non-interactive install git
	else
		echo 'Unable to install git automatically. Please install git manually and rerun.' >&2
		exit 1
	fi
fi

if ! command -v zsh >/dev/null 2>&1; then
	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update
		sudo apt-get install -y zsh
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y zsh
	elif command -v yum >/dev/null 2>&1; then
		sudo yum install -y zsh
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -Sy --noconfirm zsh
	elif command -v zypper >/dev/null 2>&1; then
		sudo zypper --non-interactive install zsh
	else
		echo 'Unable to install zsh automatically. Please install zsh manually and rerun.' >&2
		exit 1
	fi
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
	RUNZSH=no CHSH=yes KEEP_ZSHRC=yes \
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
	echo 'Oh My Zsh is already installed at ~/.oh-my-zsh'
fi

current_shell="$(getent passwd "$USER" | awk -F: '{print $7}')"
zsh_path="$(command -v zsh)"

if [ "$current_shell" != "$zsh_path" ]; then
	chsh -s "$zsh_path"
	echo "Default shell changed to: $zsh_path"
else
	echo "Default shell already set to: $zsh_path"
fi

echo
echo 'Done. Restart your WSL terminal to start using Oh My Zsh.'
EOF
)

	if [ -n "$distro" ]; then
		wsl.exe -d "$distro" -- bash -lc "$shell_cmd"
	else
		wsl.exe -- bash -lc "$shell_cmd"
	fi
}

main() {
	local distro="${1:-}"

	if is_wsl; then
		log 'Detected WSL environment. Installing directly in this distro...'
		run_in_wsl ""
		exit 0
	fi

	if command -v wsl.exe >/dev/null 2>&1; then
		log 'Detected Windows host. Installing Oh My Zsh inside WSL...'
		run_in_wsl "$distro"
		exit 0
	fi

	fail 'This installer supports Windows through WSL. Install WSL first: wsl --install'
}

main "$@"
