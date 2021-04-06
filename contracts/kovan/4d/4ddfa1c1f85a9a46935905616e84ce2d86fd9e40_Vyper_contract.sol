# @version 0.2.11
"""
@title Boardroom Distribution
@author Klondike Finance, Curve Finance
@license MIT
"""

from vyper.interfaces import ERC20


interface VotingEscrow:
    def user_point_epoch(addr: address) -> uint256: view
    def epoch() -> uint256: view
    def user_point_history(addr: address, loc: uint256) -> Point: view
    def point_history(loc: uint256) -> Point: view
    def checkpoint(): nonpayable


event CommitAdmin:
    admin: address

event ApplyAdmin:
    admin: address

event ToggleAllowCheckpointToken:
    toggle_flag: bool

event CheckpointToken:
    time: uint256
    tokens: uint256

event Claimed:
    recipient: indexed(address)
    amount: uint256
    claim_epoch: uint256
    max_epoch: uint256


struct Point:
    bias: int128
    slope: int128  # - dweight / dt
    ts: uint256
    blk: uint256  # block


WEEK: constant(uint256) = 7 * 86400
TOKEN_CHECKPOINT_DEADLINE: constant(uint256) = 86400
MAX_TOKENS: constant(uint256) = 50

start_time: public(HashMap[address, uint256])
time_cursor: public(uint256)
time_cursor_of: public(HashMap[address, HashMap[address, uint256]])
user_epoch_of: public(HashMap[address, uint256])

last_token_time: public(HashMap[address, uint256])
tokens_per_week: public(HashMap[address, uint256[1000000000000000]])

voting_escrow: public(address)
tokens: public(address[MAX_TOKENS])
tokens_len: public(uint256)
total_received: public(uint256)
token_last_balance: public(HashMap[address, uint256])

ve_supply: public(uint256[1000000000000000])  # VE total supply at week bounds

admin: public(address)
future_admin: public(address)
can_checkpoint_token: public(bool)
emergency_return: public(address)
is_killed: public(bool)


@external
def __init__(
    _voting_escrow: address,
    _admin: address,
    _emergency_return: address
):
    """
    @notice Contract constructor
    @param _voting_escrow VotingEscrow contract address
    @param _admin Admin address
    @param _emergency_return Address to transfer `_token` balance to
                             if this contract is killed
    """
    self.time_cursor = block.timestamp / WEEK * WEEK
    self.voting_escrow = _voting_escrow
    self.admin = _admin
    self.emergency_return = _emergency_return


@internal
def _checkpoint_token(token: address):
    token_balance: uint256 = ERC20(token).balanceOf(self)
    to_distribute: uint256 = token_balance - self.token_last_balance[token]
    self.token_last_balance[token] = token_balance

    t: uint256 = self.last_token_time[token]
    since_last: uint256 = block.timestamp - t
    self.last_token_time[token] = block.timestamp
    this_week: uint256 = t / WEEK * WEEK
    next_week: uint256 = 0

    for i in range(20):
        next_week = this_week + WEEK
        if block.timestamp < next_week:
            if since_last == 0 and block.timestamp == t:
                # edge case - div by 0
                self.tokens_per_week[token][this_week] += to_distribute
            else:
                # distribute incoming reward in current week evenly across weeks
                self.tokens_per_week[token][this_week] += to_distribute * (block.timestamp - t) / since_last
            break
        else:
            if since_last == 0 and next_week == t:
                # edge case - div by 0
                self.tokens_per_week[token][this_week] += to_distribute
            else:
                # distribute incoming reward evenly across weeks
                self.tokens_per_week[token][this_week] += to_distribute * (next_week - t) / since_last
        t = next_week
        this_week = next_week

    log CheckpointToken(block.timestamp, to_distribute)


