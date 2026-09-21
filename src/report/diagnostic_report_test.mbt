///|
test "render aggregate diagnostic report as JSON" {
  let repository : @git.RepositorySnapshot = {
    root: "C:/repo",
    branch: "main",
    head: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    is_dirty: false,
    changed_files: [],
    worktrees: [],
  }
  let environment = @environment.detect_environment_from_names([
    "package.json",
    "pnpm-lock.yaml",
    "node_modules",
  ])
  let report : @report.DiagnosticReport = {
    repository,
    environment,
    build: None,
    tests: None,
    diagnoses: [],
  }
  let actual = @report.render_report_json(report)

  assert_true(@json.valid(actual))
  assert_true(actual.contains("\"repository\":"))
  assert_true(actual.contains("\"branch\":\"main\""))
  assert_true(actual.contains("\"package_managers\":[\"pnpm\"]"))
  assert_true(actual.contains("\"build\":null"))
  assert_true(actual.contains("\"tests\":null"))
  assert_true(actual.contains("\"status\":\"no_diagnosis\""))
}

///|
test "aggregate report includes build observation" {
  let repository : @git.RepositorySnapshot = {
    root: "/repo",
    branch: "main",
    head: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    is_dirty: false,
    changed_files: [],
    worktrees: [],
  }
  let environment = @environment.detect_environment_from_names([])
  let build = @buildlog.parse_tsc("", 0)
  let report : @report.DiagnosticReport = {
    repository,
    environment,
    build: Some(build),
    tests: None,
    diagnoses: [],
  }
  let json = @report.render_report_json(report)
  let text = @report.render_report_text(report)

  assert_true(json.contains("\"build\":{\"compiler\":\"tsc\""))
  assert_true(json.contains("\"status\":\"pass\""))
  assert_true(text.contains("Build\n  Compiler: tsc"))
  assert_true(text.contains("Exit code: 0"))
}

///|
test "aggregate text report includes collected facts" {
  let repository : @git.RepositorySnapshot = {
    root: "/repo",
    branch: "feat/demo",
    head: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    is_dirty: true,
    changed_files: ["src/a.ts"],
    worktrees: [],
  }
  let environment = @environment.detect_environment_from_names([
    "package.json",
    "yarn.lock",
    ".pnp.cjs",
  ])
  let report : @report.DiagnosticReport = {
    repository,
    environment,
    build: None,
    tests: None,
    diagnoses: [],
  }
  let actual = @report.render_report_text(report)

  assert_true(actual.contains("Branch: feat/demo"))
  assert_true(actual.contains("Dirty: true"))
  assert_true(actual.contains("Package managers: yarn"))
  assert_true(actual.contains("Diagnoses\n  - none"))
}

///|
test "aggregate reporters redact home paths without mutating snapshots" {
  let repository : @git.RepositorySnapshot = {
    root: "C:\\Users\\Alice\\work\\repo",
    branch: "main",
    head: "cccccccccccccccccccccccccccccccccccccccc",
    is_dirty: false,
    changed_files: [],
    worktrees: [
      {
        path: "C:\\Users\\Alice\\work\\repo",
        head: "cccccccccccccccccccccccccccccccccccccccc",
        branch: "main",
        detached: false,
        bare: false,
        prunable: false,
      },
    ],
  }
  let environment = @environment.detect_environment_from_names([])
  let build = @buildlog.parse_tsc(
    "C:\\Users\\Alice\\work\\repo\\src\\main.ts(4,2): error TS2322: mismatch",
    2,
  )
  let report : @report.DiagnosticReport = {
    repository,
    environment,
    build: Some(build),
    tests: None,
    diagnoses: [],
  }

  let json = @report.render_report_json(report)
  let text = @report.render_report_text(report)

  assert_true(json.contains("\"root\":\"$HOME/work/repo\""))
  assert_true(json.contains("\"path\":\"$HOME/work/repo\""))
  assert_true(json.contains("\"file\":\"$HOME/work/repo/src/main.ts\""))
  assert_true(!json.contains("Alice"))
  assert_true(text.contains("Root: $HOME/work/repo"))
  assert_true(!text.contains("Alice"))

  // Reporting is a view concern; evidence collection remains unchanged.
  assert_eq(repository.root, "C:\\Users\\Alice\\work\\repo")
}
