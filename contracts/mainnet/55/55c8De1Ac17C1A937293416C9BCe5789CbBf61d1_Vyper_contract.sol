# @version 0.3.0
# @author bulbozaur <[email protected]>
# @notice A manager contract for the Balancer Merkle Rewards contract.

# @license MIT

from vyper.interfaces import ERC20


interface IMerkleRewardsContract:
    def createDistribution(token: address, merkleRoot: bytes32, amount: uint256, distributionId: uint256): nonpayable


event OwnerChanged:
    previous_owner: indexed(address)
    new_owner: indexed(address)


event BalancerDistributorChanged:
    previous_balancer_distributor: indexed(address)
    new_balancer_distributor: indexed(address)


event RewardsManagerChanged:
    previous_rewards_manager: indexed(address)
    new_rewards_manager: indexed(address)


event RewardsDistributed:
    amount: uint256


event ERC20TokenRecovered:
    token: indexed(address)
    amount: uint256
    recipient: indexed(address)


event AccountedAllowanceUpdated:
    new_allowance: uint256


event AccountedIterationStartDateUpdated:
    accounted_iteration_start_date: uint256


event RemainingIterationsUpdated:
    remaining_iterations: uint256


event RewardsRateUpdated:
    rewards_rate_per_iteration: uint256


event PeriodStarted:
    iterations: uint256
    start_date: uint256
    rewards_rate_per_iteration: uint256


event Paused:
    actor: indexed(address)


event Unpaused:
    actor: indexed(address)


owner: public(address)
balancer_distributor: public(address)
rewards_manager: public(address)

rewards_contract: constant(address) = 0xdAE7e32ADc5d490a43cCba1f0c736033F2b4eFca
rewards_token: constant(address) = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32

iteration_duration: constant(uint256) = 604800     # 3600 * 24 * 7  (1 week)
rewards_iterations: constant(uint256) = 4          # number of iterations in one rewards period

accounted_iteration_start_date: public(uint256)
accounted_allowance: public(uint256)

remaining_iterations: public(uint256)        # number of iterations left for current rewards period
rewards_rate_per_iteration: public(uint256)

is_paused: public(bool)
is_initialized: public(bool)


@external
def __init__(
    _balancer_distributor: address,
    _rewards_manager: address,
    _start_date: uint256
):
    self.owner = msg.sender
    self.balancer_distributor = _balancer_distributor
    self.rewards_manager = _rewards_manager

    self.accounted_allowance = 0    # allowance at accounted_iteration_start_date
    self.accounted_iteration_start_date = _start_date - iteration_duration

    self.is_paused = False
    self.is_initialized = False

    self.rewards_rate_per_iteration = 0

    log OwnerChanged(ZERO_ADDRESS, self.owner)
    log BalancerDistributorChanged(ZERO_ADDRESS, self.balancer_distributor)
    log RewardsManagerChanged(ZERO_ADDRESS, self.rewards_manager)
    log Unpaused(self.owner)
    log AccountedAllowanceUpdated(self.accounted_allowance)
    log AccountedIterationStartDateUpdated(self.accounted_iteration_start_date)
    log RemainingIterationsUpdated(0)


@internal
@view
def _period_finish() -> uint256:
    """
    @notice Date of last allowance increasing.
    """
    return self.accounted_iteration_start_date + self.remaining_iterations * iteration_duration


@internal
@view
def _is_rewards_period_finished() -> bool:
    return block.timestamp >= self._period_finish()


@internal
@view
def _unaccounted_iterations() -> uint256:
    """
    @notice Number of full iterations from last accounted iteration 
    """
    accounted_iteration_start_date: uint256 = self.accounted_iteration_start_date
    if (accounted_iteration_start_date > block.timestamp):
        return 0
    return (block.timestamp - accounted_iteration_start_date) / iteration_duration


@internal
@view
def _available_allowance() -> uint256:
    if self.is_paused == True:
        return self.accounted_allowance
    
    unaccounted_iterations: uint256 = min(self._unaccounted_iterations(), self.remaining_iterations)
    
    return self.accounted_allowance + unaccounted_iterations * self.rewards_rate_per_iteration


