# @version 0.2.12


from vyper.interfaces import ERC20


interface GaugeController:
    def vote_user_slopes(user: address, gauge: address) -> VotedSlope: view
    def last_user_vote(user: address, gauge: address) -> uint256: view
    def points_weight(gauge: address, time: uint256) -> Point: view
    def checkpoint_gauge(gauge: address): nonpayable


struct Point:
    bias: uint256
    slope: uint256

struct VotedSlope:
    slope: uint256
    power: uint256
    end: uint256


WEEK: constant(uint256) = 86400 * 7
GAUGE_CONTROLLER: constant(address) = 0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB
PRECISION: constant(uint256) = 10**18

gauge: public(address)
reward_token: public(address)

active_period: public(uint256)
reward_per_token: public(uint256)

last_user_claim: public(HashMap[address, uint256])


@external
def __init__(_gauge: address, _reward_token: address):
    """
    @notice Contract constructor
    @param _gauge Gauge address to incentivize
    @param _reward_token Incentive token address
    """
    self.gauge = _gauge
    self.reward_token = _reward_token
    self.active_period = block.timestamp / WEEK * WEEK


@internal
def _update_period() -> uint256:
    period: uint256 = self.active_period
    if block.timestamp >= period + WEEK:
        gauge: address = self.gauge
        period = block.timestamp / WEEK * WEEK
        GaugeController(GAUGE_CONTROLLER).checkpoint_gauge(gauge)
        slope: uint256 = GaugeController(GAUGE_CONTROLLER).points_weight(gauge, period).slope
        amount: uint256 = ERC20(self.reward_token).balanceOf(self)
        self.reward_per_token = amount * PRECISION / slope
        self.active_period = period

    return period


@external
def add_reward_amount(_amount: uint256) -> bool:
    """
    @notice Add reward tokens to the contract
    @dev Rewards are fully claimable at the beginning of the next epoch week, based
         on the result of current week's gauge weight vote. Rewards that are unclaimed
         by the end of the week are rolled over into the following week.
    @param _amount Amount of `reward_token` to transfer
    @return Success bool
    """
    self._update_period()
    assert ERC20(self.reward_token).transferFrom(msg.sender, self, _amount)

    return True


@external
def claim_reward(_user: address = msg.sender) -> uint256:
    """
    @notice Claim a reward for a gauge-weight vote
    @dev Rewards are only claimable for the current epoch week, based on the user's
         active gauge weight vote. The vote must have been made prior to the start
         of the current week. Rewards left unclaimed in a week are lost.
    @param _user User to claim for
    @return Amount of reward claimed
    """
    period: uint256 = self._update_period()
    amount: uint256 = 0
    if self.last_user_claim[_user] < period:
        self.last_user_claim[_user] = period
        gauge: address = self.gauge
        last_vote: uint256 = GaugeController(GAUGE_CONTROLLER).last_user_vote(_user, gauge)
        if last_vote < period:
            slope: uint256 = GaugeController(GAUGE_CONTROLLER).vote_user_slopes(_user, gauge).slope
            amount = slope * self.reward_per_token / PRECISION
            if amount > 0:
                assert ERC20(self.reward_token).transfer(_user, amount)

    return amount