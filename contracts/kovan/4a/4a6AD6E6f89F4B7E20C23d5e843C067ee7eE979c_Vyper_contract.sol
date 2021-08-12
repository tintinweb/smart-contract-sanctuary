# @version ^0.2.15

# vault_cryptopunks.vy

from vyper.interfaces import ERC20

name: public(String[64])
owner: public(address)

stablecoin_contract: public(address)
cryptopunks_contract: public(address)
dao_contract: public(address)

apr_percent: public(decimal)
collateral_percent: public(decimal)

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

event interest_added:
  owner: address
  index: uint256
  amount: uint256

event punk_value_set:
  type: String[32]
  amount: uint256

struct Position:
  owner: address
  open: bool
  repaid: bool
  liquidated: bool
  asset_type: String[32]
  asset_token: address
  asset_amount: uint256
  asset_index: uint256
  asset_value: uint256
  credit_limit: uint256
  credit_minted: uint256
  debt_principal: uint256
  debt_interest: uint256
  paid_principal: uint256
  paid_interest: uint256
  paid_total: uint256
  time_repaid: uint256
  time_deposited: uint256
  time_interest: uint256
  time_created: uint256

positions: HashMap[address,HashMap[uint256,Position]]
positions_punks: HashMap[uint256,address]

total_positions: public(uint256)
total_minted: public(uint256)
total_repaid: public(uint256)

punk_values: public(HashMap[String[32],uint256])
punk_dictionary: public(HashMap[uint256,String[32]])

interface StableCoin:
  def mint(_to:address,_value:uint256): nonpayable
  def minterTransferFrom(_from:address,_to:address,_value:uint256): nonpayable

interface CryptoPunks:
  def transferPunk(_to:address,_punk_index:uint256): nonpayable
  def punkIndexToAddress(_punk_index:uint256) -> address: nonpayable

@external
def __init__(_name:String[64],_stablecoin_addr:address,_cryptopunks_addr:address,_dao_addr:address):
  self.name = _name
  self.owner = msg.sender

  self.stablecoin_contract = _stablecoin_addr
  self.cryptopunks_contract = _cryptopunks_addr
  self.dao_contract = _dao_addr

  self.apr_percent = 0.02
  self.collateral_percent = 0.50

  # default values for punk types
  self.punk_values['floor'] = 100000
  self.punk_values['ape'] = 5000000
  self.punk_values['alien'] = 10000000

  # define aliens
  for index in [635,2890,3100,3443,5822,5905,6089,7523,7804]:
    self.punk_dictionary[index] = 'alien'

  # define apes
  for index in [372,1021,2140,2243,2386,2460,2491,2711,2924,4156,4178,4464,5217,5314,5577,5795,6145,6915,6965,7191,8219,8498,9265,9280]:
    self.punk_dictionary[index] = 'ape'

@external
def set_punk_value(_type:String[32],_amount:uint256) -> bool:
  assert msg.sender == self.owner, 'unauthorized'
  assert self.punk_values[_type] > 0, 'invalid_punk_type'

  self.punk_values[_type] = _amount

  log punk_value_set(_type,_amount)

  return True

@view
@internal
def _get_punk_type(_punk_index:uint256) -> String[32]:
  assert _punk_index < 10000, 'invalid_punk'
  if self.punk_dictionary[_punk_index] == '':
    return "floor"
  return self.punk_dictionary[_punk_index]

@view
@external
def get_punk_type(_punk_index:uint256) -> String[32]:
  return self._get_punk_type(_punk_index)

@view
@internal
def _get_punk_value(_punk_index:uint256) -> uint256:
  assert _punk_index < 10000, 'invalid_punk'
  return self.punk_values[self._get_punk_type(_punk_index)]

@view
@external
def get_punk_value(_punk_index:uint256) -> uint256:
  return self._get_punk_value(_punk_index)

