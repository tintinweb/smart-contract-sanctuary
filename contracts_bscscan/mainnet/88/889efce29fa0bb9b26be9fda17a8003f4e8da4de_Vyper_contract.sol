# @version ^0.2.15
"""
@title EGG ERC20 token
@author Waves Exchange Team
@license MIT
"""


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

event CommitOwnership:
    owner: address

event ApplyOwnership:
    owner: address


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

minter: public(address)
owner: public(address)
futureOwner: public(address)


@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals

    init_supply: uint256 = _supply * 10 ** _decimals
    self.balanceOf[msg.sender] = init_supply
    self.totalSupply = init_supply
    self.minter = ZERO_ADDRESS
    self.owner = msg.sender

    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)


@external
def setName(_name: String[32], _symbol: String[8]):
    assert msg.sender == self.owner, "owner only"
    self.name = _name
    self.symbol = _symbol


@external
def transfer(_recipient : address, _value : uint256) -> bool:
    assert _recipient != ZERO_ADDRESS, "recipient is zero address"

    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_recipient] += _value
    log Transfer(msg.sender, _recipient, _value)
    return True


@external
def transferFrom(_sender : address, _recipient : address, _value : uint256) -> bool:
    assert _sender != ZERO_ADDRESS, "sender is zero address"
    assert _recipient != ZERO_ADDRESS, "recipient is zero address"

    self.balanceOf[_sender] -= _value
    self.balanceOf[_recipient] += _value

    _allowance: uint256 = self.allowance[_sender][msg.sender]
    if _allowance != MAX_UINT256:
        self.allowance[_sender][msg.sender] = _allowance - _value
    
    log Transfer(_sender, _recipient, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    assert _value == 0 or self.allowance[msg.sender][_spender] == 0, "already approved"
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def setMinter(_minter: address):
    assert msg.sender == self.owner, "owner only"
    self.minter = _minter


@external
def mint(account: address, amount: uint256) -> bool:
    assert msg.sender == self.minter, "minter only"
    assert account != ZERO_ADDRESS, "zero address"

    self.totalSupply += amount
    self.balanceOf[account] += amount
    log Transfer(ZERO_ADDRESS, account, amount)
    
    return True


@external
def burn(amount: uint256) -> bool:
    self.totalSupply -= amount
    self.balanceOf[msg.sender] -= amount
    log Transfer(msg.sender, ZERO_ADDRESS, amount)

    return True


@external
def transferOwnership(_futureOwner: address):
    assert msg.sender == self.owner, "owner only"
    self.futureOwner = _futureOwner
    log CommitOwnership(_futureOwner)


@external
def applyOwnership():
    assert msg.sender == self.owner, "owner only"
    _owner: address = self.futureOwner
    assert _owner != ZERO_ADDRESS, "owner not set"
    self.owner = _owner
    log ApplyOwnership(_owner)