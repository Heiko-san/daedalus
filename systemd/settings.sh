# the root directory where all sandbox data will be stored
SANDBOX_BASE="$HOME/.sandbox"
# this is the home-directory vscode will see (and where it will store settings,
# extensions, etc.)
SANDBOX_HOME="$SANDBOX_BASE/vscode-home"
# this is the extensions directory all instances of vscode will use in common
# (to save disk space)
# you can also symlink this to ~/.vscode/extensions if you use a non-sandboxed
# vscode standard installation, too
SANDBOX_EXTENSIONS="$SANDBOX_HOME/extensions"
# this is the base directory for vscode's user-data (e.g. settings, cache, etc.)
# each instance of vscode will get its own subdir in there based on the provided
# WORKDIR, so we can open multiple independent vscode instances
SANDBOX_USERDATA="$SANDBOX_HOME/user-data"
# even we will use separate user-data dirs for each instance, we want some files
# to be shared between them (e.g. the "User" directory to share vscode settings
# & copilot login), so we will symlink those from a common dir into each
# user-data dir (every file or folder directly placed into this common dir will
# be symlinked into each user-data dir)
USERDATA_COMMON="$SANDBOX_USERDATA/common"
# the user's run directory (for sockets, e.g. for dbus), this should not require
# modification in most cases, but can be set to a custom path if needed
USER_RUNDIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
# local runtime dir for sockets, e.g. for dbus (wayland display and dbus
# session bus will be mounted into there from the user's runtime dir)
SANDBOX_RUNDIR="$SANDBOX_HOME/run"
# the wayland display to use inside the sandbox, this will be passed through
WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
# path to the vscode executable to run
VSCODE_EXECUTABLE="code"
# the directories that should be writeable inside the sandbox, even if they are
# inside user's home, which will be hidden by the sandox using a tmpfs, we will
# bind those back into the sandbox and make them writeable (/ will be readonly)
RW_DIRS=(
    # "$WORKDIR" will be added in the caller script,
    # it is set by parameter or defaults to CWD

    # the sandbox home
    "$SANDBOX_HOME"
    # additional paths (e.g. for programming language toolchains)
    "$HOME/.pyenv"
)
# the env vars that should be set inside the sandbox, e.g. for display, dbus, etc.
ENV_VARS=(
    # home dir
    HOME="$SANDBOX_HOME"
    # local runtime dir for sockets, e.g. for dbus (wayland display and dbus
    # session bus will be mounted into there from the user's runtime dir)
    XDG_RUNTIME_DIR="$SANDBOX_RUNDIR"
    # display for gui
    WAYLAND_DISPLAY="$WAYLAND_DISPLAY"
    # dbus session bus address
    DBUS_SESSION_BUS_ADDRESS="unix:path=$SANDBOX_RUNDIR/bus"
)
