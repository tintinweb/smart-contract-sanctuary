# @version 0.2.12
"""
@title Rewards-Only Gauge Mock
@author Curve Finance
@license MIT
@notice Distribution of third-party rewards without CRV
"""

from vyper.interfaces import ERC20

implements: ERC20


interface ERC20Extended:
    def symbol() -> String[26]: view


event Deposit:
    provider: indexed(address)
    value: uint256

event Withdraw:
    provider: indexed(address)
    value: uint256

event CommitOwnership:
    admin: address

event ApplyOwnership:
    admin: address

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

MAX_REWARDS: constant(uint256) = 8
CLAIM_FREQUENCY: constant(uint256) = 1

lp_token: public(address)

balanceOf: public(HashMap[address, uint256])
totalSupply: public(uint256)
allowance: public(HashMap[address, HashMap[address, uint256]])

name: public(String[64])
symbol: public(String[32])

# For tracking external rewards
# ???
reward_data: uint256
# CRV
reward_tokens: public(address[MAX_REWARDS])
reward_balances: public(HashMap[address, uint256])
# claimant -> default reward receiver
# ???
rewards_receiver: public(HashMap[address, address])

claim_sig: public(Bytes[4])

# reward token -> integral
# ???
reward_integral: public(HashMap[address, uint256])

# reward token -> claiming address -> integral
reward_integral_for: public(HashMap[address, HashMap[address, uint256]])

# user -> [uint128 claimable amount][uint128 claimed amount]
claim_data: HashMap[address, HashMap[address, uint256]]

admin: public(address)
future_admin: public(address)  # Can and will be a smart contract


@external
def __init__( _admin: address, _lp_token: address):
    """
    @notice Contract constructor
    @param _admin Admin who can kill the gauge
    @param _lp_token Liquidity Pool contract address
    """

    symbol: String[26] = ERC20Extended(_lp_token).symbol()
    self.name = concat("Curve.fi ", symbol, " RewardGauge Deposit")
    self.symbol = concat(symbol, "-gauge")

    self.lp_token = _lp_token
    self.admin = _admin


@view
@external
def decimals() -> uint256:
    """
    @notice Get the number of decimals for this token
    @dev Implemented as a view method to reduce gas costs
    @return uint256 decimal places
    """
    return 18


