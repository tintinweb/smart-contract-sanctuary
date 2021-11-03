name: public(String[24])
gamemaster: public(address)
valuelocked : public(uint256)

@external
def __init__():
  self.name = "Satoshi Nakamoto"
  self.gamemaster = msg.sender
  self.valuelocked = 0


@external
def ava(next: address):
  assert msg.sender == self.gamemaster
  self.gamemaster = next

@external
@payable
def send_money():
  self.valuelocked += msg.value