if [[ -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} && -z ${SSH_CONNECTION:-} && -z ${SSH_TTY:-} ]] \
  && [[ -t 0 && -t 1 ]] && [[ "$(tty 2>/dev/null)" == "/dev/tty1" ]] \
  && command -v start-hyprland >/dev/null 2>&1; then
  exec start-hyprland
fi


# Added by Antigravity CLI installer
export PATH="/home/dxle/.local/bin:$PATH"
