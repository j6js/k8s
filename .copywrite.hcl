schema_version = 1

project {
  license          = "BUSL-1.1"
  copyright_year   = 2026
  copyright_holder = "Jackson Kelly"
  ignore_year1     = true

  # (OPTIONAL) A list of globs that should not have copyright/license headers.
  # Supports doublestar glob patterns for more flexibility in defining which
  # files or folders should be ignored
  header_ignore = [
    "**/*.yaml",
    "infra/shared/outputs/**"
  ]
}