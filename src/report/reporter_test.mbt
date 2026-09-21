///|
fn r001_diagnosis() -> @diagnosis.Diagnosis {
  let log =
    #|Test Files 27 failed (27)
    #|Tests 155 failed (155)
    #|Error: Invalid Chai property: toBeInTheDocument
    #|Error: Invalid Chai property: toBeInTheDocument
  let observation = @testlog.parse_vitest(log)
  @diagnosis.diagnose_r001(true, observation)
}

///|
test "render deterministic text report" {
  let diagnosis = r001_diagnosis()
  let actual = @report.render_text(diagnosis)
  let expected =
    $|AgentTrace
    $|
    $|Diagnosis
    $|  Category: dependency_environment_error
    $|  Severity: error
    $|  Confidence: high
    $|
    $|Evidence
    $|  - [build] Compilation succeeds while tests fail
    $|  - [testlog] Multiple test suites share the same missing matcher error
    $|
    $|Suggested checks
    $|  1. verify installed test dependencies
    $|  2. verify test setup loading
    $|  3. rerun the affected test suite before reverting source changes
    $|
  assert_eq(actual, expected)
}

///|
test "render stable valid JSON report" {
  let diagnosis = r001_diagnosis()
  let actual = @report.render_json(diagnosis)

  assert_true(@json.valid(actual))
  assert_eq(
    actual,
    "{\"schema_version\":\"0.1\",\"tool_version\":\"0.1.0-dev\",\"summary\":{\"status\":\"problem_detected\"},\"diagnoses\":[{\"category\":\"dependency_environment_error\",\"severity\":\"error\",\"confidence\":\"high\",\"rule_ids\":[\"R001\"],\"evidence\":[{\"id\":\"E-R001-COMPILE-PASS\",\"kind\":\"compile_result\",\"message\":\"Compilation succeeds while tests fail\",\"source\":\"build\"},{\"id\":\"E-R001-REPEATED-MATCHER\",\"kind\":\"repeated_error_signature\",\"message\":\"Multiple test suites share the same missing matcher error\",\"source\":\"testlog\"}],\"suggested_checks\":[\"verify installed test dependencies\",\"verify test setup loading\",\"rerun the affected test suite before reverting source changes\"]}]}"
  )
}

///|
test "unknown diagnosis remains explicit in both reporters" {
  let log = ""
  let observation = @testlog.parse_vitest(log)
  let diagnosis = @diagnosis.diagnose_r001(true, observation)
  let text = @report.render_text(diagnosis)
  let json = @report.render_json(diagnosis)

  assert_true(text.contains("Category: unknown"))
  assert_true(@json.valid(json))
  assert_true(json.contains("\"status\":\"unknown\""))
}
