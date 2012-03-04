#!/usr/bin/perl

# -*- cperl -*-

=head1 NAME

traffic_accounting - Munin plugin to monitor arbitrary network
traffic, based on iptables counters. 
Can work in multigraph and "normal" (single graph) mode.

=head1 APPLICABLE SYSTEMS

Any Linux system with iptables/ip6tables

=head1 CONFIGURATION

To use the plugin, special accounting chains need to be set up
in iptables/ip6tables. Obviously, there must be jumps to those chains
from the INPUT and/or OUTPUT and/or FORWARD chains. For example:

 iptables -I INPUT 1 -j ACCT4
 iptables -I OUTPUT 1 -j ACCT4
 ip6tables -I INPUT 1 -j ACCT6
 ip6tables -I OUTPUT 1 -j ACCT6

Within each accounting chain, add non-terminating rules matching the
traffic that needs to be graphed. Each rule must have a comment
in this format:

 =tag=Free descriptive text

"tag" is a label that identifies the entity to graph. If multiple rules have
the same tag, they will be aggregated and their counters summed and graphed
as a single value.

If sent/received style graph is desired for the traffic, some rules must have
a tag like "tag_up" and some rules must have a tag like "tag_down", to indicate
what will go in the upper and lower half of the graph.

See http://backreference.org/2010/07/31/munin-traffic-accounting-with-iptables/
for full details.

Sample ruleset (ACCT4 and ACCT6 are the accounting chains):

 iptables -A ACCT4 -p udp -m udp --dport 53 -m comment --comment "=dns4=DNS traffic to local server"
 ip6tables -A ACCT6 -p tcp -m tcp --dport 80 -m comment --comment "=web6_down=Web traffic to/from local web server"
 ip6tables -A ACCT6 -p tcp -m tcp --sport 80 -m comment --comment "=web6_up=dummy"


This configuration section shows the defaults of the plugin:

 [traffic_accounting]
   # needs root for iptables-save
   user root
   # accounting chain for IPv4
   env.chain4 ACCT4
   # accounting chain for IPv6
   env.chain6 ACCT6
   # location of iptables
   env.iptables /sbin/iptables
   # location of ip6tables
   env.ip6tables /sbin/ip6tables
   # use multigraph yes|no
   env.multigraph yes
   # what to graph bits|bytes|packets
   env.what bytes

If no multigraph is available, symlink the plugin under the name

 traffic_accounting_proto_tag

for example:

 traffic_accounting_ipv4_dns4
 traffic_accounting_ipv6_web6

=head1 INTERPRETATION

The plugin shows the number of packets/bytes/bits of traffic for the defined
traffic flows. Depending on the configuration, data may be graphed in a "normal"
graph, or in a sent/received graph (sent data in the positive values, received
data in the negative values).

=head1 MAGIC MARKERS

  #%# family=network
  #%# capabilities=autoconf

=head1 VERSION

  0.1

=head1 BUGS

None! :-)

=head1 AUTHOR

Davide Brini, 30/07/2010

=cut


use warnings;
use strict;

# bignum for, uh, big numbers (eg byte counters on 32 bit systems)
use bignum;


# the %rules hash has this structure:
#
# normal (ie, single value) rules/graphs:
#
# $rules{$proto}{$tag} --- {type} == "normal" 
#                      `-- {desc}
#                      `-- {packets_up}
#                      `-- {bytes_up}
#
# up/down (ie, sent/received) rules/graphs:
#
# $rules{$proto}{$tag} --- {type} == "updown" 
#                      `-- {desc}
#                      `-- {packets_up}
#                      `-- {packets_down}
#                      `-- {bytes_up}
#                      `-- {bytes_down}
#
# The description is always taken from the first rule found that has the tag
# (where "first" is defined as "the first in the output of iptables-save",
# which returns rules in the order they were inserted.


