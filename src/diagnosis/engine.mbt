///|
pub(all) struct Evidence {
  id : String
  kind : String
  message : String
  source : String
}

///|
pub(all) struct Diagnosis {
  category : String
  severity : String
  confidence : String
  rule_ids : Array[String]
  evidence : Array[Evidence]
  suggested_checks : Array[String]
}

///|
fn unknown_diagnosis() -> Diagnosis {
  {
    category: "unknown",
    severity: "info",
    confidence: "low",
    rule_ids: [],
    evidence: [],
    suggested_checks: [],
  }
}

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
pub fn diagnose_r001(
  compile_pass : Bool,
  observation : @testlog.TestObservation,
) -> Diagnosis {
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
    unknown_diagnosis()
  }
}

///|
pub fn diagnose_r002(
  build : @buildlog.BuildObservation,
) -> Diagnosis {
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
    unknown_diagnosis()
  }
}

///|
pub fn diagnose_r005(
  environment : @environment.EnvironmentSnapshot,
) -> Diagnosis {
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
    unknown_diagnosis()
  }
}
