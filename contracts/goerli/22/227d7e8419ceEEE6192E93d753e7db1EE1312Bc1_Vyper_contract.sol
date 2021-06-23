# @version ^0.2.12

"""
@title Arena Token
@author Arena.gl
@license MIT
@dev Based on https://github.com/vyperlang/vyper/blob/master/examples/tokens/ERC20.vy
     by Takayuki Jimba (@yudetamago)
"""


from vyper.interfaces import ERC20
implements: ERC20

#OWNERSHIP
owner: public(address)

event OwnershipTransferred:
    previousOwner: indexed(address)
    newOwner:      indexed(address)

#ERC20
name:        public(String[32])
symbol:      public(String[32])
decimals:    public(int128)
balanceOf:   public(HashMap[address, uint256])
allowance:   public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

event Transfer:
    sender:   indexed(address)
    receiver: indexed(address)
    value:    uint256

event Approval:
    owner:   indexed(address)
    spender: indexed(address)
    value:   uint256

#MINTING
mintingLocked: public(bool)

event MintingLocked: pass

##############################
#          MINTING           #
##############################

@external
def mint(_to: address, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.
    @param _to The account that will receive the created tokens.
    @param _value The amount that will be created.
    """
    assert not self.mintingLocked, "Minting is permanently locked."
    assert msg.sender == self.owner, "Only owner can mint."
    assert _to != ZERO_ADDRESS, "Invalid minting target."
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)

@external
def lockMinting() -> bool:
    """
    @dev Prevent all future minting. This operation can not be undone.
    @return True if the operation was successful.
    """

    assert msg.sender == self.owner, "Only owner can lock minting."
    assert not self.mintingLocked, "Minting is already locked."

    self.mintingLocked = True
    log MintingLocked()
    return True


#################################
#           OWNERSHIP           #
#################################
@external 
def transferOwnership(_newOwner: address):
    """
    @dev Allows the current owner to transfer control of the contract to a newOwner.
    @param _newOwner The address to transfer ownership to.
    """
    assert msg.sender == self.owner, "Only owner can change ownership of the contract."
    assert _newOwner != ZERO_ADDRESS, "Invalid owner."

    log OwnershipTransferred(msg.sender, _newOwner)
    self.owner = _newOwner


##############################
#          BURNING           #
##############################

@internal
def _burn(_account: address, _value: uint256):
    """
    @dev Internal function that burns an amount of the token of a given account.
    @param _account The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    assert _account != ZERO_ADDRESS
    self.totalSupply -= _value
    self.balanceOf[_account] -= _value
    log Transfer(_account, ZERO_ADDRESS, _value)


@external
def burn(_value: uint256):
    """
    @dev Burn an amount of the token of msg.sender.
    @param _value The amount that will be burned.
    """
    self._burn(msg.sender, _value)


@external
def burnFrom(_account: address, _value: uint256):
    """
    @dev Burn an amount of the token from a given account.
    @param _account The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    self.allowance[_account][msg.sender] -= _value
    self._burn(_account, _value)


##################################
#              ERC20             #
##################################
@external
def __init__(_initialSupply: uint256):
    """
    @dev Initializes this contract.
    """

    self.name = "Arena"
    self.symbol = "ARENA"
    self.totalSupply = _initialSupply
    self.decimals = 18

    self.balanceOf[msg.sender] = self.totalSupply
    self.owner = msg.sender

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