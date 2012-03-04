#!/usr/bin/perl

@output = qx{ /usr/bin/swift-dispersion-report } ; 
open TMP0, ">/tmp/munin-plugin-openstack-swift-dispersion" or die $!;
for ( @output ) {
	#print ;
	next unless /^\d/;
	$line = $_;

	if ( $line =~ /(\d+\.\d+)% of container copies found/ ) { 
		print TMP0 "containers.value $1\n";
		next;
	}

	if ( $line =~ /(\d+\.\d+)% of object copies found/ ) { 
		print TMP0 "objects.value $1\n";
		next;
	}

}
close TMP0;