@internal
def _checkpoint_rewards(_user: address, _total_supply: uint256, _claim: bool, _receiver: address):
    """
    @notice Claim pending rewards and checkpoint rewards for a user
    """
    # claim from reward contract

    reward_data: uint256 = self.reward_data
    if _total_supply != 0 and reward_data != 0 and block.timestamp > shift(reward_data, -160) + CLAIM_FREQUENCY:
        reward_contract: address = convert(reward_data % 2**160, address)
        # mock: transfer crv directly
        # raw_call(reward_contract, self.claim_sig)  # dev: bad claim sig
        self.reward_data = convert(reward_contract, uint256) + shift(block.timestamp, 160)

    receiver: address = _receiver
    if _claim and receiver == ZERO_ADDRESS:
        # if receiver is not explicitly declared, check for default receiver
        receiver = self.rewards_receiver[_user]
        if receiver == ZERO_ADDRESS:
            # direct claims to user if no default receiver is set
            receiver = _user

    # calculate new user reward integral and transfer any owed rewards
    user_balance: uint256 = self.balanceOf[_user]
    for i in range(MAX_REWARDS):
        token: address = self.reward_tokens[i]
        if token == ZERO_ADDRESS:
            break

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
                    concat(
                        method_id("transfer(address,uint256)"),
                        convert(receiver, bytes32),
                        convert(total_claimable, bytes32),
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


@view
@external
def reward_contract() -> address:
    """
    @notice Address of the reward contract providing non-CRV incentives for this gauge
    @dev Returns `ZERO_ADDRESS` if there is no reward contract active
    """
    return convert(self.reward_data % 2**160, address)


@view
@external
def last_claim() -> uint256:
    """
    @notice Epoch timestamp of the last call to claim from `reward_contract`
    @dev Rewards are claimed at most once per hour in order to reduce gas costs
    """
    return shift(self.reward_data, -160)


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
        self._checkpoint_rewards(_addr, self.totalSupply, False, ZERO_ADDRESS)
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
    self._checkpoint_rewards(_addr, self.totalSupply, True, _receiver)


@external
@nonreentrant('lock')
def deposit(_value: uint256, _addr: address = msg.sender, _claim_rewards: bool = False):
    """
    @notice Deposit `_value` LP tokens
    @dev Depositting also claims pending reward tokens
    @param _value Number of tokens to deposit
    @param _addr Address to deposit for
    """
    if _value != 0:
        reward_contract: address = convert(self.reward_data % 2**160, address)
        total_supply: uint256 = self.totalSupply

        self._checkpoint_rewards(_addr, total_supply, _claim_rewards, ZERO_ADDRESS)

        total_supply += _value
        new_balance: uint256 = self.balanceOf[_addr] + _value
        self.balanceOf[_addr] = new_balance
        self.totalSupply = total_supply

        ERC20(self.lp_token).transferFrom(msg.sender, self, _value)

    log Deposit(_addr, _value)
    log Transfer(ZERO_ADDRESS, _addr, _value)


@external
@nonreentrant('lock')
def withdraw(_value: uint256, _claim_rewards: bool = False):
    """
    @notice Withdraw `_value` LP tokens
    @dev Withdrawing also claims pending reward tokens
    @param _value Number of tokens to withdraw
    """
    if _value != 0:
        reward_contract: address = convert(self.reward_data % 2**160, address)
        total_supply: uint256 = self.totalSupply

        self._checkpoint_rewards(msg.sender, total_supply, _claim_rewards, ZERO_ADDRESS)

        total_supply -= _value
        new_balance: uint256 = self.balanceOf[msg.sender] - _value
        self.balanceOf[msg.sender] = new_balance
        self.totalSupply = total_supply

        ERC20(self.lp_token).transfer(msg.sender, _value)

    log Withdraw(msg.sender, _value)
    log Transfer(msg.sender, ZERO_ADDRESS, _value)


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    reward_contract: address = convert(self.reward_data % 2**160, address)

    if _value != 0:
        total_supply: uint256 = self.totalSupply
        self._checkpoint_rewards(_from, total_supply, False, ZERO_ADDRESS)
        new_balance: uint256 = self.balanceOf[_from] - _value
        self.balanceOf[_from] = new_balance

        self._checkpoint_rewards(_to, total_supply, False, ZERO_ADDRESS)
        new_balance = self.balanceOf[_to] + _value
        self.balanceOf[_to] = new_balance

    log Transfer(_from, _to, _value)


@external
@nonreentrant('lock')
def transfer(_to : address, _value : uint256) -> bool:
    """
    @notice Transfer token for a specified address
    @dev Transferring claims pending reward tokens for the sender and receiver
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    self._transfer(msg.sender, _to, _value)

    return True


@external
@nonreentrant('lock')
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
    @notice Transfer tokens from one address to another.
    @dev Transferring claims pending reward tokens for the sender and receiver
    @param _from address The address which you want to send tokens from
    @param _to address The address which you want to transfer to
    @param _value uint256 the amount of tokens to be transferred
    """
    _allowance: uint256 = self.allowance[_from][msg.sender]
    if _allowance != MAX_UINT256:
        self.allowance[_from][msg.sender] = _allowance - _value

    self._transfer(_from, _to, _value)

    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @notice Approve the passed address to transfer the specified amount of
            tokens on behalf of msg.sender
    @dev Beware that changing an allowance via this method brings the risk
         that someone may use both the old and new allowance by unfortunate
         transaction ordering. This may be mitigated with the use of
         {incraseAllowance} and {decreaseAllowance}.
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will transfer the funds
    @param _value The amount of tokens that may be transferred
    @return bool success
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)

    return True


