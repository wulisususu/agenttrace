///|
fn valid_rule() -> @core.PolicyRule {
  {
    id: "CFG001",
    category: "configuration_error",
    severity: "error",
    confidence: "high",
    priority: 10,
    condition: {
      all_of: ["config_missing"],
      any_of: [],
      none_of: [],
    },
    suggested_checks: ["restore configuration"],
  }
}

///|
test "valid policy rule has no validation issues" {
  assert_eq(@core.validate_policy_rule(valid_rule()).length(), 0)
}

///|
test "validation rejects empty identity and condition" {
  let rule : @core.PolicyRule = {
    id: "",
    category: "",
    severity: "fatal",
    confidence: "certain",
    priority: 0,
    condition: { all_of: [], any_of: [], none_of: [] },
    suggested_checks: [],
  }

  let issues = @core.validate_policy_rule(rule)
  assert_eq(issues.length(), 5)
}

///|
test "validation rejects empty evidence kind" {
  let rule : @core.PolicyRule = {
    id: "CFG001",
    category: "configuration_error",
    severity: "error",
    confidence: "medium",
    priority: 1,
    condition: {
      all_of: [""],
      any_of: [],
      none_of: [],
    },
    suggested_checks: [],
  }

  let issues = @core.validate_policy_rule(rule)
  assert_eq(issues.length(), 1)
  assert_eq(issues[0].field, "condition.all_of")
}

///|
test "rule set validation reports duplicate ids" {
  let first = valid_rule()
  let second = valid_rule()
  let issues = @core.validate_policy_rules([first, second])

  assert_eq(issues.length(), 1)
  assert_true(issues[0].message.contains("duplicate rule id"))
}
