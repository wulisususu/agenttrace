///|
test "generic rule matches reusable evidence kinds" {
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
    Some(diagnosis) => {
      assert_eq(diagnosis.category, "network_unavailable")
      assert_eq(diagnosis.rule_ids[0], "NET001")
      assert_eq(diagnosis.evidence.length(), 2)
    }
    None => fail("expected generic rule to match")
  }
}

///|
test "generic rule remains unmatched when evidence is incomplete" {
  let evidence : Array[@core.Evidence] = [
    {
      id: "E1",
      kind: "timeout",
      message: "request timed out",
      source: "network",
    },
  ]
  let rule : @core.Rule = {
    id: "NET001",
    category: "network_unavailable",
    severity: "error",
    confidence: "high",
    required_evidence_kinds: ["timeout", "retry_exhausted"],
    suggested_checks: [],
  }

  match @core.evaluate_rule(rule, evidence) {
    Some(_) => fail("incomplete evidence must not match")
    None => ()
  }
}

///|
test "generic engine evaluates multiple independent rules" {
  let evidence : Array[@core.Evidence] = [
    {
      id: "E1",
      kind: "config_missing",
      message: "configuration file is missing",
      source: "filesystem",
    },
  ]
  let rules : Array[@core.Rule] = [
    {
      id: "CFG001",
      category: "configuration_error",
      severity: "error",
      confidence: "high",
      required_evidence_kinds: ["config_missing"],
      suggested_checks: ["restore the required configuration"],
    },
    {
      id: "NET001",
      category: "network_unavailable",
      severity: "error",
      confidence: "high",
      required_evidence_kinds: ["timeout"],
      suggested_checks: [],
    },
  ]

  let diagnoses = @core.evaluate_rules(rules, evidence)
  assert_eq(diagnoses.length(), 1)
  assert_eq(diagnoses[0].category, "configuration_error")
}
