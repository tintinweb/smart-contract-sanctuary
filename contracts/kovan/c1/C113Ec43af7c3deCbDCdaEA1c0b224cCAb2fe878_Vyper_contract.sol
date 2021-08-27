# @version ^0.2.15

# vault_erc20.vy

from vyper.interfaces import ERC20

event position_opened:
  owner: address
  index: uint256
  credit: uint256

event position_closed:
  owner: address
  index: uint256

event position_liquidated:
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

event interest_transferred:
  amount: uint256

event principal_burned:
  amount: uint256

event punk_value_set:
  type: String[32]
  amount: uint256

name: public(String[64])
owner: public(address)
decimals: public(int128)

stablecoin_contract: public(address)
cryptopunks_contract: public(address)
dao_contract: public(address)
oracle_contract: public(address)

time_last_oracle_update: public(uint256)

apr_rate: public(uint256)
colaterallization_rate: public(uint256)
compounding_interval_secs: public(uint256)

SECS_MINUTE: constant(uint256) = 60
SECS_15M: constant(uint256) = 60 * 15
SECS_30M: constant(uint256) = 60 * 30
SECS_HOUR: constant(uint256) = 3600
SECS_DAY: constant(uint256) = 86400
SECS_WEEK: constant(uint256) = 86400 * 7
SECS_YEAR: constant(uint256) = 86400 * 365

struct Position:
  owner: address
  repaid: bool
  liquidated: bool
  asset_type: String[32]
  asset_token: address
  asset_amount: uint256
  asset_index: uint256
  asset_value: uint256
  asset_value_eth: uint256
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
total_liquidated: public(uint256)

punk_values: HashMap[String[32],uint256]
punk_values_usd: HashMap[String[32],uint256]
punk_dictionary: HashMap[uint256,String[32]]

tick_i: uint256
tick_chunk_size: uint256

interface StableCoin:
  def mint(_to:address,_value:uint256): nonpayable
  def transfer(_to:address,_value:uint256): nonpayable
  def minterTransferFrom(_from:address,_to:address,_value:uint256): nonpayable
  def burnFrom(_from: address,_value:uint256): nonpayable

interface Oracle:
  def update() -> bool: nonpayable
  def eth_usd() -> int128: view
  def eth_usd_18() -> uint256: view
  def last_update_time() -> uint256: view
  def last_update_remote() -> bool: view

interface CryptoPunks:
  def transferPunk(_to:address,_punk_index:uint256): nonpayable
  def punkIndexToAddress(_punk_index:uint256) -> address: nonpayable

@external
def __init__(_name:String[64],_stablecoin_addr:address,_cryptopunks_addr:address,_dao_addr:address,_oracle_addr:address):
  self.tick_i = 0
  self.tick_chunk_size = 500

  self.name = _name
  self.owner = msg.sender
  self.decimals = 18

  self.stablecoin_contract = _stablecoin_addr
  self.cryptopunks_contract = _cryptopunks_addr
  self.dao_contract = _dao_addr
  self.oracle_contract = _oracle_addr

  self.apr_rate = 2
  self.colaterallization_rate = 50
  self.compounding_interval_secs = SECS_HOUR

  # default values (in eth) for punk types
  self.punk_values['floor'] = 50 * 10**18
  self.punk_values['ape'] = 2000 * 10**18
  self.punk_values['alien'] = 4000 * 10**18

  # update price oracle
  Oracle(self.oracle_contract).update()
  eth_usd_18: uint256 = Oracle(self.oracle_contract).eth_usd_18()

  self.punk_values_usd['floor'] = (self.punk_values['floor'] * eth_usd_18)/(10**18)
  self.punk_values_usd['ape'] = (self.punk_values['ape'] * eth_usd_18)/(10**18)
  self.punk_values_usd['alien'] = (self.punk_values['alien'] * eth_usd_18)/(10**18)

  # define aliens
  for index in [635,2890,3100,3443,5822,5905,6089,7523,7804]:
    self.punk_dictionary[index] = 'alien'

  # define apes
  for index in [372,1021,2140,2243,2386,2460,2491,2711,2924,4156,4178,4464,5217,5314,5577,5795,6145,6915,6965,7191,8219,8498,9265,9280]:
    self.punk_dictionary[index] = 'ape'

@internal
def _update_oracle_pricing() -> bool:
  Oracle(self.oracle_contract).update()
  eth_usd_18: uint256 = Oracle(self.oracle_contract).eth_usd_18()

  self.punk_values_usd['floor'] = (self.punk_values['floor'] * eth_usd_18)/(10**18)
  self.punk_values_usd['ape'] = (self.punk_values['ape'] * eth_usd_18)/(10**18)
  self.punk_values_usd['alien'] = (self.punk_values['alien'] * eth_usd_18)/(10**18)

  return True

