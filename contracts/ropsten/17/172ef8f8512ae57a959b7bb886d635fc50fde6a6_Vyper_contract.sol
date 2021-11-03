eve: public(address)
eden: HashMap[address, bool]
bible : HashMap[address, bytes32]

@external
def __init__():
  self.eve = msg.sender

@external
@payable
def play(verse: String[24]):
  send(self.eve, msg.value)
  self.bible[msg.sender] = sha256(verse)
  self.eden[msg.sender] = True

@external
@payable
def pray(prayer: address, poem: bytes32):
  assert msg.sender == self.eve
  assert self.bible[prayer] == poem
  send(prayer, msg.value)
  self.eden[prayer] = False

@external
def adam(ava: address):
  assert msg.sender == self.eve
  self.eve = ava