@internal
def _update_accounted_and_remaining_iterations():
    """
    @notice 
        Updates accounted_iteration_start_date to timestamp of current iteration
        and decreases remaining_iterations by number of iterations passed
    """
    unaccounted_iterations: uint256 = self._unaccounted_iterations()
    if (unaccounted_iterations == 0):
        return

    accounted_iteration_start_date: uint256 = self.accounted_iteration_start_date \
        + iteration_duration * unaccounted_iterations

    self.accounted_iteration_start_date = accounted_iteration_start_date
    
    remaining_iterations: uint256 = 0
    if (unaccounted_iterations < self.remaining_iterations): 
        remaining_iterations = self.remaining_iterations - unaccounted_iterations

    self.remaining_iterations = remaining_iterations
    
    log AccountedIterationStartDateUpdated(accounted_iteration_start_date)
    log RemainingIterationsUpdated(remaining_iterations)


@internal
def _set_allowance(_new_allowance: uint256):
    """
    @notice Changes the allowance limit for Merkle Rewards contact. 
    """
    self.accounted_allowance = _new_allowance

    # Resetting unaccounted iteration date
    self._update_accounted_and_remaining_iterations()

    log AccountedAllowanceUpdated(_new_allowance)


@external
def set_state(_new_allowance: uint256, _remaining_iterations: uint256, _rewards_rate_per_iteration: uint256, _new_start_date: uint256):
    """
    @notice 
        Sets new start date, allowance limit, rewards rate per iteration, and number of not accounted iterations.

        Allows to confirate program state without calling notifyRewardAmount, may be used to fix previous allowance state.

        Can be called by owner only.
    """
    assert msg.sender == self.owner, "manager: not permitted"

    accounted_iteration_start_date: uint256 = _new_start_date - iteration_duration
    self.accounted_iteration_start_date = accounted_iteration_start_date
    self.accounted_allowance = _new_allowance
    self.remaining_iterations = _remaining_iterations
    self.rewards_rate_per_iteration = _rewards_rate_per_iteration

    log AccountedAllowanceUpdated(_new_allowance)
    log AccountedIterationStartDateUpdated(accounted_iteration_start_date)
    log RemainingIterationsUpdated(_remaining_iterations)
    log RewardsRateUpdated(_rewards_rate_per_iteration)


@external
def notifyRewardAmount(amount: uint256, holder: address):
    """
    @notice
        Starts the next rewards period from the begining of the next iteration with amount from 
        holder address.
        If call before period finished it will distibute remainded amout of non distibuted tokens 
        additionally to the provided amount.
    """
    assert msg.sender == self.rewards_manager, "manager: not permitted"

    assert self.is_paused == False, "manager: contract is paused"

    assert ERC20(rewards_token).transferFrom(holder, self, amount), "manager: transfer failed"

    # Allows to start first rewards period from start date passed in constructor call
    if self.is_initialized:  
        new_allowance: uint256 = self._available_allowance()
        self._set_allowance(new_allowance)
    else:
        self.is_initialized = True

    unaccounted_iterations: uint256 = min(self._unaccounted_iterations(), self.remaining_iterations)
    
    amount_to_distribute: uint256 = unaccounted_iterations * self.rewards_rate_per_iteration + amount 
    assert amount_to_distribute != 0, "manager: no funds"
  
    rate: uint256 = amount_to_distribute / rewards_iterations
    self.rewards_rate_per_iteration = rate
    self.remaining_iterations = rewards_iterations

    log PeriodStarted(rewards_iterations, self.accounted_iteration_start_date, rate)


