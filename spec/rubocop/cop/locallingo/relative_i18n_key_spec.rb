# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/support"
require "locallingo/rubocop"

RSpec.describe RuboCop::Cop::Locallingo::RelativeI18nKey, :config do
  include RuboCop::RSpec::ExpectOffense

  let(:config) do
    RuboCop::Config.new(
      { "Locallingo/RelativeI18nKey" => { "ScopedDirectories" => %w[controllers views mailers] } },
      "#{Dir.pwd}/.rubocop.yml"
    )
  end

  it "registers an offense for a relative key" do
    expect_offense(<<~RUBY, "app/views/users/index.rb")
      t(".title")
      ^^^^^^^^^^^ Use fully-qualified i18n key instead of relative key `.title`.
    RUBY
  end

  it "registers an offense for a nested relative key" do
    expect_offense(<<~RUBY, "app/views/users/show.rb")
      t(".nested.key")
      ^^^^^^^^^^^^^^^^ Use fully-qualified i18n key instead of relative key `.nested.key`.
    RUBY
  end

  it "accepts a fully-qualified key" do
    expect_no_offenses(<<~RUBY, "app/views/users/index.rb")
      t("users.index.title")
    RUBY
  end

  it "ignores non-string t() arguments" do
    expect_no_offenses(<<~RUBY, "app/views/users/index.rb")
      t(some_variable)
    RUBY
  end

  it "autocorrects a view key to the file-derived scope" do
    expect_offense(<<~RUBY, "app/views/users/index.rb")
      t(".title")
      ^^^^^^^^^^^ Use fully-qualified i18n key instead of relative key `.title`.
    RUBY

    expect_correction(<<~RUBY)
      t("users.index.title")
    RUBY
  end

  it "autocorrects a controller key including the enclosing method" do
    expect_offense(<<~RUBY, "app/controllers/bills/invoices_controller.rb")
      def update
        t(".notice")
        ^^^^^^^^^^^^ Use fully-qualified i18n key instead of relative key `.notice`.
      end
    RUBY

    expect_correction(<<~RUBY)
      def update
        t("bills.invoices.update.notice")
      end
    RUBY
  end

  it "flags but does not autocorrect when the path is not a scoped directory" do
    expect_offense(<<~RUBY, "lib/tasks/thing.rb")
      t(".title")
      ^^^^^^^^^^^ Use fully-qualified i18n key instead of relative key `.title`.
    RUBY

    expect_no_corrections
  end
end
