# @version ^0.2.11


interface IERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable



inicio: public(uint256)
id: public(int128)
id_to_address: public(HashMap[int128, address])
address_to_id: public(HashMap[address, int128])
stakes: public(HashMap[address, uint256])
address_to_timestamp: public(HashMap[address, uint256])
address_rewards: public(HashMap[address, uint256])
token_contract: public(address)
deadline: public(uint256)
rewards_per_second: public(uint256)
totalStaked: public(uint256)

@external
def __init__(stakingToken: address):
  self.token_contract = stakingToken
  self.inicio = block.timestamp
  self.deadline = 1621711800
  self.rewards_per_second = 11557*10**12
  self.id = 0

@internal
def addStaker(staker: address):
  self.id_to_address[self.id] = staker
  self.address_to_id[staker] = self.id
  self.id += 1

@internal
def removeStaker(id: int128):
  self.id_to_address[id] = empty(address)

@internal
def distributeRewards():

  for i in range(5):

    tiempo_actual: uint256 = block.timestamp

    _address: address = self.id_to_address[i]

    if _address != ZERO_ADDRESS:


      if block.timestamp > self.deadline:
        tiempo_actual = self.deadline

      tokens_antes_de_aplicar_porcentaje:uint256 = self.rewards_per_second*(self.address_to_timestamp[_address]-tiempo_actual)
      tokens_totales_escalados:uint256 = self.totalStaked*10**10
      porcentaje_escalado:uint256 = tokens_totales_escalados/self.stakes[_address]
      parte_entera:uint256 = porcentaje_escalado/10**10
      parte_fraccion:uint256 = porcentaje_escalado%10**10
      tokens_rewards: uint256 = (parte_entera+parte_fraccion)*(tokens_antes_de_aplicar_porcentaje/10**10)
      self.address_rewards[_address] += tokens_rewards
      self.address_to_timestamp[_address] = block.timestamp


@external
def staking(_amount: uint256):
  assert _amount > 0, 'You need to send funds'
  assert block.timestamp < self.deadline
  self.distributeRewards()
  IERC20(self.token_contract).transferFrom(msg.sender, self, _amount)

  if self.stakes[msg.sender] == 0:
    self.addStaker(msg.sender)
    self.stakes[msg.sender] = _amount
    self.address_to_timestamp[msg.sender] = block.timestamp

  else:
    self.stakes[msg.sender] += _amount

  self.totalStaked += _amount

@external
def unStaking():
  assert self.stakes[msg.sender] > 0, 'You havent staked yet'
  self.distributeRewards()
  IERC20(self.token_contract).transfer(msg.sender, self.stakes[msg.sender]+ self.address_rewards[msg.sender])
  self.totalStaked -= self.stakes[msg.sender]
  identificacion: int128 = self.address_to_id[msg.sender]
  self.removeStaker(identificacion)
  self.stakes[msg.sender] = empty(uint256)