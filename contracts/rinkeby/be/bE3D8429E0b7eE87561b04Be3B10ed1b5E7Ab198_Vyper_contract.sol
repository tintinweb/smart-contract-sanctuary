# @version ^0.2.0

"""
@notice Mock ERC20 for testing
"""

from vyper.interfaces import ERC20

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowances: HashMap[address, HashMap[address, uint256]]
total_supply: uint256

underlying_token: ERC20
getPricePerFullShare: public(uint256)


@external
def __init__(
    _name: String[64],
    _symbol: String[32],
    _decimals: uint256,
    _underlying_token: address,
    _exchange_rate: uint256
):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.underlying_token = ERC20(_underlying_token)
    self.getPricePerFullShare = _exchange_rate


@external
@view
def totalSupply() -> uint256:
    return self.total_supply


@external
@view
def allowance(_owner : address, _spender : address) -> uint256:
    return self.allowances[_owner][_spender]


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
    self.allowances[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


# yERC20-specific functions
@external
def deposit(depositAmount: uint256):
    """
     @notice Sender supplies assets into the market and receives yTokens in exchange
     @dev Accrues interest whether or not the operation succeeds, unless reverted
     @param depositAmount The amount of the underlying asset to supply
    """
    self.underlying_token.transferFrom(msg.sender, self, depositAmount)
    value: uint256 = depositAmount * 10 ** 18 / self.getPricePerFullShare
    self.total_supply += value
    self.balanceOf[msg.sender] += value


@external
def withdraw(withdrawTokens: uint256):
    """
     @notice Sender redeems yTokens in exchange for the underlying asset
     @dev Accrues interest whether or not the operation succeeds, unless reverted
     @param withdrawTokens The number of yTokens to redeem into underlying
    """
    uvalue: uint256 = withdrawTokens * self.getPricePerFullShare / 10 ** 18
    self.balanceOf[msg.sender] -= withdrawTokens
    self.total_supply -= withdrawTokens
    self.underlying_token.transfer(msg.sender, uvalue)


# testing functions
@external
def _set_exchange_rate(_rate: uint256):
    self.getPricePerFullShare = _rate


@external
def _mint_for_testing(_to: address, _value: uint256):
    self.total_supply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)