name "swift-proxy"

run_list(
    "recipe[swift::proxy]",
    "recipe[swift::rsync]"
)
description "configures a swift proxy node"
