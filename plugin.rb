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

module ::FindTopicsToResetBumpDate
  PLUGIN_NAME = "find-topics-to-reset-bump-date"
end

#require_relative "lib/my_plugin_module/engine"

after_initialize do
  class ::Jobs::FindTopics < Jobs::Scheduled
    every 12.hours # Run everyday

    def execute(args)
      topics_list = "#{Discourse.base_url}/latest.json"
      json = api_request(topics_list)
      topics_need_to_reset = []
      
      json["topic_list"]["topics"].each do |topic_data|
        if topic_data["last_posted_at"] != topic_data["bumped_at"]
          topics_need_to_reset.push({"topic_id" => topic_data["id"], "topic_title" => topic_data["title"], "topic_url" => "#{Discourse.base_url}/t/-/#{topic_data["id"]}"})
        end
      end
      
      # Compose your PM details
      title = SiteSetting.reset_bump_date_pm_title
      raw = SiteSetting.reset_bump_date_pm_body
      rawTopicsToResetBumpDate = ""
      
      if SiteSetting.send_pm_when_no_topics_to_reset_bump_date == true 
        if topics_need_to_reset.length() == 0
          title = SiteSetting.no_topics_to_reset_bump_date_pm_title
          raw = SiteSetting.no_topics_to_reset_bump_date_pm_body
        else
          raw = SiteSetting.reset_bump_date_pm_body
        end
      end

      # Add newline below body text for suitable spacing, above the list of topics
      raw << "\n"
      
      topics_need_to_reset.each do |topic_data|
        rawTopicsToResetBumpDate << "\n- [#{topic_data["topic_title"]}](#{topic_url})"
      end      
        
      # Find the admin group
      admin_group = Group.find_by(name: "admins")
      
      # The system user often sends automated messages
      system_user = Discourse.system_user
      
      # Send the PM to the admin group
      PostCreator.create!(
        system_user,
        title: title,
        raw: raw,
        archetype: Archetype.private_message,
        target_group_names: [admin_group.name]
      )
    end
    
    def api_request(url)
      uri = URI(url)
      response = Net::HTTP.get_response(uri)

      JSON.parse(response.body) if response.kind_of? Net::HTTPSuccess
    end
  end
end
