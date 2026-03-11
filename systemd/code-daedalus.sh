#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/settings.sh"

# provide WORKDIR as parameter (defaults to CWD),
# this is the directory vscode will open on start
WORKDIR="$(realpath "${1:-.}")"
RW_DIRS+=(
    "${WORKDIR}"
)

# calculate a unique user-data dir for this workspace based on the WORKDIR,
# so we can open multiple independent vscode instances with different workspaces
WORKSPACE_ID="$(printf '%s' "${WORKDIR}" | sha256sum | awk '{print substr($1,1,12)}')"
USERDATA_DIR="${SANDBOX_USERDATA}/${WORKSPACE_ID}"

# populate the user-data dir for this instance by symlinking all files from the
# common dir into it
mkdir -p "$SANDBOX_EXTENSIONS" "$USERDATA_DIR"
find "$USERDATA_COMMON" -mindepth 1 -maxdepth 1 -print0 \
    | while IFS= read -r -d '' src; do
        base="$(basename "$src")"
        ln -snf -- "$src" "$USERDATA_DIR/$base"
    done

# build all the arguments for systemd-run in an array, this is easier to
# maintain and offers the possibility to add comments for each option
args=(
    # run as a user service
    --user
    # cleanup the (temporary) unit after exit
    --collect
    # give the sandbox its own /tmp & /var/tmp
    --property=PrivateTmp=yes
    # give each instance its own mount namespace
    --property=PrivateMounts=yes
    # do not allow to escalate privileges
    --property=NoNewPrivileges=yes
    # readonly root (/)
    --property=ProtectSystem=strict
    # replace /home with tmpfs -> hide home
    --property=ProtectHome=tmpfs
    # block SUID/SGID binaries from having effect
    --property=RestrictSUIDSGID=yes
    # reduce kernel / cgroup attack surface
    --property=ProtectKernelTunables=yes
    --property=ProtectControlGroups=yes
    # prevent personality changes
    --property=LockPersonality=yes
    # set the CWD
    --working-directory="$WORKDIR"
)

# add all the required env vars (e.g. for display, dbus, etc.)
for env_var in "${ENV_VARS[@]}"; do
    args+=(--setenv="$env_var")
done

# bind the required directories into the sandbox and make them writeable
for dir in "${RW_DIRS[@]}"; do
    args+=(
        # bind allowed paths back into tmpfs-home namespace ...
        --property="BindPaths=$dir:$dir"
        # ... and make them writeable
        --property="ReadWritePaths=$dir"
    )
done

# the actual command to run, we have to use bash -c to be able to use the trap
# for cleanup of the user-data dir on vscode exit
# since we have separate user-data dirs per instance, there would be a lot of
# cache data lying around otherwise
args+=(
    /usr/bin/env bash -c "
        set -euo pipefail
        trap \"rm -rf -- \\\"$USERDATA_DIR\\\"\" EXIT
        \"${VSCODE_EXECUTABLE}\" --new-window --user-data-dir \"$USERDATA_DIR\" \
            --extensions-dir \"$SANDBOX_EXTENSIONS\" --verbose \"$WORKDIR\"
    "
)

# run our pseudo service
systemd-run "${args[@]}"
