-- LazyVim Java extra: jdtls (via Mason), breadcrumbs, test runner,
-- in/outlays, and debug support. Needs a JDK >= 21 on PATH — provided by
-- `mise use -g java@lts` from install-ubuntu.sh.
return {
  { import = "lazyvim.plugins.extras.lang.java" },
}
