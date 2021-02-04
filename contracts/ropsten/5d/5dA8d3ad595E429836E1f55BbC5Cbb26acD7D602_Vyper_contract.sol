# @version ^0.2.0

state: public(uint256)

@external
def __init__(_val: uint256):
  self.state = _val

@external
def set(_val: uint256):
  self.state = _val

@external
@view
def get() -> uint256:
  return self.state