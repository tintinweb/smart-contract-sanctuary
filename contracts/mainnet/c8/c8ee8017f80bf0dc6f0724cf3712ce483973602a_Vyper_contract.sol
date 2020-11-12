"""
                                   YFX
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    https://yfx.fund/
  
     YFXXT is an adverserial trading system for producing profits
       based on the actions of YFI, and other highly predictable
              smart contract auto-trading/staking systems.

    YYYYYYY       YYYYYYYFFFFFFFFFFFFFFFFFFFFFFXXXXXXX       XXXXXXX
    Y:::::Y       Y:::::YF::::::::::::::::::::FX:::::X       X:::::X
    Y:::::Y       Y:::::YF::::::::::::::::::::FX:::::X       X:::::X
    Y::::::Y     Y::::::YFF::::::FFFFFFFFF::::FX::::::X     X::::::X
    YYY:::::Y   Y:::::YYY  F:::::F       FFFFFFIXX:::::X   X:::::XXI
       Y:::::Y Y:::::Y     F:::::F                X:::::X X:::::X   
        Y:::::Y:::::Y      F::::::FFFFFFFFFF       X:::::X:::::X    
         Y:::::::::Y       F:::::::::::::::F        X:::::::::X     
          Y:::::::Y        F:::::::::::::::F        X:::::::::X     
           Y:::::Y         F::::::FFFFFFFFFF       X:::::X:::::X    
           Y:::::Y         F:::::F                X:::::X X:::::X   
           Y:::::Y         F:::::F             (XX:::::X   X:::::XX)
           Y:::::Y       FF:::::::FF           X::::::X     X::::::X
        YYYY:::::YYYY    F::::::::FF           X:::::X       X:::::X
        Y:::::::::::Y    F::::::::FF           X:::::X       X:::::X
        YYYYYYYYYYYYY    FFFFFFFFFFF           XXXXXXX       XXXXXXX


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

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)

# NOTE: By declaring `balanceOf` as public, vyper automatically generates a 'balanceOf()' getter
#       method to allow access to account balances.
#       The _KeyType will become a required parameter for the getter and it will return _ValueType.
#       See: https://vyper.readthedocs.io/en/v0.1.0-beta.8/types.html?highlight=getter#mappings
balanceOf: public(HashMap[address, uint256])
allowances: HashMap[address, HashMap[address, uint256]]
total_supply: uint256
minter: address


@external
def __init__():
    init_supply: uint256 = 1000 * 10 ** 18
    self.name = "YFX"
    self.symbol = "YFX"
    self.decimals = 18
    self.balanceOf[msg.sender] = init_supply
    self.total_supply = init_supply
    self.minter = msg.sender
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)


@view
@external
def totalSupply() -> uint256:
    """
    @dev Total number of tokens in existence.
    """
    return self.total_supply


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
def setMinter(_newMinter: address):
    """
    @dev Change the minter of tokens - useful for the farming contract.
    @param _newMinter The account of the new minter
    """
    assert msg.sender == self.minter
    self.minter = _newMinter

@external
def burnMintingKeys():
    """
    @dev Forever burn the keys to the minting capability, permanently locking the total supply
    """
    assert msg.sender == self.minter
    self.minter = ZERO_ADDRESS

@external
def mint(_to: address, _value: uint256):
    """
    @dev Mint an amount of the token and assigns it to an account.
         This encapsulates the modification of balances such that the
         proper events are emitted.
    @param _to The account that will receive the created tokens.
    @param _value The amount that will be created.
    """
    assert msg.sender == self.minter
    assert _to != ZERO_ADDRESS
    self.total_supply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)


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


@external
def burnFrom(_to: address, _value: uint256):
    """
    @dev Burn an amount of the token from a given account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    """
    self.allowances[_to][msg.sender] -= _value
    self._burn(_to, _value)