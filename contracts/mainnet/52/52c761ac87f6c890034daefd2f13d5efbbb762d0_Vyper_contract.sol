# @version 0.2.12
"""
@title Polymer
@license MIT
@author Original: Takayuki Jimba (@yudetamago), Editor: Polymer
@notice Polymer is the token used in the Polymer ecosystem.
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


event OwnerChange:
    owner: indexed(address)


event MinterChange:
    minter: indexed(address)


# Public variables
name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)

# Function variables
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
minter: public(address)
owner: public(address)


@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256, source: address):
    init_supply: uint256 = _supply * 10 ** _decimals
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.totalSupply = init_supply
    self.minter = source
    self.owner = msg.sender
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)


@external
def setOwner(_owner : address):
    """
    @notice Sets the owner
    @param _owner address The new owner
    """
    assert self.owner == msg.sender, "Staff Only"

    self.owner = _owner

    log OwnerChange(_owner)


@external
def setMinter(_minter : address):
    assert self.owner == msg.sender, "Staff Only"

    self.minter = _minter

    log MinterChange(_minter)


@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    # NOTE: vyper does not allow underflows
    #      so the following subtraction would revert on insufficient allowance
    if self.allowance[_from][msg.sender] != MAX_UINT256:
        self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def mint(_to: address, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.
         This encapsulates the modification of balances such that the
         proper events are emitted.
    @param _to The account that will receive the created tokens.
    @param _value The amount that will be created.
    """
    assert msg.sender == self.minter, "Seniors Only"
    assert _to != ZERO_ADDRESS
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)


@internal
def _burn(_from: address, _value: uint256):
    """
    @dev Internal function that burns an amount of the token of a given
         account.
    @param _from The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    assert _from != ZERO_ADDRESS
    self.totalSupply -= _value
    self.balanceOf[_from] -= _value
    log Transfer(_from, ZERO_ADDRESS, _value)


@external
def burn(_value: uint256):
    """
    @dev Burn an amount of the token of msg.sender.
    @param _value The amount that will be burned.
    """
    self._burn(msg.sender, _value)


@external
def burnFrom(_from: address, _value: uint256):
    """
    @dev Burn an amount of the token from a given account.
    @param _from The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    if self.allowance[_from][msg.sender] != MAX_UINT256:
        self.allowance[_from][msg.sender] -= _value
    self._burn(_from, _value)