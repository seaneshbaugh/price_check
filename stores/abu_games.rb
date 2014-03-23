class AbuGames < Store
  @name = 'abugames.com'

  def self.search(agent, card_name, card_set = nil, foil = nil)
    search_page = agent.get("http://www.abugames.com/shop.cgi?command=search&log=1&cardname=#{card_name.downcase}&edition=0&displaystyle=list", :referer => 'http://www.abugames.com/')

    cards = search_page.parser.css('[name=inventoryform] .cardinfo').map do |card_info|
      name = card_info.css('.cardblocklink').first.text.strip.gsub(' - FOIL', '')

      set = card_info.css('span')[1].text.split('/').first.strip.gsub(' Foil', '')

      foil = card_info.css('span')[1].text.split('/').first.strip.downcase.include?('foil')

      link = "http://www.abugames.com#{card_info.css('.cardblocklink').first.attributes['href'].text.strip}"

      card_info.css('table').last.css('tr:not(:last-child)').map do |inventory_item|
        parts = inventory_item.css('td')

        price = parts[3].text.strip

        condition = parts[1].text.strip

        quanity_available = parts[2].text.strip.to_i

        Card.new(name, set, price, condition, foil, quanity_available, link)
      end
    end.flatten.select { |card| card.name.downcase == card_name.downcase && card.quanity_available > 0 }
  end
end
