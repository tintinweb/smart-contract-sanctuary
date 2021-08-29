# @version ^0.2.15

# vault_erc20.vy

event contract_created:
  time: uint256

event lending_enabled_changed:
  value: bool
  time: uint256

event interest_enabled_changed:
  value: bool
  time: uint256

event position_opened:
  owner: address
  index: uint256
  value: uint256

event position_closed:
  owner: address
  index: uint256

event position_liquidated:
  owner: address
  index: uint256

event position_flagged:
  owner: address
  index: uint256

event position_unflagged:
  owner: address
  index: uint256

event position_asset_deposited:
  owner: address
  index: uint256
  value: uint256

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

event punk_value_set_eth:
  type: String[32]
  amount: uint256

event colaterallization_rate_changed:
  value: uint256

event compounding_interval_changed:
  value: uint256

event apr_rate_changed:
  value: uint256

event automatic_liquidation_changed:
  value: bool

event punk_transferred_out:
  owner: address
  index: uint256

name: public(String[64])
owner: public(address)

stablecoin_contract: public(address)
cryptopunks_contract: public(address)
dao_contract: public(address)
oracle_contract: public(address)
apr_rate: public(uint256)
colaterallization_rate: public(uint256)
compounding_interval_secs: public(uint256)
automatic_liquidation: public(bool)
lending_enabled: public(bool)
interest_enabled: public(bool)

SECS_MINUTE: constant(uint256) = 60
SECS_15M: constant(uint256) = 60 * 15
SECS_30M: constant(uint256) = 60 * 30
SECS_HOUR: constant(uint256) = 3600
SECS_DAY: constant(uint256) = 86400
SECS_WEEK: constant(uint256) = 86400 * 7
SECS_YEAR: constant(uint256) = 86400 * 365
SECS_STALE_POSITION_EXPIRES: constant(uint256) = SECS_HOUR

struct Position:
  owner: address
  repaid: bool
  liquidated: bool
  flagged: bool
  asset_type: String[32]
  asset_token: address
  asset_amount: uint256
  asset_index: uint256
  asset_value_usd: uint256
  asset_value_eth: uint256
  asset_deposited: bool
  credit_limit_usd: uint256
  credit_minted: uint256
  debt_principal: uint256
  debt_interest: uint256
  debt_total: uint256
  paid_principal: uint256
  paid_interest: uint256
  paid_total: uint256
  health_score: uint256
  health_score_100: uint256
  time_health_score: uint256
  time_repaid: uint256
  time_deposited: uint256
  time_interest: uint256
  time_created: uint256
  time_tick: uint256
  tick_count: uint256
  apr_rate: uint256

struct PunkInfo:
  index: uint256
  type: String[32]
  owner: address

struct Status:
  current_positions_open: uint256
  positions_opened: uint256
  positions_closed: uint256
  positions_repaid: uint256
  positions_flagged: uint256
  positions_liquidated: uint256
  positions_borrows: uint256
  assets_deposited: uint256
  payments_applied: uint256
  usd_mint_count: uint256
  usd_interest_added: uint256
  usd_interest_collected: uint256
  usd_principal_issued: uint256
  usd_principal_collected: uint256
  time_last_tick: uint256
  time_last_oracle: uint256

struct PositionPreview:
  asset_index: uint256
  asset_type: String[32]
  asset_value_eth: uint256
  asset_value_eth_human: uint256
  asset_value_usd: uint256
  asset_value_usd_human: uint256
  credit_limit_usd: uint256
  credit_limit_usd_human: uint256
  apr_rate: uint256

positions: public(HashMap[address,HashMap[uint256,Position]])
positions_punks: public(HashMap[uint256,address])
#positions_addresses: public(HashMap[address,uint256])

punk_values_eth: HashMap[String[32],uint256]
punk_values_usd: HashMap[String[32],uint256]
punk_dictionary: HashMap[uint256,String[32]]

tick_i: uint256
tick_chunk_size: uint256

status: public(Status)

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

@pure
@internal
def _percent_uint(part:uint256,whole:uint256) -> uint256:
  return (part*100)/whole

@pure
@internal
def _percent_of_uint(whole:uint256,percent:uint256) -> uint256:
  return (whole*percent)/100

