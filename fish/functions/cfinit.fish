function cfinit
	command cfinit $argv 2>|read dir;
	and test -n "$dir"
	and cd $dir
end