@external
def checkpoint_token(token: address):
    """
    @notice Update the token checkpoint
    @dev Calculates the total number of tokens to be distributed in a given week.
         During setup for the initial distribution this function is only callable
         by the contract owner. Beyond initial distro, it can be enabled for anyone
         to call.
    """
    assert (msg.sender == self.admin) or\
           (self.can_checkpoint_token and (block.timestamp > self.last_token_time[token] + TOKEN_CHECKPOINT_DEADLINE))
    self._checkpoint_token(token)


@internal
def _find_timestamp_epoch(ve: address, _timestamp: uint256) -> uint256:
    _min: uint256 = 0
    _max: uint256 = VotingEscrow(ve).epoch()
    for i in range(128):
        if _min >= _max:
            break
        _mid: uint256 = (_min + _max + 2) / 2
        pt: Point = VotingEscrow(ve).point_history(_mid)
        if pt.ts <= _timestamp:
            _min = _mid
        else:
            _max = _mid - 1
    return _min


@view
@internal
def _find_timestamp_user_epoch(ve: address, user: address, _timestamp: uint256, max_user_epoch: uint256) -> uint256:
    _min: uint256 = 0
    _max: uint256 = max_user_epoch
    for i in range(128):
        if _min >= _max:
            break
        _mid: uint256 = (_min + _max + 2) / 2
        pt: Point = VotingEscrow(ve).user_point_history(user, _mid)
        if pt.ts <= _timestamp:
            _min = _mid
        else:
            _max = _mid - 1
    return _min


@view
@external
def ve_for_at(_user: address, _timestamp: uint256) -> uint256:
    """
    @notice Get the veCRV balance for `_user` at `_timestamp`
    @param _user Address to query balance for
    @param _timestamp Epoch time
    @return uint256 veCRV balance
    """
    ve: address = self.voting_escrow
    max_user_epoch: uint256 = VotingEscrow(ve).user_point_epoch(_user)
    epoch: uint256 = self._find_timestamp_user_epoch(ve, _user, _timestamp, max_user_epoch)
    pt: Point = VotingEscrow(ve).user_point_history(_user, epoch)
    return convert(max(pt.bias - pt.slope * convert(_timestamp - pt.ts, int128), 0), uint256)


@internal
def _checkpoint_total_supply():
    ve: address = self.voting_escrow
    t: uint256 = self.time_cursor
    rounded_timestamp: uint256 = block.timestamp / WEEK * WEEK
    VotingEscrow(ve).checkpoint()

    for i in range(20):
        if t > rounded_timestamp:
            break
        else:
            epoch: uint256 = self._find_timestamp_epoch(ve, t)
            pt: Point = VotingEscrow(ve).point_history(epoch)
            dt: int128 = 0
            if t > pt.ts:
                # If the point is at 0 epoch, it can actually be earlier than the first deposit
                # Then make dt 0
                dt = convert(t - pt.ts, int128)
            self.ve_supply[t] = convert(max(pt.bias - pt.slope * dt, 0), uint256)
        t += WEEK

    self.time_cursor = t


@external
def checkpoint_total_supply():
    """
    @notice Update the veCRV total supply checkpoint
    @dev The checkpoint is also updated by the first claimant each
         new epoch week. This function may be called independently
         of a claim, to reduce claiming gas costs.
    """
    self._checkpoint_total_supply()


