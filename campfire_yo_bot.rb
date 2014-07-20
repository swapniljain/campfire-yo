require 'rubygems'
require 'yaml'
require 'tinder'
require 'net/http'

class Yo
  def initialize
    @config = YAML.load_file('config.yml')
    @campfire = Tinder::Campfire.new @config['campfire_domain'], :username => @config['campfire_username'], :password => @config['campfire_password']
    @room = @campfire.find_room_by_id(@config['campfire_room'])
    @yo_api_key = @config['yo_api_key']
    @yo_username_mapping = @config['yo_mapping']
  end
  
  def start_listening
    @room.listen do |m|
      parse_message(m)
    end
  end   

  def parse_message(message)
    if (message[:type] == 'TextMessage' || message[:type] == "PasteMessage")
      body = message[:body]
      if body.downcase.start_with?('yo!')     
        message_array = body.downcase.split
        if message_array.length < 2
          @room.speak 'Name missing. Usage instructions: Yo! <Name>. Example: Yo! Murat'
          return
        end    
        username = @yo_username_mapping[message_array[1]]
        if !username    
          @room.speak 'Name to Yo! username mapping not found. Please get in touch with Swapnil to add this entry.'
          return
        end
        yo(username)      
      end   
    end
  end  

  def yo(username)
    response = Net::HTTP.post_form(URI('http://api.justyo.co/yo/'), 'api_token' => @yo_api_key, 'username' => username)
    @room.speak 'Failed to Yo! ' + username if response.code.to_i >= 300 
  end  
end

Yo.new.start_listening
