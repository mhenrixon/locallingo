# frozen_string_literal: true

# In-memory registry of the reference docs. One line per page — slug and view
# derive from the title (both overridable), and the sidebar nav derives from this
# registry with zero extra code (see config/initializers/docs_kit.rb's
# `nav_registries`). It also feeds the AI surfaces (/llms.txt, /llms-full.txt,
# search, MCP): an unwritten page (whose view class doesn't resolve yet) is
# silently skipped everywhere, so the whole list can be declared up front as a
# burn-down of pages to author.
#
# Add a page with `rails g docs_kit:page "Title" --group=…`, which appends the
# `page` line here and writes the class under app/views/docs/pages/. Uses
# DocsKit::Registry for the shared all/from_slug/grouped/nav_items API.
class Doc
  extend DocsKit::Registry
  path_prefix    "/docs"
  view_namespace "Views::Docs::Pages"

  # Getting started
  page "Overview",      group: "Getting started"
  page "Installation",  group: "Getting started"
  page "Quick start",   group: "Getting started", slug: "quick-start", view: "QuickStart"

  # CLI
  page "CLI reference", group: "CLI", slug: "cli", view: "Cli"
  page "Commands",      group: "CLI"

  # Configuration
  page "Configuration",           group: "Configuration"
  page "Providers & models",      group: "Configuration", slug: "providers", view: "Providers"
  page "Prompt & glossary",       group: "Configuration", slug: "prompt-glossary", view: "PromptGlossary"
  page "Multiple packages",       group: "Configuration", slug: "packages", view: "Packages"
  page "Configuration reference", group: "Configuration", slug: "configuration-reference", view: "ConfigurationReference"

  # Validation & quality
  page "Validators",      group: "Validation & quality"
  page "Drift & state",   group: "Validation & quality", slug: "drift-state", view: "DriftState"
  page "Quality linting", group: "Validation & quality", slug: "quality", view: "Quality"

  # Enforcement
  page "RuboCop cops", group: "Enforcement", slug: "rubocop-cops", view: "RubocopCops"

  # Guides
  page "Continuous integration",  group: "Guides", slug: "ci", view: "Ci"
  page "Migrating from a script", group: "Guides", slug: "migrating", view: "Migrating"
end
