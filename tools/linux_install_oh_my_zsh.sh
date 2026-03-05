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

install_pkg() {
	local package_name="$1"

	if command -v apt-get >/dev/null 2>&1; then
		sudo apt-get update
		sudo apt-get install -y "$package_name"
	elif command -v dnf >/dev/null 2>&1; then
		sudo dnf install -y "$package_name"
	elif command -v yum >/dev/null 2>&1; then
		sudo yum install -y "$package_name"
	elif command -v pacman >/dev/null 2>&1; then
		sudo pacman -Sy --noconfirm "$package_name"
	elif command -v zypper >/dev/null 2>&1; then
		sudo zypper --non-interactive install "$package_name"
	elif command -v apk >/dev/null 2>&1; then
		sudo apk add --no-cache "$package_name"
	else
		fail "No supported package manager found to install: $package_name"
	fi
}

ensure_cmd() {
	local command_name="$1"
	local package_name="${2:-$1}"

	if ! command -v "$command_name" >/dev/null 2>&1; then
		log "Installing $package_name..."
		install_pkg "$package_name"
	fi
}

main() {
	if [[ "${OSTYPE:-}" == "msys"* || "${OSTYPE:-}" == "cygwin"* || "${OSTYPE:-}" == "win32"* ]]; then
		fail "This script is for Linux only. Use tools/win_install_oh_my_zsh.sh on Windows."
	fi

	ensure_cmd curl
	ensure_cmd git
	ensure_cmd zsh

	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		log 'Installing Oh My Zsh...'
		RUNZSH=no CHSH=yes KEEP_ZSHRC=yes \
			sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	else
		log 'Oh My Zsh already installed at ~/.oh-my-zsh'
	fi

	current_shell="$(getent passwd "$USER" | awk -F: '{print $7}')"
	zsh_path="$(command -v zsh)"

	if [ "$current_shell" != "$zsh_path" ]; then
		chsh -s "$zsh_path"
		log "Default shell changed to: $zsh_path"
	else
		log "Default shell already set to: $zsh_path"
	fi

	echo
	log 'Done. Restart your terminal to start using Oh My Zsh.'
}

main "$@"
