# @version >=0.2.7 <0.3.0

stored_data: public(uint256)

event MonEvent: 
  message: String[30]
  arg1: uint256

@external
def __init__():
    self.stored_data = 10

@external
def set(_x: uint256):
    self.stored_data = _x

@external
@view
def get() -> uint256:
    return self.stored_data

@external
def mafonction(param: uint256) -> uint256:
    assert param<100, "valeur doit etre inf 100"
    log MonEvent("coucou",2)
    return param + 10