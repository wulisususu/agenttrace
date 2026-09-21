///|
test "version is stable" {
  assert_eq(@agenttrace.version(), "0.1.0-dev")
}

///|
test "banner identifies AgentTrace" {
  assert_eq(@agenttrace.banner(), "AgentTrace 0.1.0-dev")
}
