# @version ^0.2.15

# stable_token.vy

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

event MinterAdded:
  _address: indexed(address)

event MinterRemoved:
  _address: indexed(address)

name: public(String[64])
symbol: public(String[32])
decimals: public(int128)

balances: HashMap[address, uint256]
allowances: HashMap[address, HashMap[address, uint256]]

totalSupply: public(uint256)
minters: public(HashMap[address,bool])

@external
def __init__(_name:String[64], _symbol:String[32]):
  self.decimals = 18
  self.name = _name
  self.symbol = _symbol

  self.minters[msg.sender] = True
  self.balances[self] = 0

  log Transfer(ZERO_ADDRESS,self,0)

@view
@external
def balanceOf(_owner: address) -> uint256:
  return self.balances[_owner]

@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
  return self.allowances[_owner][_spender]

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

@external
def minterTransferFrom(_from:address,_to:address,_value:uint256) -> bool:
  assert self.minters[msg.sender], 'Unauthorized'
  self._transfer(_from,_to,_value)
  return True

@external
def mint(_to: address, _value: uint256) -> bool:
  assert self.minters[msg.sender], 'Unauthorized'
  assert _to != ZERO_ADDRESS

  self.totalSupply += _value
  self.balances[_to] += _value

  log Transfer(ZERO_ADDRESS, _to, _value)

  return True

@external
def burnFrom(_from: address, _value: uint256) -> bool:
  assert self.minters[msg.sender], 'Unauthorized'

  self.totalSupply -= _value
  self.balances[_from] -= _value

  log Transfer(_from, ZERO_ADDRESS, _value)

  return True

@external
def addMinter(_addr: address) -> bool:
  assert self.minters[msg.sender], 'Unauthorized'
  self.minters[_addr] = True

  log MinterAdded(_addr)

  return True

@external
def removeMinter(_addr: address) -> bool:
  assert self.minters[msg.sender], 'Unauthorized'
  self.minters[_addr] = False

  log MinterRemoved(_addr)

  return True