@external
def update_oracle_pricing() -> bool:
  self.time_last_oracle_update = block.timestamp
  self._update_oracle_pricing()
  return True

@external
def set_tick_chunk_size(_number:uint256) -> bool:
  assert msg.sender == self.owner, 'unauthorized'
  self.tick_chunk_size = _number
  return True

@external
def set_apr_rate(_number:uint256) -> bool:
  assert msg.sender == self.owner, 'unauthorized'
  self.apr_rate = _number
  return True

@external
def set_colaterallization_rate(_number:uint256) -> bool:
  assert msg.sender == self.owner, 'unauthorized'
  self.colaterallization_rate = _number
  return True

@external
def set_compounding_interval_secs(_number:uint256) -> bool:
  assert msg.sender == self.owner, 'unauthorized'
  self.compounding_interval_secs = _number
  return True

@external
def set_punk_value(_type:String[32],_amount_eth:uint256) -> bool:
  assert msg.sender == self.owner, 'unauthorized'
  assert self.punk_values[_type] > 0, 'invalid_punk_type'

  self.punk_values[_type] = _amount_eth
  log punk_value_set(_type,_amount_eth)

  self._update_oracle_pricing()

  return True

@view
@internal
def _get_punk_type(_punk_index:uint256) -> String[32]:
  assert _punk_index < 10000, 'invalid_punk'
  if self.punk_dictionary[_punk_index] == '':
    return "floor"
  return self.punk_dictionary[_punk_index]

@view
@internal
def _get_punk_value(_punk_index:uint256) -> uint256:
  assert _punk_index < 10000, 'invalid_punk'
  return self.punk_values[self._get_punk_type(_punk_index)]

@view
@internal
def _get_punk_value_usd(_punk_index:uint256) -> uint256:
  assert _punk_index < 10000, 'invalid_punk'
  return self.punk_values_usd[self._get_punk_type(_punk_index)]

@internal
def _get_punk_owner(_punk_index:uint256) -> address:
  owner_addr: address = CryptoPunks(self.cryptopunks_contract).punkIndexToAddress(_punk_index)
  return owner_addr

struct PunkInfo:
  index: uint256
  type: String[32]
  owner: address

@external
def get_punk_info(_punk_index:uint256) -> PunkInfo:
  assert _punk_index < 10000, 'invalid_punk'

  punk_info: PunkInfo = PunkInfo({
    index: _punk_index,
    type: self._get_punk_type(_punk_index),
    owner: self._get_punk_owner(_punk_index)
  })

  return punk_info

@view
@internal
def _get_collateralized_punk_value(_punk_index:uint256) -> uint256:
  assert _punk_index < 10000, 'invalid_punk'

  asset_value: uint256 = self._get_punk_value(_punk_index)
  colat_value: uint256 = ((asset_value * self.colaterallization_rate) / 100)

  return colat_value

@view
@internal
def _get_collateralized_punk_value_usd(_punk_index:uint256) -> uint256:
  assert _punk_index < 10000, 'invalid_punk'

  asset_value: uint256 = self._get_punk_value_usd(_punk_index)
  colat_value: uint256 = ((asset_value * self.colaterallization_rate) / 100)

  return colat_value

@external
def get_punk_owner(_punk_index:uint256) -> address:
  return self._get_punk_owner(_punk_index)

struct PositionPreview:
  punk_index: uint256
  punk_type: String[32]
  punk_value: uint256
  apr_rate: uint256
  colaterallization_rate: uint256
  credit_limit: uint256

@view
@external
def preview_position(_punk_index:uint256) -> PositionPreview:
  assert _punk_index < 10000, 'invalid_punk'

  preview: PositionPreview = PositionPreview({
    punk_index: _punk_index,
    punk_type: self._get_punk_type(_punk_index),
    punk_value: self._get_punk_value_usd(_punk_index),
    apr_rate: self.apr_rate,
    colaterallization_rate: self.colaterallization_rate,
    credit_limit: self._get_collateralized_punk_value_usd(_punk_index),
  })

  return preview

