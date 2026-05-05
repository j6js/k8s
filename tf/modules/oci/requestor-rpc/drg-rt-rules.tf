resource "time_sleep" "drg_rt_rule_wait" {
  create_duration = "10s"
}

# Note: Route rules are handled by the subnet module which creates bidirectional routes
# The requestor-rpc module here is not needed as the subnet module already handles all RPC routing
