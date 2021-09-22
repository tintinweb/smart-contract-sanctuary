value: public(uint256)
seller: public(address)
buyer: public(address)
unlocked: public(bool)
ended: public(bool)

@external
@payable
def __init__():
  assert (msg.value % 2) == 0
  # The seller initializes the contract by posting a safety deposit of 2*value
  self.value = msg.value / 2
  self.seller = msg.sender
  self.unlocked = True

@external
def abort():
  # Is the contract still refundable
  assert self.unlocked
  # Only the seller can refund his deposit before any buyer purchases the item
  assert msg.sender == self.seller
  selfdestruct(self.seller)

@external
@payable
def purchase():
  assert self.unlocked

  assert msg.value == (2*self.value)
  self.buyer = msg.sender
  self.unlocked = False

@external
def received():
  assert not self.unlocked

  assert msg.sender == self.buyer
  assert not self.ended

  self.ended = True
  selfdestruct(self.seller)