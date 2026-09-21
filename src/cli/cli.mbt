///|
pub(all) struct CliRequest {
  command : String
  input : String
  format : String
  log : String
  build_log : String
  build_exit_code : Int
  expected_branch : String
  require_clean : Bool
  error : String
}

///|
pub(all) struct CliResult {
  stdout : String
  stderr : String
  exit_code : Int
}

///|
pub fn usage() -> String {
  let text =
    #|AgentTrace
    #|
    #|Usage:
    #|  agenttrace inspect <path> [--format text|json] [--log <file>] [--build-exit-code <n>] [--build-log <file>] [--expected-branch <name>] [--require-clean]
    #|  agenttrace analyze-log <file> [--format text|json]
    #|  agenttrace version
    #|  agenttrace --help
    #|
    #|Exit codes:
    #|  0  execution succeeded, no diagnosis produced
    #|  1  execution succeeded, a diagnosis was produced
    #|  2  invalid arguments
    #|  3  input could not be read
    #|  4  internal error
  text
}

///|
fn invalid(message : String) -> CliRequest {
  {
    command: "invalid",
    input: "",
    format: "text",
    log: "",
    build_log: "",
    build_exit_code: -1,
    expected_branch: "",
    require_clean: false,
    error: message,
  }
}

///|
fn parse_nonnegative_int(value : String) -> Int {
  let parsed = @string.from_str(value) catch {
    _ => -1
  }
  if parsed < 0 { -1 } else { parsed }
}

///|
fn parse_inspect(argv : ArrayView[String]) -> CliRequest {
  if argv.length() < 2 {
    return invalid("inspect requires a repository path")
  }

  let input = argv[1]
  let mut format = "text"
  let mut log = ""
  let mut build_log = ""
  let mut build_exit_code = -1
  let mut expected_branch = ""
  let mut require_clean = false
  let mut index = 2

  while index < argv.length() {
    if argv[index] == "--format" {
      if index + 1 >= argv.length() {
        return invalid("--format requires text or json")
      }
      let value = argv[index + 1]
      if value != "text" && value != "json" {
        return invalid("--format must be text or json")
      }
      format = value
      index = index + 2
    } else if argv[index] == "--log" {
      if index + 1 >= argv.length() {
        return invalid("--log requires a file path")
      }
      log = argv[index + 1]
      index = index + 2
    } else if argv[index] == "--build-log" {
      if index + 1 >= argv.length() {
        return invalid("--build-log requires a file path")
      }
      build_log = argv[index + 1]
      index = index + 2
    } else if argv[index] == "--build-exit-code" {
      if index + 1 >= argv.length() {
        return invalid("--build-exit-code requires a non-negative integer")
      }
      build_exit_code = parse_nonnegative_int(argv[index + 1])
      if build_exit_code < 0 {
        return invalid("--build-exit-code must be a non-negative integer")
      }
      index = index + 2
    } else if argv[index] == "--expected-branch" {
      if index + 1 >= argv.length() || argv[index + 1] == "" {
        return invalid("--expected-branch requires a branch name")
      }
      expected_branch = argv[index + 1]
      index = index + 2
    } else if argv[index] == "--require-clean" {
      require_clean = true
      index = index + 1
    } else {
      return invalid("unsupported inspect argument: \{argv[index]}")
    }
  }

  if build_log != "" && build_exit_code < 0 {
    return invalid("--build-log requires --build-exit-code")
  }

  {
    command: "inspect",
    input,
    format,
    log,
    build_log,
    build_exit_code,
    expected_branch,
    require_clean,
    error: "",
  }
}

///|
pub fn parse_cli(argv : ArrayView[String]) -> CliRequest {
  if argv.length() == 0 {
    return {
      command: "help",
      input: "",
      format: "text",
      log: "",
      build_log: "",
      build_exit_code: -1,
      expected_branch: "",
      require_clean: false,
      error: "",
    }
  }

  let command = argv[0]
  if command == "--help" || command == "-h" || command == "help" {
    if argv.length() == 1 {
      {
        command: "help",
        input: "",
        format: "text",
        log: "",
        build_log: "",
        build_exit_code: -1,
        expected_branch: "",
        require_clean: false,
        error: "",
      }
    } else {
      invalid("help does not accept positional arguments")
    }
  } else if command == "version" {
    if argv.length() == 1 {
      {
        command: "version",
        input: "",
        format: "text",
        log: "",
        build_log: "",
        build_exit_code: -1,
        expected_branch: "",
        require_clean: false,
        error: "",
      }
    } else {
      invalid("version does not accept additional arguments")
    }
  } else if command == "inspect" {
    parse_inspect(argv)
  } else if command == "analyze-log" {
    if argv.length() < 2 {
      return invalid("analyze-log requires a log file")
    }

    let input = argv[1]
    if argv.length() == 2 {
      return {
        command,
        input,
        format: "text",
        log: "",
        build_log: "",
        build_exit_code: -1,
        expected_branch: "",
        require_clean: false,
        error: "",
      }
    }

    if argv.length() == 4 && argv[2] == "--format" {
      let format = argv[3]
      if format == "text" || format == "json" {
        {
          command,
          input,
          format,
          log: "",
          build_log: "",
          build_exit_code: -1,
          expected_branch: "",
          require_clean: false,
          error: "",
        }
      } else {
        invalid("--format must be text or json")
      }
    } else {
      invalid("unsupported analyze-log arguments")
    }
  } else {
    invalid("unknown command: \{command}")
  }
}

