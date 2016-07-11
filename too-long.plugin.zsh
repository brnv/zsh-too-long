autoload -U add-zsh-hook
zmodload zsh/datetime

_zsh_too_long_callback()
{
    notify-send $@
}

_zsh_too_long_start_time=$EPOCHSECONDS
_zsh_too_long_window_id=$(xdotool getwindowfocus getwindowname)
_zsh_too_long_executing_command=""

_zsh_too_long_start()
{
    _zsh_too_long_start_time=$EPOCHSECONDS
    _zsh_too_long_executing_command="$1"
}

_zsh_too_long_stop()
{
    if ! [ "$_zsh_too_long_executing_command" ]; then
        return
    fi

    local current_window_id=$(xdotool getwindowfocus getwindowname)

    if (( $_zsh_too_long_window_id == $current_window_id )); then
        return
    fi

    local threshold
    zstyle -g threshold 'too-long:threshold'
    threshold=${threshold:-5}
    execution_time=$(($EPOCHSECONDS - $_zsh_too_long_start_time))

    if (( $execution_time > $threshold )); then
        _zsh_too_long_callback \
            $_zsh_too_long_executing_command "execution done"
    fi

    _zsh_too_long_executing_command=""
}

add-zsh-hook preexec _zsh_too_long_start
add-zsh-hook precmd _zsh_too_long_stop
