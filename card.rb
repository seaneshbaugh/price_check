class Card
  attr_accessor :name, :set, :price, :condition, :foil, :quanity_available, :link

  def initialize(name, set, price, condition, foil, quanity_available, link)
    @name = name

    @set = set

    @price = price

    @condition = condition

    @foil = foil

    @quanity_available = quanity_available

    @link = link
  end

  def to_s
    "#{@name} - #{@set}#{ @foil ? ' (FOIL)' : ''}: #{@condition} #{@quanity_available} avail. #{@price}"
  end

  def inspect
    to_s
  end
end
