require 'nokogiri'
require 'open-uri'
require 'pry'
require 'CSV'

module MyHelper
  def time_to_s(time_string)
    m_s = time_string.split(":").map(&:to_i)
    m_s.length == 1 ? "N/A" : m_s[0]*60 + m_s[1]
  end
end

class Scraper
  include MyHelper
  attr_accessor :names

  def initialize
    @names = []
  end

  def get_personal_records
      t_start = Time.new
      puts "Starting: #{t_start}"

    CSV.open("./seeds/all_records.csv","wb") do |csv|
      CSV.foreach("./seeds/player_names.csv") do |row|
        doc = Nokogiri::HTML(open("https://rankings.the-elite.net/~#{row[0]}/goldeneye/history"))
        data = doc.css("td")

        i = 0
        while (i < data.length)
          csv << [
            row[0], # player_name
            data[i].text, # date_achieved https://apidock.com/ruby/DateTime/strftime
            data[i+1].text, # stage
            data[i+2].text, # difficulty
            time_to_s(data[i+3].text), # time_seconds, m:s to s
            data[i+3].children.first.attributes.first.last.value.split("/").last.to_i, # personal_record_id
            data[i+4].text, # system
            data[i+5].text == "Yes", # current pr?
            data[i+6].text == "Yes", # video?
          ]
          i += 7
        end
      end
    end
    # t_end = Time.new
    # puts "Finished at: #{t_end}"
    # difference = t_end - t_start
    # puts "Total Seconds: #{difference}"
    # difference = difference.to_i
    # puts "Or #{difference/60} minutes, #{difference % 60} seconds"
  end

  def get_players
    # top 50
    doc = Nokogiri::HTML(open("https://rankings.the-elite.net/ajax/rankings/ge/"))
    text = doc.css("p").children.text.split(":").last.split(",")
    @names = text.values_at(* text.each_index.select{ |i| (i-1)%6 == 0})

    # remaining names
    doc = Nokogiri::HTML(open("https://rankings.the-elite.net/ajax/rankings/ge/post50/1510367957"))
    text = doc.css("p").children.text.split(":").last.split(",")
    remaining_names = text.values_at(* text.each_index.select{ |i| (i-1)%6 == 0})

    @names << remaining_names
    @names.flatten!
    @names.map! { |n| n[1..-2]}

    CSV.open("./seeds/player_names.csv","wb") do |csv|
      @names.each { |n| csv << [n] }
    end

  end

  def get_player_achievements
    CSV.open("./seeds/achievements.csv","wb") do |csv|
      @names.each do |player|
        doc = Nokogiri::HTML(open("https://rankings.the-elite.net/~#{player}/achievements"))
        i = 0
        while (i < doc.css(".achievement").length)
          csv << [player, doc.css(".achievement-name")[i], doc.css(".achievement-description")[i]]
          i += 1
        end
      end
    end
  end

end

sample_seed = Scraper.new
# sample_seed.get_players
# sample_seed.get_player_achievements
sample_seed.get_personal_records
