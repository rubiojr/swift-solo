name "swift-testnode"

run_list(
    "recipe[swift::ring-builder]",
    "role[swift-proxy]",
    "role[swift-storage]"
)
description "configures a swift test node, everything in one server"
