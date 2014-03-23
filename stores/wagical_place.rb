class WagicalPlace < Store
  @name = 'wagicalplace.com'

  def self.search(agent, card_name, card_set = nil, foil = nil)
    search_page = agent.post("http://wagicalplace.com/index.php?mode=search", { 'for' => card_name.downcase, 'x' => '0', 'y' => '0' }, 'Referer' => 'http://wagicalplace.com/index.php?mode=left1')

    search_page.parser.css('tr').map do |card_info|
      name = card_info.css('td')[4].text.strip.gsub(/ \(.+\)/, '').gsub(/ #\d+/, '')

      set = card_info.css('td')[2].text.strip

      price = card_info.css('td')[5].text.strip

      condition = 'NM'

      foil = card_info.css('td')[4].text.strip.downcase.include?(' (foil)')

      quanity_available = card_info.css('td')[1].text.strip.gsub('/', '').to_i

      link = "http://wagicalplace.com/#{card_info.css('td')[4].css('a').first.attributes['href'].text.strip}"

      Card.new(name, set, price, condition, foil, quanity_available, link)
    end.select { |card| card.name.downcase == card_name.downcase && card.quanity_available > 0 }
  end
end
