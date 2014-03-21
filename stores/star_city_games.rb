class StarCityGames < Store
  @name = 'starcitygames.com'

  @cards = {}

  def self.search(agent, card_name, card_set = nil, foil = nil)
    #page = 1
    #
    #cards = []
    #
    #"http://sales.starcitygames.com/autocomplete/products_only.php?callback=jQuery17105610187854617834_1395346318327&term=E&_=1395346356416"
    #
    #loop do
    #  puts "http://sales.starcitygames.com/search.php?substring=#{card_name.downcase}&go.x=17&go.y=3&go=GO&t_all=All&start_date=2010-01-29&end_date=2012-04-22&order_1=finish&limit=25&action=Show%2BDecks&card_qty%5B1%5D=1&start=#{(page - 1) * 50}"
    #
    #  search_page = agent.get("http://sales.starcitygames.com/search.php?substring=#{card_name.downcase}&go.x=17&go.y=3&go=GO&t_all=All&start_date=2010-01-29&end_date=2012-04-22&order_1=finish&limit=25&action=Show%2BDecks&card_qty%5B1%5D=1&start=#{(page - 1) * 50}", :referer => 'http://www.starcitygames.com/index.php')
    #  puts search_page.body
    #  search_page.parser.css('.deckdbbody_row').each do |card_info|
    #    current_row = card_info
    #
    #    loop do
    #      break if current_row.attributes['class'] == 'deckdbbody_row'
    #
    #      name_container = card_info.css('td.deckdbbody.search_results_1')
    #
    #      name = nil
    #
    #      if name_container
    #        name = name_container.text.strip
    #
    #        break
    #      else
    #        current_row = current_row.previous_element
    #      end
    #    end
    #
    #    cards << name
    #  end
    #
    #  next_link = search_page.parser.css('#content > table:first-child > tbody > tr:nth-child(2) > td > div:first-child > a').last
    #
    #  break unless next_link && next_link.text.include?('Next')
    #
    #  page += 1
    #end
    #
    #cards
  end
end
