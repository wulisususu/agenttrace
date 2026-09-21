///|
test "R001 diagnoses repeated matcher failures after successful compile" {
  let log =
    #| RUN  v3.2.4 D:/repo
    #|
    #|Error: Invalid Chai property: toBeInTheDocument
    #|Error: Invalid Chai property: toBeInTheDocument
    #|Error: Invalid Chai property: toBeInTheDocument
    #|
    #|Test Files 27 failed (27)
    #|Tests 155 failed (155)
  let observation = @testlog.parse_vitest(log)
  let diagnosis = @diagnosis.diagnose_r001(true, observation)

  assert_eq(diagnosis.category, "dependency_environment_error")
  assert_eq(diagnosis.severity, "error")
  assert_eq(diagnosis.confidence, "high")
  assert_eq(diagnosis.rule_ids.length(), 1)
  assert_eq(diagnosis.rule_ids[0], "R001")
  assert_eq(diagnosis.evidence.length(), 2)
  assert_eq(diagnosis.evidence[0].source, "build")
  assert_eq(diagnosis.evidence[1].source, "testlog")
  assert_eq(diagnosis.suggested_checks.length(), 3)
}

///|
test "R001 does not diagnose when compilation fails" {
  let log =
    #|Test Files 27 failed (27)
    #|Tests 155 failed (155)
    #|Error: Invalid Chai property: toBeInTheDocument
    #|Error: Invalid Chai property: toBeInTheDocument
  let observation = @testlog.parse_vitest(log)
  let diagnosis = @diagnosis.diagnose_r001(false, observation)

  assert_eq(diagnosis.category, "unknown")
  assert_eq(diagnosis.evidence.length(), 0)
}

///|
test "R001 does not diagnose isolated matcher failure" {
  let log =
    #|Test Files 1 failed (1)
    #|Tests 1 failed (1)
    #|Error: Invalid Chai property: toBeInTheDocument
  let observation = @testlog.parse_vitest(log)
  let diagnosis = @diagnosis.diagnose_r001(true, observation)

  assert_eq(diagnosis.category, "unknown")
  assert_eq(diagnosis.rule_ids.length(), 0)
}

///|
test "R001 does not diagnose passing tests" {
  let log =
    #|Test Files 4 passed (4)
    #|Tests 21 passed (21)
  let observation = @testlog.parse_vitest(log)
  let diagnosis = @diagnosis.diagnose_r001(true, observation)

  assert_eq(diagnosis.category, "unknown")
}
