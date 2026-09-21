///|
pub(all) struct DiagnosticReport {
  repository : @git.RepositorySnapshot
  environment : @environment.EnvironmentSnapshot
  build : @buildlog.BuildObservation?
  tests : @testlog.TestObservation?
  diagnoses : Array[@diagnosis.Diagnosis]
}

///|
fn worktree_to_json(worktree : @git.WorktreeSnapshot) -> Json {
  {
    "path": worktree.path,
    "head": worktree.head,
    "branch": worktree.branch,
    "detached": worktree.detached,
    "bare": worktree.bare,
    "prunable": worktree.prunable,
  }
}

///|
fn repository_to_json(repository : @git.RepositorySnapshot) -> Json {
  let worktrees : Array[Json] = []
  for worktree in repository.worktrees {
    worktrees.push(worktree_to_json(worktree))
  }

  {
    "root": repository.root,
    "branch": repository.branch,
    "head": repository.head,
    "is_dirty": repository.is_dirty,
    "changed_files": @json.to_json(repository.changed_files),
    "worktrees": @json.to_json(worktrees),
  }
}

///|
fn environment_to_json(environment : @environment.EnvironmentSnapshot) -> Json {
  {
    "package_managers": @json.to_json(environment.package_managers),
    "lockfiles": @json.to_json(environment.lockfiles),
    "dependency_markers": @json.to_json(environment.dependency_markers),
    "config_files": @json.to_json(environment.config_files),
  }
}

///|
fn build_error_to_json(error : @buildlog.BuildError) -> Json {
  {
    "file": error.file,
    "line": error.line,
    "column": error.column,
    "code": error.code,
    "message": error.message,
  }
}

///|
fn build_to_json(build : @buildlog.BuildObservation) -> Json {
  let errors : Array[Json] = []
  for error in build.errors {
    errors.push(build_error_to_json(error))
  }

  {
    "compiler": build.compiler,
    "status": build.status,
    "exit_code": build.exit_code,
    "errors": @json.to_json(errors),
  }
}

///|
fn tests_to_json(tests : @testlog.TestObservation) -> Json {
  {
    "runner": tests.runner,
    "status": tests.status,
    "failed_suites": tests.failed_suites,
    "failed_tests": tests.failed_tests,
    "assertion_failures": tests.assertion_failures,
  }
}

///|
fn diagnoses_to_json(diagnoses : Array[@diagnosis.Diagnosis]) -> Json {
  let items : Array[Json] = []
  for diagnosis in diagnoses {
    items.push(diagnosis_to_json(diagnosis))
  }
  @json.to_json(items)
}

///|
pub fn render_report_json(report : DiagnosticReport) -> String {
  let build : Json = match report.build {
    Some(observation) => build_to_json(observation)
    None => null
  }
  let tests : Json = match report.tests {
    Some(observation) => tests_to_json(observation)
    None => null
  }
  let value : Json = {
    "schema_version": "0.1",
    "tool_version": @app.version(),
    "summary": {
      "status": if report.diagnoses.length() == 0 {
        "no_diagnosis"
      } else {
        "problem_detected"
      },
    },
    "repository": repository_to_json(report.repository),
    "environment": environment_to_json(report.environment),
    "build": build,
    "tests": tests,
    "diagnoses": diagnoses_to_json(report.diagnoses),
  }
  value.stringify()
}

///|
fn list_text(values : Array[String]) -> String {
  if values.length() == 0 {
    "none"
  } else {
    values.join(", ")
  }
}

///|
pub fn render_report_text(report : DiagnosticReport) -> String {
  let mut output =
    "AgentTrace\n\nRepository\n  Root: \{report.repository.root}\n  Branch: \{report.repository.branch}\n  HEAD: \{report.repository.head}\n  Dirty: \{report.repository.is_dirty}\n  Changed files: \{report.repository.changed_files.length()}\n  Worktrees: \{report.repository.worktrees.length()}\n"

  output = output +
    "\nEnvironment\n  Package managers: \{list_text(report.environment.package_managers)}\n  Lockfiles: \{list_text(report.environment.lockfiles)}\n  Dependency markers: \{list_text(report.environment.dependency_markers)}\n"

  match report.build {
    Some(build) => {
      output = output +
        "\nBuild\n  Compiler: \{build.compiler}\n  Status: \{build.status}\n  Exit code: \{build.exit_code}\n  Source errors: \{build.errors.length()}\n"
    }
    None => ()
  }

  match report.tests {
    Some(tests) => {
      output = output +
        "\nTests\n  Runner: \{tests.runner}\n  Status: \{tests.status}\n  Failed suites: \{tests.failed_suites}\n  Failed tests: \{tests.failed_tests}\n"
    }
    None => ()
  }

  output = output + "\nDiagnoses\n"
  if report.diagnoses.length() == 0 {
    output = output + "  - none\n"
  } else {
    for diagnosis in report.diagnoses {
      output = output +
        "  - \{diagnosis.category} (\{diagnosis.confidence}, \{diagnosis.rule_ids.join(", ")})\n"
    }
  }

  output
}
