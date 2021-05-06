# @version >=0.2.12

rewardsToken: public(address)
stakingToken: public(address)
periodFinish: public(uint256)
rewardRate: public(uint256)
rewardsDuration: public(uint256)
lastUpdateTime: public(uint256)
rewardPerTokenStored: public(uint256)
rewardsDistribution: public(address)
owner: public(address)
uniswapRemove: public(address)
userRewardPerTokenPaid: public(HashMap[address, uint256])
rewards: public(HashMap[address, uint256])

totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])

_uniswapRemoveFee: uint256

APPROVE_MID: constant(Bytes[4]) = method_id("approve(address,uint256)")
TRANSFERFROM_MID: constant(Bytes[4]) = method_id("transferFrom(address,address,uint256)")
TRANSFER_MID: constant(Bytes[4]) = method_id("transfer(address,uint256)")
VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE

interface ERC20:
    def balanceOf(_account: address) -> uint256: view

interface IUniswapRemove:
    def divestUniPairToToken(pair: address, token: address, amount: uint256, minTokenAmount: uint256) -> uint256: payable

event Staked:
    user: indexed(address)
    amount: uint256

event Withdrawn:
    user: indexed(address)
    amount: uint256

event RewardPaid:
    user: indexed(address)
    reward: uint256

event RewardAdded:
    reward: uint256

event Recovered:
    token: address
    amount: uint256

event RewardsDurationUpdated:
    newDuration: uint256

@external
def initialize(_owner: address, _rewardsDistribution: address, _rewardsToken: address, _stakingToken: address, _rewardsDuration: uint256, _uniswapRemove: address):
    assert self.owner == ZERO_ADDRESS
    self.owner = _owner
    self.rewardsToken = _rewardsToken
    self.stakingToken = _stakingToken
    self.rewardsDistribution = _rewardsDistribution
    self.rewardsDuration = _rewardsDuration
    self.uniswapRemove = _uniswapRemove
    self._uniswapRemoveFee = 5 * 10 ** 15

@external
def __init__(_owner: address, _rewardsDistribution: address, _rewardsToken: address, _stakingToken: address, _rewardsDuration: uint256, _uniswapRemove: address):
    self.owner = _owner
    self.rewardsToken = _rewardsToken
    self.stakingToken = _stakingToken
    self.rewardsDistribution = _rewardsDistribution
    self.rewardsDuration = _rewardsDuration
    self.uniswapRemove = _uniswapRemove
    self._uniswapRemoveFee = 5 * 10 ** 15

# VIEW FUNCTIONS

@internal
@view
def _lastTimeRewardApplicable() -> uint256:
    _periodFinish: uint256 = self.periodFinish
    if block.timestamp > _periodFinish:
        return _periodFinish
    else:
        return block.timestamp

@external
@view
def lastTimeRewardApplicable() -> uint256:
    return self._lastTimeRewardApplicable()

@internal
@view
def _rewardPerToken() -> uint256:
    _totalSupply: uint256 = self.totalSupply
    if _totalSupply == 0:
        return self.rewardPerTokenStored
    return (self.rewardPerTokenStored + self._lastTimeRewardApplicable() - self.lastUpdateTime) * self.rewardRate * 10 ** 18 / _totalSupply

@external
@view
def rewardPerToken() -> uint256:
    return self._rewardPerToken()

@internal
@view
def _earned(account: address) -> uint256:
    return (self.balanceOf[account] * self._rewardPerToken() - self.userRewardPerTokenPaid[account]) / 10 ** 18 + self.rewards[account]

@external
@view
def earned(account: address) -> uint256:
    return self._earned(account)

@external
@view
def getRewardForDuration() -> uint256:
    return self.rewardRate * self.rewardsDuration

