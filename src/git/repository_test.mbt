///|
test "parse porcelain v2 status without losing spaces or Unicode" {
  let status =
    "1 .M N... 100644 100644 100644 aaaaaaa bbbbbbb src/file with spaces.ts\u0000" +
    "2 R. N... 100644 100644 100644 aaaaaaa bbbbbbb R100 src/new name.ts\u0000" +
    "src/old name.ts\u0000" +
    "? 设计/测试.ts\u0000" +
    "! ignored.txt\u0000"
  let snapshot = @git.parse_status_v2_z(status)

  assert_true(snapshot.is_dirty)
  assert_eq(snapshot.changed_files.length(), 3)
  assert_eq(snapshot.changed_files[0], "src/file with spaces.ts")
  assert_eq(snapshot.changed_files[1], "src/new name.ts")
  assert_eq(snapshot.changed_files[2], "设计/测试.ts")
}

///|
test "empty porcelain status is clean" {
  let snapshot = @git.parse_status_v2_z("")

  assert_false(snapshot.is_dirty)
  assert_eq(snapshot.changed_files.length(), 0)
}

///|
test "parse worktree porcelain with Windows paths and CRLF" {
  let output =
    "worktree C:/Users/User Name/project\r\n" +
    "HEAD aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\r\n" +
    "branch refs/heads/main\r\n" +
    "\r\n" +
    "worktree D:/开发/agent-worktree\r\n" +
    "HEAD bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\r\n" +
    "detached\r\n" +
    "prunable gitdir file points to non-existent location\r\n"
  let worktrees = @git.parse_worktree_porcelain(output)

  assert_eq(worktrees.length(), 2)
  assert_eq(worktrees[0].path, "C:/Users/User Name/project")
  assert_eq(worktrees[0].branch, "main")
  assert_false(worktrees[0].detached)
  assert_eq(worktrees[1].path, "D:/开发/agent-worktree")
  assert_true(worktrees[1].detached)
  assert_true(worktrees[1].prunable)
}

///|
async test "collect the current checkout as a real repository" {
  @async.pause()
  let snapshot = @git.collect_repository(".")

  assert_true(snapshot.root != "")
  assert_true(snapshot.head != "")
  assert_true(snapshot.worktrees.length() >= 1)
}
