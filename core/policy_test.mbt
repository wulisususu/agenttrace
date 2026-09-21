///|
fn fact(kind : String, id : String) -> @core.Evidence {
  {
    id,
    kind,
    message: kind,
    source: "test",
  }
}

///|
fn service_rule(id : String, category : String, priority : Int) -> @core.PolicyRule {
  {
    id,
    category,
    severity: "error",
    confidence: "high",
    priority,
    condition: {
      all_of: ["service_started"],
      any_of: ["http_500", "connection_refused"],
      none_of: ["maintenance_mode"],
    },
    suggested_checks: ["inspect upstream service"],
  }
}

///|
test "policy rule combines all any and none constraints" {
  let rule = service_rule("SERVICE001", "service_unavailable", 10)
  let facts = [
    fact("service_started", "E1"),
    fact("connection_refused", "E2"),
  ]

  match @core.evaluate_policy_rule(rule, facts) {
    Some(diagnosis) => {
      assert_eq(diagnosis.category, "service_unavailable")
      assert_eq(diagnosis.evidence.length(), 2)
      assert_eq(diagnosis.rule_ids[0], "SERVICE001")
    }
    None => fail("expected policy rule to match")
  }
}

///|
test "policy rule does not match during maintenance" {
  let rule = service_rule("SERVICE001", "service_unavailable", 10)
  let facts = [
    fact("service_started", "E1"),
    fact("http_500", "E2"),
    fact("maintenance_mode", "E3"),
  ]

  match @core.evaluate_policy_rule(rule, facts) {
    Some(_) => fail("forbidden evidence must block the rule")
    None => ()
  }
}

///|
test "evaluate policy rules preserves caller order" {
  let rules = [
    service_rule("LOW", "low_priority_match", 1),
    service_rule("HIGH", "high_priority_match", 100),
  ]
  let facts = [fact("service_started", "E1"), fact("http_500", "E2")]

  let diagnoses = @core.evaluate_policy_rules(rules, facts)
  assert_eq(diagnoses.length(), 2)
  assert_eq(diagnoses[0].category, "low_priority_match")
  assert_eq(diagnoses[1].category, "high_priority_match")
}

///|
test "highest priority returns strongest matching policy" {
  let rules = [
    service_rule("LOW", "degraded_service", 10),
    service_rule("HIGH", "service_unavailable", 100),
  ]
  let facts = [fact("service_started", "E1"), fact("http_500", "E2")]

  match @core.evaluate_highest_priority(rules, facts) {
    Some(diagnosis) => {
      assert_eq(diagnosis.category, "service_unavailable")
      assert_eq(diagnosis.rule_ids[0], "HIGH")
    }
    None => fail("expected one highest-priority diagnosis")
  }
}

///|
test "highest priority is stable on ties" {
  let rules = [
    service_rule("FIRST", "first", 50),
    service_rule("SECOND", "second", 50),
  ]
  let facts = [fact("service_started", "E1"), fact("http_500", "E2")]

  match @core.evaluate_highest_priority(rules, facts) {
    Some(diagnosis) => assert_eq(diagnosis.rule_ids[0], "FIRST")
    None => fail("expected a diagnosis")
  }
}