@external 
def createDistribution(token: address, _merkle_root: bytes32, _amount: uint256, _distribution_id: uint256):    
    """
    @notice
        Wraps createDistribution(token: ERC20, merkleRoot: bytes32, amount: uint256, distributionId: uint256)
        of Merkle rewards contract and allowes to distibute LDO token holded by this contract
        with amount limited by available_allowance()

        Can be called by balancer_distributor address only.
    """
    assert msg.sender == self.balancer_distributor, "manager: not permitted"
    assert rewards_token == token, "manager: only LDO distribution allowed"
    assert self.is_paused == False, "manager: contract is paused"
    assert ERC20(rewards_token).balanceOf(self) >= _amount, "manager: reward token balance is low"

    available_allowance: uint256 = self._available_allowance()
    assert available_allowance >= _amount, "manager: not enough amount approved"

    self._set_allowance(available_allowance - _amount)

    ERC20(rewards_token).approve(rewards_contract, _amount)
    IMerkleRewardsContract(rewards_contract).createDistribution(rewards_token, _merkle_root, _amount, _distribution_id)

    log RewardsDistributed(_amount)


@external
def pause():
    """
    @notice
        Pause allowance increasing and rejects createDistribution calling
    """
    assert msg.sender == self.owner, "manager: not permitted"
    assert not self.is_paused, "manager: contract already paused"

    new_allowance: uint256 = self._available_allowance()
    self._set_allowance(new_allowance)
    
    self.is_paused = True

    log Paused(msg.sender)


@external
def unpause():
    """
    @notice
        Unpause allowance increasing and allows createDistribution calling
    """
    assert msg.sender == self.owner, "manager: not permitted"
    assert self.is_paused, "manager: contract not paused"

    self._update_accounted_and_remaining_iterations()
    self.is_paused = False

    log Unpaused(msg.sender)


@external
def transfer_ownership(_to: address):
    """
    @notice Changes the contract owner. Can only be called by the current owner.
    """
    previous_owner: address = self.owner
    assert msg.sender == previous_owner, "manager: not permitted"
    assert _to != ZERO_ADDRESS, "manager: zero address not allowed"
    self.owner = _to
    log OwnerChanged(previous_owner, _to)


@external
def set_balancer_distributor(_new_balancer_distributor: address):
    """
    @notice Changes the balancer_distributor. Can only be called by the current owner or current balancer_distributor.
    """
    previous_balancer_distributor: address = self.balancer_distributor
    assert msg.sender == self.owner or msg.sender ==  previous_balancer_distributor, "manager: not permitted"
    assert _new_balancer_distributor != ZERO_ADDRESS, "manager: zero address not allowed"
    self.balancer_distributor = _new_balancer_distributor
    log BalancerDistributorChanged(previous_balancer_distributor, _new_balancer_distributor)


@external
def set_rewards_manager(_new_rewards_manager: address):
    """
    @notice Changes the rewards_manager. Can only be called by the current owner.
    """
    assert msg.sender == self.owner, "manager: not permitted"
    assert _new_rewards_manager != ZERO_ADDRESS, "manager: zero address not allowed"
    previous_rewards_manager: address = self.rewards_manager
    self.rewards_manager = _new_rewards_manager
    log RewardsManagerChanged(previous_rewards_manager, _new_rewards_manager)


@external
def recover_erc20(_token: address, _amount: uint256, _recipient: address = msg.sender):
    """
    @notice
        Transfers specified amount of the given ERC20 token from self
        to the recipient. Can only be called by the owner.
    """
    assert msg.sender == self.owner, "manager: not permitted"

    if _amount > 0:
        assert ERC20(_token).transfer(_recipient, _amount), "manager: token transfer failed"
        log ERC20TokenRecovered(_token, _amount, _recipient)


@external
@view
def periodFinish() -> uint256:
    """
    @notice Date of last allowance increasing.
    """
    return self._period_finish()


@external
@view
def is_rewards_period_finished() -> bool:
    """
    @notice Whether the current rewards period has finished.
    """
    return self._is_rewards_period_finished()


@external
@view
def available_allowance() -> uint256:
    """
    @notice 
        Returns current allowance limit available for distribution 
        by calling createDistribution
    """
    return self._available_allowance()