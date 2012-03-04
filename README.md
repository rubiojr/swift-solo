# DESCRIPTION

OpenStack Swift Chef Cookbooks for knife-solo - Ubuntu LTS 12.04

The swift cookbook is based on the work from Voxel (https://github.com/voxeldotnet/openstack-swift-chef) and Dell, Inc. OpenStack Swift cookbooks.

It can be used to create three different Swift installations:

* Test node install: 1 proxy+storage node with no replicas
* n-storage nodes + 1 proxy node
* n-storage nodes + n proxy nodes

The cookbook is not intented to be used to create production Swift cluster right now. It's been coded to easily setup test clusters with knife-esx/kvm and knife-solo.

If you wan't to setup Swift production clusters, have a look at https://github.com/dellcloudedge/crowbar 

*This documentation is a work in progress.*

## How to use

The swift cookbook has been designed to setup the nodes in a specific order:

1. Setup the proxy+ring-builder node.
2. Setup the storage nodes and additional proxy nodes if requried.

Proxy (not the ring-builder proxy node) and storge servers require the ring files to start, so we need to fetch them from the proxy+ring-builder. The fetch files files using rsync so setting up this node (the proxy+ring-builder node) first is important.

## Proxy nodes

We can setup two different kinds of proxy nodes: 

* A proxy+ring-builder node

This proxy node is responsible for computing the rings (running swift-ring-bulder create/add/rebalance). This cookbook has been designed to have one ring-builder node only

* A standard proxy node

Standard proxy nodes will copy the rings from the ring-builder node.

## Storage nodes

Storage nodes will copy required ring files from the ring-builder node too.


