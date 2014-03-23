class ChannelFireball < Store
  @name = 'channelfireball.com'

  def self.search(agent, card_name, card_set = nil, foil = nil)
    page = 1

    cards = []

    loop do
      search_page = agent.get("http://store.channelfireball.com/advanced_search?search%5Border%5D=&search%5Bfuzzy_search%5D=#{card_name}&search%5Btags_name_eq%5D=&search%5Bsell_price_gte%5D=&search%5Bsell_price_lte%5D=&search%5Bbuy_price_gte%5D=&search%5Bbuy_price_lte%5D=&buylist_mode=0&search%5Bin_stock%5D=0&search%5Bin_stock%5D=on&search%5Bcategory_ids_with_descendants%5D%5B%5D=8&search%5Bwith_descriptor_values%5D%5B13%5D=&search%5Bwith_descriptor_values%5D%5B7%5D=&search%5Bwith_descriptor_values%5D%5B9%5D=&search%5Bwith_descriptor_values%5D%5B11%5D=&search%5Bwith_descriptor_values%5D%5B6%5D=&search%5Bwith_descriptor_values%5D%5B255%5D=&search%5Bwith_descriptor_values%5D%5B10%5D=&search%5Bwith_descriptor_values%5D%5B290%5D=&search%5Bwith_descriptor_values%5D%5B366%5D=&search%5Bvariants_with_identifier%5D%5B14%5D%5B%5D=&search%5Bvariants_with_identifier%5D%5B15%5D%5B%5D=&search%5Bsort%5D=name&search%5Bdirection%5D=ascend&commit=Search&page=#{page}", :referer => 'http://store.channelfireball.com/')

      cards += search_page.parser.css('.product_row .list-info-container').map do |card_info|
        name = card_info.css('.scraperLink h2').first.children.first.text.strip

        set = card_info.css('.scraperLink h2').first.children.last.text.strip

        foil = card_info.css('.scraperLink h2').first.children.first.text.strip.include?(' - Foil')

        link = "http://store.channelfireball.com/#{card_info.css('.scraperLink').first.attributes['href'].text.strip}"

        card_info.css('.variantRow').map do |inventory_item|
          price = inventory_item.css('.variant-pricing').first.text.strip

          condition = inventory_item.css('.variant-main-info').first.text.strip.gsub(/, .+/, '')

          quanity_available = inventory_item.css('.variant-stock').first.text.strip.gsub('stock: ', '').to_i

          Card.new(name, set, price, condition, foil, quanity_available, link)
        end
      end.flatten.select { |card| card.name.downcase == card_name.downcase && card.quanity_available > 0 }

      next_link = search_page.parser.css('.next_page').last

      break unless next_link && next_link.text.include?('Next')

      page += 1
    end

    cards
  end
end
