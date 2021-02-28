addressToInitialisationStatus: public(HashMap[address, bool])
# @author usernameistakenistaken
# The following portion of code is modified from Takayuki Jimba's example voting contract (@yudetamago) (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md)

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
init_bal: public(uint256)

# NOTE: By declaring `balanceOf` as public, vyper automatically generates a 'balanceOf()' getter
#       method to allow access to account balances.
#       The _KeyType will become a required parameter for the getter and it will return _ValueType.
#       See: https://vyper.readthedocs.io/en/v0.1.0-beta.8/types.html?highlight=getter#mappings
addressToBalance: (HashMap[address, uint256])
allowances: HashMap[address, HashMap[address, uint256]]
total_supply: uint256
minter: address


@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256):
    init_supply: uint256 = _supply * 10 ** _decimals
    self.init_bal = 100 * (10 ** _decimals)
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.total_supply = init_supply
    log Transfer(ZERO_ADDRESS, msg.sender, 100 * 10 ** _decimals)


@view
@internal
def _getBalance(_to: address) -> uint256:
	if (self.addressToInitialisationStatus[_to]):
		return self.addressToBalance[_to]
	else:
		return (self.init_bal + self.addressToBalance[_to])

@view
@external
def balanceOf(_to: address) -> uint256:
	return self._getBalance(_to)

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
    if self.addressToInitialisationStatus[msg.sender]:
    	self.addressToBalance[msg.sender] -= _value
    	self.addressToBalance[_to] += _value
    else:
    	self.addressToBalance[msg.sender] += self.init_bal
    	self.addressToBalance[msg.sender] -= _value
    	self.addressToBalance[_to] += _value
    	self.addressToInitialisationStatus[msg.sender] = True
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
    if self.addressToInitialisationStatus[_from]:
    	self.addressToBalance[_from] -= _value
    	self.addressToBalance[_to] += _value
    else:
    	self.addressToBalance[_from] += self.init_bal
    	self.addressToBalance[_from] -= _value
    	self.addressToBalance[_to] += _value
    	self.addressToInitialisationStatus[_from] = True
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