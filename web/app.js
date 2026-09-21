const CASES = {
  dependency: {
    dataUrl: "./data/dependency-environment.json",
    title: "依赖 / 测试环境故障",
    summary:
      "编译已经通过，但大量测试以同一种方式失败。现有证据更支持先检查测试依赖或测试环境，而不是直接回滚源码。",
    reproduce: [
      "moon run cmd/main inspect . \\",
      "  --log fixtures/logs/vitest-missing-matcher.txt \\",
      "  --build-exit-code 0 \\",
      "  --format json",
    ].join("\n"),
  },
  branch: {
    dataUrl: "./data/unexpected-branch.json",
    title: "当前分支与任务预期不一致",
    summary:
      "仓库本身可以正常读取，但当前分支不符合调用方显式声明的任务预期。继续验收前，应先确认当前 Worktree 和分支是否就是本次任务的执行现场。",
    reproduce: [
      "moon run cmd/main inspect . \\",
      "  --expected-branch __agenttrace_expected_branch__ \\",
      "  --format json",
    ].join("\n"),
  },
  compile: {
    dataUrl: "./data/source-compile-error.json",
    title: "源码编译错误",
    summary:
      "编译器以非零状态退出，并给出了明确的 TypeScript 源码位置。此时应优先检查源码类型或语法问题，而不是先修改依赖环境。",
    reproduce: [
      "moon run cmd/main inspect . \\",
      "  --build-log fixtures/logs/tsc-type-error.txt \\",
      "  --build-exit-code 2 \\",
      "  --format json",
    ].join("\n"),
  },
};

const TEXT = {
  severity: {
    error: "错误",
    warning: "警告",
    info: "信息",
    blocking: "阻塞",
  },
  confidence: {
    high: "高",
    medium: "中",
    low: "低",
  },
  status: {
    pass: "通过",
    fail: "失败",
    unknown: "未知",
  },
  boolean: {
    true: "是",
    false: "否",
  },
  kind: {
    compile_result: "构建结果",
    repeated_error_signature: "重复错误签名",
    branch_mismatch: "分支不匹配",
    dirty_worktree: "工作区未清理",
    compiler_exit: "编译器退出状态",
    source_location: "源码定位",
    test_summary: "测试摘要",
    assertion_failure: "断言失败",
    package_manager_signal: "包管理器信号",
    lockfile_set: "锁文件集合",
  },
  source: {
    build: "构建",
    buildlog: "构建日志",
    testlog: "测试日志",
    repository: "仓库",
    environment: "环境",
  },
  evidence: {
    "Compilation succeeds while tests fail": "编译通过，但测试阶段失败",
    "Multiple test suites share the same missing matcher error":
      "多个测试文件出现了相同的 matcher 缺失错误",
    "Current worktree branch does not match the explicitly expected branch":
      "当前 Worktree 分支与显式声明的预期分支不一致",
    "Working tree contains changes while a clean worktree was explicitly required":
      "调用方明确要求干净工作区，但当前工作区存在未提交修改",
    "TypeScript compiler exited with a non-zero status":
      "TypeScript 编译器以非零状态退出",
    "Compiler reported at least one source-located TypeScript error":
      "编译器报告了至少一个能够定位到源码位置的 TypeScript 错误",
  },
  actions: {
    "verify installed test dependencies": "核对测试依赖是否已正确安装",
    "verify test setup loading": "确认测试初始化 / setup 文件是否被正确加载",
    "rerun the affected test suite before reverting source changes":
      "在回滚源码前，先重新运行受影响的测试集",
    "verify that the current worktree is the intended execution target":
      "确认当前 Worktree 是否就是本次任务应该执行的工作目录",
    "compare the current branch and HEAD with the expected task context":
      "对比当前分支、HEAD 与任务预期上下文",
    "review local changes before switching branches or cleaning the worktree":
      "切换分支或清理工作区前，先检查本地未提交修改",
    "inspect the first source-located compiler error":
      "优先检查第一个带有源码位置的编译错误",
    "rerun the compiler after a targeted source fix":
      "完成针对性源码修复后重新运行编译器",
    "avoid changing dependency state unless compiler evidence points there":
      "除非编译证据明确指向依赖，否则不要先修改依赖状态",
  },
};

const byId = (id) => document.getElementById(id);

function setText(id, value) {
  byId(id).textContent = value ?? "—";
}

