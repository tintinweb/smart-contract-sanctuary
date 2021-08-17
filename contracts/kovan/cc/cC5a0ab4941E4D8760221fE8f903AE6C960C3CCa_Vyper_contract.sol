# @version ^0.2.15

# price_oracle.vy

from vyper.interfaces import ERC20

name: public(String[64])
owner: public(address)

chainlink_contract: public(address)

eth_usd: public(int128)
eth_usd_18: public(uint256)

last_update_time: public(uint256)
last_update_remote: public(bool)

SECS_MINUTE: constant(uint256) = 60
SECS_5M: constant(uint256) = 60 * 10
SECS_10M: constant(uint256) = 60 * 10
SECS_HOUR: constant(uint256) = 3600
SECS_DAY: constant(uint256) = 86400
SECS_WEEK: constant(uint256) = 86400 * 7
SECS_YEAR: constant(uint256) = 86400 * 365

event price_updated:
  time: uint256
  remote: bool

interface ChainLink:
  def latestAnswer() -> int128: view

@external
def __init__(_name:String[64]):
  self.name = _name
  self.owner = msg.sender

  self.eth_usd = (3100 * 10**8)
  self.eth_usd_18 = convert(self.eth_usd * (10 ** (18-8)),uint256)

  self.last_update_time = block.timestamp
  self.last_update_remote = False

@internal
def _update() -> bool:
  if self.chainlink_contract == ZERO_ADDRESS:
    self.eth_usd = (3100 * 10**8)
    self.eth_usd_18 = convert(self.eth_usd * (10 ** (18-8)),uint256)
    self.last_update_time = block.timestamp
    self.last_update_remote = False

    log price_updated(block.timestamp,False)

    return True

  # only update once every 5 minutes
  if self.last_update_remote == True:
    if (block.timestamp - self.last_update_time) < SECS_5M:
      return True

  self.eth_usd = ChainLink(self.chainlink_contract).latestAnswer()
  self.eth_usd_18 = convert(self.eth_usd * (10 ** (18-8)),uint256)
  self.last_update_time = block.timestamp
  self.last_update_remote = True

  log price_updated(block.timestamp,True)

  return True

@external
def update() -> bool:
  return self._update()

@external
def set_chainlink_contract(_addr:address) -> bool:
  assert msg.sender == self.owner, 'unauthorized'
  self.chainlink_contract = _addr
  self._update()
  return True