@external
def open_position(_punk_index:uint256) -> bool:
  assert _punk_index < 10000, 'invalid_punk'

  self._update_oracle_pricing()

  punk_owner: address = self._get_punk_owner(_punk_index)

  assert punk_owner == msg.sender, 'punk_not_owned'
  assert self.positions[msg.sender][_punk_index].time_created == 0, 'position_already_exists'

  asset_value_eth: uint256 = self._get_punk_value_usd(_punk_index)
  asset_value: uint256 = self._get_punk_value_usd(_punk_index)
  colat_value: uint256 = self._get_collateralized_punk_value_usd(_punk_index)

  # create position
  self.positions[msg.sender][_punk_index] = Position({
    owner: msg.sender,
    repaid: False,
    liquidated: False,
    asset_type: 'PUNK',
    asset_token: self.cryptopunks_contract,
    asset_amount: 1,
    asset_index: _punk_index,
    asset_value: asset_value,
    asset_value_eth: asset_value_eth,
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
  owner: address = self.positions_punks[_punk_index]
  return self.positions[owner][_punk_index]

@external
def borrow(_punk_index:uint256,_amount:uint256) -> bool:
  assert msg.sender == self.positions[msg.sender][_punk_index].owner, 'unauthorized'
  assert not self.positions[msg.sender][_punk_index].liquidated, 'position_liquidated'

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

  # transfer interest to dao
  if paid_interest > 0:
    StableCoin(self.stablecoin_contract).transfer(self.dao_contract,paid_interest)

    log interest_transferred(paid_interest)

  # burn principal payment
  if paid_principal > 0:
    StableCoin(self.stablecoin_contract).burnFrom(self,paid_principal)

    log principal_burned(paid_principal)

  return True

@external
def close_position(_punk_index:uint256) -> bool:
  assert msg.sender == self.positions[msg.sender][_punk_index].owner, 'unauthorized'
  assert not self.positions[msg.sender][_punk_index].liquidated, 'position_liquidated'
  assert self.positions[msg.sender][_punk_index].repaid, 'position_not_repaid'

  pos_owner: address = self.positions[msg.sender][_punk_index].owner
  pos_index: uint256 = self.positions[msg.sender][_punk_index].asset_index

  # transfer punk back to owner
  CryptoPunks(self.cryptopunks_contract).transferPunk(pos_owner,pos_index)

  self.positions[msg.sender][_punk_index] = empty(Position)
  self.positions_punks[_punk_index] = empty(address)

  log position_closed(msg.sender,_punk_index)

  return True

@internal
def _attempt_add_interest(_address:address,_punk_index:uint256) -> uint256:
  interest_base_amt: uint256 = (self.positions[_address][_punk_index].debt_principal)
  interest_base_amt += self.positions[_address][_punk_index].debt_interest
  if interest_base_amt == 0: return 0

  last_interest: uint256 = self.positions[_address][_punk_index].time_interest
  if last_interest == 0: return 0

  interest_per_year: uint256 = ((interest_base_amt * self.apr_rate) / 100)
  interest_per_second: uint256 = interest_per_year/SECS_YEAR

  time_difference_secs: uint256 = block.timestamp - last_interest

  if time_difference_secs > self.compounding_interval_secs:
    new_interest: uint256 = time_difference_secs * interest_per_second

    self.positions[_address][_punk_index].debt_interest += new_interest
    self.positions[_address][_punk_index].time_interest = block.timestamp

    log interest_added(_address,_punk_index,new_interest)

    return new_interest

  return 0

# update a position's health score
@internal
def _update_position_health_score(_address:address,punk_index:uint256) -> uint256:

  # @todo:
  # - calculate position health score
  # - if health score < threshold then mark position as {eligible_for_liquidation:true}

  return 0

# attempt to add liquidation flag to a position
@internal
def _attempt_liquidate(_address:address,punk_index:uint256) -> bool:
  return False

@internal
def _liquidate(_address:address,punk_index:uint256) -> bool:
  return False

# process a chunk of positions
@external
def tick() -> uint256:
  self._update_oracle_pricing()

  if self.tick_i > 9999: self.tick_i = 0

  loops: uint256 = 0
  found: uint256 = 0

  for i in range(9999):
    loops += 1
    if loops > self.tick_chunk_size: break

    _punk_index: uint256 = self.tick_i
    self.tick_i += 1

    if _punk_index > 9999:
      self.tick_i = 0
      continue

    if self.positions_punks[_punk_index] == empty(address):
      continue

    found += 1
    _address: address = self.positions_punks[_punk_index]

    # add interest
    self._attempt_add_interest(_address,_punk_index)

    # update health score after interest was added
    self._update_position_health_score(_address,_punk_index)

    # attempt liquidation
    self._attempt_liquidate(_address,_punk_index)

  return found