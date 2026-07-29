# Repository Instructions for Gemini CLI

This repository contains **altdoc**, an R package for building package documentation websites with Quarto, Docsify, Docute, or MkDocs.

## Development & Quality Checks

Before committing or submitting changes, ensure the following checks are executed:

1. **Load Package**: Run `devtools::load_all()` first (required prior to linting so that `object_usage_linter` does not report false positives for exported package objects).
2. **Linting**: Run `jarl check` to execute code linter checks.
3. **Formatting**: Run `air format . --check` to verify code formatting.
4. **Spell Checking**: Run `spelling::spell_check_package()` and add any new valid package terms to `inst/WORDLIST`.
5. **Testing**: Run `devtools::test()` to verify all test suites pass.
6. **Documentation**: Run `devtools::document()` after making any changes to roxygen2 documentation tags.
7. **Changelog**: Add a bullet point to `NEWS.md` describing user-facing changes under the current development section.
