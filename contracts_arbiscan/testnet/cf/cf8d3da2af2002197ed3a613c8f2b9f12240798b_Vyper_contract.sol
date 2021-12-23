storedData: public(uint256)
@external
def __init__(_x: uint256):
  self.storedData = _x
@external
def set(_x: uint256):
  self.storedData = _x