@external
def __init__(_name:String[64],_stablecoin_addr:address,_cryptopunks_addr:address,_dao_addr:address,_oracle_addr:address):
  self.tick_i = 0
  self.tick_chunk_size = 500

  self.name = _name
  self.owner = msg.sender

  self.stablecoin_contract = _stablecoin_addr
  self.cryptopunks_contract = _cryptopunks_addr
  self.dao_contract = _dao_addr
  self.oracle_contract = _oracle_addr

  self.lending_enabled = True
  self.apr_rate = 2
  self.colaterallization_rate = 33
  self.compounding_interval_secs = SECS_30M
  self.automatic_liquidation = False

  # default values (in eth) for punk types
  self.punk_values_eth['floor'] = 50 * 10**18
  self.punk_values_eth['ape'] = 2000 * 10**18
  self.punk_values_eth['alien'] = 4000 * 10**18

  # update price oracle
  Oracle(self.oracle_contract).update()
  eth_usd_18: uint256 = Oracle(self.oracle_contract).eth_usd_18()

  self.punk_values_usd['floor'] = (self.punk_values_eth['floor'] * eth_usd_18)/(10**18)
  self.punk_values_usd['ape'] = (self.punk_values_eth['ape'] * eth_usd_18)/(10**18)
  self.punk_values_usd['alien'] = (self.punk_values_eth['alien'] * eth_usd_18)/(10**18)

  # define aliens
  for index in [635,2890,3100,3443,5822,5905,6089,7523,7804]:
    self.punk_dictionary[index] = 'alien'

  # define apes
  for index in [372,1021,2140,2243,2386,2460,2491,2711,2924,4156,4178,4464,5217,5314,5577,5795,6145,6915,6965,7191,8219,8498,9265,9280]:
    self.punk_dictionary[index] = 'ape'

  log contract_created(block.timestamp)

@view
@external
def show_status() -> Status:
  return self.status

@internal
def _update_oracle_pricing() -> bool:
  Oracle(self.oracle_contract).update()
  eth_usd_18: uint256 = Oracle(self.oracle_contract).eth_usd_18()

  self.punk_values_usd['floor'] = (self.punk_values_eth['floor'] * eth_usd_18)/(10**18)
  self.punk_values_usd['ape'] = (self.punk_values_eth['ape'] * eth_usd_18)/(10**18)
  self.punk_values_usd['alien'] = (self.punk_values_eth['alien'] * eth_usd_18)/(10**18)

  self.status.time_last_oracle = block.timestamp

  return True

@external
def update_oracle_pricing() -> bool:
  self._update_oracle_pricing()
  return True

@external
def set_tick_chunk_size(_number:uint256) -> bool:
  assert msg.sender == self.owner
  self.tick_chunk_size = _number
  return True

@external
def set_apr_rate(_number:uint256) -> bool:
  assert msg.sender == self.owner
  assert _number < 100
  assert _number > 0

  self.apr_rate = _number
  log apr_rate_changed(_number)
  return True

@external
def set_colaterallization_rate(_number:uint256) -> bool:
  assert msg.sender == self.owner
  assert _number < 100
  assert _number > 0

  self.colaterallization_rate = _number
  log colaterallization_rate_changed(_number)
  return True

@external
def set_compounding_interval_secs(_number:uint256):
  assert msg.sender == self.owner

  self.compounding_interval_secs = _number
  log compounding_interval_changed(_number)

@external
def set_automatic_liquidation(_enabled:bool):
  assert msg.sender == self.owner

  self.automatic_liquidation = _enabled
  log automatic_liquidation_changed(_enabled)

@external
def set_lending_enabled(_enabled:bool):
  assert msg.sender == self.owner

  self.lending_enabled = _enabled
  log lending_enabled_changed(_enabled,block.timestamp)

@external
def set_interest_enabled(_enabled:bool):
  assert msg.sender == self.owner

  self.interest_enabled = _enabled
  log interest_enabled_changed(_enabled,block.timestamp)

