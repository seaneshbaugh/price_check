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

  Version = '0.0.2'

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

    @stores = {}

    Dir.glob("#{File.dirname(File.absolute_path(__FILE__))}/stores/*.rb") do |file|
      require file

      store_class = File.basename(file, '.*').camelize.safe_constantize

      raise NameError, "Expected \"stores/#{File.basename(file)}\" to define a class named \"#{File.basename(file, '.*').camelize}\"." unless store_class

      @stores[store_class.name] = store_class
    end

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
    rescue
      puts Usage

      puts

      raise
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

        @stores[store].search(@agent, card)
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
