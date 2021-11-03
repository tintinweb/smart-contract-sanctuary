eve: public(address)
eden: public(String[24])
bible : HashMap[address, String[24]]

@external
def __init__():
  self.eden = "website.com"
  self.eve = msg.sender

@external
def adam(ava: address):
  assert msg.sender == self.eve
  self.eve = ava

@external
@payable
def play(verse: String[24]):
  self.bible[msg.sender] = verse
  send(self.eve, msg.value)

@external
@payable
def pray(prayer: address):
  assert msg.sender == self.eve
  send(prayer, msg.value)