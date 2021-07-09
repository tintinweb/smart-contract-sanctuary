#  @version ^0.2.11
from vyper.interfaces import ERC20

implements: ERC20

NAME: constant(String[64]) = "asmr.finance"
SYMBOL: constant(String[32]) = "ASMR"
DECIMALS: constant(uint256) = 18
SUPPLY: constant(uint256) = 100000 * 10 ** DECIMALS


event Transfer:
    sender: indexed(address)
    recipient: indexed(address)
    value: uint256


event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256


event Burn:
    sender: indexed(address)
    value: uint256


event ExemptionUpdate:
    recipient: indexed(address)
    status: bool


event AdminChange:
    admin: indexed(address)


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
totalSupply: public(uint256)

exempt: public(HashMap[address, bool])
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

admin: public(address)


@external
def __init__():
    self.name = NAME
    self.symbol = SYMBOL
    self.decimals = DECIMALS
    self.totalSupply = SUPPLY
    self.balanceOf[msg.sender] = SUPPLY
    log Transfer(ZERO_ADDRESS, msg.sender, SUPPLY)
    self.exempt[msg.sender] = True
    self.admin = msg.sender
    log ExemptionUpdate(msg.sender, True)
    log AdminChange(msg.sender)


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    self.balanceOf[_from] -= _value
    receives: uint256 = _value
    if not (self.exempt[_from] or self.exempt[_to]):
        tax: uint256 = receives * 3 / 1000
        receives -= tax
        self.totalSupply -= tax
        log Burn(_from, tax)
        log Transfer(_from, ZERO_ADDRESS, tax)
    self.balanceOf[_to] += receives
    log Transfer(_from, _to, receives)


@external
def updateExempt(_to: address, status: bool):
    """
    @notice
        Update fee on transfer status of address
    @param _to
        Address to change status
    @param status
        Whether address is exempt or not
    """
    assert msg.sender == self.admin
    self.exempt[_to] = status
    log ExemptionUpdate(_to, status)


@external
def updateAdmin(_to: address):
    """
    @notice
        Change admin
    @param _to
        Address of new admin
    """
    assert msg.sender == self.admin
    self.admin = _to
    log AdminChange(_to)


@external
def approve(spender: address, _value: uint256) -> bool:
    self.allowance[msg.sender][spender] = _value
    log Approval(msg.sender, spender, _value)
    return True


@external
def transfer(_to: address, _value: uint256) -> bool:
    self._transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    self.allowance[_from][msg.sender] -= _value
    self._transfer(_from, _to, _value)
    return True