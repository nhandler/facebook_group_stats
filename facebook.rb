require 'open-uri'
require 'json'
require 'yaml'

def url(endpoint)
  config = YAML.load_file("config.yml")

  base_url = "https://graph.facebook.com"
  access_token = config['access_token']
  group_id = config['group_id']
  url = "#{base_url}/#{group_id}/#{endpoint}?access_token=#{access_token}"
end

def get_json(url)
  json = JSON.parse(open(url).read)
  data = json['data']
  while json['paging'] && json['paging']['next']
    json = JSON.parse(open(json['paging']['next']).read)
    data.concat(json['data'])
  end
  return data
end

def member_count
  endpoint = "members"
  members = get_json(url(endpoint))

  puts "There are #{members.length} members."
  admins = members.select { |member| member['administrator'] }
  @admin_ids = []
  admins.each do |admin|
    @admin_ids << admin['id']
  end
  puts "#{admins.count} of those members are admins."
  admins = members.select { |member| member['administrator'] }
end

def post_count
  endpoint = "feed"
  posts = get_json(url(endpoint))

  like_count = 0
  puts "There are #{posts.length} posts."
  num_admin_posts = posts.inject(0) do |sum, post|
    if post['likes'] && post['likes']['data']
      like_count += post['likes']['data'].length
    end
    if @admin_ids.include?(post['from']['id'])
      sum = sum + 1
    else
      sum
    end
  end
  puts "#{num_admin_posts} of those posts are from admins"

  num_comments = 0
  num_admin_comments = 0
  posts.each do |post|
    comments = post['comments'] || {}
    data = comments['data'] || []
    data.each do |comment|
      like_count += comment['like_count']
      if @admin_ids.include?(comment['from']['id'])
        num_admin_comments += 1
      end
      num_comments += 1
    end
  end
  puts "There are #{num_comments} comments."
  puts "#{num_admin_comments} of those comments are from admins"

  puts "There are #{like_count} likes."
end

member_count
post_count
