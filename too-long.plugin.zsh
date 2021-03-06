autoload -U add-zsh-hook
zmodload zsh/datetime

_zsh_too_long_pipe="$( {
    mkfifo $(
        mktemp -tu zsh-too-long-XXXXXX | tee /dev/stderr
    ) } 2>&1
)"

_zsh_too_long_callback() {
    local executed_command=$1
    local exit_code=$2

    local message=""
    if [[ "$exit_code" != "0" ]]; then
        message=" ($exit_code)"
    fi

    # dbus-launch to show notification on the remote client,
    # e.g. connected via x11 forwarding
    dbus-launch --exit-with-session \
        notify-send " $executed_command$message"
}

_zsh_too_long_start() {
    _zsh_too_long_start_time=$EPOCHSECONDS

    # run in the subshell to avoid slow xdotool run time
    (
        local pid="$(_zsh_too_long_get_window_pid)"

        echo "$pid" >! "$_zsh_too_long_pipe"
    ) &|

    _zsh_too_long_executing_command="$1"
}

_zsh_too_long_stop() {
    local command_exit_code=$?

    if ! [ "$_zsh_too_long_executing_command" ]; then
        return
    fi

    local command="$_zsh_too_long_executing_command"

    _zsh_too_long_executing_command=""

    local threshold
    zstyle -g threshold 'too-long:threshold'
    threshold=${threshold:-5}
    execution_time=$(($EPOCHSECONDS - $_zsh_too_long_start_time))

    if (( $execution_time > $threshold )); then
        local current_window_id=$(_zsh_too_long_get_window_pid)

        if [ "$(_zsh_too_long_pipe)" = "$current_window_id" ]; then
            return
        fi

        _zsh_too_long_callback \
            "$command" "$command_exit_code"
    else
        ( _zsh_too_long_pipe > /dev/null ) &|
    fi
}

_zsh_too_long_pipe() {
    cat "$_zsh_too_long_pipe" 2>/dev/null
}

_zsh_too_long_cleanup() {
    rm "$_zsh_too_long_pipe"
}

_zsh_too_long_get_window_pid() {
    if [[ "$DISPLAY" ]]; then
        xdotool getwindowfocus getwindowpid 2>/dev/null
    fi
}

add-zsh-hook preexec _zsh_too_long_start
add-zsh-hook precmd _zsh_too_long_stop
add-zsh-hook zshexit _zsh_too_long_cleanup