@internal
def _claim(token: address, addr: address, ve: address, _last_token_time: uint256) -> uint256:
    # Minimal user_epoch is 0 (if user had no point)
    user_epoch: uint256 = 0
    to_distribute: uint256 = 0

    max_user_epoch: uint256 = VotingEscrow(ve).user_point_epoch(addr)
    _start_time: uint256 = self.start_time[token]

    if max_user_epoch == 0:
        # No lock = no fees
        return 0

    week_cursor: uint256 = self.time_cursor_of[token][addr]
    if week_cursor == 0:
        # Need to do the initial binary search
        user_epoch = self._find_timestamp_user_epoch(ve, addr, _start_time, max_user_epoch)
    else:
        user_epoch = self.user_epoch_of[addr]

    if user_epoch == 0:
        user_epoch = 1

    user_point: Point = VotingEscrow(ve).user_point_history(addr, user_epoch)

    if week_cursor == 0:
        week_cursor = (user_point.ts + WEEK - 1) / WEEK * WEEK

    if week_cursor >= _last_token_time:
        return 0

    if week_cursor < _start_time:
        week_cursor = _start_time
    old_user_point: Point = empty(Point)

    # Iterate over weeks
    for i in range(50):
        if week_cursor >= _last_token_time:
            break

        if week_cursor >= user_point.ts and user_epoch <= max_user_epoch:
            user_epoch += 1
            old_user_point = user_point
            if user_epoch > max_user_epoch:
                user_point = empty(Point)
            else:
                user_point = VotingEscrow(ve).user_point_history(addr, user_epoch)

        else:
            # Calc
            # + i * 2 is for rounding errors
            dt: int128 = convert(week_cursor - old_user_point.ts, int128)
            balance_of: uint256 = convert(max(old_user_point.bias - dt * old_user_point.slope, 0), uint256)
            if balance_of == 0 and user_epoch > max_user_epoch:
                break
            if balance_of > 0:
                to_distribute += balance_of * self.tokens_per_week[token][week_cursor] / self.ve_supply[week_cursor]

            week_cursor += WEEK

    user_epoch = min(max_user_epoch, user_epoch - 1)
    self.user_epoch_of[addr] = user_epoch
    self.time_cursor_of[token][addr] = week_cursor

    log Claimed(addr, to_distribute, user_epoch, max_user_epoch)

    return to_distribute


@external
@nonreentrant('lock')
def claim(token: address, _addr: address = msg.sender) -> uint256:
    """
    @notice Claim fees for `_addr`
    @dev Each call to claim look at a maximum of 50 user veCRV points.
         For accounts with many veCRV related actions, this function
         may need to be called more than once to claim all available
         fees. In the `Claimed` event that fires, if `claim_epoch` is
         less than `max_epoch`, the account may claim again.
    @param token Address of the token to claim
    @param _addr Address to claim fees for
    @return uint256 Amount of fees claimed in the call
    """
    assert not self.is_killed

    if block.timestamp >= self.time_cursor:
        self._checkpoint_total_supply()

    last_token_time: uint256 = self.last_token_time[token]

    if self.can_checkpoint_token and (block.timestamp > last_token_time + TOKEN_CHECKPOINT_DEADLINE):
        self._checkpoint_token(token)
        last_token_time = block.timestamp

    last_token_time = last_token_time / WEEK * WEEK

    amount: uint256 = self._claim(token, _addr, self.voting_escrow, last_token_time)
    if amount != 0:
        assert ERC20(token).transfer(_addr, amount)
        self.token_last_balance[token] -= amount

    return amount


@external
@nonreentrant('lock')
def claim_many(token: address, _receivers: address[20]) -> bool:
    """
    @notice Make multiple fee claims in a single call
    @dev Used to claim for many accounts at once, or to make
         multiple claims for the same address when that address
         has significant veCRV history
    @param token Address of the token to claim
    @param _receivers List of addresses to claim for. Claiming
                      terminates at the first `ZERO_ADDRESS`.
    @return bool success
    """
    assert not self.is_killed

    if block.timestamp >= self.time_cursor:
        self._checkpoint_total_supply()

    last_token_time: uint256 = self.last_token_time[token]

    if self.can_checkpoint_token and (block.timestamp > last_token_time + TOKEN_CHECKPOINT_DEADLINE):
        self._checkpoint_token(token)
        last_token_time = block.timestamp

    last_token_time = last_token_time / WEEK * WEEK
    voting_escrow: address = self.voting_escrow
    total: uint256 = 0

    for addr in _receivers:
        if addr == ZERO_ADDRESS:
            break

        amount: uint256 = self._claim(token, addr, voting_escrow, last_token_time)
        if amount != 0:
            assert ERC20(token).transfer(addr, amount)
            total += amount

    if total != 0:
        self.token_last_balance[token] -= total

    return True