@external
def set_punk_value_eth(_type:String[32],_amount_eth:uint256):
  assert msg.sender == self.owner
  assert self.punk_values_eth[_type] > 0

  self.punk_values_eth[_type] = _amount_eth
  self._update_oracle_pricing()
  log punk_value_set_eth(_type,_amount_eth)

@view
@internal
def _get_punk_type(_punk_index:uint256) -> String[32]:
  assert _punk_index < 10000

  if self.punk_dictionary[_punk_index] == '': return 'floor'
  return self.punk_dictionary[_punk_index]

@view
@internal
def _get_punk_value_eth(_punk_index:uint256) -> uint256:
  assert _punk_index < 10000
  return self.punk_values_eth[self._get_punk_type(_punk_index)]

@view
@internal
def _get_punk_value_usd(_punk_index:uint256) -> uint256:
  assert _punk_index < 10000
  return self.punk_values_usd[self._get_punk_type(_punk_index)]

@internal
def _get_punk_owner(_punk_index:uint256) -> address:
  assert _punk_index < 10000

  owner_addr: address = CryptoPunks(self.cryptopunks_contract).punkIndexToAddress(_punk_index)
  return owner_addr

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
def _get_collateralized_punk_value_eth(_punk_index:uint256) -> uint256:
  assert _punk_index < 10000, 'invalid_punk'

  asset_value_eth: uint256 = self._get_punk_value_eth(_punk_index)
  colat_value_eth: uint256 = self._percent_of_uint(asset_value_eth,self.colaterallization_rate)

  return colat_value_eth

@view
@internal
def _get_collateralized_punk_value_usd(_punk_index:uint256) -> uint256:
  assert _punk_index < 10000, 'invalid_punk'

  asset_value_usd: uint256 = self._get_punk_value_usd(_punk_index)
  colat_value_usd: uint256 = self._percent_of_uint(asset_value_usd,self.colaterallization_rate)

  return colat_value_usd

@external
def get_punk_owner(_punk_index:uint256) -> address:
  return self._get_punk_owner(_punk_index)

@view
@external
def preview_position(_punk_index:uint256) -> PositionPreview:
  assert _punk_index < 10000, 'invalid_punk'
  assert self.lending_enabled, 'lending_disabled'

  pos_preview: PositionPreview = PositionPreview({
    asset_index: _punk_index,
    asset_type: self._get_punk_type(_punk_index),
    asset_value_eth: self._get_punk_value_eth(_punk_index),
    asset_value_eth_human: self._get_punk_value_eth(_punk_index)/(10**18),
    asset_value_usd: self._get_punk_value_usd(_punk_index),
    asset_value_usd_human: self._get_punk_value_usd(_punk_index)/(10**18),
    credit_limit_usd: self._get_collateralized_punk_value_usd(_punk_index),
    credit_limit_usd_human: self._get_collateralized_punk_value_usd(_punk_index)/(10**18),
    apr_rate: self.apr_rate
  })

  return pos_preview

@external
@nonreentrant('lock')
def open_position(_punk_index:uint256):
  assert _punk_index < 10000, 'invalid_punk'
  assert self.lending_enabled, 'lending_disabled'

  punk_owner: address = self._get_punk_owner(_punk_index)

  assert punk_owner == msg.sender
  assert self.positions[msg.sender][_punk_index].time_created == 0, 'position_already_exists'

  self._update_oracle_pricing()

  asset_value_eth: uint256 = self._get_punk_value_eth(_punk_index)
  asset_value_usd: uint256 = self._get_punk_value_usd(_punk_index)

  colat_value_eth: uint256 = self._get_collateralized_punk_value_eth(_punk_index)
  colat_value_usd: uint256 = self._get_collateralized_punk_value_usd(_punk_index)

  # create position
  self.positions[msg.sender][_punk_index] = Position({
    owner: msg.sender,
    repaid: False,
    liquidated: False,
    flagged: False,
    asset_type: 'PUNK',
    asset_token: self.cryptopunks_contract,
    asset_amount: 1,
    asset_index: _punk_index,
    asset_value_usd: asset_value_usd,
    asset_value_eth: asset_value_eth,
    asset_deposited: False,
    credit_limit_usd: colat_value_usd,
    credit_minted: 0,
    debt_principal: 0,
    debt_interest: 0,
    debt_total: 0,
    paid_principal: 0,
    paid_interest: 0,
    paid_total: 0,
    health_score: 0,
    health_score_100: 0,
    time_health_score: 0,
    time_repaid: 0,
    time_deposited: 0,
    time_interest: 0,
    time_created: block.timestamp,
    time_tick: 0,
    tick_count: 0,
    apr_rate: self.apr_rate,
  })

  pos: Position = self.positions[msg.sender][_punk_index]

  self.positions_punks[_punk_index] = msg.sender

  self.status.current_positions_open += 1
  self.status.positions_opened += 1

  log position_opened(msg.sender,_punk_index,colat_value_usd)

