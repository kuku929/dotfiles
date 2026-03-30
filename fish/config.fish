if status is-interactive
    # Commands to run in interactive sessions can go here
	set -U fish_greeting ''
	set -gx EDITOR vi
	set -gx VISUAL nvim

	set -gx TERMINAL alacritty

	set -gx LANG en_US.UTF-8

	eval "$(pyenv init -)"
	eval "$(pyenv virtualenv-init -)"
	eval "xset r rate 200 30"

	set -gxa PATH "/home/krutarth/.local/bin"
end


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
test -r '/home/krutarth/.opam/opam-init/init.fish' && source '/home/krutarth/.opam/opam-init/init.fish' > /dev/null 2> /dev/null; or true
# END opam configuration
