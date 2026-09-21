///|
test "parse Vitest missing matcher failure" {
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

  assert_eq(observation.runner, "vitest")
  assert_eq(observation.status, "fail")
  assert_eq(observation.failed_suites, 27)
  assert_eq(observation.failed_tests, 155)
  assert_eq(observation.error_signatures.length(), 1)
  assert_eq(
    observation.error_signatures[0].message,
    "Invalid Chai property: toBeInTheDocument",
  )
  assert_eq(observation.error_signatures[0].occurrences, 3)
}

///|
test "parse passing Vitest summary" {
  let log =
    #| RUN  v3.2.4 D:/repo
    #|
    #|Test Files 4 passed (4)
    #|Tests 21 passed (21)
  let observation = @testlog.parse_vitest(log)

  assert_eq(observation.status, "pass")
  assert_eq(observation.failed_suites, 0)
  assert_eq(observation.failed_tests, 0)
  assert_eq(observation.error_signatures.length(), 0)
}
