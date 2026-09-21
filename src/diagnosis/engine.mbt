///|
fn missing_matcher_occurrences(
  observation : @testlog.TestObservation,
) -> Int {
  let mut occurrences = 0
  for signature in observation.error_signatures {
    if signature.message == "Invalid Chai property: toBeInTheDocument" {
      occurrences = signature.occurrences
    }
  }
  occurrences
}

///|
/// Built-in AgentTrace rule for repeated missing-matcher failures after a
/// successful compile. The reusable data model lives in src/core.
pub fn diagnose_r001(
  compile_pass : Bool,
  observation : @testlog.TestObservation,
) -> @core.Diagnosis {
  let repeated_matcher = missing_matcher_occurrences(observation)

  if compile_pass &&
    observation.status == "fail" &&
    observation.failed_suites >= 2 &&
    repeated_matcher >= 2 {
    {
      category: "dependency_environment_error",
      severity: "error",
      confidence: "high",
      rule_ids: ["R001"],
      evidence: [
        {
          id: "E-R001-COMPILE-PASS",
          kind: "compile_result",
          message: "Compilation succeeds while tests fail",
          source: "build",
        },
        {
          id: "E-R001-REPEATED-MATCHER",
          kind: "repeated_error_signature",
          message: "Multiple test suites share the same missing matcher error",
          source: "testlog",
        },
      ],
      suggested_checks: [
        "verify installed test dependencies",
        "verify test setup loading",
        "rerun the affected test suite before reverting source changes",
      ],
    }
  } else {
    @core.unknown_diagnosis()
  }
}

///|
pub fn diagnose_r002(
  build : @buildlog.BuildObservation,
) -> @core.Diagnosis {
  if build.status == "fail" &&
    build.exit_code != 0 &&
    build.errors.length() > 0 {
    {
      category: "build_compile_error",
      severity: "error",
      confidence: "high",
      rule_ids: ["R002"],
      evidence: [
        {
          id: "E-R002-COMPILER-EXIT",
          kind: "compiler_exit",
          message: "TypeScript compiler exited with a non-zero status",
          source: "build",
        },
        {
          id: "E-R002-SOURCE-LOCATION",
          kind: "source_location",
          message: "Compiler reported at least one source-located TypeScript error",
          source: "buildlog",
        },
      ],
      suggested_checks: [
        "inspect the first source-located compiler error",
        "rerun the compiler after a targeted source fix",
        "avoid changing dependency state unless compiler evidence points there",
      ],
    }
  } else {
    @core.unknown_diagnosis()
  }
}

///|
pub fn diagnose_r003(
  observation : @testlog.TestObservation,
) -> @core.Diagnosis {
  let repeated_matcher = missing_matcher_occurrences(observation)

  if observation.status == "fail" &&
    observation.failed_suites >= 1 &&
    observation.failed_suites <= 3 &&
    observation.failed_tests >= 1 &&
    observation.failed_tests <= 5 &&
    observation.assertion_failures >= 1 &&
    repeated_matcher == 0 {
    {
      category: "test_assertion_failure",
      severity: "error",
      confidence: "high",
      rule_ids: ["R003"],
      evidence: [
        {
          id: "E-R003-RUNNER-SUMMARY",
          kind: "test_summary",
          message: "Vitest completed with a bounded set of failed tests",
          source: "testlog",
        },
        {
          id: "E-R003-ASSERTION",
          kind: "assertion_failure",
          message: "At least one explicit assertion failure was observed",
          source: "testlog",
        },
      ],
      suggested_checks: [
        "inspect the first assertion diff and its expected value",
        "rerun the smallest affected test target",
        "compare the failing behavior with the recent source change",
      ],
    }
  } else {
    @core.unknown_diagnosis()
  }
}

///|
pub fn diagnose_r004(
  repository : @git.RepositorySnapshot,
  expected_branch : String,
  require_clean : Bool,
) -> @core.Diagnosis {
  let branch_mismatch =
    expected_branch != "" && repository.branch != expected_branch
  let dirty_violation = require_clean && repository.is_dirty

  if branch_mismatch || dirty_violation {
    let evidence : Array[@core.Evidence] = []

    if branch_mismatch {
      evidence.push({
        id: "E-R004-BRANCH-MISMATCH",
        kind: "branch_mismatch",
        message: "Current worktree branch does not match the explicitly expected branch",
        source: "repository",
      })
    }

    if dirty_violation {
      evidence.push({
        id: "E-R004-DIRTY-WORKTREE",
        kind: "dirty_worktree",
        message: "Working tree contains changes while a clean worktree was explicitly required",
        source: "repository",
      })
    }

    {
      category: "worktree_state_error",
      severity: if branch_mismatch { "error" } else { "warning" },
      confidence: if branch_mismatch { "high" } else { "medium" },
      rule_ids: ["R004"],
      evidence,
      suggested_checks: [
        "verify that the current worktree is the intended execution target",
        "compare the current branch and HEAD with the expected task context",
        "review local changes before switching branches or cleaning the worktree",
      ],
    }
  } else {
    @core.unknown_diagnosis()
  }
}

///|
pub fn diagnose_r005(
  environment : @environment.EnvironmentSnapshot,
) -> @core.Diagnosis {
  if environment.package_managers.length() >= 2 &&
    environment.lockfiles.length() >= 2 {
    {
      category: "package_manager_ambiguity",
      severity: "warning",
      confidence: "medium",
      rule_ids: ["R005"],
      evidence: [
        {
          id: "E-R005-MULTIPLE-MANAGERS",
          kind: "package_manager_signal",
          message: "Top-level lockfiles indicate multiple package managers",
          source: "environment",
        },
        {
          id: "E-R005-MULTIPLE-LOCKFILES",
          kind: "lockfile_set",
          message: "Multiple top-level lockfiles are present",
          source: "environment",
        },
      ],
      suggested_checks: [
        "confirm the package manager intended for this repository",
        "check whether any top-level lockfile is stale",
        "avoid regenerating or deleting lockfiles until the intended manager is confirmed",
      ],
    }
  } else {
    @core.unknown_diagnosis()
  }
}
