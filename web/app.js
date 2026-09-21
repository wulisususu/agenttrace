const CASES = {
  dependency: {
    dataUrl: "./data/dependency-environment.json",
    kicker: "测试突然全红，但编译其实通过了",
    title: "先别回滚代码，先检查测试环境",
    summary:
      "27 个测试文件、155 个测试一起失败，看起来像“代码全坏了”。但编译层是正常的，而且失败原因高度重复。",
    verdict: "更可能是测试环境 / 依赖问题",
    verdictNote: "现在直接改源码，很可能是在修错东西。",
    actionTitle: "先验证环境，再决定要不要碰代码",
    story: [
      ["表面现象", "大量测试同时失败"],
      ["AgentTrace 交叉检查", "编译通过，错误高度重复"],
      ["最终判断", "优先检查测试依赖 / setup"],
    ],
    actions: [
      "确认测试依赖有没有正确安装",
      "确认测试 setup / 初始化文件是否被正确加载",
      "环境验证后再重跑测试，最后才考虑回滚源码",
    ],
    without:
      "看到 155 个测试失败 → AI 继续改代码 → 仍然失败 → 继续改。",
    with:
      "先检查构建与重复错误 → 发现代码未必有问题 → 把排查方向切到环境。",
    technicalTitle: "dependency_environment_error",
    reproduce: [
      "moon run cmd/main inspect . \\",
      "  --log fixtures/logs/vitest-missing-matcher.txt \\",
      "  --build-exit-code 0 \\",
      "  --format json",
    ].join("\n"),
  },
  branch: {
    dataUrl: "./data/unexpected-branch.json",
    kicker: "AI 验收结果和你预期的不一样",
    title: "先确认 AI 是不是在正确的分支上验收",
    summary:
      "代码仓库本身能正常读取，但当前分支和任务明确要求的分支不一致。继续跑测试之前，应该先确认当前工作目录是不是本次任务真正的执行现场。",
    verdict: "先别继续验收，当前开发现场不可信",
    verdictNote: "问题可能不是代码，而是 AI 在错误的分支 / Worktree 上检查结果。",
    actionTitle: "先把“在哪儿验收”确认清楚",
    story: [
      ["任务预期", "应该在指定任务分支验收"],
      ["AgentTrace 发现", "当前实际分支与预期不一致"],
      ["最终判断", "先确认 Worktree / 分支，再继续测试"],
    ],
    actions: [
      "确认当前 Worktree 是否就是本次任务的工作目录",
      "对比当前分支、HEAD 和任务预期",
      "确认现场正确以后，再继续跑测试或让 AI 修改代码",
    ],
    without:
      "验收不对 → 以为代码有问题 → AI 在错误分支继续改 → 结果越来越乱。",
    with:
      "先核对分支和工作目录 → 发现执行现场不对 → 切回正确现场再验收。",
    technicalTitle: "worktree_state_error",
    reproduce: [
      "moon run cmd/main inspect . \\",
      "  --expected-branch __agenttrace_expected_branch__ \\",
      "  --format json",
    ].join("\n"),
  },
  compile: {
    dataUrl: "./data/source-compile-error.json",
    kicker: "这次编译器直接指出了源码位置",
    title: "这次真的更像是代码写错了",
    summary:
      "编译器非零退出，而且给出了明确的 TypeScript 源码位置和错误码。现有证据已经足够把排查重点放回源码，而不是先折腾依赖环境。",
    verdict: "优先修源码，再重新编译",
    verdictNote: "这是 AgentTrace 用来和“环境故障”做区分的另一类结果。",
    actionTitle: "从第一个明确的源码错误开始",
    story: [
      ["编译结果", "编译器直接失败"],
      ["AgentTrace 发现", "存在明确源码位置与 TS2322"],
      ["最终判断", "优先处理源码类型 / 语法问题"],
    ],
    actions: [
      "先看第一个带源码位置的编译错误",
      "只做针对性的源码修复",
      "重新编译；没有证据时不要先改依赖环境",
    ],
    without:
      "看到项目失败 → 不知道是代码还是环境 → 依赖、配置、源码一起乱改。",
    with:
      "编译器证据明确指向源码 → 把排查范围缩小 → 先修真正相关的代码。",
    technicalTitle: "build_compile_error",
    reproduce: [
      "moon run cmd/main inspect . \\",
      "  --build-log fixtures/logs/tsc-type-error.txt \\",
      "  --build-exit-code 2 \\",
      "  --format json",
    ].join("\n"),
  },
};

const TEXT = {
  severity: { error: "错误", warning: "警告", info: "信息", blocking: "阻塞" },
  confidence: { high: "高", medium: "中", low: "低" },
  status: { pass: "通过", fail: "失败", unknown: "未知" },
  boolean: { true: "是", false: "否" },
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
  const node = byId(id);
  if (node) node.textContent = value ?? "—";
}

function translate(map, value, fallback = value) {
  if (value === undefined || value === null || value === "") return "—";
  return map[value] ?? fallback;
}

function shortHead(value) {
  if (!value) return "—";
  return value.length > 12 ? value.slice(0, 12) : value;
}

function renderStory(items) {
  const root = byId("story-flow");
  root.replaceChildren();

  items.forEach(([label, value], index) => {
    const item = document.createElement("div");
    item.className = "story-step";

    const number = document.createElement("span");
    number.className = "story-number";
    number.textContent = String(index + 1);

    const body = document.createElement("div");
    const labelNode = document.createElement("small");
    labelNode.textContent = label;
    const valueNode = document.createElement("strong");
    valueNode.textContent = value;

    body.append(labelNode, valueNode);
    item.append(number, body);
    root.append(item);
  });
}

function renderPlainActions(items) {
  const list = byId("plain-actions");
  list.replaceChildren();

  items.forEach((text) => {
    const item = document.createElement("li");
    item.textContent = text;
    list.append(item);
  });
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

  setText("scenario-kicker", meta.kicker);
  setText("plain-title", meta.title);
  setText("plain-summary", meta.summary);
  setText("plain-verdict", meta.verdict);
  setText("plain-verdict-note", meta.verdictNote);
  setText("action-title", meta.actionTitle);
  setText("without-agenttrace", meta.without);
  setText("with-agenttrace", meta.with);
  renderStory(meta.story);
  renderPlainActions(meta.actions);

  setText("technical-title", meta.technicalTitle);
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