# Parse the output of iptables-save and saves tags and counters in the provided hash
sub get_data {
  my ($ruleref, $prog, $chain, $proto) = @_;

  open(IPT, "${prog}-save -c -t filter|") or die "Error opening the pipe to ${prog}-save: $!";
  while(<IPT>) {
    my $tag;
    my $packets;
    my $bytes;
    my $desc;
    my $direction;
    my $type;

    # skip non-rules
    /^\[(\d+):(\d+)\] -A \Q${chain}\E .* --comment "=([^=]+)=(.*)"\s+$/ or next;

    $packets = $1;
    $bytes = $2;
    $tag = $3;
    $desc = $4;

    ($tag, $type, $direction) = ($tag=~/(.*)_(down|up)$/i)?($1, "updown", $2):($tag, "normal", "up");

    ${$ruleref}{$proto}{$tag}{type} = $type;

    if (! exists ${$ruleref}{$proto}{$tag}{desc}) {
      # get desc from the first rule with this tag
      ${$ruleref}{$proto}{$tag}{desc} = $desc || $tag;
    }
    
    ${$ruleref}{$proto}{$tag}{ qq {packets_${direction}} } += $packets;
    ${$ruleref}{$proto}{$tag}{ qq {bytes_${direction}} } += $bytes;
  }
  close(IPT);
}


sub print_graph_config {

  my ($iref, $isroot, $what, $tag, $proto, $multigraph) = @_;

  if ($multigraph eq "yes") {
    print "#\n";
    print "multigraph traffic_accounting.${tag}_${proto}\n";
  }

  print "graph_title ${$iref}{desc} ($proto)\n";
  print "graph_info ${$iref}{desc} ($proto)\n";

  print "graph_args --base 1000 -l 0\n";
  print "graph_category network\n";

  if (${$iref}{type} eq "normal") {
    print "graph_vlabel $what per \${graph_period}\n";
  } else {
    print "graph_vlabel $what in (-) / out (+) per \${graph_period}\n";
  }
}

sub print_item_config {

  my ($iref, $isroot, $tag, $proto, $what) = @_;
  my $name = "${proto}_${tag}";

  if (! $isroot) {
    print "${name}_up.label $what ($proto)\n";
  } else {
    print "${name}_up.label ${$iref}{desc} ($proto)\n";
  }

  print "${name}_up.type DERIVE\n";
  print "${name}_up.min 0\n";

  if ($what eq "bits") {
    print "${name}_up.cdef ${name}_up,8,*\n";
  }

  if (${$iref}{type} eq "updown") {

    print "${name}_up.negative ${name}_down\n";

    if (! $isroot) {
      print "graph_order ${name}_down ${name}_up\n";    # MUST be down,up not up, down
    }

    # download, graphed in the lower half
    print "${name}_down.label ${$iref}{desc} ($proto)\n";
    print "${name}_down.type DERIVE\n";
    print "${name}_down.min 0\n";
    print "${name}_down.graph no\n";
    if ($what eq "bits") {
      print "${name}_down.cdef ${name}_down,8,*\n";
    }
  }

}

sub print_item_value {

  my ($iref, $isroot, $tag, $proto, $realwhat, $multigraph) = @_;
  my $name = "${proto}_${tag}";
  
  if ((! $isroot) && ($multigraph eq "yes")) {
    print "#\n";
    print "multigraph traffic_accounting.${tag}_${proto}\n";
  }

  print "${name}_up.value ${$iref}{ qq {${realwhat}_up} }\n";

  if (${$iref}{type} eq "updown") {
    print "${name}_down.value ${$iref}{ qq {${realwhat}_down} }\n";
  }
}



# BEGIN
my $chain4 = $ENV{chain4} || "ACCT4";
my $chain6 = $ENV{chain6} || "ACCT6";
my $iptables = $ENV{iptables} || "/sbin/iptables";
my $ip6tables = $ENV{ip6tables} || "/sbin/ip6tables";
my $what = lc($ENV{what}) || "bytes";
my $realwhat = ($what eq "packets")?$what:"bytes";

my %rules;
my $tag;
my $proto;

# these are used only for non-multigraph mode
my $targetproto;
my $targettag;