///|
fn diagnosis_result(
  diagnosis : @core.Diagnosis,
  format : String,
) -> CliResult {
  let output = if format == "json" {
    @report.render_json(diagnosis)
  } else {
    @report.render_text(diagnosis)
  }
  {
    stdout: output + "\n",
    stderr: "",
    exit_code: if diagnosis.category == "unknown" { 0 } else { 1 },
  }
}

///|
async fn analyze_log(request : CliRequest) -> CliResult {
  let data = @fs.read_file(request.input) catch {
    _ =>
      return {
        stdout: "",
        stderr: "AgentTrace: unable to read input log\n",
        exit_code: 3,
      }
  }
  let observation = @testlog.parse_vitest(data.text())

  // analyze-log deliberately has no compile observation. R001 requires an
  // explicit successful compile signal, so this command must not invent one.
  let diagnosis = @diagnosis.diagnose_r003(observation)
  diagnosis_result(diagnosis, request.format)
}

///|
async fn inspect(request : CliRequest) -> CliResult {
  let repository = @git.collect_repository(request.input) catch {
    _ =>
      return {
        stdout: "",
        stderr: "AgentTrace: unable to inspect Git repository\n",
        exit_code: 3,
      }
  }
  let environment = @environment.collect_environment(repository.root) catch {
    _ =>
      return {
        stdout: "",
        stderr: "AgentTrace: unable to inspect project environment\n",
        exit_code: 3,
      }
  }

  let diagnoses : Array[@core.Diagnosis] = []

  let worktree_state = @diagnosis.diagnose_r004(
    repository,
    request.expected_branch,
    request.require_clean,
  )
  if worktree_state.category != "unknown" {
    diagnoses.push(worktree_state)
  }

  let package_manager = @diagnosis.diagnose_r005(environment)
  if package_manager.category != "unknown" {
    diagnoses.push(package_manager)
  }

  let mut build : @buildlog.BuildObservation? = None
  if request.build_exit_code >= 0 {
    let mut build_text = ""
    if request.build_log != "" {
      let data = @fs.read_file(request.build_log) catch {
        _ =>
          return {
            stdout: "",
            stderr: "AgentTrace: unable to read build log\n",
            exit_code: 3,
          }
      }
      build_text = data.text()
    }

    let observation = @buildlog.parse_tsc(build_text, request.build_exit_code)
    build = Some(observation)
    let compile_failure = @diagnosis.diagnose_r002(observation)
    if compile_failure.category != "unknown" {
      diagnoses.push(compile_failure)
    }
  }

  let mut tests : @testlog.TestObservation? = None
  if request.log != "" {
    let data = @fs.read_file(request.log) catch {
      _ =>
        return {
          stdout: "",
          stderr: "AgentTrace: unable to read input log\n",
          exit_code: 3,
        }
    }
    let observation = @testlog.parse_vitest(data.text())
    tests = Some(observation)

    match build {
      Some(build_observation) => {
        let environment_failure = @diagnosis.diagnose_r001(
          build_observation.status == "pass",
          observation,
        )
        if environment_failure.category != "unknown" {
          diagnoses.push(environment_failure)
        }
      }
      None => ()
    }

    let assertion = @diagnosis.diagnose_r003(observation)
    if assertion.category != "unknown" {
      diagnoses.push(assertion)
    }
  }

  let report : @report.DiagnosticReport = {
    repository,
    environment,
    build,
    tests,
    diagnoses,
  }
  let output = if request.format == "json" {
    @report.render_report_json(report)
  } else {
    @report.render_report_text(report)
  }

  {
    stdout: output + "\n",
    stderr: "",
    exit_code: if diagnoses.length() == 0 { 0 } else { 1 },
  }
}

///|
pub async fn run(argv : ArrayView[String]) -> CliResult {
  let request = parse_cli(argv)

  if request.error != "" {
    return {
      stdout: "",
      stderr: "AgentTrace: \{request.error}\n\n\{usage()}\n",
      exit_code: 2,
    }
  }

  if request.command == "help" {
    { stdout: usage() + "\n", stderr: "", exit_code: 0 }
  } else if request.command == "version" {
    { stdout: @app.banner() + "\n", stderr: "", exit_code: 0 }
  } else if request.command == "inspect" {
    inspect(request)
  } else if request.command == "analyze-log" {
    analyze_log(request)
  } else {
    {
      stdout: "",
      stderr: "AgentTrace: internal command dispatch error\n",
      exit_code: 4,
    }
  }
}
