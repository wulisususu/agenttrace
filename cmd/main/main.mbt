///|
extern "C" fn exit(code : Int) = "exit"

///|
async fn main {
  @async.pause()
  let argv = @env.args()
  let result = @cli.run(argv[1:])

  if result.stdout != "" {
    @stdio.stdout.write(result.stdout)
  }
  if result.stderr != "" {
    @stdio.stderr.write(result.stderr)
  }

  exit(result.exit_code)
}
