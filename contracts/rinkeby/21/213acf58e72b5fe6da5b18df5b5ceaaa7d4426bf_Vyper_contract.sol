# @version >=0.2.12

base: public(address)
owner: public(address)
uniswapRemove: public(address)

TRANSFERFROM_MID: constant(Bytes[4]) = method_id("transferFrom(address,address,uint256)")

interface StakeRewardPool:
    def initialize(_owner: address, _rewardsDistribution: address, _rewardsToken: address, _stakingToken: address, _rewardsDuration: uint256, _uniswapRemove: address): nonpayable
    def notifyRewardAmount(reward: uint256): nonpayable
    def updateRewardsDistribution(newRewardsDistribution: address): nonpayable

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

@external
def __init__(_base: address):
    self.base = _base
    self.owner = msg.sender
    self.uniswapRemove = 0x430f33353490b256D2fD7bBD9DaDF3BB7f905E78

@external
def setBaseContract(_base: address):
    assert msg.sender == self.owner, "Not owner"
    self.base = _base

@external
def setUniswapRemoveContract(_uniswapRemove: address):
    assert msg.sender == self.owner, "Not owner"
    self.uniswapRemove = _uniswapRemove

@external
def createNewContract(_rewardsToken: address, _stakingToken: address, _rewardsAmount: uint256, _rewardsDuration: uint256):
    _owner: address = msg.sender
    _rewardsDistribution: address = msg.sender
    pool: address = create_forwarder_to(self.base)
    StakeRewardPool(pool).initialize(msg.sender, self, _rewardsToken, _stakingToken, _rewardsDuration, self.uniswapRemove)
    self._safeTransferFrom(_rewardsToken, msg.sender, pool, _rewardsAmount)
    StakeRewardPool(pool).notifyRewardAmount(_rewardsAmount)
    StakeRewardPool(pool).updateRewardsDistribution(msg.sender)