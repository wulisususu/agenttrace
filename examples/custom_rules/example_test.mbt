///|
test "consumer defines a domain rule on AgentTrace Core" {
  let evidence : Array[@core.Evidence] = [
    {
      id: "E1",
      kind: "timeout",
      message: "request timed out",
      source: "http",
    },
    {
      id: "E2",
      kind: "retry_exhausted",
      message: "retry budget exhausted",
      source: "runtime",
    },
  ]

  match @custom_rules.diagnose_service(evidence) {
    Some(diagnosis) => {
      assert_eq(diagnosis.category, "service_unavailable")
      assert_eq(diagnosis.rule_ids[0], "SERVICE001")
    }
    None => fail("expected custom consumer rule to match")
  }
}
