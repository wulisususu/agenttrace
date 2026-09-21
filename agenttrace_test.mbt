///|
test "version is stable" {
  assert_eq(version(), "0.1.0-dev")
}

///|
test "banner identifies AgentTrace" {
  assert_eq(banner(), "AgentTrace 0.1.0-dev")
}
