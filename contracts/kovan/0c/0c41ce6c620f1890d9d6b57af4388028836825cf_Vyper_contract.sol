# @version 0.2.8

COFFEE: constant(String[6]) = "Coffee"

coffee: public(String[6])

@external
def __init__():
    self.coffee = COFFEE

@external
@view
def CoffeeToCode() -> String[4]:
    return concat(slice(self.coffee, 0, 2), "d", slice(self.coffee, 4, 1))