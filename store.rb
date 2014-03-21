class Store
  attr_accessor :name, :cards

  def initialize(name, &block)
    @name = name

    @search = block

    @cards = {}
  end

  def search(card_name, card_set = nil, foil = nil)
    instance_exec card_name, card_set, foil, &@search
  end
end