# update a position's health score
@internal
def _update_position_health_score(_address:address,_punk_index:uint256):
  position: Position = self.positions[_address][_punk_index]

  health_score: uint256 = self._percent_uint(position.debt_total,position.asset_value_usd)
  health_score_100: uint256 = (health_score * 100)/self.colaterallization_rate

  self.positions[_address][_punk_index].health_score = health_score
  self.positions[_address][_punk_index].health_score_100 = health_score_100
  self.positions[_address][_punk_index].time_health_score = block.timestamp

@view
@external
def show_position(_punk_index:uint256) -> Position:
  owner: address = self.positions_punks[_punk_index]
  return self.positions[owner][_punk_index]

@external
@nonreentrant('lock')
def borrow(_punk_index:uint256,_amount:uint256):
  assert self.lending_enabled, 'lending_disabled'
  assert msg.sender == self.positions[msg.sender][_punk_index].owner
  assert not self.positions[msg.sender][_punk_index].liquidated

  punk_owner: address = self._get_punk_owner(_punk_index)
  assert punk_owner == self

  self._update_position_health_score(msg.sender,_punk_index)

  # update deposited and interest timestamp if they don't exist
  if self.positions[msg.sender][_punk_index].time_deposited == 0:
    self.positions[msg.sender][_punk_index].time_deposited = block.timestamp
    self.positions[msg.sender][_punk_index].asset_deposited = True

    self.status.assets_deposited += 1

    log position_asset_deposited(msg.sender,_punk_index,self.positions[msg.sender][_punk_index].asset_value_usd)

  if self.positions[msg.sender][_punk_index].time_interest == 0:
    self.positions[msg.sender][_punk_index].time_interest = block.timestamp

  # continue with lending logic
  avail_credit: uint256 = self.positions[msg.sender][_punk_index].credit_limit_usd
  avail_credit -= self.positions[msg.sender][_punk_index].credit_minted

  assert _amount <= avail_credit, 'insufficient_credit'

  # mint stablecoin
  StableCoin(self.stablecoin_contract).mint(msg.sender,_amount)

  self.positions[msg.sender][_punk_index].credit_minted += _amount
  self.positions[msg.sender][_punk_index].debt_principal += _amount
  self.positions[msg.sender][_punk_index].debt_total += _amount

  self.status.usd_mint_count += 1
  self.status.usd_principal_issued += _amount
  self.status.positions_borrows += 1

  # make sure this is marked as non-repaid in case the user borrowed against
  # a position that they repaid on at one time in the past
  self.positions[msg.sender][_punk_index].repaid = False

  log credit_minted(msg.sender,_punk_index,_amount)

@external
@nonreentrant('lock')
def repay(_punk_index:uint256,_amount:uint256):
  assert msg.sender == self.positions[msg.sender][_punk_index].owner
  assert not self.positions[msg.sender][_punk_index].liquidated, 'position_liquidated'
  assert not self.positions[msg.sender][_punk_index].repaid, 'position_repaid'

  # send payment to vault
  StableCoin(self.stablecoin_contract).minterTransferFrom(msg.sender,self,_amount)

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

  if self.positions[msg.sender][_punk_index].debt_total > 0:
    self.positions[msg.sender][_punk_index].debt_total -= paid

  self.status.payments_applied += 1

  log payment_applied(msg.sender,_punk_index,paid)

  # check if position was repaid
  if self.positions[msg.sender][_punk_index].debt_total == 0:
    self.positions[msg.sender][_punk_index].repaid = True
    self.positions[msg.sender][_punk_index].time_repaid = block.timestamp

    self.status.positions_repaid += 1

    log position_repaid(msg.sender,_punk_index,self.positions[msg.sender][_punk_index].credit_minted)

  # transfer interest to dao
  if paid_interest > 0:
    StableCoin(self.stablecoin_contract).transfer(self.dao_contract,paid_interest)

    self.status.usd_interest_collected += paid_interest

    log interest_transferred(paid_interest)

  # burn principal payment
  if paid_principal > 0:
    StableCoin(self.stablecoin_contract).burnFrom(self,paid_principal)

    self.status.usd_principal_collected += paid_principal

    log principal_burned(paid_principal)

  self._update_position_health_score(msg.sender,_punk_index)

