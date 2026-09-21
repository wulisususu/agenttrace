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
