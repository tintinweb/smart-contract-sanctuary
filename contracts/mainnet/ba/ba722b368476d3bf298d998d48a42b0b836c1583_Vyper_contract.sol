# @version ^0.2.0

from vyper.interfaces import ERC20

implements: ERC20

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Minter:
    minter: indexed(address)
    rm: bool

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
minter: address
minters: HashMap[address, bool]


@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = _supply
    self.totalSupply = _supply
    self.minter = msg.sender
    self.minters[msg.sender] = True
    log Transfer(ZERO_ADDRESS, msg.sender, _supply)


@external
def addMinter(_minter : address) -> bool:
    assert _minter != ZERO_ADDRESS
    assert msg.sender == self.minter
    assert msg.sender != _minter
    assert self.minters[_minter] == False
    self.minters[_minter] = True
    log Minter(_minter, False)
    return True


@external
def rmMinter(_minter : address) -> bool:
    assert _minter != ZERO_ADDRESS
    assert msg.sender == self.minter
    assert msg.sender != _minter
    assert self.minters[_minter] == True
    self.minters[_minter] = False
    log Minter(_minter, True)
    return True


@external
def transfer(_to : address, _value : uint256) -> bool:
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def mint(_to: address, _value: uint256):
    assert self.minters[msg.sender] == True
    assert _to != ZERO_ADDRESS
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)


@internal
def _burn(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)


@external
def burn(_value: uint256):
    self._burn(msg.sender, _value)


@external
def burnFrom(_to: address, _value: uint256):
    self.allowance[_to][msg.sender] -= _value
    self._burn(_to, _value)