function shortHead(value) {
  if (!value) return "—";
  return value.length > 12 ? value.slice(0, 12) : value;
}

function translate(map, value, fallback = value) {
  if (value === undefined || value === null || value === "") return "—";
  return map[value] ?? fallback;
}

function renderEvidence(items) {
  const list = byId("evidence-list");
  list.replaceChildren();

  items.forEach((evidence, index) => {
    const item = document.createElement("li");
    item.className = "evidence-item";

    const marker = document.createElement("span");
    marker.className = "evidence-index";
    marker.textContent = String(index + 1).padStart(2, "0");

    const body = document.createElement("div");
    const title = document.createElement("strong");
    title.textContent = translate(TEXT.evidence, evidence.message);
    const meta = document.createElement("p");
    meta.textContent =
      `${translate(TEXT.kind, evidence.kind)} · 来源：${translate(TEXT.source, evidence.source)}`;

    body.append(title, meta);
    item.append(marker, body);
    list.append(item);
  });

  setText("evidence-count", `${items.length} 条证据`);
}

function renderActions(items) {
  const list = byId("suggested-checks");
  list.replaceChildren();

  items.forEach((action) => {
    const item = document.createElement("li");
    item.textContent = translate(TEXT.actions, action);
    list.append(item);
  });
}

function renderReport(data, meta) {
  const diagnosis = data.diagnoses?.[0];
  if (!diagnosis) throw new Error("可视化报告至少需要一条诊断结果");

  setText("diagnosis-title", meta.title);
  setText("diagnosis-summary", meta.summary);
  setText("severity", translate(TEXT.severity, diagnosis.severity));
  setText("confidence", translate(TEXT.confidence, diagnosis.confidence));
  setText("rule-ids", diagnosis.rule_ids?.join(", ") || "—");

  setText(
    "build-status",
    data.build ? translate(TEXT.status, data.build.status) : "未提供",
  );
  setText("build-compiler", data.build?.compiler);
  setText("build-exit", data.build?.exit_code);

  setText(
    "test-status",
    data.tests ? translate(TEXT.status, data.tests.status) : "未提供",
  );
  setText("failed-suites", data.tests?.failed_suites);
  setText("failed-tests", data.tests?.failed_tests);

  setText("repo-branch", data.repository?.branch);
  setText("repo-head", shortHead(data.repository?.head));
  setText(
    "repo-dirty",
    translate(TEXT.boolean, String(Boolean(data.repository?.is_dirty))),
  );

  renderEvidence(diagnosis.evidence || []);
  renderActions(diagnosis.suggested_checks || []);

  setText("schema-version", `schema ${data.schema_version || "—"}`);
  setText("reproduce-command", meta.reproduce);

  byId("error-state").hidden = true;
  byId("report").hidden = false;
}

function setActiveCase(caseId) {
  document.querySelectorAll("[data-case]").forEach((button) => {
    const active = button.dataset.case === caseId;
    button.classList.toggle("is-active", active);
    button.setAttribute("aria-pressed", String(active));
  });
}

async function loadCase(caseId, updateUrl = true) {
  const resolvedId = CASES[caseId] ? caseId : "dependency";
  const meta = CASES[resolvedId];

  setActiveCase(resolvedId);
  setText("diagnosis-title", "正在载入诊断结果…");
  setText(
    "diagnosis-summary",
    "正在读取 AgentTrace 生成的结构化诊断结果。",
  );
  byId("report").hidden = true;
  byId("error-state").hidden = true;

  if (updateUrl) {
    const url = new URL(window.location.href);
    url.searchParams.set("case", resolvedId);
    history.replaceState({}, "", url);
  }

  try {
    const response = await fetch(meta.dataUrl, { cache: "no-store" });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    renderReport(data, meta);
  } catch (error) {
    console.error(error);
    setText("diagnosis-title", "可视化报告数据不完整");
    setText(
      "diagnosis-summary",
      "页面本身已经载入，但由 CLI 生成的诊断 JSON 缺失或无法解析。",
    );
    byId("error-state").hidden = false;
  }
}

function main() {
  document.querySelectorAll("[data-case]").forEach((button) => {
    button.addEventListener("click", () => loadCase(button.dataset.case));
  });

  const requested = new URLSearchParams(window.location.search).get("case");
  loadCase(requested || "dependency", false);
}

main();
