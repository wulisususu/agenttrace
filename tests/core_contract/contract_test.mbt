///|
test "public core package is independently consumable" {
  let facts : Array[@core.Evidence] = [
    {
      id: "E1",
      kind: "latency_high",
      message: "p95 latency exceeded threshold",
      source: "metrics",
    },
    {
      id: "E2",
      kind: "error_rate_high",
      message: "error rate exceeded threshold",
      source: "metrics",
    },
  ]

  let rule : @core.PolicyRule = {
    id: "SLO001",
    category: "service_degraded",
    severity: "warning",
    confidence: "high",
    priority: 50,
    condition: {
      all_of: ["latency_high", "error_rate_high"],
      any_of: [],
      none_of: ["planned_load_test"],
    },
    suggested_checks: ["inspect recent deployment and upstream dependencies"],
  }

  assert_eq(@core.validate_policy_rule(rule).length(), 0)

  match @core.evaluate_policy_rule(rule, facts) {
    Some(diagnosis) => {
      assert_eq(diagnosis.category, "service_degraded")
      assert_eq(diagnosis.evidence.length(), 2)
    }
    None => fail("public core contract must evaluate the rule")
  }
}
