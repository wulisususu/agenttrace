///|
test "original Rule API remains supported" {
  let evidence : Array[@core.Evidence] = [
    {
      id: "E1",
      kind: "timeout",
      message: "request timed out",
      source: "network",
    },
    {
      id: "E2",
      kind: "retry_exhausted",
      message: "retry budget exhausted",
      source: "runtime",
    },
  ]
  let rule : @core.Rule = {
    id: "NET001",
    category: "network_unavailable",
    severity: "error",
    confidence: "high",
    required_evidence_kinds: ["timeout", "retry_exhausted"],
    suggested_checks: ["verify upstream availability"],
  }

  match @core.evaluate_rule(rule, evidence) {
    Some(diagnosis) => assert_eq(diagnosis.category, "network_unavailable")
    None => fail("legacy simple rule API must remain compatible")
  }
}