@view
@internal
def _has_token(token: address) -> bool:
    """
    @notice Check if token is allowed
    @param token address of the token to check
    """
    for i in range(MAX_TOKENS):
        if i >= self.tokens_len:
            return False
        if self.tokens[i] == token:
            return True
    return False

@external 
def add_token(_addr: address, _start_time: uint256):
    """
    @notice Add token to allowlist
    @param _addr address of the token to add
    @param _start_time Epoch time for distribution to start
    """
    assert msg.sender == self.admin
    assert not self._has_token(_addr)
    self.tokens[self.tokens_len] = _addr
    self.tokens_len += 1
    t: uint256 = _start_time / WEEK * WEEK
    self.start_time[_addr] = t
    self.last_token_time[_addr] = t


@external 
def delete_token(_addr: address):
    """
    @notice Remove token from allowlist
    @param _addr address of the token to remove
    """
    assert msg.sender == self.admin
    for i in range(MAX_TOKENS):
        if i >= self.tokens_len:
            return
        if self.tokens[i] == _addr:
            self.tokens[i] = ZERO_ADDRESS
            return


@external
def burn(_coin: address) -> bool:
    """
    @notice Receive 3CRV into the contract and trigger a token checkpoint
    @param _coin Address of the coin being received (must be 3CRV)
    @return bool success
    """
    assert self._has_token(_coin), "token is not whitelisted"
    assert not self.is_killed

    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    if amount != 0:
        ERC20(_coin).transferFrom(msg.sender, self, amount)
        if self.can_checkpoint_token and (block.timestamp > self.last_token_time[_coin] + TOKEN_CHECKPOINT_DEADLINE):
            self._checkpoint_token(_coin)

    return True


@external
def commit_admin(_addr: address):
    """
    @notice Commit transfer of ownership
    @param _addr New admin address
    """
    assert msg.sender == self.admin  # dev: access denied
    self.future_admin = _addr
    log CommitAdmin(_addr)


@external
def apply_admin():
    """
    @notice Apply transfer of ownership
    """
    assert msg.sender == self.admin
    assert self.future_admin != ZERO_ADDRESS
    future_admin: address = self.future_admin
    self.admin = future_admin
    log ApplyAdmin(future_admin)


@external
def toggle_allow_checkpoint_token():
    """
    @notice Toggle permission for checkpointing by any account
    """
    assert msg.sender == self.admin
    flag: bool = not self.can_checkpoint_token
    self.can_checkpoint_token = flag
    log ToggleAllowCheckpointToken(flag)


@external
def kill_me():
    """
    @notice Kill the contract
    @dev Killing transfers the entire 3CRV balance to the emergency return address
         and blocks the ability to claim or burn. The contract cannot be unkilled.
    """
    assert msg.sender == self.admin

    self.is_killed = True

    for i in range(MAX_TOKENS):
        if i >= self.tokens_len:
            return
        token: address = self.tokens[i]
        if token == ZERO_ADDRESS:
            continue
        assert ERC20(token).transfer(self.emergency_return, ERC20(token).balanceOf(self))


@external
def recover_balance(_coin: address) -> bool:
    """
    @notice Recover ERC20 tokens from this contract
    @dev Tokens are sent to the emergency return address.
    @param _coin Token address
    @return bool success
    """
    assert msg.sender == self.admin
    assert not self._has_token(_coin)

    amount: uint256 = ERC20(_coin).balanceOf(self)
    response: Bytes[32] = raw_call(
        _coin,
        concat(
            method_id("transfer(address,uint256)"),
            convert(self.emergency_return, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) != 0:
        assert convert(response, bool)

    return True