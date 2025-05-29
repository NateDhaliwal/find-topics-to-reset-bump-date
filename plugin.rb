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

module ::MyPluginModule
  PLUGIN_NAME = "discourse-plugin-name"
end

#require_relative "lib/my_plugin_module/engine"

after_initialize doafter_initialize do
  class ::Jobs::FindTopics < Jobs::Scheduled
    every 12.hours # Run everyday

    def execute(args)
      topics_list = "#{Discourse.base_url}/latest.json"
      json = api_request(topics_list)
      
      json["topic_list"]["topics"].each do |topic_data|
        
      end
    end
    
    def api_request(url)
      uri = URI(url)
      response = Net::HTTP.get_response(uri)

      JSON.parse(response.body) if response.kind_of? Net::HTTPSuccess
    end
  end
end