@internal
def _safeTransferFrom(_token: address, _from: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            TRANSFERFROM_MID,
            convert(_from, bytes32),
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed transferFrom
    if len(_response) > 0:
        assert convert(_response, bool), "TransferFrom failed"  # dev: failed transferFrom

@internal
def _updateReward(account: address):
    self.rewardPerTokenStored = self._rewardPerToken()
    self.lastUpdateTime = self._lastTimeRewardApplicable()
    if account != ZERO_ADDRESS:
        self.rewards[account] = self._earned(account)
        self.userRewardPerTokenPaid[account] = self.rewardPerTokenStored

# User functions

@external
@nonreentrant('lock')
def stake(amount: uint256):
    assert amount > 0, "Cannot stake 0"
    self._updateReward(msg.sender)
    self.totalSupply += amount
    self.balanceOf[msg.sender] += amount
    self._safeTransferFrom(self.stakingToken, msg.sender, self, amount)
    log Staked(msg.sender, amount)

@internal
def _safeTransfer(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            TRANSFER_MID,
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed transfer
    if len(_response) > 0:
        assert convert(_response, bool), "Transfer failed"  # dev: failed transfer

@internal
def _withdraw(amount: uint256, withdrawer: address):
    assert amount > 0, "Cannot withdraw 0"
    assert block.timestamp > self.periodFinish, "Not finished yet"
    self._updateReward(withdrawer)
    self.totalSupply -= amount
    self.balanceOf[withdrawer] -= amount
    self._safeTransfer(self.stakingToken, withdrawer, amount)
    log Withdrawn(withdrawer, amount)

@external
@nonreentrant('lock')
def withdraw(amount: uint256):
    self._withdraw(amount, msg.sender)

@internal
def _getReward(sender: address):
    self._updateReward(sender)
    reward: uint256 = self.rewards[sender]
    if reward > 0:
        self.rewards[sender] = 0
        self._safeTransfer(self.rewardsToken, sender, reward)
        log RewardPaid(sender, reward)

@external
@nonreentrant('lock')
def getReward():
    self._getReward(msg.sender)

@external
@nonreentrant('lock')
def exit():
    self._withdraw(self.balanceOf[msg.sender], msg.sender)
    self._getReward(msg.sender)

@internal
def _safeApprove(_token: address, _spender: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            APPROVE_MID,
            convert(_spender, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed approve
    if len(_response) > 0:
        assert convert(_response, bool), "Approve failed"  # dev: failed approve

@external
@nonreentrant('lock')
@payable
def withdrawToToken(amount: uint256, token: address, minTokenAmount: uint256):
    fee: uint256 = self._uniswapRemoveFee
    _stakingToken: address = self.stakingToken
    _uniswapRemove: address = self.uniswapRemove
    if msg.value > fee:
        send(msg.sender, msg.value - fee)
    else:
        assert msg.value == fee, "Insufficient fee for UniswapRemove"
    self._withdraw(amount, self)
    self._safeApprove(_stakingToken, _uniswapRemove, amount)
    retAmount: uint256 = IUniswapRemove(_uniswapRemove).divestUniPairToToken(_stakingToken, token, amount, minTokenAmount, value=fee)
    if token == ZERO_ADDRESS or token == VETH:
        send(msg.sender, retAmount)
    else:
        self._safeTransfer(token, msg.sender, retAmount)

@external
@nonreentrant('lock')
@payable
def exitToToken(token: address, minTokenAmount: uint256):
    fee: uint256 = self._uniswapRemoveFee
    _balance: uint256 = self.balanceOf[msg.sender]
    _stakingToken: address = self.stakingToken
    _uniswapRemove: address = self.uniswapRemove
    if msg.value > fee:
        send(msg.sender, msg.value - fee)
    else:
        assert msg.value == fee, "Insufficient fee for UniswapRemove"
    self._withdraw(_balance, self)
    self._safeApprove(_stakingToken, _uniswapRemove, _balance)
    retAmount: uint256 = IUniswapRemove(_uniswapRemove).divestUniPairToToken(_stakingToken, token, _balance, minTokenAmount, value=fee)
    if token == ZERO_ADDRESS or token == VETH:
        send(msg.sender, retAmount)
    else:
        self._safeTransfer(token, msg.sender, retAmount)

# Restricted Functions

@external
def notifyRewardAmount(reward: uint256):
    assert msg.sender == self.rewardsDistribution, "Not RewardDistribution"
    self._updateReward(ZERO_ADDRESS)
    _periodFinish: uint256 = self.periodFinish
    _rewardsDuration: uint256 = self.rewardsDuration
    if block.timestamp >= _periodFinish:
        self.rewardRate = reward / _rewardsDuration
    else:
        self.rewardRate = (reward + (_periodFinish - block.timestamp) * self.rewardRate) / _rewardsDuration
    
    _balance: uint256 = ERC20(self.rewardsToken).balanceOf(self)
    assert self.rewardRate <= _balance / _rewardsDuration, "Reward too high"
    self.lastUpdateTime = block.timestamp
    self.periodFinish = block.timestamp + _rewardsDuration
    log RewardAdded(reward)

@external
def updateRewardsDistribution(newRewardsDistribution: address):
    _rewardsDistribution: address = self.rewardsDistribution
    assert msg.sender == _rewardsDistribution, "Not RewardsDistribution"
    assert _rewardsDistribution != newRewardsDistribution, "Same address"
    self.rewardsDistribution = newRewardsDistribution
    

@external
def updatePeriodFinish(_timestamp: uint256):
    assert msg.sender == self.owner, "Not owner"
    self._updateReward(ZERO_ADDRESS)
    self.periodFinish = _timestamp

@external
def recoverERC20(token: address, amount: uint256):
    _owner: address = self.owner
    assert msg.sender == _owner, "Not owner"
    assert token != self.stakingToken, "Cannot withdraw staking token"
    self._safeTransfer(token, _owner, amount)
    log Recovered(token, amount)

@external
def setRewardsDuration(_rewardsDuration: uint256):
    assert msg.sender == self.owner, "Not owner"
    assert block.timestamp > self.periodFinish, "Not finished yet"
    self.rewardsDuration = _rewardsDuration
    log RewardsDurationUpdated(_rewardsDuration)