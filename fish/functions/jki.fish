function jki --wraps jk --description "alias for jk -i"
	command jk -i $argv 2>| read dir;
	test -n "$dir"
	and cd $dir
end
