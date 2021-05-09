# @version ^0.2.11



interface IERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def allowance(arg0: address, arg1: address) -> uint256: view

event Staking:
  sender: indexed(address)


event Unstaking:
  sender: indexed(address)

timestamp_inicio: HashMap[address, uint256]
timestamp_final: HashMap[address,uint256]
funds_per_address: public(HashMap[address, uint256])
address_per_id: public(HashMap[uint256, address])
id_per_address: HashMap[address, uint256]
reward_per_address: public(HashMap[address, uint256])
tokenA_contract: public(address)
deadline: public(uint256)
total_rewards: public(uint256)
daily_rewards: public(uint256)
amount_staked: public(uint256)
tokens_per_second: public(uint256)
id: uint256

@external
def __init__(token_address: address, _daily_reward:uint256, _total_rewards: uint256):
  self.tokenA_contract = token_address
  self.deadline = block.timestamp + 259200
  self.daily_rewards = _daily_reward
  self.total_rewards = _total_rewards
  self.tokens_per_second = self.daily_rewards/86400
  self.id = 1


@external
def stake(_amount: uint256) -> bool:
  assert block.timestamp < self.deadline, 'time is over'

  for i in range(1, 10):
    _address:address = self.address_per_id[i]
    tiempo_transcurrido: uint256 = block.timestamp - self.timestamp_inicio[_address]
    porcentaje_pool: uint256= self.funds_per_address[msg.sender]/self.amount_staked
    self.reward_per_address[_address] = porcentaje_pool*tiempo_transcurrido*self.tokens_per_second
    self.timestamp_inicio[_address] = block.timestamp

  if self.id_per_address[msg.sender] == 0:

    assert _amount > 0, 'Error staking amount'
    assert IERC20(self.tokenA_contract).allowance(msg.sender, self) >= _amount, 'contract not allowed'
    IERC20(self.tokenA_contract).transferFrom(msg.sender, self, _amount)
    self.address_per_id[self.id] = msg.sender
    self.funds_per_address[msg.sender] = _amount
    self.id_per_address[msg.sender] = self.id
    self.id += 1
    self.amount_staked += _amount
    self.timestamp_inicio[msg.sender] = block.timestamp
    log Staking(msg.sender)
    return True

  else:
    assert _amount > 0, 'Error staking amount'
    IERC20(self.tokenA_contract).transferFrom(msg.sender, self, _amount)
    self.funds_per_address[msg.sender] += _amount
    self.amount_staked += _amount
    log Staking(msg.sender)
    return True


@external
def unstake() -> bool:
  assert self.funds_per_address[msg.sender] > 0, "You dont have staked coins"
  for i in range(1, 10):
    _address: address = self.address_per_id[i]
    tiempo_transcurrido: uint256 = block.timestamp - self.timestamp_inicio[_address]
    porcentaje_pool: uint256 = self.funds_per_address[msg.sender]/self.amount_staked
    self.reward_per_address[_address] = porcentaje_pool*tiempo_transcurrido*self.tokens_per_second
    self.timestamp_inicio[_address] = block.timestamp

  IERC20(self.tokenA_contract).transfer(msg.sender, (self.funds_per_address[msg.sender] + self.reward_per_address[msg.sender]))
  self.amount_staked -= self.funds_per_address[msg.sender]
  self.funds_per_address[msg.sender] = 0

  log Unstaking(msg.sender)
  return True