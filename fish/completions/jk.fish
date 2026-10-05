function __jk_problem_letters
	set -l files (command ls -1 2>/dev/null | string match -r '.*\.cpp$')
	for f in $files
		string replace -r '\.cpp$' '' -- $f
	end
end

complete -c jk -f

complete -c jk -s r -x -a "(__jk_problem_letters)" -d "Run a solution"
complete -c jk -s i -d "Initialize contest"
complete -c jk -s f -x -d "Compile flags"
complete -c jk -o debug -l debug -d "Debug mode"
