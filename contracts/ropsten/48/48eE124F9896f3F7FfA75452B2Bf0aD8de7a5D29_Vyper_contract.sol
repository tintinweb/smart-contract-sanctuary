# @version ^0.2.0

# Vault Contract

from vyper.interfaces import ERC20

event TokenSet:
    contract: address
    value: uint256

event Deposit:
    sender: address
    contract: address
    amount: uint256

name: public(String[64])
symbol: public(String[32])
owner: public(address)
balances: HashMap[address, uint256]
tokenValues: HashMap[address, uint256]
stablecoinContract: public(address)

interface StableCoin:
  def mint(_to:address,_value:uint256): nonpayable

@external
def __init__(_name:String[64], _symbol:String[32], _stablecoin_addr:address):
    self.name = _name
    self.symbol = _symbol
    self.stablecoinContract = _stablecoin_addr
    self.owner = msg.sender

@external
def deposit(_token_addr: address, _amount: uint256) -> bool:
    assert self.tokenValues[_token_addr] > 0, 'Token unsupported'
    assert ERC20(_token_addr).transferFrom(msg.sender,self,_amount), 'Transfer failed'

    self.balances[_token_addr] += _amount
    log Deposit(msg.sender,_token_addr,_amount)

    StableCoin(self.stablecoinContract).mint(msg.sender,(self.tokenValues[_token_addr] * _amount))

    return True

@view
@external
def balanceOf(_token_addr: address) -> uint256:
    return self.balances[_token_addr]

@view
@external
def getTokenValue(_token_addr:address) -> uint256:
  assert self.tokenValues[_token_addr] > 0, 'Token unsupported'
  return self.tokenValues[_token_addr]

@external
def setTokenValue(_token_addr:address, _value:uint256) -> bool:
    assert msg.sender == self.owner, 'Unauthorized'

    self.tokenValues[_token_addr] = _value
    log TokenSet(_token_addr,_value)

    return True