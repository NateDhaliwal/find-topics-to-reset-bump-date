# frozen_string_literal: true

# name: find-topics-to-reset-bump-date
# about: TODO
# meta_topic_id: TODO
# version: 0.0.1
# authors: NateDhaliwal
# url: TODO

require "net/http"
require "json"
require "uri"

enabled_site_setting :enable_find_topics_to_reset_bump_date

after_initialize do
  %w[
    ../app/jobs/scheduled/find_topics_to_reset.rb
  ].each { |path| require File.expand_path(path, __FILE__) }
end