@view
@internal
def _get_collateralized_punk_value(_punk_index:uint256) -> uint256:
  assert _punk_index < 10000, 'invalid_punk'

  asset_value: uint256 = self._get_punk_value(_punk_index)
  _colat_value: decimal = convert(asset_value,decimal) * self.collateral_percent
  colat_value: uint256 = convert(_colat_value,uint256)

  return colat_value

@internal
def add_interest(_address:address,_punk_index:uint256) -> bool:
  interest: uint256 = (self.positions[_address][_punk_index].debt_principal)
  interest += self.positions[_address][_punk_index].debt_interest

  _new_interest: decimal = convert(interest,decimal) * self.apr_percent
  new_interest: uint256 = convert(_new_interest,uint256)

  self.positions[_address][_punk_index].debt_interest += new_interest
  self.positions[_address][_punk_index].time_interest = block.timestamp

  log interest_added(_address,_punk_index,new_interest)

  return True

@internal
def _get_punk_owner(_punk_index:uint256) -> address:
  owner_addr: address = CryptoPunks(self.cryptopunks_contract).punkIndexToAddress(_punk_index)
  return owner_addr

@external
def get_punk_owner(_punk_index:uint256) -> address:
  return self._get_punk_owner(_punk_index)

struct PositionPreview:
  punk_index: uint256
  punk_type: String[32]
  punk_value: uint256
  apr_percent: decimal
  collateralization_ratio: decimal
  total_credit: uint256

@view
@external
def preview_position(_punk_index:uint256) -> PositionPreview:
  assert _punk_index < 10000, 'invalid_punk'

  return PositionPreview({
    punk_index: _punk_index,
    punk_type: self._get_punk_type(_punk_index),
    punk_value: self._get_punk_value(_punk_index),
    apr_percent: self.apr_percent,
    collateralization_ratio: self.collateral_percent,
    total_credit: self._get_collateralized_punk_value(_punk_index),
  })

@external
def open_position(_punk_index:uint256) -> bool:
  assert _punk_index < 10000, 'invalid_punk'

  punk_owner: address = self._get_punk_owner(_punk_index)
  assert punk_owner == msg.sender, 'punk_not_owned'
  assert self.positions[msg.sender][_punk_index].time_created == 0, 'position_already_exists'

  asset_value: uint256 = self._get_punk_value(_punk_index)
  colat_value: uint256 = self._get_collateralized_punk_value(_punk_index)

  # create position
  self.positions[msg.sender][_punk_index] = Position({
    owner: msg.sender,
    open: True,
    repaid: False,
    liquidated: False,
    asset_type: 'PUNK',
    asset_token: self.cryptopunks_contract,
    asset_amount: 1,
    asset_index: _punk_index,
    asset_value: asset_value,
    credit_limit: colat_value,
    credit_minted: 0,
    debt_principal: 0,
    debt_interest: 0,
    paid_principal: 0,
    paid_interest: 0,
    paid_total: 0,
    time_repaid: 0,
    time_deposited: 0,
    time_interest: 0,
    time_created: block.timestamp,
  })

  self.positions_punks[_punk_index] = msg.sender
  self.total_positions += 1

  log position_opened(msg.sender,_punk_index,colat_value)

  return True

@view
@external
def show_position(_punk_index:uint256) -> Position:
  return self.positions[msg.sender][_punk_index]

@external
def borrow(_punk_index:uint256,_amount:uint256) -> bool:
  assert msg.sender == self.positions[msg.sender][_punk_index].owner, 'unauthorized'
  assert not self.positions[msg.sender][_punk_index].liquidated, 'position_liquidated'
  assert self.positions[msg.sender][_punk_index].open, 'position_closed'

  punk_owner: address = self._get_punk_owner(_punk_index)
  assert punk_owner == self, 'punk_not_deposited'

  # updated deposited and interest timestamp if they don't exist
  if self.positions[msg.sender][_punk_index].time_deposited == 0:
    self.positions[msg.sender][_punk_index].time_deposited = block.timestamp

  if self.positions[msg.sender][_punk_index].time_interest == 0:
    self.positions[msg.sender][_punk_index].time_interest = block.timestamp

  # continue with lending logic
  avail_credit: uint256 = self.positions[msg.sender][_punk_index].credit_limit
  avail_credit -= self.positions[msg.sender][_punk_index].credit_minted

  assert _amount <= avail_credit, 'insufficient_credit'

  # mint stablecoin
  StableCoin(self.stablecoin_contract).mint(msg.sender,_amount)
  self.total_minted += _amount

  self.positions[msg.sender][_punk_index].credit_minted += _amount
  self.positions[msg.sender][_punk_index].debt_principal += _amount

  log credit_minted(msg.sender,_punk_index,_amount)

  return True

