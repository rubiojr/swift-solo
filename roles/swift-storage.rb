name "swift-storage"

run_list(
    "recipe[swift::storage]",
    "recipe[swift::rsync]"
)
description "configures a swift storage node, including creating a loopback device disks, creating XFS"
