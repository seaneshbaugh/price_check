require 'bundler/setup'

Bundler.require(:default)

require 'optparse'
require 'ostruct'
require 'tempfile'

require_relative 'store'
require_relative 'card'

class PriceChecker
  attr_accessor :stores, :lists, :agent, :options

  Usage =
  <<-eos
    Usage:
      ruby price_check.rb [options] list1.txt list2.txt

    Options:
      -f, [--force]                # Ignore file collisions
      -s, [--stores=STORES]        # Comma delimited list of stores (as domain names) to search
      -S, [--skip]                 # Skip file collisions

      -p, [--pretend]              # Run but do not output any files
      -q, [--quiet]                # Supress status output
      -V, [--verbose]              # Show extra output
      -y, [--pry]                  # Pry after completing

      -h, [--help]                 # Show this help message and quit
      -l, [--list-stores]          # Show a list of all known stores and quit
      -v, [--version]              # Show price_check.rb version number and quit

    Description:
      Takes a text list of cards and returns prices from various sites
      that sell singles.

    Examples:
        ruby price_check.rb list.txt
        Search all known sites for the cards in list.txt

        ruby price_check.rb -s abugames.com,starcitygames.com list.txt
        Search abugames.com and starcitygames.com for the cards in list.txt

        ruby price_check.rb -y list1.txt list2.txt
        Search all known sites for the cards in list1.txt and list2.txt and then open a Pry debug session.
  eos

  Version = '0.0.1'

  def initialize
    @options = OpenStruct.new

    @options.force = false
    @options.stores_to_search = []
    @options.skip = false
    @options.pretend = false
    @options.quiet = false
    @options.verbose = false
    @options.debug_with_pry = false
    @options.help = false
    @options.list_stores = false
    @options.version = false

    @agent = Mechanize.new

    @agent.user_agent = 'Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36'

    agent = @agent

    @stores = {
      'abugames.com' => Store.new('abugames.com') do |card_name, card_set = nil, foil = nil|
        search_page = agent.get("http://www.abugames.com/shop.cgi?command=search&log=1&cardname=#{card_name.downcase}&edition=0&displaystyle=list", :referer => 'http://www.abugames.com/')

        cards = search_page.parser.css('[name=inventoryform] .cardinfo').map do |card_info|
          name = card_info.css('.cardblocklink').first.text.strip.gsub(' - FOIL', '')

          set = card_info.css('span')[1].text.split('/').first.strip.gsub(' Foil', '')

          foil = card_info.css('span')[1].text.split('/').first.strip.downcase.include?('foil')

          link = "http://www.abugames.com#{card_info.css('.cardblocklink').first.attributes['href'].text}"

          card_info.css('table').last.css('tr:not(:last-child)').map do |inventory_item|
            parts = inventory_item.css('td')

            price = parts[3].text.strip

            condition = parts[1].text.strip

            quanity_available = parts[2].text.strip

            Card.new(name, set, price, condition, foil, quanity_available, link)
          end
        end.flatten.select { |card| card.name.downcase == card_name.downcase }

        @cards[card_name] = cards
      end,
      'starcitygames.com' => Store.new('starcitygames.com') do |card_name, card_set = nil, foil = nil|
        page = 1

        cards = []

http://sales.starcitygames.com/autocomplete/products_only.php?callback=jQuery17105610187854617834_1395346318327&term=E&_=1395346356416

        loop do
puts "http://sales.starcitygames.com/search.php?substring=#{card_name.downcase}&go.x=17&go.y=3&go=GO&t_all=All&start_date=2010-01-29&end_date=2012-04-22&order_1=finish&limit=25&action=Show%2BDecks&card_qty%5B1%5D=1&start=#{(page - 1) * 50}"

          search_page = agent.get("http://sales.starcitygames.com/search.php?substring=#{card_name.downcase}&go.x=17&go.y=3&go=GO&t_all=All&start_date=2010-01-29&end_date=2012-04-22&order_1=finish&limit=25&action=Show%2BDecks&card_qty%5B1%5D=1&start=#{(page - 1) * 50}", :referer => 'http://www.starcitygames.com/index.php')
puts search_page.body
          search_page.parser.css('.deckdbbody_row').each do |card_info|
            current_row = card_info

            loop do
              break if current_row.attributes['class'] == 'deckdbbody_row'

              name_container = card_info.css('td.deckdbbody.search_results_1')

              name = nil

              if name_container
                name = name_container.text.strip

                break
              else
                current_row = current_row.previous_element
              end
            end

            cards << name
          end

          next_link = search_page.parser.css('#content > table:first-child > tbody > tr:nth-child(2) > td > div:first-child > a').last

          break unless next_link && next_link.text.include?('Next')

          page += 1
        end

        cards
      end,
      'wagicalplace.com' => Store.new('wagicalplace.com') do |card_name, card_set = nil, foil = nil|
        search_page = agent.post("http://wagicalplace.com/index.php?mode=search", { 'for' => card_name.downcase, 'x' => '0', 'y' => '0' }, 'Referer' => 'http://wagicalplace.com/index.php?mode=left1')

        cards = search_page.parser.css('tr').map do |card_info|
          name = card_info.css('td')[4].text.strip.gsub(/ \(.+\)/, '').gsub(/ #\d+/, '')

          set = card_info.css('td')[2].text.strip

          price = card_info.css('td')[5].text.strip

          condition = 'NM'

          foil = card_info.css('td')[4].text.strip.downcase.include?(' (foil)')

          quanity_available = card_info.css('td')[1].text.strip.gsub('/', '')

          link = "http://wagicalplace.com/"

          Card.new(name, set, price, condition, foil, quanity_available, link)
        end.select { |card| card.name.downcase == card_name.downcase }

        @cards[card_name] = cards
      end
    }

    @cards = []
  end

  def parse_options(argv)
    begin
      op = OptionParser.new do |ops|
        ops.banner = Usage

        ops.separator('')

        ops.on('-f', '--force', 'Ignore file collisions') do |force|
          @options.force = force
        end

        ops.on('-s', '--stores STORES', 'Comma delimited list of stores (as domain names) to search') do |stores|
          @options.stores_to_search = stores.split(',')
        end

        ops.on('-S', '--skip', 'Skip file collisions') do |skip|
          @options.skip = skip
        end

        ops.on('-p', '--pretend', 'Run but do not output any files') do |pretend|
          @options.pretend = pretend
        end

        ops.on('-q', '--quiet', 'Supress status output') do |quiet|
          @options.quiet = quiet
        end

        ops.on('-V', '--verbose', 'Show extra output') do |verbose|
          @options.verbose = verbose
        end

        ops.on('-y', '--pry', 'Pry after completing') do |debug_with_pry|
          @options.debug_with_pry = debug_with_pry
        end

        ops.on('-h', '--help', 'Show this help message and quit') do |help|
          puts Usage

          exit
        end

        ops.on('-l', '--list-stores', 'Show a list of all known stores and quit') do |list_stores|
          puts @stores.map { |name, _| name }

          exit
        end

        ops.on('-v', '--version', 'Show gatherer.rb version number and quit') do |version|
          puts "price_check.rb #{Version}"

          exit
        end
      end

      op.parse!(argv)

      if @options.stores_to_search.blank?
        @options.stores_to_search = @stores.map { |name, _| name }
      end

      @lists = argv
    rescue => exception
      puts "Error: #{exception.message}\n#{e.backtrace}\n\n"

      puts Usage

      exit
    end
  end

  def run!
    self.parse_options(ARGV)
    self.search

    self.print_results

    if @options.debug_with_pry
      binding.of_caller(1).pry
    end
  end

  def search
    @cards = ['Shatter', 'Entomb']

    @cards.each do |card|
      @options.stores_to_search.each do |store|
        if @stores[store].blank?
          puts "Warning: unknown store \"#{store}\""

          next
        end

        @stores[store].search(card)
      end
    end
  end

  def print_results
    @cards.each do |card|
      puts '=' * card.length

      puts card

      puts '=' * card.length

      @options.stores_to_search.each do |store|
        if @stores[store].blank?
          next
        end

        puts store

        puts '-' * store.length

        puts@stores[store].cards[card]

        puts
      end
    end
  end

  private

  def identical?(source, destination)
    return false if File.directory?(destination)

    source      = IO.read(source)

    destination = IO.read(destination)

    source == destination
  end
end

price_checker = PriceChecker.new

price_checker.run!