my $multigraph;
if (exists $ENV{MUNIN_CAP_MULTIGRAPH}) {
  $multigraph = lc($ENV{multigraph}) || "yes";
} else {
  $multigraph = "no";    # regardless
}

# if multigraph is "no", then assume the script is symlinked as traffic_accounting_proto_tag
if ($multigraph eq "no") {
  # get protocol and tag name from our name
  ($targetproto, $targettag) = ($0 =~ /_([^_]+)_([^_]+)$/);
  $targetproto = lc $targetproto;
}

# sanity checks
if ($multigraph !~ /^(yes|no)/i) {
  die "Invalid value for multigraph: $multigraph";
}

if ($what !~ /^(bytes|bits|packets)$/i) {
  die "Invalid value for what to graph: $what";
}

if ($targetproto && $targetproto !~ /^ipv[46]$/i) {
  die "Invalid protocol $targetproto";
}

if ($ARGV[0] and $ARGV[0] =~ /^\s*autoconf\s*$/i) {
  if (-x $iptables or -x $ip6tables) {
    print "yes\n";
    exit 0;
  } else {
    print "no ($iptables/$ip6tables not found)\n";
    exit 1;
  }
}

# we need this both for config and for data, so do it now

get_data \%rules, $iptables, $chain4, "ipv4";
get_data \%rules, $ip6tables, $chain6, "ipv6";

# sanity check that both up and down parts exist for up/down rules
for $proto (keys %rules) {
  for $tag (keys %{$rules{$proto}}) {
    next if $rules{$proto}{$tag}{type} eq "normal";
    next if (exists $rules{$proto}{$tag}{ qq {${realwhat}_up} } && exists $rules{$proto}{$tag}{ qq {${realwhat}_down} });
    die "Unmatched up/down tag: $proto $tag";
  }
}

my $config = ($ARGV[0] and $ARGV[0] =~ /^\s*config\s*$/i);

# If multigraph enabled, output the root graph
if ($multigraph eq "yes") {
  if ($config) {

    # config
    my $updown = 0;
    
    print "graph_title Root traffic accounting graph (allprotos)\n";
    print "graph_info Root traffic accounting graph (allprotos)\n";
    print "graph_args --base 1000 -l 0\n";
    print "graph_category network\n";

    # the big graph_order thing

    print "graph_order"; 
    for $proto (keys %rules) {
      for $tag (keys %{$rules{$proto}}) {
        if ($rules{$proto}{$tag}{type} eq "normal") {
          print " ${proto}_${tag}_up";
        } else {
          $updown = 1;
          print " ${proto}_${tag}_down ${proto}_${tag}_up";
        }
      }
    }
    print "\n";

    if ($updown) {
      print "graph_vlabel $what in (-) / out (+) per \${graph_period}\n";
    } else {
      print "graph_vlabel $what per \${graph_period}\n";   # FIXME
    }

    # individual graphs config

    for $proto (keys %rules) {
      for $tag (keys %{$rules{$proto}}) {
        print_item_config $rules{$proto}{$tag}, 1, $tag, $proto, $what
      }
    }

  } else {

    # just values

    for $proto (keys %rules) {
      for $tag (keys %{$rules{$proto}}) {
        print_item_value $rules{$proto}{$tag}, 1, $tag, $proto, $realwhat, $multigraph
      }
    }
  }
}


# print either the multigraphs, or the single graph we want
for $proto (keys %rules) {
  for $tag (keys %{$rules{$proto}}) {
    if (($multigraph eq "yes") || ($proto eq $targetproto && $tag eq $targettag)) {
      if ($config) {
        print_graph_config $rules{$proto}{$tag}, 0, $what, $tag, $proto, $multigraph;
        print_item_config $rules{$proto}{$tag}, 0, $tag, $proto, $what;
      } else {
        print_item_value $rules{$proto}{$tag}, 0, $tag, $proto, $realwhat, $multigraph;
      }
    }
  }
}

exit 0;

# vim:syntax=perl
