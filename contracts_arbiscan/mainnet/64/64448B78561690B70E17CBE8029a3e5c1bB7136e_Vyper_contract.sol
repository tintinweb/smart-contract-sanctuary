# @version 0.2.16
"""
@title Curve Factory Metapool Gauge Extension
@author Curve.Fi
@license Copyright (c) Curve.Fi, 2020-2021 - all rights reserved
"""
from vyper.interfaces import ERC20


interface BaseGauge:
    def claim_rewards(_addr: address): nonpayable
    def reward_tokens(_i: uint256) -> address: view

interface Factory:
    def admin() -> address: view


struct Reward:
    token: address
    distributor: address
    period_finish: uint256
    rate: uint256
    last_update: uint256
    integral: uint256


MAX_REWARDS: constant(uint256) = 8
FACTORY: constant(address) = 0xb17b674D9c5CB2e441F8e196a2f048A81355d031
WEEK: constant(uint256) = 86400 * 7


deployer: public(address)
pool: public(address)

# For tracking external rewards
reward_balances: public(HashMap[address, uint256])
# claimant -> default reward receiver
rewards_receiver: public(HashMap[address, address])

# reward token -> integral
reward_integral: public(HashMap[address, uint256])

# reward token -> claiming address -> integral
reward_integral_for: public(HashMap[address, HashMap[address, uint256]])

# user -> [uint128 claimable amount][uint128 claimed amount]
claim_data: HashMap[address, HashMap[address, uint256]]

reward_count: public(uint256)
reward_tokens: public(address[MAX_REWARDS])

reward_data: public(HashMap[address, Reward])

is_killed: public(bool)

base_gauge: public(address)

@external
def __init__():
    self.pool = 0x000000000000000000000000000000000000dEaD


@external
def initialize(_base_gauge: address):
    assert self.pool == ZERO_ADDRESS
    self.pool = msg.sender
    self.base_gauge = _base_gauge
    self.deployer = tx.origin


@internal
def _checkpoint_rewards(_user: address, _total_supply: uint256, _claim: bool, _receiver: address):
    """
    @notice Claim pending rewards and checkpoint rewards for a user
    """
    # claim from base gauge
    gauge: address = self.base_gauge
    BaseGauge(gauge).claim_rewards(self.pool)

    checkpointed: address[MAX_REWARDS] = empty(address[MAX_REWARDS])

    receiver: address = _receiver
    if _claim and receiver == ZERO_ADDRESS:
        # if receiver is not explicitly declared, check for default receiver
        receiver = self.rewards_receiver[_user]
        if receiver == ZERO_ADDRESS:
            # direct claims to user if no default receiver is set
            receiver = _user

    # calculate new user reward integral and transfer any owed rewards
    user_balance: uint256 = ERC20(self.pool).balanceOf(_user)
    for i in range(MAX_REWARDS):
        token: address = BaseGauge(gauge).reward_tokens(i)
        if token == ZERO_ADDRESS:
            break
        checkpointed[i] = token
        dI: uint256 = 0
        if _total_supply != 0:
            token_balance: uint256 = ERC20(token).balanceOf(self)
            dI = 10**18 * (token_balance - self.reward_balances[token]) / _total_supply
            self.reward_balances[token] = token_balance
            if _user == ZERO_ADDRESS:
                if dI != 0:
                    self.reward_integral[token] += dI
                continue

        integral: uint256 = self.reward_integral[token] + dI
        if dI != 0:
            self.reward_integral[token] = integral

        integral_for: uint256 = self.reward_integral_for[token][_user]
        new_claimable: uint256 = 0
        if integral_for < integral:
            self.reward_integral_for[token][_user] = integral
            new_claimable = user_balance * (integral - integral_for) / 10**18

        claim_data: uint256 = self.claim_data[_user][token]
        total_claimable: uint256 = shift(claim_data, -128) + new_claimable
        if total_claimable > 0:
            total_claimed: uint256 = claim_data % 2 ** 128
            if _claim:
                response: Bytes[32] = raw_call(
                    token,
                    _abi_encode(
                        receiver, total_claimable, method_id=method_id("transfer(address,uint256)")
                    ),
                    max_outsize=32,
                )
                if len(response) != 0:
                    assert convert(response, bool)
                self.reward_balances[token] -= total_claimable
                # update amount claimed (lower order bytes)
                self.claim_data[_user][token] = total_claimed + total_claimable
            elif new_claimable > 0:
                # update total_claimable (higher order bytes)
                self.claim_data[_user][token] = total_claimed + shift(total_claimable, 128)

    reward_count: uint256 = self.reward_count
    for i in range(MAX_REWARDS):
        if i == reward_count:
            break
        token: address = self.reward_tokens[i]
        if token in checkpointed:
            # if token is apart of base rewards
            # skip it
            continue

        integral: uint256 = self.reward_data[token].integral
        last_update: uint256 = min(block.timestamp, self.reward_data[token].period_finish)
        duration: uint256 = last_update - self.reward_data[token].last_update
        if duration != 0:
            self.reward_data[token].last_update = last_update
            if _total_supply != 0:
                integral += duration * self.reward_data[token].rate * 10**18 / _total_supply
                self.reward_data[token].integral = integral

        if _user != ZERO_ADDRESS:
            integral_for: uint256 = self.reward_integral_for[token][_user]
            new_claimable: uint256 = 0

            if integral_for < integral:
                self.reward_integral_for[token][_user] = integral
                new_claimable = user_balance * (integral - integral_for) / 10**18

            claim_data: uint256 = self.claim_data[_user][token]
            total_claimable: uint256 = shift(claim_data, -128) + new_claimable
            if total_claimable > 0:
                total_claimed: uint256 = claim_data % 2**128
                if _claim:
                    response: Bytes[32] = raw_call(
                        token,
                        _abi_encode(
                            receiver,
                            total_claimable,
                            method_id=method_id("transfer(address,uint256)")
                        ),
                        max_outsize=32,
                    )
                    if len(response) != 0:
                        assert convert(response, bool)
                    self.claim_data[_user][token] = total_claimed + total_claimable
                elif new_claimable > 0:
                    self.claim_data[_user][token] = total_claimed + shift(total_claimable, 128)


