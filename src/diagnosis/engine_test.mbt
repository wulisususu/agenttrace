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

///|
test "R002 diagnoses source-located compiler failures" {
  let build = @buildlog.parse_tsc(
    "src/main.ts(12,5): error TS2322: Type 'string' is not assignable to type 'number'.",
    2,
  )
  let diagnosis = @diagnosis.diagnose_r002(build)

  assert_eq(diagnosis.category, "build_compile_error")
  assert_eq(diagnosis.severity, "error")
  assert_eq(diagnosis.confidence, "high")
  assert_eq(diagnosis.rule_ids.length(), 1)
  assert_eq(diagnosis.rule_ids[0], "R002")
  assert_eq(diagnosis.evidence.length(), 2)
}

///|
test "R002 does not guess when compiler output lacks a source location" {
  let build = @buildlog.parse_tsc(
    "error TS5058: The specified path does not exist.",
    1,
  )
  let diagnosis = @diagnosis.diagnose_r002(build)

  assert_eq(diagnosis.category, "unknown")
  assert_eq(diagnosis.evidence.length(), 0)
}

///|
test "R002 does not diagnose a successful compiler run" {
  let build = @buildlog.parse_tsc("", 0)
  let diagnosis = @diagnosis.diagnose_r002(build)

  assert_eq(diagnosis.category, "unknown")
}

///|
test "R005 reports top-level package manager ambiguity" {
  let environment = @environment.detect_environment_from_names([
    "package.json",
    "package-lock.json",
    "pnpm-lock.yaml",
    "node_modules",
  ])
  let diagnosis = @diagnosis.diagnose_r005(environment)

  assert_eq(diagnosis.category, "package_manager_ambiguity")
  assert_eq(diagnosis.severity, "warning")
  assert_eq(diagnosis.confidence, "medium")
  assert_eq(diagnosis.rule_ids.length(), 1)
  assert_eq(diagnosis.rule_ids[0], "R005")
  assert_eq(diagnosis.evidence.length(), 2)
  assert_eq(diagnosis.evidence[0].source, "environment")
  assert_eq(diagnosis.suggested_checks.length(), 3)
}

///|
test "R005 does not confuse two npm lockfiles with two package managers" {
  let environment = @environment.detect_environment_from_names([
    "package.json",
    "package-lock.json",
    "npm-shrinkwrap.json",
  ])
  let diagnosis = @diagnosis.diagnose_r005(environment)

  assert_eq(environment.package_managers.length(), 1)
  assert_eq(diagnosis.category, "unknown")
}

///|
test "R005 leaves a valid Yarn PnP layout alone" {
  let environment = @environment.detect_environment_from_names([
    "package.json",
    "yarn.lock",
    ".pnp.cjs",
    ".yarnrc.yml",
  ])
  let diagnosis = @diagnosis.diagnose_r005(environment)

  assert_eq(diagnosis.category, "unknown")
  assert_eq(diagnosis.evidence.length(), 0)
}
