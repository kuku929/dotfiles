function shot --description "select region with mouse, save to ~/Pictures and copy to clipboard"
	set -l geom (slurp); or return 1
	set -l out ~/Pictures/shot-(date +%Y%m%d-%H%M%S).png
	grim -g "$geom" $out; and wl-copy < $out; and echo $out
end
