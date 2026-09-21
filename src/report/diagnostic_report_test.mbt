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
    tests: None,
    diagnoses: [],
  }
  let actual = @report.render_report_json(report)

  assert_true(@json.valid(actual))
  assert_true(actual.contains("\"repository\":"))
  assert_true(actual.contains("\"branch\":\"main\""))
  assert_true(actual.contains("\"package_managers\":[\"pnpm\"]"))
  assert_true(actual.contains("\"tests\":null"))
  assert_true(actual.contains("\"status\":\"no_diagnosis\""))
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
    tests: None,
    diagnoses: [],
  }
  let actual = @report.render_report_text(report)

  assert_true(actual.contains("Branch: feat/demo"))
  assert_true(actual.contains("Dirty: true"))
  assert_true(actual.contains("Package managers: yarn"))
  assert_true(actual.contains("Diagnoses\n  - none"))
}
