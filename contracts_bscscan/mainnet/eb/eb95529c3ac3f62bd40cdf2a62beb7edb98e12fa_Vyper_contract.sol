# @version ^0.2.16

from vyper.interfaces import ERC20

implements: ERC20


event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
totalSupply: public(uint256)
owner: public(address)
minter: public(address)


balances: HashMap[address, uint256]
allowances: HashMap[address, HashMap[address, uint256]]


@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _total_supply: uint256):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balances[msg.sender] = _total_supply
    self.owner = msg.sender
    self.minter = msg.sender
    self.totalSupply = _total_supply
    log Transfer(ZERO_ADDRESS, msg.sender, _total_supply)


@view
@external
def balanceOf(_owner: address) -> uint256:
    return self.balances[_owner]


@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    return self.allowances[_owner][_spender]


@external
def setOwner(_owner : address) -> bool:
    assert msg.sender == self.owner, 'You are not current owner'
    self.owner = _owner
    return True


@external
def setMinter(_minter : address) -> bool:
    assert msg.sender == self.minter, 'You are not current minter'
    self.minter = _minter
    return True


@external
def mint() -> bool:
    assert msg.sender == self.minter, 'You are not current minter'
    self.balances[self.owner] += 1000000000000000000
    self.totalSupply += 1000000000000000000
    log Transfer(ZERO_ADDRESS, self.owner, 1000000000000000000)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    assert self.balances[_from] >= _value, "Insufficient balance"
    self.balances[_from] -= _value
    self.balances[_to] += _value
    log Transfer(_from, _to, _value)


@external
def transfer(_to : address, _value : uint256) -> bool:
    self._transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    assert self.allowances[_from][msg.sender] >= _value, "Insufficient allowance"
    self.allowances[_from][msg.sender] -= _value
    self._transfer(_from, _to, _value)
    return True