@external
@nonreentrant('lock')
def close_position(_punk_index:uint256):
  assert msg.sender == self.positions[msg.sender][_punk_index].owner
  assert not self.positions[msg.sender][_punk_index].liquidated, 'position_liquidated'
  assert self.positions[msg.sender][_punk_index].repaid, 'position_not_repaid'

  pos_owner: address = self.positions[msg.sender][_punk_index].owner
  pos_index: uint256 = self.positions[msg.sender][_punk_index].asset_index

  # transfer punk back to owner
  CryptoPunks(self.cryptopunks_contract).transferPunk(pos_owner,pos_index)

  log punk_transferred_out(pos_owner,pos_index)

  self.positions[msg.sender][_punk_index] = empty(Position)
  self.positions_punks[_punk_index] = empty(address)

  self.status.current_positions_open -= 1
  self.status.positions_closed += 1

  log position_closed(msg.sender,_punk_index)

@internal
def _attempt_add_interest(_address:address,_punk_index:uint256) -> uint256:
  if not self.interest_enabled: return 0

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
    self.positions[_address][_punk_index].debt_total += new_interest
    self.positions[_address][_punk_index].time_interest = block.timestamp

    self.status.usd_interest_added += new_interest

    log interest_added(_address,_punk_index,new_interest)

    return new_interest

  return 0

@internal
def _attempt_flag(_address:address,_punk_index:uint256) -> bool:
  position: Position = self.positions[_address][_punk_index]

  if position.health_score > self.colaterallization_rate:
    if not position.flagged:
      self.positions[_address][_punk_index].flagged = True

      self.status.positions_flagged += 1

      log position_flagged(_address,_punk_index)
      return True

  if position.flagged:
    self.positions[_address][_punk_index].flagged = False

    self.status.positions_flagged -= 1

    log position_unflagged(_address,_punk_index)
    return False

  return position.flagged

@internal
@nonreentrant('lock')
def _attempt_liquidate(_address:address,_punk_index:uint256,manual:bool=False,forced:bool=False) -> bool:
  assert self.positions[_address][_punk_index] != empty(Position), 'position_noexists'

  # only allow manual liquidations
  if not self.automatic_liquidation:
    if not manual or not forced: return False

  if not forced:
    assert self.positions[_address][_punk_index].flagged, 'position_not_flagged'

  # perform liquidation
  CryptoPunks(self.cryptopunks_contract).transferPunk(self.dao_contract,_punk_index)

  log punk_transferred_out(_address,_punk_index)

  self.positions[_address][_punk_index] = empty(Position)
  self.positions_punks[_punk_index] = empty(address)

  self.status.current_positions_open -= 1
  self.status.positions_liquidated += 1

  log position_liquidated(_address,_punk_index)

  return True

@external
@nonreentrant('lock')
def liquidate(_punk_index:uint256):
  assert msg.sender == self.owner

  pos_owner: address = self.positions_punks[_punk_index]

  # force liquidation
  self._attempt_liquidate(pos_owner,_punk_index,True,True)

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

    # update health score
    self._update_position_health_score(_address,_punk_index)

    # attempt liquidation
    if self._attempt_flag(_address,_punk_index):
      self._attempt_liquidate(_address,_punk_index,False)

    # add tick metrics
    self.positions[_address][_punk_index].time_tick = block.timestamp
    self.positions[_address][_punk_index].tick_count += 1

  self.status.time_last_tick = block.timestamp

  return found