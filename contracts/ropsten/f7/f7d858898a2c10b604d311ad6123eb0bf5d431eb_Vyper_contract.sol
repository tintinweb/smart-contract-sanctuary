name: public(String[24])
gamemaster: public(address)

@external
def __init__():
  self.name = "Satoshi Nakamoto"
  self.gamemaster = msg.sender


@external
def change_name(new_name: String[24]):
  assert msg.sender == self.gamemaster
  self.name = new_name

@external
def say_hello() -> String[32]:
  return concat("Hello, ", self.name)