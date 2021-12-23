storedData: public(uint256)

@public
def __init__(_x: uint256):
  self.storedData = _x

@public
def set(_x: uint256):
  self.storedData = _x