@external
def repay(_punk_index:uint256,_amount:uint256) -> bool:
  assert msg.sender == self.positions[msg.sender][_punk_index].owner, 'unauthorized'
  assert not self.positions[msg.sender][_punk_index].liquidated, 'position_liquidated'
  assert not self.positions[msg.sender][_punk_index].repaid, 'position_repaid'
  assert self.positions[msg.sender][_punk_index].open, 'position_closed'

  # send payment to vault
  StableCoin(self.stablecoin_contract).minterTransferFrom(msg.sender,self,_amount)

  self.total_repaid += _amount

  cur_amount: uint256 = _amount
  cur_interest: uint256 = self.positions[msg.sender][_punk_index].debt_interest
  cur_principal: uint256 = self.positions[msg.sender][_punk_index].debt_principal

  paid: uint256 = 0
  paid_interest: uint256 = 0
  paid_principal: uint256 = 0

  # pay interest
  if cur_interest > 0:
    if cur_amount >= cur_interest:
      cur_amount -= cur_interest
      paid_interest += cur_interest
      self.positions[msg.sender][_punk_index].debt_interest = 0
    else:
      paid_interest += cur_amount
      self.positions[msg.sender][_punk_index].debt_interest -= cur_amount

  # pay principal
  if cur_principal > 0:
    if cur_amount >= cur_principal:
      cur_amount -= cur_principal
      paid_principal += cur_principal
      self.positions[msg.sender][_punk_index].debt_principal = 0
    else:
      paid_principal += cur_amount
      self.positions[msg.sender][_punk_index].debt_principal -= cur_amount

  paid += paid_interest
  paid += paid_principal

  self.positions[msg.sender][_punk_index].paid_interest += paid_interest
  self.positions[msg.sender][_punk_index].paid_principal += paid_principal
  self.positions[msg.sender][_punk_index].paid_total += paid

  log payment_applied(msg.sender,_punk_index,paid)

  # check if position was repaid
  if self.positions[msg.sender][_punk_index].debt_principal == 0 and \
      self.positions[msg.sender][_punk_index].debt_interest == 0:

    self.positions[msg.sender][_punk_index].repaid = True
    self.positions[msg.sender][_punk_index].time_repaid = block.timestamp

    log position_repaid(msg.sender,_punk_index,self.positions[msg.sender][_punk_index].credit_minted)

  # todo: send `paid_principal` to stablecoin addr, burn
  # todo: send `paid_interest` to dao

  return True

@external
def close_position(_punk_index:uint256) -> bool:
  assert msg.sender == self.positions[msg.sender][_punk_index].owner, 'unauthorized'
  assert not self.positions[msg.sender][_punk_index].liquidated, 'position_liquidated'
  assert self.positions[msg.sender][_punk_index].repaid, 'position_not_repaid'
  assert self.positions[msg.sender][_punk_index].open, 'position_closed'

  pos_owner: address = self.positions[msg.sender][_punk_index].owner
  pos_index: uint256 = self.positions[msg.sender][_punk_index].asset_index

  # transfer punk back to owner
  CryptoPunks(self.cryptopunks_contract).transferPunk(pos_owner,pos_index)

  self.positions[msg.sender][_punk_index].open = False

  log position_closed(msg.sender,_punk_index)

  return True

# add interest, liquidate
@external
def heartbeat() -> bool:
  return True

# cleanup positions that never got deposited
@external
def cleanup() -> bool:
  return True