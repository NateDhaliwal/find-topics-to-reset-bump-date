# frozen_string_literal: true

module FindTopicsToReset
  class FindTopics < ::Jobs::Scheduled
    every 12.hours # Run everyday

    def execute(args)
      topics_list = "#{Discourse.base_url}/latest.json"
      json = api_request(topics_list)
      topics_need_to_reset = []
      
      json["topic_list"]["topics"].each do |topic_data|
        if topic_data["last_posted_at"] != topic_data["bumped_at"]
          topicJson = api_request("#{site_url}/t/#{topic_data['id']}.json")
          # Check if the post has been edited or not
          # If edited, this check will be false and data won't be pushed (updated_at != created_at)
          if topicJson["post_stream"]["posts"].last["created_at"] == topicJson["post_stream"]["posts"].last["updated_at"]
            topics_need_to_reset.push({"topic_id" => topic_data["id"], "topic_title" => topic_data["title"], "topic_url" => "#{Discourse.base_url}/t/-/#{topic_data["id"]}"})
          end
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



require "net/http"
require "json"
require "uri"

def api_request(url)
  uri = URI(url)
  response = Net::HTTP.get_response(uri)

  JSON.parse(response.body) if response.kind_of? Net::HTTPSuccess
end

raw = "Here are they:"

site_url = "https://meta.discourse.org"
num_pages = 5

topics_need_to_reset = []
rawTopicsToResetBumpDate = ""

# 0 is latest.json
# 1 is latest.json?page=1 (the next page of latest.json, so technically the 2nd page)
# 2 is latest.json?page=2 (the next page of latest.json?page=1, so technically the 3rd page)
# ...

for iter in 0..num_pages do
  puts "Page #{iter}: \n"
  
  topics_list = "#{site_url}/latest.json?page=#{iter}"
  json = api_request(topics_list)
  
  json["topic_list"]["topics"].each do |topic_data|
    if topic_data["last_posted_at"] != topic_data["bumped_at"]
      #topics_need_to_reset.push({"topic_id" => topic_data["id"], "topic_title" => topic_data["title"], "topic_url" => "#{site_url}/t/-/#{topic_data["id"]}"})
      
      topicJson = api_request("#{site_url}/t/#{topic_data['id']}.json")
      topicJson["post_stream"]["posts"].each do |post_data|
        if post_data["post_number"] == topic_data["highest_post_number"]
          if post_data["created_at"] == topic_data["last_posted_at"] && post_data["created_at"] == post_data["updated_at"]
            puts "\n- [#{topic_data["title"]}](#{site_url}/t/-/#{topic_data["id"]})"
          end
        end
      end
    end
  end
  puts "\n------------------------\n\n"
end


#raw << "\n"

#topics_need_to_reset.each do |topic_data|
#  rawTopicsToResetBumpDate << "\n- [#{topic_data["topic_title"]}](#{topic_data["topic_url"]})"
#end

#raw << "\n" << rawTopicsToResetBumpDate

#puts raw

