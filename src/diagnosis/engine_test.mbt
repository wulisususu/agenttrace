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
test "R003 diagnoses bounded explicit assertion failures" {
  let log =
    #| RUN  v3.2.4 D:/repo
    #|
    #|AssertionError: expected 3 to be 4 // Object.is equality
    #|
    #|Test Files 1 failed (1)
    #|Tests 1 failed | 3 passed (4)
  let observation = @testlog.parse_vitest(log)
  let diagnosis = @diagnosis.diagnose_r003(observation)

  assert_eq(diagnosis.category, "test_assertion_failure")
  assert_eq(diagnosis.severity, "error")
  assert_eq(diagnosis.confidence, "high")
  assert_eq(diagnosis.rule_ids.length(), 1)
  assert_eq(diagnosis.rule_ids[0], "R003")
  assert_eq(diagnosis.evidence.length(), 2)
}

///|
test "R003 does not diagnose widespread assertion failures conservatively" {
  let log =
    #|AssertionError: expected 3 to be 4
    #|Test Files 10 failed (10)
    #|Tests 20 failed (20)
  let observation = @testlog.parse_vitest(log)
  let diagnosis = @diagnosis.diagnose_r003(observation)

  assert_eq(diagnosis.category, "unknown")
}

///|
test "R003 does not confuse missing matcher setup failure with assertion failure" {
  let log =
    #|AssertionError: expected setup to load
    #|Error: Invalid Chai property: toBeInTheDocument
    #|Error: Invalid Chai property: toBeInTheDocument
    #|Test Files 2 failed (2)
    #|Tests 2 failed (2)
  let observation = @testlog.parse_vitest(log)
  let diagnosis = @diagnosis.diagnose_r003(observation)

  assert_eq(diagnosis.category, "unknown")
  assert_eq(diagnosis.evidence.length(), 0)
}

///|
test "R004 diagnoses an explicit branch expectation mismatch" {
  let repository : @git.RepositorySnapshot = {
    root: "C:/repo",
    branch: "feat/actual",
    head: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    is_dirty: false,
    changed_files: [],
    worktrees: [],
  }
  let diagnosis = @diagnosis.diagnose_r004(
    repository,
    "feat/expected",
    false,
  )

  assert_eq(diagnosis.category, "worktree_state_error")
  assert_eq(diagnosis.severity, "error")
  assert_eq(diagnosis.confidence, "high")
  assert_eq(diagnosis.rule_ids[0], "R004")
  assert_eq(diagnosis.evidence.length(), 1)
  assert_eq(diagnosis.evidence[0].kind, "branch_mismatch")
}

///|
test "R004 diagnoses dirty state only when clean worktree is required" {
  let repository : @git.RepositorySnapshot = {
    root: "/repo",
    branch: "main",
    head: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    is_dirty: true,
    changed_files: ["src/main.ts"],
    worktrees: [],
  }
  let diagnosis = @diagnosis.diagnose_r004(repository, "main", true)

  assert_eq(diagnosis.category, "worktree_state_error")
  assert_eq(diagnosis.severity, "warning")
  assert_eq(diagnosis.confidence, "medium")
  assert_eq(diagnosis.evidence.length(), 1)
  assert_eq(diagnosis.evidence[0].kind, "dirty_worktree")
}

///|
test "R004 leaves ordinary dirty development worktree alone without clean requirement" {
  let repository : @git.RepositorySnapshot = {
    root: "/repo",
    branch: "main",
    head: "cccccccccccccccccccccccccccccccccccccccc",
    is_dirty: true,
    changed_files: ["src/main.ts"],
    worktrees: [],
  }
  let diagnosis = @diagnosis.diagnose_r004(repository, "main", false)

  assert_eq(diagnosis.category, "unknown")
  assert_eq(diagnosis.evidence.length(), 0)
}

///|
test "R004 accepts matching branch and clean worktree" {
  let repository : @git.RepositorySnapshot = {
    root: "/repo",
    branch: "main",
    head: "dddddddddddddddddddddddddddddddddddddddd",
    is_dirty: false,
    changed_files: [],
    worktrees: [],
  }
  let diagnosis = @diagnosis.diagnose_r004(repository, "main", true)

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
