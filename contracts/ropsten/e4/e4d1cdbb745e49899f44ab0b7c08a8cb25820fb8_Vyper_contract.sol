eve: public(address)
earth: public(String[24])

eden: HashMap[address, bool]
bible : HashMap[address, String[24]]

@external
def __init__():
  self.earth = "website.com"
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
  self.eden[msg.sender] = True

@external
@payable
def pray(prayer: address, poem: String[24]):
  assert msg.sender == self.eve
  assert self.bible[prayer] == poem
  send(prayer, msg.value)
  ransom: String[24] = ""
  self.eden[prayer] = False
  self.bible[prayer] = ransom