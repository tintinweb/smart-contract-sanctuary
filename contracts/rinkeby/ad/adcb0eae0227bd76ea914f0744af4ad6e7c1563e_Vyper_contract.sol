# @version 0.2.4

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)

balanceOf: public(HashMap[address, uint256])
total_supply: uint256

minter: public(address)
admin: public(address)

@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
 
@external
@view
def totalSupply() -> uint256:
    return self.total_supply

@external
def transfer(_to : address, _value : uint256) -> bool:
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    return True

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    return True

@external
def mint(_to: address, _value: uint256) -> bool:
    _total_supply: uint256 = self.total_supply + _value
    self.total_supply = _total_supply
    self.balanceOf[_to] += _value
    return True

@external
def burn(_value: uint256) -> bool:
    self.balanceOf[msg.sender] -= _value
    self.total_supply -= _value
    return True

@external
def approve(_spender : address, _value : uint256) -> bool:
    return True