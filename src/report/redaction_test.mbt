///|
test "redact Linux home path" {
  assert_eq(
    @report.redact_path("/home/alice/projects/agenttrace"),
    "$HOME/projects/agenttrace",
  )
  assert_eq(@report.redact_path("/home/alice"), "$HOME")
}

///|
test "redact macOS home path" {
  assert_eq(
    @report.redact_path("/Users/alice/work/repo"),
    "$HOME/work/repo",
  )
}

///|
test "redact Windows home path with either separator" {
  assert_eq(
    @report.redact_path("C:\\Users\\Alice\\work\\repo"),
    "$HOME/work/repo",
  )
  assert_eq(
    @report.redact_path("D:/Users/Alice/work/repo"),
    "$HOME/work/repo",
  )
}

///|
test "do not redact non-home or shared profile paths" {
  assert_eq(@report.redact_path("/srv/build/agenttrace"), "/srv/build/agenttrace")
  assert_eq(
    @report.redact_path("C:\\Users\\Public\\repo"),
    "C:\\Users\\Public\\repo",
  )
  assert_eq(@report.redact_path("$HOME/work/repo"), "$HOME/work/repo")
}
