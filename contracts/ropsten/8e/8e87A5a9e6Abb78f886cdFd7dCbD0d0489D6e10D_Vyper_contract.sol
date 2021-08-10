# @version ^0.2.0

# Vault Contract

from vyper.interfaces import ERC20

name: public(String[64])
owner: public(address)

stablecoin_contract: public(address)

event position_opened:
  owner: address
  index: uint256
  credit: uint256

event position_closed:
  owner: address
  index: uint256

event credit_minted:
  owner: address
  index: uint256
  amount: uint256

event payment_applied:
  owner: address
  index: uint256
  amount: uint256

event position_repaid:
  owner: address
  index: uint256
  amount: uint256

struct Position:
  open: bool
  repaid: bool
  liquidated: bool
  owner: address
  asset_type: String[64]
  asset_token: address
  asset_amount: uint256
  asset_index: uint256
  credit_limit: uint256
  credit_minted: uint256
  debt_principal: uint256
  debt_interest: uint256
  amount_paid: uint256
  ctime: uint256

positions: public(HashMap[address, HashMap[uint256,Position]])
positions_indexes: public(HashMap[address,uint256])

balances: HashMap[address, uint256]
token_values: HashMap[address, uint256]

total_positions: public(uint256)
total_credit: public(uint256)
total_minted: public(uint256)
total_repaid: public(uint256)

interface StableCoin:
  def mint(_to:address,_value:uint256): nonpayable
  def transferFrom(_from:address,_to:address,_value:uint256): nonpayable

@external
def __init__(_name:String[64], _stablecoin_addr:address):
  self.name = _name
  self.owner = msg.sender
  self.stablecoin_contract = _stablecoin_addr

#
# open a new position
#
@external
def open_position(_token_addr:address, _amount:uint256) -> bool:
  assert self.token_values[_token_addr] > 0, 'Unsupported token'
  assert ERC20(_token_addr).transferFrom(msg.sender,self,_amount), 'Transfer failed'

  self.positions_indexes[msg.sender] += 1
  cur_index: uint256 = self.positions_indexes[msg.sender]

  asset_value: uint256 = (self.token_values[_token_addr] * _amount)

  self.positions[msg.sender][cur_index] = Position({
    open: True,
    repaid: False,
    liquidated: False,
    owner: msg.sender,
    asset_type: 'ERC20',
    asset_token: _token_addr,
    asset_amount: _amount,
    asset_index: 0,
    credit_limit: asset_value,
    credit_minted: 0,
    debt_principal: 0,
    debt_interest: 0,
    amount_paid: 0,
    ctime: block.timestamp,
  })

  self.balances[_token_addr] += _amount

  self.total_positions += 1
  self.total_credit += asset_value

  log position_opened(msg.sender,cur_index,asset_value)

  return True

#
# borrow against a position
#
@external
def borrow(_position_index:uint256, _amount:uint256) -> bool:
  assert msg.sender == self.positions[msg.sender][_position_index].owner, 'Unauthorized'
  assert not self.positions[msg.sender][_position_index].liquidated, 'Position liquidated'
  assert self.positions[msg.sender][_position_index].open, 'Position closed'

  avail_credit: uint256 = self.positions[msg.sender][_position_index].credit_limit
  avail_credit -= self.positions[msg.sender][_position_index].credit_minted

  assert _amount < avail_credit, 'Insufficient available credit'

  # mint
  StableCoin(self.stablecoin_contract).mint(msg.sender,_amount)

  self.positions[msg.sender][_position_index].credit_minted += _amount
  self.positions[msg.sender][_position_index].debt_principal += _amount

  self.total_minted += _amount

  log credit_minted(msg.sender,_position_index,_amount)

  return True

#
# apply a payment against an open position
#
@external
def payment(_position_index:uint256, _amount:uint256) -> bool:
  assert msg.sender == self.positions[msg.sender][_position_index].owner, 'Unauthorized'
  assert not self.positions[msg.sender][_position_index].liquidated, 'Position liquidated'
  assert not self.positions[msg.sender][_position_index].repaid, 'Position repaid'
  assert self.positions[msg.sender][_position_index].open, 'Position closed'

  # send pusd to pay down the debt
  StableCoin(self.stablecoin_contract).transferFrom(msg.sender,self,_amount)

  cur_amount: uint256 = _amount
  cur_interest: uint256 = self.positions[msg.sender][_position_index].debt_interest
  cur_principal: uint256 = self.positions[msg.sender][_position_index].debt_principal

  paid: uint256 = 0
  paid_interest: uint256 = 0
  paid_principal: uint256 = 0

  # pay interest
  if cur_interest > 0:
    if cur_amount >= cur_interest:
      cur_amount -= cur_interest
      paid_interest += cur_interest
      self.positions[msg.sender][_position_index].debt_interest = 0
    else:
      paid_interest += cur_amount
      self.positions[msg.sender][_position_index].debt_interest -= cur_amount

  # pay principal
  if cur_principal > 0:
    if cur_amount >= cur_principal:
      cur_amount -= cur_principal
      paid_principal += cur_principal
      self.positions[msg.sender][_position_index].debt_principal = 0
    else:
      paid_principal += cur_amount
      self.positions[msg.sender][_position_index].debt_principal -= cur_amount

  paid += paid_interest
  paid += paid_principal

  self.positions[msg.sender][_position_index].amount_paid += paid

  log payment_applied(msg.sender,_position_index,paid)

  # check if position was repaid
  if self.positions[msg.sender][_position_index].debt_principal == 0 and \
      self.positions[msg.sender][_position_index].debt_interest == 0:

    self.positions[msg.sender][_position_index].repaid = True
    log position_repaid(msg.sender,_position_index,self.positions[msg.sender][_position_index].credit_minted)

  return True

@external
def withdraw() -> bool:
  return True

@external
def heartbeat() -> bool:
  return True

@view
@external
def get_token_value(_token_addr:address) -> uint256:
  assert self.token_values[_token_addr] > 0, 'Unsupported token'
  return self.token_values[_token_addr]

@external
def set_token_value(_token_addr:address, _value:uint256) -> bool:
  assert msg.sender == self.owner, 'Unauthorized'
  self.token_values[_token_addr] = _value
  return True