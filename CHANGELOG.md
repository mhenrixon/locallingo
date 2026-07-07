# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial extraction from the `bin/translate` toolchain into a standalone gem.
- `lingo` CLI with subcommands: `status`, `translate`, `validate`, `quality`,
  `fix-quality`, `accept-edits`, `hash`, `sync`. Legacy `--flag` forms still work
  and print a deprecation notice.
- `Locallingo::Configuration` — `.locallingo.yml` with a `defaults:` block plus
  optional per-`packages:` overrides (deep-merged, ERB-evaluated).
- Provider-agnostic translation via RubyLLM (`provider:`/`model:` config).
- Validators (config-gated): `missing`, `outdated`, `duplicate_values`,
  `manual_edits`.
- Quality checks: static rules, universal fixes, configurable terminology lists
  (`business`/`banking`/custom), optional British-spelling drift, plus an
  optional AI review pass.
- Source-hash drift detection with per-namespace state files under `.i18n-state/`.
- Configurable `after_translate` hook commands (e.g. `i18n-tasks normalize -p`,
  `rails i18n:export`).
- RuboCop cops `Locallingo/RelativeI18nKey` (with autocorrect) and
  `Locallingo/StrftimeInView`, loaded via `require: locallingo/rubocop`.
