///|
test "parse analyze-log with Windows path and JSON format" {
  let request = @cli.parse_cli([
    "analyze-log",
    "C:\\Users\\User Name\\logs\\vitest.txt",
    "--format",
    "json",
  ])

  assert_eq(request.command, "analyze-log")
  assert_eq(request.input, "C:\\Users\\User Name\\logs\\vitest.txt")
  assert_eq(request.format, "json")
  assert_eq(request.error, "")
}

///|
test "parse inspect with build and test context" {
  let request = @cli.parse_cli([
    "inspect",
    "C:\\Users\\User Name\\project",
    "--log",
    "C:\\logs\\vitest.txt",
    "--build-log",
    "C:\\logs\\tsc.txt",
    "--build-exit-code",
    "2",
    "--format",
    "json",
  ])

  assert_eq(request.command, "inspect")
  assert_eq(request.input, "C:\\Users\\User Name\\project")
  assert_eq(request.log, "C:\\logs\\vitest.txt")
  assert_eq(request.build_log, "C:\\logs\\tsc.txt")
  assert_eq(request.build_exit_code, 2)
  assert_eq(request.format, "json")
  assert_eq(request.error, "")
}

///|
test "reject build log without explicit exit code" {
  let request = @cli.parse_cli([
    "inspect",
    ".",
    "--build-log",
    "build.txt",
  ])

  assert_true(request.error.contains("--build-log requires --build-exit-code"))
}

///|
test "reject invalid build exit code" {
  let request = @cli.parse_cli([
    "inspect",
    ".",
    "--build-exit-code",
    "failed",
  ])

  assert_true(request.error.contains("non-negative integer"))
}

///|
test "reject invalid output format" {
  let request = @cli.parse_cli([
    "analyze-log",
    "test.log",
    "--format",
    "xml",
  ])

  assert_true(request.error != "")
}

///|
test "no arguments shows help" {
  let request = @cli.parse_cli([])

  assert_eq(request.command, "help")
  assert_eq(request.error, "")
}

///|
async test "analyze-log diagnoses explicit assertion fixture" {
  @async.pause()
  let result = @cli.run([
    "analyze-log",
    "fixtures/logs/vitest-assertion-failure.txt",
    "--format",
    "json",
  ])

  assert_eq(result.exit_code, 1)
  assert_eq(result.stderr, "")
  assert_true(result.stdout.contains("\"category\":\"test_assertion_failure\""))
  assert_true(result.stdout.contains("\"rule_ids\":[\"R003\"]"))
}

///|
async test "analyze-log does not invent compile-pass evidence for matcher failure" {
  @async.pause()
  let result = @cli.run([
    "analyze-log",
    "fixtures/logs/vitest-missing-matcher.txt",
  ])

  assert_eq(result.exit_code, 0)
  assert_true(result.stdout.contains("Category: unknown"))
}

///|
async test "analyze-log returns input error for missing file" {
  @async.pause()
  let result = @cli.run([
    "analyze-log",
    "fixtures/logs/does-not-exist.txt",
  ])

  assert_eq(result.exit_code, 3)
  assert_eq(result.stdout, "")
  assert_true(result.stderr.contains("unable to read input log"))
}

///|
async test "inspect current repository as JSON" {
  @async.pause()
  let result = @cli.run(["inspect", ".", "--format", "json"])

  assert_eq(result.exit_code, 0)
  assert_eq(result.stderr, "")
  assert_true(result.stdout.contains("\"repository\":"))
  assert_true(result.stdout.contains("\"environment\":"))
  assert_true(result.stdout.contains("\"build\":null"))
  assert_true(result.stdout.contains("\"diagnoses\":[]"))
}

///|
async test "inspect correlates compile pass with repeated matcher failures" {
  @async.pause()
  let result = @cli.run([
    "inspect",
    ".",
    "--log",
    "fixtures/logs/vitest-missing-matcher.txt",
    "--build-exit-code",
    "0",
    "--format",
    "json",
  ])

  assert_eq(result.exit_code, 1)
  assert_true(result.stdout.contains("\"build\":{\"compiler\":\"tsc\""))
  assert_true(result.stdout.contains("\"category\":\"dependency_environment_error\""))
  assert_true(result.stdout.contains("\"rule_ids\":[\"R001\"]"))
}

///|
async test "inspect diagnoses source-located TypeScript compile errors" {
  @async.pause()
  let result = @cli.run([
    "inspect",
    ".",
    "--build-log",
    "fixtures/logs/tsc-type-error.txt",
    "--build-exit-code",
    "2",
    "--format",
    "json",
  ])

  assert_eq(result.exit_code, 1)
  assert_true(result.stdout.contains("\"category\":\"build_compile_error\""))
  assert_true(result.stdout.contains("\"rule_ids\":[\"R002\"]"))
  assert_true(result.stdout.contains("\"code\":\"TS2322\""))
}

///|
async test "inspect can include assertion test observations and diagnoses" {
  @async.pause()
  let result = @cli.run([
    "inspect",
    ".",
    "--log",
    "fixtures/logs/vitest-assertion-failure.txt",
    "--format",
    "json",
  ])

  assert_eq(result.exit_code, 1)
  assert_true(result.stdout.contains("\"tests\":"))
  assert_true(result.stdout.contains("\"category\":\"test_assertion_failure\""))
}

///|
async test "inspect returns input error for an inaccessible repository path" {
  @async.pause()
  let result = @cli.run([
    "inspect",
    "fixtures/repository/does-not-exist",
  ])

  assert_eq(result.exit_code, 3)
  assert_true(result.stderr.contains("unable to inspect Git repository"))
}
