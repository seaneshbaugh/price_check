class TrollAndToad < Store
  @name = 'trollandtoad.com'

  def self.search(agent, card_name, card_set = nil, foil = nil)
    search_page = agent.get("http://www.trollandtoad.com/products/search.php?search_words=#{card_name.downcase}&search_category=1041&search_order=relevance_desc&in_stock=yes", :referer => 'http://www.trollandtoad.com/')

    search_page.parser.css('.search_result_wrapper').map do |card_info|
      name = card_info.css('h2').text.strip.gsub(' - Foil', '')

      set = card_info.css('a.search_result_category_link').text.strip.gsub(' Singles', '').gsub('MTG ', '').gsub(' (Magic Cards)', '').gsub(' Foil', '')

      foil = card_info.css('h2').text.strip.downcase.include?('foil')

      link = "http://www.trollandtoad.com/#{card_info.css('a.search_result_category_link').first.attributes['href'].text.strip}"

      card_info.css('.condition_is').map do |inventory_item|
        price = inventory_item.css('.price_text').text.strip

        condition = inventory_item.css('.condition_text a').last.text.strip.gsub('English ', '').gsub('Foil ', '')

        quanity_available = inventory_item.css('.search_result_conditions_qty option').last.text.strip.to_i

        Card.new(name, set, price, condition, foil, quanity_available, link)
      end
    end.flatten.select { |card| card.name.downcase == card_name.downcase && card.quanity_available > 0 }
  end
end
