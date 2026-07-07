# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/support"
require "locallingo/rubocop"

RSpec.describe RuboCop::Cop::Locallingo::StrftimeInView, :config do
  include RuboCop::RSpec::ExpectOffense

  let(:config) { RuboCop::Config.new({}, "#{Dir.pwd}/.rubocop.yml") }

  it "registers an offense for .strftime in a view" do
    expect_offense(<<~RUBY, "app/views/users/show.rb")
      created_at.strftime("%B %d, %Y")
                 ^^^^^^^^ Use `I18n.l(value, format: :name)` instead of `.strftime(...)`. Define formats in config/locales/{time,date}.*.yml.
    RUBY
  end

  it "accepts I18n.l" do
    expect_no_offenses(<<~RUBY, "app/views/users/show.rb")
      I18n.l(created_at, format: :long)
    RUBY
  end

  it "exempts strftime inside a value: pair (HTML datetime input)" do
    expect_no_offenses(<<~RUBY, "app/views/forms/edit.rb")
      input(type: "datetime-local", value: due_date.strftime("%Y-%m-%dT%H:%M"))
    RUBY
  end
end
