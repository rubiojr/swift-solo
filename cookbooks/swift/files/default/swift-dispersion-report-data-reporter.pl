#!/usr/bin/perl
if ($ARGV[0] eq 'config') {
	print "graph_title Cluster Dispersion Test\n";
	print "graph_category Swift Cluster\n";
	print "graph_args --upper-limit 100 -l 0 \n";
	print "graph_scale no\n";
	print "graph_vlabel object % dispersion\n";
	print "objects.label Objects\n";
	print "graph_vlabel container % dispersion\n";
	print "containers.label Containers\n";
	print "graph_info How well the sample data is dispersed through the cluster.\n";
	exit 0;
}
open $FH, "<", "/tmp/munin-plugin-openstack-swift-dispersion" ;
while ( <$FH> ) {
	print ;
}