@external
def increaseAllowance(_spender: address, _added_value: uint256) -> bool:
    """
    @notice Increase the allowance granted to `_spender` by the caller
    @dev This is alternative to {approve} that can be used as a mitigation for
         the potential race condition
    @param _spender The address which will transfer the funds
    @param _added_value The amount of to increase the allowance
    @return bool success
    """
    allowance: uint256 = self.allowance[msg.sender][_spender] + _added_value
    self.allowance[msg.sender][_spender] = allowance

    log Approval(msg.sender, _spender, allowance)

    return True


@external
def decreaseAllowance(_spender: address, _subtracted_value: uint256) -> bool:
    """
    @notice Decrease the allowance granted to `_spender` by the caller
    @dev This is alternative to {approve} that can be used as a mitigation for
         the potential race condition
    @param _spender The address which will transfer the funds
    @param _subtracted_value The amount of to decrease the allowance
    @return bool success
    """
    allowance: uint256 = self.allowance[msg.sender][_spender] - _subtracted_value
    self.allowance[msg.sender][_spender] = allowance

    log Approval(msg.sender, _spender, allowance)

    return True


@external
@nonreentrant('lock')
def set_rewards(_reward_contract: address, _claim_sig: bytes32, _reward_tokens: address[MAX_REWARDS]):
    """
    @notice Set the active reward contract
    @dev A reward contract cannot be set while this contract has no deposits
    @param _reward_contract Reward contract address. Set to ZERO_ADDRESS to
                            disable staking.
    @param _claim_sig Four byte selectors for staking, withdrawing and claiming,
                 left padded with zero bytes. If the reward contract can
                 be claimed from but does not require staking, the staking
                 and withdraw selectors should be set to 0x00
    @param _reward_tokens List of claimable reward tokens. New reward tokens
                          may be added but they cannot be removed. When calling
                          this function to unset or modify a reward contract,
                          this array must begin with the already-set reward
                          token addresses.
    """
    assert msg.sender == self.admin

    lp_token: address = self.lp_token
    current_reward_contract: address = convert(self.reward_data % 2**160, address)
    total_supply: uint256 = self.totalSupply
    self._checkpoint_rewards(ZERO_ADDRESS, total_supply, False, ZERO_ADDRESS)

    if _reward_contract != ZERO_ADDRESS:
        assert _reward_tokens[0] != ZERO_ADDRESS  # dev: no reward token
        assert _reward_contract.is_contract  # dev: not a contract

    self.reward_data = convert(_reward_contract, uint256)
    self.claim_sig = slice(_claim_sig, 28, 4)
    for i in range(MAX_REWARDS):
        current_token: address = self.reward_tokens[i]
        new_token: address = _reward_tokens[i]
        if current_token != ZERO_ADDRESS:
            assert current_token == new_token  # dev: cannot modify existing reward token
        elif new_token != ZERO_ADDRESS:
            self.reward_tokens[i] = new_token
        else:
            break

    if _reward_contract != ZERO_ADDRESS:
        # do an initial checkpoint to verify that claims are working
        self._checkpoint_rewards(ZERO_ADDRESS, total_supply, False, ZERO_ADDRESS)


@external
def commit_transfer_ownership(addr: address):
    """
    @notice Transfer ownership of GaugeController to `addr`
    @param addr Address to have ownership transferred to
    """
    assert msg.sender == self.admin  # dev: admin only

    self.future_admin = addr
    log CommitOwnership(addr)


@external
def accept_transfer_ownership():
    """
    @notice Accept a pending ownership transfer
    """
    _admin: address = self.future_admin
    assert msg.sender == _admin  # dev: future admin only

    self.admin = _admin
    log ApplyOwnership(_admin)