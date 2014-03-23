class Ideal808 < Store
  @name = 'ideal808.com'

  def self.search(agent, card_name, card_set = nil, foil = nil)
    search_page = agent.get("http://www.ideal808.com/advanced_search?utf8=%E2%9C%93&search%5Bfuzzy_search%5D=#{card_name}&search%5Btags_name_eq%5D=&search%5Bsort%5D=name&search%5Bdirection%5D=ascend&search%5Bcategory_ids_with_descendants%5D%5B%5D=&search%5Bcategory_ids_with_descendants%5D%5B%5D=8&buylist_mode=0&search%5Bsell_price_gte%5D=&search%5Bsell_price_lte%5D=&search%5Bbuy_price_gte%5D=&search%5Bbuy_price_lte%5D=&search%5Bin_stock%5D=0&search%5Bin_stock%5D=1&commit=Search&search%5Bwith_descriptor_values%5D%5B603%5D=&search%5Bwith_descriptor_values%5D%5B9%5D=&search%5Bwith_descriptor_values%5D%5B601%5D=&search%5Bwith_descriptor_values%5D%5B604%5D=&search%5Bwith_descriptor_values%5D%5B602%5D=&search%5Bwith_descriptor_values%5D%5B11%5D=&search%5Bwith_descriptor_values%5D%5B7%5D=&search%5Bwith_descriptor_values%5D%5B6%5D=&search%5Bwith_descriptor_values%5D%5B463%5D=&search%5Bwith_descriptor_values%5D%5B537%5D=&search%5Bwith_descriptor_values%5D%5B10%5D=&search%5Bwith_descriptor_values%5D%5B558%5D=&search%5Bwith_descriptor_values%5D%5B581%5D=&search%5Bwith_descriptor_values%5D%5B13%5D=&search%5Bvariants_with_identifier%5D%5B14%5D%5B%5D=&search%5Bvariants_with_identifier%5D%5B15%5D%5B%5D=&search%5Bvariants_with_identifier%5D%5B15%5D%5B%5D=English", :referer => 'http://www.ideal808.com/')

    search_page.parser.css('.products tr td:last-child').map do |card_info|
      name = card_info.css('a').first.text.strip.gsub(' - Foil', '')

      set = card_info.css('small').text.strip

      foil = card_info.css('a').first.text.strip.downcase.include?(' - Foil')

      link = "http://www.ideal808.com/#{card_info.css('a').first.attributes['href'].text.strip}"

      card_info.css('.variantRow').map do |inventory_item|
        parts = inventory_item.css('td')

        price = parts[1].text.strip

        condition = parts[0].text.strip.gsub('Condition: ', '').gsub(/, .+/, '')

        quanity_available = parts[2].text.strip.gsub('x ', '').to_i

        Card.new(name, set, price, condition, foil, quanity_available, link)
      end
    end.flatten.select { |card| card.name.downcase == card_name.downcase && card.quanity_available > 0 }
  end
end
