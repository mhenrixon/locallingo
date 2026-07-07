# frozen_string_literal: true

require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)

RuboCop::RakeTask.new do |task|
  task.patterns = %w[exe lib spec Rakefile Gemfile locallingo.gemspec]
end

desc "Build gem and verify contents"
task :build do
  sh("gem build locallingo.gemspec --strict")
  gem_file = Dir["locallingo-*.gem"].first
  abort "Gem file not found after build" unless gem_file

  sh("gem unpack #{gem_file} --target /tmp/locallingo-verify")
  puts "\n=== Gem contents ==="
  sh("find /tmp/locallingo-verify -type f | sort")
  sh("rm -rf /tmp/locallingo-verify #{gem_file}")
end

# Colored status helpers shared by the release task.
module ReleaseHelpers
  def info(msg)    = puts "\e[34m→\e[0m #{msg}"
  def success(msg) = puts "\e[32m✓\e[0m #{msg}"
  def skip(msg)    = puts "\e[33m⊘\e[0m #{msg} \e[33m(skipped)\e[0m"
  def header(msg)  = puts "\n\e[1;36m#{msg}\e[0m\n#{"─" * msg.length}"
end

desc "Release a new version (rake release[1.2.3] or rake release[pre])"
task :release, %i[version] do |_t, args|
  include ReleaseHelpers

  require_relative "lib/locallingo/version"

  new_version = args[:version]
  abort "\e[31mUsage: rake release[X.Y.Z]\e[0m" unless new_version

  current_branch = `git branch --show-current`.strip
  abort "\e[31mAborting: must be on main to release (on #{current_branch})\e[0m" unless current_branch == "main"

  dirty = `git status --porcelain`.strip
  abort "\e[31mAborting: working directory is not clean.\e[0m\n#{dirty}" unless dirty.empty?

  current = Locallingo::VERSION
  prerelease = new_version.match?(/alpha|beta|rc|pre/) || new_version == "pre"
  new_version = current if new_version == "pre"
  tag = "v#{new_version}"
  version_file = "lib/locallingo/version.rb"

  header "Release #{tag}"
  info "Current: #{current}  →  New: #{new_version}  (prerelease: #{prerelease})"

  # Bump the version file.
  if new_version == current
    skip "Version already #{new_version}"
  else
    content = File.read(version_file)
    content.sub!(/VERSION = ".*"/, "VERSION = \"#{new_version}\"")
    File.write(version_file, content)
    success "Updated #{version_file}"
  end

  # Verify it still builds clean before tagging.
  header "Build verification"
  sh("bundle install --quiet")
  sh("gem build locallingo.gemspec --strict")
  sh("rm -f locallingo-*.gem")
  success "Gem builds cleanly"

  # Commit + push the bump (skip if version unchanged, e.g. `pre`).
  header "Git"
  unless `git diff #{version_file}`.strip.empty? && `git diff --cached #{version_file}`.strip.empty?
    sh("git add #{version_file}")
    sh("git commit -m 'chore: bump version to #{new_version}'")
    success "Committed version bump"
  end
  sh("git push origin main")

  # Create the release — this fires the Release workflow, which publishes to
  # RubyGems via OIDC trusted publishing.
  header "Release"
  pre_flag = prerelease ? "--prerelease" : ""
  sh("gh release create #{tag} --generate-notes --target main #{pre_flag}".strip)
  success "\e[1mRelease #{tag} created!\e[0m The Release workflow now:"
  puts "    • Runs the suite on Ruby 3.2–3.4"
  puts "    • Builds + verifies the gem"
  puts "    • Signs with Sigstore + publishes to RubyGems (trusted publishing)"
  puts "    • Attaches assets to the GitHub release"
end

task default: %i[spec rubocop]
