///|
test "parse source-located TypeScript compiler errors" {
  let log =
    "C:/repo/src/main.ts(12,5): error TS2322: Type 'string' is not assignable to type 'number'.\r\n" +
    "src/config.ts(7,3): error TS2304: Cannot find name 'missingValue'.\r\n"
  let observation = @buildlog.parse_tsc(log, 2)

  assert_eq(observation.compiler, "tsc")
  assert_eq(observation.status, "fail")
  assert_eq(observation.exit_code, 2)
  assert_eq(observation.errors.length(), 2)
  assert_eq(observation.errors[0].file, "C:/repo/src/main.ts")
  assert_eq(observation.errors[0].line, 12)
  assert_eq(observation.errors[0].column, 5)
  assert_eq(observation.errors[0].code, "TS2322")
}

///|
test "successful tsc exit is a pass" {
  let observation = @buildlog.parse_tsc("", 0)

  assert_eq(observation.status, "pass")
  assert_eq(observation.errors.length(), 0)
}

///|
test "nonzero tsc exit without source-located errors stays a failed observation" {
  let observation = @buildlog.parse_tsc(
    "error TS5058: The specified path does not exist.",
    1,
  )

  assert_eq(observation.status, "fail")
  assert_eq(observation.errors.length(), 0)
}
