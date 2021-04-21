# @version 0.2.4
# https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

interface Curve:
    def owner() -> address: view

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)

balanceOf: public(HashMap[address, uint256])
total_supply: uint256

@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256):
    init_supply: uint256 = _supply * 10 ** _decimals
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.total_supply = init_supply
 
@view
@external
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
    self.total_supply += _value
    self.balanceOf[_to] += _value
    return True


@external
def burnFrom(_to: address, _value: uint256) -> bool:
    self.total_supply -= _value
    self.balanceOf[_to] -= _value
    return True

@external
def approve(_spender : address, _value : uint256) -> bool:
    return True