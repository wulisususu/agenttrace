///|
pub(all) struct CliRequest {
  command : String
  input : String
  format : String
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
  #|AgentTrace
  #|
  #|Usage:
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
}

///|
fn invalid(message : String) -> CliRequest {
  { command: "invalid", input: "", format: "text", error: message }
}

///|
pub fn parse_cli(argv : ArrayView[String]) -> CliRequest {
  if argv.length() == 0 {
    return { command: "help", input: "", format: "text", error: "" }
  }

  let command = argv[0]
  if command == "--help" || command == "-h" || command == "help" {
    if argv.length() == 1 {
      { command: "help", input: "", format: "text", error: "" }
    } else {
      invalid("help does not accept positional arguments")
    }
  } else if command == "version" {
    if argv.length() == 1 {
      { command: "version", input: "", format: "text", error: "" }
    } else {
      invalid("version does not accept additional arguments")
    }
  } else if command == "analyze-log" {
    if argv.length() < 2 {
      return invalid("analyze-log requires a log file")
    }

    let input = argv[1]
    if argv.length() == 2 {
      return { command, input, format: "text", error: "" }
    }

    if argv.length() == 4 && argv[2] == "--format" {
      let format = argv[3]
      if format == "text" || format == "json" {
        { command, input, format, error: "" }
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
  diagnosis : @diagnosis.Diagnosis,
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