@external
def checkpoint_rewards(_addr: address):
    if self.is_killed:
        return
    self._checkpoint_rewards(_addr, ERC20(self.pool).totalSupply(), False, ZERO_ADDRESS)


@view
@external
def claimed_reward(_addr: address, _token: address) -> uint256:
    """
    @notice Get the number of already-claimed reward tokens for a user
    @param _addr Account to get reward amount for
    @param _token Token to get reward amount for
    @return uint256 Total amount of `_token` already claimed by `_addr`
    """
    return self.claim_data[_addr][_token] % 2**128


@view
@external
def claimable_reward(_addr: address, _token: address) -> uint256:
    """
    @notice Get the number of claimable reward tokens for a user
    @dev This call does not consider pending claimable amount in `reward_contract`.
         Off-chain callers should instead use `claimable_rewards_write` as a
         view method.
    @param _addr Account to get reward amount for
    @param _token Token to get reward amount for
    @return uint256 Claimable reward token amount
    """
    return shift(self.claim_data[_addr][_token], -128)


@external
@nonreentrant('lock')
def claimable_reward_write(_addr: address, _token: address) -> uint256:
    """
    @notice Get the number of claimable reward tokens for a user
    @dev This function should be manually changed to "view" in the ABI
         Calling it via a transaction will claim available reward tokens
    @param _addr Account to get reward amount for
    @param _token Token to get reward amount for
    @return uint256 Claimable reward token amount
    """
    if self.reward_tokens[0] != ZERO_ADDRESS:
        self._checkpoint_rewards(_addr, ERC20(self.pool).totalSupply(), False, ZERO_ADDRESS)
    return shift(self.claim_data[_addr][_token], -128)


@external
def set_rewards_receiver(_receiver: address):
    """
    @notice Set the default reward receiver for the caller.
    @dev When set to ZERO_ADDRESS, rewards are sent to the caller
    @param _receiver Receiver address for any rewards claimed via `claim_rewards`
    """
    self.rewards_receiver[msg.sender] = _receiver


@external
@nonreentrant('lock')
def claim_rewards(_addr: address = msg.sender, _receiver: address = ZERO_ADDRESS):
    """
    @notice Claim available reward tokens for `_addr`
    @param _addr Address to claim for
    @param _receiver Address to transfer rewards to - if set to
                     ZERO_ADDRESS, uses the default reward receiver
                     for the caller
    """
    if _receiver != ZERO_ADDRESS:
        assert _addr == msg.sender  # dev: cannot redirect when claiming for another user
    self._checkpoint_rewards(_addr, ERC20(self.pool).totalSupply(), True, _receiver)


@external
def add_reward(_reward_token: address, _distributor: address):
    """
    @notice Set the active reward contract
    """
    assert msg.sender == Factory(FACTORY).admin() or msg.sender == self.deployer  # dev: only owner

    reward_count: uint256 = self.reward_count
    assert reward_count < MAX_REWARDS
    assert self.reward_data[_reward_token].distributor == ZERO_ADDRESS

    self.reward_data[_reward_token].distributor = _distributor
    self.reward_tokens[reward_count] = _reward_token
    self.reward_count = reward_count + 1


@external
def set_reward_distributor(_reward_token: address, _distributor: address):
    current_distributor: address = self.reward_data[_reward_token].distributor

    assert msg.sender == current_distributor or msg.sender == Factory(FACTORY).admin() or msg.sender == self.deployer
    assert current_distributor != ZERO_ADDRESS
    assert _distributor != ZERO_ADDRESS

    self.reward_data[_reward_token].distributor = _distributor


@external
@nonreentrant("lock")
def deposit_reward_token(_reward_token: address, _amount: uint256):
    assert msg.sender == self.reward_data[_reward_token].distributor

    self._checkpoint_rewards(ZERO_ADDRESS, ERC20(self.pool).totalSupply(), False, ZERO_ADDRESS)

    response: Bytes[32] = raw_call(
        _reward_token,
        _abi_encode(
            msg.sender, self, _amount, method_id=method_id("transferFrom(address,address,uint256)")
        ),
        max_outsize=32,
    )
    if len(response) != 0:
        assert convert(response, bool)

    period_finish: uint256 = self.reward_data[_reward_token].period_finish
    if block.timestamp >= period_finish:
        self.reward_data[_reward_token].rate = _amount / WEEK
    else:
        remaining: uint256 = period_finish - block.timestamp
        leftover: uint256 = remaining * self.reward_data[_reward_token].rate
        self.reward_data[_reward_token].rate = (_amount + leftover) / WEEK

    self.reward_data[_reward_token].last_update = block.timestamp
    self.reward_data[_reward_token].period_finish = block.timestamp + WEEK


@external
def set_killed(_is_killed: bool):
    """
    @notice Set the killed status for this contract
    @dev When killed, the gauge always yields a rate of 0 and so cannot mint CRV
    @param _is_killed Killed status to set
    """
    assert msg.sender == Factory(FACTORY).admin()  # dev: only owner

    self.is_killed = _is_killed