///|
fn evidence(kind : String, id : String) -> @core.Evidence {
  {
    id,
    kind,
    message: kind,
    source: "test",
  }
}

///|
test "condition requires every all_of kind" {
  let condition : @core.Condition = {
    all_of: ["timeout", "retry_exhausted"],
    any_of: [],
    none_of: [],
  }

  assert_true(
    @core.condition_matches(
      condition,
      [evidence("timeout", "E1"), evidence("retry_exhausted", "E2")],
    ),
  )
  assert_true(
    !@core.condition_matches(condition, [evidence("timeout", "E1")]),
  )
}

///|
test "condition accepts one any_of kind" {
  let condition : @core.Condition = {
    all_of: ["service_started"],
    any_of: ["http_500", "connection_refused"],
    none_of: [],
  }

  assert_true(
    @core.condition_matches(
      condition,
      [evidence("service_started", "E1"), evidence("http_500", "E2")],
    ),
  )
  assert_true(
    !@core.condition_matches(
      condition,
      [evidence("service_started", "E1")],
    ),
  )
}

///|
test "condition rejects forbidden none_of kind" {
  let condition : @core.Condition = {
    all_of: ["config_loaded"],
    any_of: [],
    none_of: ["maintenance_mode"],
  }

  assert_true(
    @core.condition_matches(condition, [evidence("config_loaded", "E1")]),
  )
  assert_true(
    !@core.condition_matches(
      condition,
      [
        evidence("config_loaded", "E1"),
        evidence("maintenance_mode", "E2"),
      ],
    ),
  )
}

///|
test "empty condition never becomes an accidental catch all" {
  let condition : @core.Condition = {
    all_of: [],
    any_of: [],
    none_of: [],
  }

  assert_true(!@core.condition_matches(condition, []))
  assert_true(
    !@core.condition_matches(condition, [evidence("anything", "E1")]),
  )
}

///|
test "condition evidence returns only positive matched facts" {
  let condition : @core.Condition = {
    all_of: ["service_started"],
    any_of: ["http_500", "connection_refused"],
    none_of: ["maintenance_mode"],
  }
  let facts = [
    evidence("service_started", "E1"),
    evidence("http_500", "E2"),
    evidence("unrelated", "E3"),
  ]

  let matched = @core.condition_evidence(condition, facts)
  assert_eq(matched.length(), 2)
  assert_eq(matched[0].id, "E1")
  assert_eq(matched[1].id, "E2")
}

///|
test "evidence query helpers are deterministic" {
  let facts = [
    evidence("timeout", "E1"),
    evidence("timeout", "E2"),
    evidence("retry_exhausted", "E3"),
  ]

  assert_true(@core.evidence_has_kind(facts, "timeout"))
  assert_eq(@core.evidence_count_kind(facts, "timeout"), 2)
  assert_eq(@core.evidence_by_kind(facts, "timeout").length(), 2)
}

///|
test "condition report explains missing and blocking evidence" {
  let condition : @core.Condition = {
    all_of: ["service_started", "health_probe_enabled"],
    any_of: ["http_500", "timeout"],
    none_of: ["maintenance_mode"],
  }
  let facts = [
    evidence("service_started", "E1"),
    evidence("timeout", "E2"),
    evidence("maintenance_mode", "E3"),
  ]

  let report = @core.inspect_condition(condition, facts)
  assert_true(!report.matched)
  assert_true(!report.empty_condition)
  assert_eq(report.missing_all.length(), 1)
  assert_eq(report.missing_all[0], "health_probe_enabled")
  assert_eq(report.matched_any.length(), 1)
  assert_eq(report.matched_any[0], "timeout")
  assert_eq(report.blocked_by.length(), 1)
  assert_eq(report.blocked_by[0], "maintenance_mode")
}

///|
test "empty condition report remains explicit" {
  let condition : @core.Condition = {
    all_of: [],
    any_of: [],
    none_of: [],
  }

  let report = @core.inspect_condition(condition, [])
  assert_true(report.empty_condition)
  assert_true(!report.matched)
}
