///|
pub(all) struct StatusSnapshot {
  is_dirty : Bool
  changed_files : Array[String]
}

///|
pub(all) struct WorktreeSnapshot {
  path : String
  head : String
  branch : String
  detached : Bool
  bare : Bool
  prunable : Bool
}

///|
pub(all) struct RepositorySnapshot {
  root : String
  branch : String
  head : String
  is_dirty : Bool
  changed_files : Array[String]
  worktrees : Array[WorktreeSnapshot]
}

///|
fn fields(line : String) -> Array[String] {
  line.split(" ").map(fn(part) { part.to_owned() }).collect()
}

///|
fn join_tail(parts : Array[String], start : Int) -> String {
  if start >= parts.length() {
    ""
  } else {
    parts[start:].join(" ")
  }
}

///|
fn clean_line(line : StringView) -> String {
  let text = line.to_owned()
  if text.has_suffix("\r") {
    text[:text.length() - 1].to_owned()
  } else {
    text
  }
}

///|
fn first_line(output : String) -> String {
  let lines = output.split("\n").collect()
  if lines.length() == 0 {
    ""
  } else {
    clean_line(lines[0])
  }
}

///|
pub fn parse_status_v2_z(status : String) -> StatusSnapshot {
  let changed_files : Array[String] = []
  let records = status.split("\u0000").collect()
  let mut index = 0

  while index < records.length() {
    let record = records[index].to_owned()
    let parts = fields(record)
    let mut step = 1

    if parts.length() > 0 {
      let kind = parts[0]
      if kind == "1" {
        let path = join_tail(parts, 8)
        if path != "" {
          changed_files.push(path)
        }
      } else if kind == "2" {
        let path = join_tail(parts, 9)
        if path != "" {
          changed_files.push(path)
        }
        // Porcelain v2 -z stores the original rename/copy path in the
        // following NUL-delimited record. It is evidence, not another change.
        step = 2
      } else if kind == "u" {
        let path = join_tail(parts, 10)
        if path != "" {
          changed_files.push(path)
        }
      } else if kind == "?" {
        let path = join_tail(parts, 1)
        if path != "" {
          changed_files.push(path)
        }
      }
    }

    index = index + step
  }

  { is_dirty: changed_files.length() > 0, changed_files }
}

///|
fn branch_name(refname : String) -> String {
  let prefix = "refs/heads/"
  if refname.has_prefix(prefix) {
    refname[prefix.length():].to_owned()
  } else {
    refname
  }
}

///|
pub fn parse_worktree_porcelain(output : String) -> Array[WorktreeSnapshot] {
  let worktrees : Array[WorktreeSnapshot] = []
  let mut path = ""
  let mut head = ""
  let mut branch = ""
  let mut detached = false
  let mut bare = false
  let mut prunable = false

  for raw_line in output.split("\n") {
    let line = clean_line(raw_line)

    if line.has_prefix("worktree ") {
      if path != "" {
        worktrees.push({ path, head, branch, detached, bare, prunable })
      }
      path = join_tail(fields(line), 1)
      head = ""
      branch = ""
      detached = false
      bare = false
      prunable = false
    } else if line.has_prefix("HEAD ") {
      head = join_tail(fields(line), 1)
    } else if line.has_prefix("branch ") {
      branch = branch_name(join_tail(fields(line), 1))
    } else if line == "detached" {
      detached = true
    } else if line == "bare" {
      bare = true
    } else if line.has_prefix("prunable") {
      prunable = true
    }
  }

  if path != "" {
    worktrees.push({ path, head, branch, detached, bare, prunable })
  }

  worktrees
}

///|
async fn git_stdout(path : String, args : Array[String]) -> String {
  let command_args : Array[String] = ["-C", path]
  for arg in args {
    command_args.push(arg)
  }

  let (exit_code, output) = @process.collect_stdout("git", command_args)
  if exit_code != 0 {
    fail("git command failed with exit code \{exit_code}")
  }
  output.text()
}

///|
pub async fn collect_repository(path : String) -> RepositorySnapshot {
  let root = first_line(git_stdout(path, ["rev-parse", "--show-toplevel"]))
  let head = first_line(git_stdout(path, ["rev-parse", "HEAD"]))
  let branch = first_line(git_stdout(path, ["branch", "--show-current"]))
  let status = parse_status_v2_z(
    git_stdout(
      path,
      [
        "-c",
        "core.quotepath=false",
        "status",
        "--porcelain=v2",
        "-z",
        "--untracked-files=normal",
      ],
    ),
  )
  let worktrees = parse_worktree_porcelain(
    git_stdout(
      path,
      ["-c", "core.quotepath=false", "worktree", "list", "--porcelain"],
    ),
  )

  {
    root,
    branch,
    head,
    is_dirty: status.is_dirty,
    changed_files: status.changed_files,
    worktrees,
  }
}
