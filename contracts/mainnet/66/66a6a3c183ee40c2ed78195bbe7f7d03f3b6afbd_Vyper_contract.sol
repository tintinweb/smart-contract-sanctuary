# Contract created by Oswald Castro y Riverberg
# https://www.oswaldriverberg.com/ or https://www.oswaldriverberg.art/
# 34% contract ownership is representative of artwork onwership on a FIFO basis.
# Artwork details: La Vanille Bourbon - Plantation Paralels
# An introspection on the impact of climate change on one of the most expensive spices in the world.
# In 2017, vanilla crops of Madagascar were damaged by tropical cyclones which skyrocketed the prices
# of the commodity and led to the emergence of a crime wave targeting vanilla farmers.
# Oswald Castro y Riverberg,
# Madagascar, 2019
# Acrylic on canvas
# 75cm by 40cm,  29.13in. by 15.74 in.
#
# Ownership threshold:
# 34% of $LVB maximum supply (102,000 LVB) is required for the smart contract to authenticate an automatic transfer of ownership.

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

owner: public(address)
newOwner: address

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
max_supply: public(uint256)
ownership_threshold: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowances: HashMap[address, HashMap[address, uint256]]
total_supply: uint256
minter: address


@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256, _max_supply: uint256, _ownership_threshold: uint256):
    init_supply: uint256 = _supply * 10 ** _decimals
    self.owner = msg.sender
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.total_supply = init_supply
    self.max_supply = _max_supply * 10 ** _decimals
    self.ownership_threshold = (_max_supply * _ownership_threshold / 100) * 10 ** _decimals
    self.minter = msg.sender
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)


@view
@external
def totalSupply() -> uint256:
    """
    @dev Total number of tokens in existence.
    """
    return self.total_supply

@external
def ownershipTransfer(_newOwner: address):
    """
    @def Function to transfer ownership to a new address after crossing a defined threshold
    """
    assert msg.sender != self.owner, "You are already the owner."
    assert _newOwner != ZERO_ADDRESS, "Invalid address."
    if self.balanceOf[_newOwner] >= self.ownership_threshold:
        self.minter = _newOwner
        self.owner = _newOwner
    else:
        raise "Insufficient Balance for Ownership transfer."

@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    """
    @dev Function to check the amount of tokens that an owner allowed to a spender.
    @param _owner The address which owns the funds.
    @param _spender The address which will spend the funds.
    @return An uint256 specifying the amount of tokens still available for the spender.
    """
    return self.allowances[_owner][_spender]

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
    self.allowances[_from][msg.sender] -= _value
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
    self.allowances[msg.sender][_spender] = _value
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
    if (self.total_supply + _value) <= self.max_supply:
        assert msg.sender == self.minter
        assert _to != ZERO_ADDRESS, "Invalid Address."
        self.total_supply += _value
        self.balanceOf[_to] += _value
        log Transfer(ZERO_ADDRESS, _to, _value)
    else:
        raise "Unable to mint over the stipulated max supply."


@internal
def _burn(_to: address, _value: uint256):
    """
    @dev Internal function that burns an amount of the token of a given
         account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    assert _to != ZERO_ADDRESS
    self.total_supply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)


@external
def burn(_value: uint256):
    """
    @dev Burn an amount of the token of msg.sender.
    @param _value The amount that will be burned.
    """
    self._burn(msg.sender, _value)