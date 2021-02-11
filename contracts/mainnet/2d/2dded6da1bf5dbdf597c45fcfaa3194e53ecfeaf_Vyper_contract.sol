# @version 0.2.8
"""
@title Curve IronBank Pool
@author Curve.Fi
@license Copyright (c) Curve.Fi, 2021 - all rights reserved
@notice Pool for swapping between cyTokens (cyDAI, cyUSDC, cyUSDT)
"""

# External Contracts
interface cyToken:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def mint(mintAmount: uint256) -> uint256: nonpayable
    def redeem(redeemTokens: uint256) -> uint256: nonpayable
    def exchangeRateStored() -> uint256: view
    def exchangeRateCurrent() -> uint256: nonpayable
    def supplyRatePerBlock() -> uint256: view
    def accrualBlockNumber() -> uint256: view

interface CurveToken:
    def mint(_to: address, _value: uint256) -> bool: nonpayable
    def burnFrom(_to: address, _value: uint256) -> bool: nonpayable

interface ERC20:
    def transfer(_to: address, _value: uint256): nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256): nonpayable
    def totalSupply() -> uint256: view
    def balanceOf(_addr: address) -> uint256: view

# Events
event TokenExchange:
    buyer: indexed(address)
    sold_id: int128
    tokens_sold: uint256
    bought_id: int128
    tokens_bought: uint256

event TokenExchangeUnderlying:
    buyer: indexed(address)
    sold_id: int128
    tokens_sold: uint256
    bought_id: int128
    tokens_bought: uint256

event AddLiquidity:
    provider: indexed(address)
    token_amounts: uint256[N_COINS]
    fees: uint256[N_COINS]
    invariant: uint256
    token_supply: uint256

event RemoveLiquidity:
    provider: indexed(address)
    token_amounts: uint256[N_COINS]
    fees: uint256[N_COINS]
    token_supply: uint256

event RemoveLiquidityOne:
    provider: indexed(address)
    token_amount: uint256
    coin_amount: uint256

event RemoveLiquidityImbalance:
    provider: indexed(address)
    token_amounts: uint256[N_COINS]
    fees: uint256[N_COINS]
    invariant: uint256
    token_supply: uint256

event CommitNewAdmin:
    deadline: indexed(uint256)
    admin: indexed(address)

event NewAdmin:
    admin: indexed(address)

event CommitNewFee:
    deadline: indexed(uint256)
    fee: uint256
    admin_fee: uint256

event NewFee:
    fee: uint256
    admin_fee: uint256

event RampA:
    old_A: uint256
    new_A: uint256
    initial_time: uint256
    future_time: uint256

event StopRampA:
    A: uint256
    t: uint256


# These constants must be set prior to compiling
N_COINS: constant(int128) = 3
PRECISION_MUL: constant(uint256[N_COINS]) = [1, 1000000000000, 1000000000000]

# fixed constants
FEE_DENOMINATOR: constant(uint256) = 10 ** 10
PRECISION: constant(uint256) = 10 ** 18  # The precision to convert to

MAX_ADMIN_FEE: constant(uint256) = 10 * 10 ** 9
MAX_FEE: constant(uint256) = 5 * 10 ** 9
MAX_A: constant(uint256) = 10 ** 6
MAX_A_CHANGE: constant(uint256) = 10

ADMIN_ACTIONS_DELAY: constant(uint256) = 3 * 86400
MIN_RAMP_TIME: constant(uint256) = 86400

coins: public(address[N_COINS])
underlying_coins: public(address[N_COINS])
balances: public(uint256[N_COINS])

previous_balances: public(uint256[N_COINS])
block_timestamp_last: public(uint256)

fee: public(uint256)  # fee * 1e10
admin_fee: public(uint256)  # admin_fee * 1e10

owner: public(address)
lp_token: public(address)

A_PRECISION: constant(uint256) = 100
initial_A: public(uint256)
future_A: public(uint256)
initial_A_time: public(uint256)
future_A_time: public(uint256)

admin_actions_deadline: public(uint256)
transfer_ownership_deadline: public(uint256)
future_fee: public(uint256)
future_admin_fee: public(uint256)
future_owner: public(address)

is_killed: bool
kill_deadline: uint256
KILL_DEADLINE_DT: constant(uint256) = 2 * 30 * 86400

@external
def __init__(
    _owner: address,
    _coins: address[N_COINS],
    _underlying_coins: address[N_COINS],
    _pool_token: address,
    _A: uint256,
    _fee: uint256,
    _admin_fee: uint256,
):
    """
    @notice Contract constructor
    @param _owner Contract owner address
    @param _coins Addresses of ERC20 contracts of wrapped coins
    @param _underlying_coins Addresses of ERC20 contracts of underlying coins
    @param _pool_token Address of the token representing LP share
    @param _A Amplification coefficient multiplied by n * (n - 1)
    @param _fee Fee to charge for exchanges
    @param _admin_fee Admin fee
    """
    for i in range(N_COINS):
        assert _coins[i] != ZERO_ADDRESS
        assert _underlying_coins[i] != ZERO_ADDRESS

        # approve underlying coins for infinite transfers
        _response: Bytes[32] = raw_call(
            _underlying_coins[i],
            concat(
                method_id("approve(address,uint256)"),
                convert(_coins[i], bytes32),
                convert(MAX_UINT256, bytes32),
            ),
            max_outsize=32,
        )
        if len(_response) > 0:
            assert convert(_response, bool)

    self.coins = _coins
    self.underlying_coins = _underlying_coins
    self.initial_A = _A * A_PRECISION
    self.future_A = _A * A_PRECISION
    self.fee = _fee
    self.admin_fee = _admin_fee
    self.owner = _owner
    self.kill_deadline = block.timestamp + KILL_DEADLINE_DT
    self.lp_token = _pool_token


@view
@internal
def _A() -> uint256:
    """
    Handle ramping A up or down
    """
    t1: uint256 = self.future_A_time
    A1: uint256 = self.future_A

    if block.timestamp < t1:
        A0: uint256 = self.initial_A
        t0: uint256 = self.initial_A_time
        # Expressions in uint256 cannot have negative numbers, thus "if"
        if A1 > A0:
            return A0 + (A1 - A0) * (block.timestamp - t0) / (t1 - t0)
        else:
            return A0 - (A0 - A1) * (block.timestamp - t0) / (t1 - t0)

    else:  # when t1 == 0 or block.timestamp >= t1
        return A1


@view
@external
def A() -> uint256:
    return self._A() / A_PRECISION


@view
@external
def A_precise() -> uint256:
    return self._A()


@view
@internal
def _stored_rates() -> uint256[N_COINS]:
    # exchangeRateStored * (1 + supplyRatePerBlock * (getBlockNumber - accrualBlockNumber) / 1e18)
    result: uint256[N_COINS] = PRECISION_MUL
    for i in range(N_COINS):
        coin: address = self.coins[i]
        rate: uint256 = cyToken(coin).exchangeRateStored()
        rate += rate * cyToken(coin).supplyRatePerBlock() * (block.number - cyToken(coin).accrualBlockNumber()) / PRECISION
        result[i] *= rate
    return result


@internal
def _update():
    """
    Commits pre-change balances for the previous block
    Can be used to compare against current values for flash loan checks
    """
    if block.timestamp > self.block_timestamp_last:
        self.previous_balances = self.balances
        self.block_timestamp_last = block.timestamp


@internal
def _current_rates() -> uint256[N_COINS]:
    self._update()
    result: uint256[N_COINS] = PRECISION_MUL
    for i in range(N_COINS):
        result[i] *= cyToken(self.coins[i]).exchangeRateCurrent()
    return result


@view
@internal
def _xp(rates: uint256[N_COINS]) -> uint256[N_COINS]:
    result: uint256[N_COINS] = empty(uint256[N_COINS])
    for i in range(N_COINS):
        result[i] = rates[i] * self.balances[i] / PRECISION
    return result

@pure
@internal
def get_D(xp: uint256[N_COINS], amp: uint256) -> uint256:
    S: uint256 = 0
    Dprev: uint256 = 0

    for _x in xp:
        S += _x
    if S == 0:
        return 0

    D: uint256 = S
    Ann: uint256 = amp * N_COINS
    for _i in range(255):
        D_P: uint256 = D
        for _x in xp:
            D_P = D_P * D / (_x * N_COINS)  # If division by 0, this will be borked: only withdrawal will work. And that is good
        Dprev = D
        D = (Ann * S / A_PRECISION + D_P * N_COINS) * D / ((Ann - A_PRECISION) * D / A_PRECISION + (N_COINS + 1) * D_P)
        # Equality with the precision of 1
        if D > Dprev:
            if D - Dprev <= 1:
                return D
        else:
            if Dprev - D <= 1:
                return D
    # convergence typically occurs in 4 rounds or less, this should be unreachable!
    # if it does happen the pool is borked and LPs can withdraw via `remove_liquidity`
    raise


@view
@internal
def get_D_mem(rates: uint256[N_COINS], _balances: uint256[N_COINS], _amp: uint256) -> uint256:
    xp: uint256[N_COINS] = empty(uint256[N_COINS])
    for i in range(N_COINS):
        xp[i] = rates[i] * _balances[i] / PRECISION

    return self.get_D(xp, _amp)


@view
@external
def get_virtual_price() -> uint256:
    """
    @notice The current virtual price of the pool LP token
    @dev Useful for calculating profits
    @return LP token virtual price normalized to 1e18
    """
    D: uint256 = self.get_D(self._xp(self._stored_rates()), self._A())
    # D is in the units similar to DAI (e.g. converted to precision 1e18)
    # When balanced, D = n * x_u - total virtual value of the portfolio
    return D * PRECISION / ERC20(self.lp_token).totalSupply()


@view
@external
def calc_token_amount(amounts: uint256[N_COINS], is_deposit: bool) -> uint256:
    """
    @notice Calculate addition or reduction in token supply from a deposit or withdrawal
    @dev This calculation accounts for slippage, but not fees.
         Needed to prevent front-running, not for precise calculations!
    @param amounts Amount of each coin being deposited
    @param is_deposit set True for deposits, False for withdrawals
    @return Expected amount of LP tokens received
    """
    amp: uint256 = self._A()
    rates: uint256[N_COINS] = self._stored_rates()
    _balances: uint256[N_COINS] = self.balances
    D0: uint256 = self.get_D_mem(rates, _balances, amp)
    for i in range(N_COINS):
        _amount: uint256 = amounts[i]
        if is_deposit:
            _balances[i] += _amount
        else:
            _balances[i] -= _amount
    D1: uint256 = self.get_D_mem(rates, _balances, amp)
    token_amount: uint256 = ERC20(self.lp_token).totalSupply()
    diff: uint256 = 0
    if is_deposit:
        diff = D1 - D0
    else:
        diff = D0 - D1
    return diff * token_amount / D0


@external
@nonreentrant('lock')
def add_liquidity(
    _amounts: uint256[N_COINS],
    _min_mint_amount: uint256,
    _use_underlying: bool = False
) -> uint256:
    """
    @notice Deposit coins into the pool
    @param _amounts List of amounts of coins to deposit
    @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
    @param _use_underlying If True, deposit underlying assets instead of cyTokens
    @return Amount of LP tokens received by depositing
    """
    assert not self.is_killed

    amp: uint256 = self._A()
    rates: uint256[N_COINS] = self._current_rates()
    _lp_token: address = self.lp_token
    token_supply: uint256 = ERC20(_lp_token).totalSupply()

    # Initial invariant
    old_balances: uint256[N_COINS] = self.balances
    D0: uint256 = self.get_D_mem(rates, old_balances, amp)

    # Take coins from the sender
    new_balances: uint256[N_COINS] = old_balances
    amounts: uint256[N_COINS] = empty(uint256[N_COINS])
    for i in range(N_COINS):
        amount: uint256 = _amounts[i]

        if amount == 0:
            assert token_supply > 0
        else:
            coin: address = self.coins[i]
            if _use_underlying:
                ERC20(self.underlying_coins[i]).transferFrom(msg.sender, self, amount)
                before: uint256 = ERC20(coin).balanceOf(self)
                assert cyToken(coin).mint(amount) == 0
                amount = ERC20(coin).balanceOf(self) - before
            else:
                assert cyToken(coin).transferFrom(msg.sender, self, amount)
            amounts[i] = amount
            new_balances[i] += amount

    # Invariant after change
    D1: uint256 = self.get_D_mem(rates, new_balances, amp)
    assert D1 > D0

    # We need to recalculate the invariant accounting for fees
    # to calculate fair user's share
    fees: uint256[N_COINS] = empty(uint256[N_COINS])
    mint_amount: uint256 = 0
    if token_supply != 0:
        # Only account for fees if we are not the first to deposit
        _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
        _admin_fee: uint256 = self.admin_fee
        difference: uint256 = 0
        for i in range(N_COINS):
            new_balance: uint256 = new_balances[i]
            ideal_balance: uint256 = D1 * old_balances[i] / D0
            if ideal_balance > new_balance:
                difference = ideal_balance - new_balance
            else:
                difference = new_balance - ideal_balance
            fees[i] = _fee * difference / FEE_DENOMINATOR
            self.balances[i] = new_balance - (fees[i] * _admin_fee / FEE_DENOMINATOR)
            new_balances[i] -= fees[i]
        D2: uint256 = self.get_D_mem(rates, new_balances, amp)
        mint_amount = token_supply * (D2 - D0) / D0
    else:
        self.balances = new_balances
        mint_amount = D1  # Take the dust if there was any

    assert mint_amount >= _min_mint_amount, "Slippage screwed you"

    # Mint pool tokens
    CurveToken(_lp_token).mint(msg.sender, mint_amount)

    log AddLiquidity(msg.sender, amounts, fees, D1, token_supply + mint_amount)

    return mint_amount


@view
@internal
def get_y(i: int128, j: int128, x: uint256, xp_: uint256[N_COINS]) -> uint256:
    # x in the input is converted to the same price/precision

    assert i != j       # dev: same coin
    assert j >= 0       # dev: j below zero
    assert j < N_COINS  # dev: j above N_COINS

    # should be unreachable, but good for safety
    assert i >= 0
    assert i < N_COINS

    A_: uint256 = self._A()
    D: uint256 = self.get_D(xp_, A_)
    Ann: uint256 = A_ * N_COINS
    c: uint256 = D
    S_: uint256 = 0
    _x: uint256 = 0
    y_prev: uint256 = 0

    for _i in range(N_COINS):
        if _i == i:
            _x = x
        elif _i != j:
            _x = xp_[_i]
        else:
            continue
        S_ += _x
        c = c * D / (_x * N_COINS)
    c = c * D * A_PRECISION / (Ann * N_COINS)
    b: uint256 = S_ + D * A_PRECISION / Ann  # - D
    y: uint256 = D
    for _i in range(255):
        y_prev = y
        y = (y*y + c) / (2 * y + b - D)
        # Equality with the precision of 1
        if y > y_prev:
            if y - y_prev <= 1:
                return y
        else:
            if y_prev - y <= 1:
                return y
    raise


@view
@external
def get_dy(i: int128, j: int128, dx: uint256) -> uint256:
    # dx and dy in c-units
    rates: uint256[N_COINS] = self._stored_rates()
    xp: uint256[N_COINS] = self._xp(rates)

    x: uint256 = xp[i] + dx * rates[i] / PRECISION
    y: uint256 = self.get_y(i, j, x, xp)
    dy: uint256 = xp[j] - y - 1
    return (dy - (self.fee * dy / FEE_DENOMINATOR)) * PRECISION / rates[j]


@view
@external
def get_dx(i: int128, j: int128, dy: uint256) -> uint256:
    # dx and dy in c-units
    rates: uint256[N_COINS] = self._stored_rates()
    xp: uint256[N_COINS] = self._xp(rates)

    y: uint256 = xp[j] - (dy * FEE_DENOMINATOR / (FEE_DENOMINATOR - self.fee)) * rates[j] / PRECISION
    x: uint256 = self.get_y(j, i, y, xp)
    return (x - xp[i]) * PRECISION / rates[i]


@view
@external
def get_dy_underlying(i: int128, j: int128, dx: uint256) -> uint256:
    # dx and dy in underlying units
    rates: uint256[N_COINS] = self._stored_rates()
    xp: uint256[N_COINS] = self._xp(rates)
    precisions: uint256[N_COINS] = PRECISION_MUL

    x: uint256 = xp[i] + dx * precisions[i]
    dy: uint256 = xp[j] - self.get_y(i, j, x, xp) - 1
    _fee: uint256 = self.fee * dy / FEE_DENOMINATOR
    return (dy - _fee) / precisions[j]


@external
@view
def get_dx_underlying(i: int128, j: int128, dy: uint256) -> uint256:
    # dx and dy in underlying units
    rates: uint256[N_COINS] = self._stored_rates()
    xp: uint256[N_COINS] = self._xp(rates)
    precisions: uint256[N_COINS] = PRECISION_MUL

    y: uint256 = xp[j] - (dy * FEE_DENOMINATOR / (FEE_DENOMINATOR - self.fee)) * precisions[j]
    return (self.get_y(j, i, y, xp) - xp[i]) / precisions[i]

@internal
def _exchange(i: int128, j: int128, dx: uint256) -> uint256:
    assert not self.is_killed
    # dx and dy are in cy tokens

    rates: uint256[N_COINS] = self._current_rates()
    old_balances: uint256[N_COINS] = self.balances

    xp: uint256[N_COINS] = empty(uint256[N_COINS])
    for k in range(N_COINS):
        xp[k] = rates[k] * old_balances[k] / PRECISION

    x: uint256 = xp[i] + dx * rates[i] / PRECISION
    dy: uint256 = xp[j] - self.get_y(i, j, x, xp) - 1  # -1 just in case there were some rounding errors
    dy_fee: uint256 = dy * self.fee / FEE_DENOMINATOR

    dy = (dy - dy_fee) * PRECISION / rates[j]
    dy_admin_fee: uint256 = dy_fee * self.admin_fee / FEE_DENOMINATOR
    dy_admin_fee = dy_admin_fee * PRECISION / rates[j]

    self.balances[i] = old_balances[i] + dx
    self.balances[j] = old_balances[j] - dy - dy_admin_fee

    return dy


@external
@nonreentrant('lock')
def exchange(i: int128, j: int128, dx: uint256, min_dy: uint256) -> uint256:
    """
    @notice Perform an exchange between two coins
    @dev Index values can be found via the `coins` public getter method
    @param i Index value for the coin to send
    @param j Index valie of the coin to recieve
    @param dx Amount of `i` being exchanged
    @param min_dy Minimum amount of `j` to receive
    @return Actual amount of `j` received
    """
    dy: uint256 = self._exchange(i, j, dx)
    assert dy >= min_dy, "Too few coins in result"

    assert cyToken(self.coins[i]).transferFrom(msg.sender, self, dx)
    assert cyToken(self.coins[j]).transfer(msg.sender, dy)

    log TokenExchange(msg.sender, i, dx, j, dy)

    return dy


@external
@nonreentrant('lock')
def exchange_underlying(i: int128, j: int128, dx: uint256, min_dy: uint256) -> uint256:
    """
    @notice Perform an exchange between two underlying coins
    @dev Index values can be found via the `underlying_coins` public getter method
    @param i Index value for the underlying coin to send
    @param j Index valie of the underlying coin to recieve
    @param dx Amount of `i` being exchanged
    @param min_dy Minimum amount of `j` to receive
    @return Actual amount of `j` received
    """

    ERC20(self.underlying_coins[i]).transferFrom(msg.sender, self, dx)

    coin: address = self.coins[i]

    dx_: uint256 = ERC20(coin).balanceOf(self)
    assert cyToken(coin).mint(dx) == 0
    dx_ = ERC20(coin).balanceOf(self) - dx_
    dy_: uint256 = self._exchange(i, j, dx_)

    assert cyToken(self.coins[j]).redeem(dy_) == 0

    underlying: address = self.underlying_coins[j]

    dy: uint256 = ERC20(underlying).balanceOf(self)
    assert dy >= min_dy, "Too few coins in result"

    ERC20(underlying).transfer(msg.sender, dy)

    log TokenExchangeUnderlying(msg.sender, i, dx, j, dy)

    return dy


@external
@nonreentrant('lock')
def remove_liquidity(
    _amount: uint256,
    _min_amounts: uint256[N_COINS],
    _use_underlying: bool = False
) -> uint256[N_COINS]:
    """
    @notice Withdraw coins from the pool
    @dev Withdrawal amounts are based on current deposit ratios
    @param _amount Quantity of LP tokens to burn in the withdrawal
    @param _min_amounts Minimum amounts of underlying coins to receive
    @param _use_underlying If True, withdraw underlying assets instead of cyTokens
    @return List of amounts of coins that were withdrawn
    """
    self._update()
    _lp_token: address = self.lp_token
    total_supply: uint256 = ERC20(_lp_token).totalSupply()
    amounts: uint256[N_COINS] = empty(uint256[N_COINS])

    for i in range(N_COINS):
        _balance: uint256 = self.balances[i]
        value: uint256 = _balance * _amount / total_supply
        self.balances[i] = _balance - value
        amounts[i] = value

        coin: address = self.coins[i]
        if _use_underlying:
            assert cyToken(coin).redeem(value) == 0
            underlying: address = self.underlying_coins[i]
            value = ERC20(underlying).balanceOf(self)
            ERC20(underlying).transfer(msg.sender, value)
        else:
            assert cyToken(coin).transfer(msg.sender, value)

        assert value >= _min_amounts[i]

    CurveToken(_lp_token).burnFrom(msg.sender, _amount)  # Will raise if not enough

    log RemoveLiquidity(msg.sender, amounts, empty(uint256[N_COINS]), total_supply - _amount)

    return amounts


@external
@nonreentrant('lock')
def remove_liquidity_imbalance(
    _amounts: uint256[N_COINS],
    _max_burn_amount: uint256,
    _use_underlying: bool = False
) -> uint256:
    """
    @notice Withdraw coins from the pool in an imbalanced amount
    @param _amounts List of amounts of underlying coins to withdraw
    @param _max_burn_amount Maximum amount of LP token to burn in the withdrawal
    @param _use_underlying If True, withdraw underlying assets instead of cyTokens
    @return Actual amount of the LP token burned in the withdrawal
    """
    assert not self.is_killed

    amp: uint256 = self._A()
    rates: uint256[N_COINS] = self._current_rates()
    old_balances: uint256[N_COINS] = self.balances
    D0: uint256 = self.get_D_mem(rates, old_balances, amp)

    new_balances: uint256[N_COINS] = old_balances
    amounts: uint256[N_COINS] = _amounts

    precisions: uint256[N_COINS] = PRECISION_MUL
    for i in range(N_COINS):
        amount: uint256 = amounts[i]
        if amount > 0:
            if _use_underlying:
                amount = amount * precisions[i] * PRECISION / rates[i]
                amounts[i] = amount
            new_balances[i] -= amount

    D1: uint256 = self.get_D_mem(rates, new_balances, amp)

    fees: uint256[N_COINS] = empty(uint256[N_COINS])
    _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
    _admin_fee: uint256 = self.admin_fee
    for i in range(N_COINS):
        ideal_balance: uint256 = D1 * old_balances[i] / D0
        new_balance: uint256 = new_balances[i]
        difference: uint256 = 0
        if ideal_balance > new_balance:
            difference = ideal_balance - new_balance
        else:
            difference = new_balance - ideal_balance
        coin_fee: uint256 = _fee * difference / FEE_DENOMINATOR
        self.balances[i] = new_balance - (coin_fee * _admin_fee / FEE_DENOMINATOR)
        new_balances[i] -= coin_fee
        fees[i] = coin_fee
    D2: uint256 = self.get_D_mem(rates, new_balances, amp)

    lp_token: address = self.lp_token
    token_supply: uint256 = ERC20(lp_token).totalSupply()
    token_amount: uint256 = (D0 - D2) * token_supply / D0
    assert token_amount != 0
    assert token_amount <= _max_burn_amount, "Slippage screwed you"

    CurveToken(lp_token).burnFrom(msg.sender, token_amount)  # dev: insufficient funds
    for i in range(N_COINS):
        amount: uint256 = amounts[i]
        if amount != 0:
            coin: address = self.coins[i]
            if _use_underlying:
                assert cyToken(coin).redeem(amount) == 0
                underlying: address = self.underlying_coins[i]
                ERC20(underlying).transfer(msg.sender, ERC20(underlying).balanceOf(self))
            else:
                assert cyToken(coin).transfer(msg.sender, amount)

    log RemoveLiquidityImbalance(msg.sender, amounts, fees, D1, token_supply - token_amount)

    return token_amount


@pure
@internal
def get_y_D(A_: uint256, i: int128, xp: uint256[N_COINS], D: uint256) -> uint256:
    """
    Calculate x[i] if one reduces D from being calculated for xp to D

    Done by solving quadratic equation iteratively.
    x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
    x_1**2 + b*x_1 = c

    x_1 = (x_1**2 + c) / (2*x_1 + b)
    """
    # x in the input is converted to the same price/precision

    assert i >= 0  # dev: i below zero
    assert i < N_COINS  # dev: i above N_COINS

    Ann: uint256 = A_ * N_COINS
    c: uint256 = D
    S_: uint256 = 0
    _x: uint256 = 0
    y_prev: uint256 = 0

    for _i in range(N_COINS):
        if _i != i:
            _x = xp[_i]
        else:
            continue
        S_ += _x
        c = c * D / (_x * N_COINS)
    c = c * D * A_PRECISION / (Ann * N_COINS)
    b: uint256 = S_ + D * A_PRECISION / Ann
    y: uint256 = D

    for _i in range(255):
        y_prev = y
        y = (y*y + c) / (2 * y + b - D)
        # Equality with the precision of 1
        if y > y_prev:
            if y - y_prev <= 1:
                return y
        else:
            if y_prev - y <= 1:
                return y
    raise


@view
@internal
def _calc_withdraw_one_coin(_token_amount: uint256, i: int128, _use_underlying: bool, _rates: uint256[N_COINS]) -> uint256[2]:
    # First, need to calculate
    # * Get current D
    # * Solve Eqn against y_i for D - _token_amount
    amp: uint256 = self._A()
    xp: uint256[N_COINS] = self._xp(_rates)
    D0: uint256 = self.get_D(xp, amp)

    total_supply: uint256 = ERC20(self.lp_token).totalSupply()

    D1: uint256 = D0 - _token_amount * D0 / total_supply
    new_y: uint256 = self.get_y_D(amp, i, xp, D1)

    xp_reduced: uint256[N_COINS] = xp
    _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
    rate: uint256 = _rates[i]

    for j in range(N_COINS):
        dx_expected: uint256 = 0
        xp_j: uint256 = xp[j]
        if j == i:
            dx_expected = xp_j * D1 / D0 - new_y
        else:
            dx_expected = xp_j - xp_j * D1 / D0
        xp_reduced[j] -= _fee * dx_expected / FEE_DENOMINATOR

    dy: uint256 = xp_reduced[i] - self.get_y_D(amp, i, xp_reduced, D1)
    dy = (dy - 1) * PRECISION / rate  # Withdraw less to account for rounding errors
    dy_fee: uint256 = ((xp[i] - new_y) * PRECISION / rate) - dy
    if _use_underlying:
        # this branch is only reachable when called via `calc_withdraw_one_coin`, which
        # only needs `dy` - so we don't bother converting `dy_fee` to the underlying
        precisions: uint256[N_COINS] = PRECISION_MUL
        dy = dy * rate / precisions[i] / PRECISION

    return [dy, dy_fee]


@view
@external
def calc_withdraw_one_coin(_token_amount: uint256, i: int128, _use_underlying: bool = False) -> uint256:
    """
    @notice Calculate the amount received when withdrawing a single coin
    @param _token_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the coin to withdraw
    @return Amount of coin received
    """
    return self._calc_withdraw_one_coin(_token_amount, i, _use_underlying, self._stored_rates())[0]


@external
@nonreentrant('lock')
def remove_liquidity_one_coin(
    _token_amount: uint256,
    i: int128,
    _min_amount: uint256,
    _use_underlying: bool = False
) -> uint256:
    """
    @notice Withdraw a single coin from the pool
    @param _token_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the coin to withdraw
    @param _min_amount Minimum amount of coin to receive
    @param _use_underlying If True, withdraw underlying assets instead of cyTokens
    @return Amount of coin received
    """
    assert not self.is_killed  # dev: is killed

    dy: uint256[2] = self._calc_withdraw_one_coin(_token_amount, i, False, self._current_rates())
    amount: uint256 = dy[0]

    self.balances[i] -= (dy[0] + dy[1] * self.admin_fee / FEE_DENOMINATOR)
    CurveToken(self.lp_token).burnFrom(msg.sender, _token_amount)  # dev: insufficient funds
    coin: address = self.coins[i]
    if _use_underlying:
        assert cyToken(coin).redeem(dy[0]) == 0
        underlying: address = self.underlying_coins[i]
        amount = ERC20(underlying).balanceOf(self)
        ERC20(underlying).transfer(msg.sender, amount)
    else:
        assert cyToken(coin).transfer(msg.sender, amount)

    assert amount >= _min_amount, "Not enough coins removed"
    log RemoveLiquidityOne(msg.sender, _token_amount, dy[0])

    return dy[0]


### Admin functions ###
@external
def ramp_A(_future_A: uint256, _future_time: uint256):
    assert msg.sender == self.owner  # dev: only owner
    assert block.timestamp >= self.initial_A_time + MIN_RAMP_TIME
    assert _future_time >= block.timestamp + MIN_RAMP_TIME  # dev: insufficient time

    _initial_A: uint256 = self._A()
    _future_A_p: uint256 = _future_A * A_PRECISION

    assert _future_A > 0 and _future_A < MAX_A
    if _future_A_p < _initial_A:
        assert _future_A_p * MAX_A_CHANGE >= _initial_A
    else:
        assert _future_A_p <= _initial_A * MAX_A_CHANGE

    self.initial_A = _initial_A
    self.future_A = _future_A_p
    self.initial_A_time = block.timestamp
    self.future_A_time = _future_time

    log RampA(_initial_A, _future_A_p, block.timestamp, _future_time)


@external
def stop_ramp_A():
    assert msg.sender == self.owner  # dev: only owner

    current_A: uint256 = self._A()
    self.initial_A = current_A
    self.future_A = current_A
    self.initial_A_time = block.timestamp
    self.future_A_time = block.timestamp
    # now (block.timestamp < t1) is always False, so we return saved A

    log StopRampA(current_A, block.timestamp)


@external
def commit_new_fee(new_fee: uint256, new_admin_fee: uint256):
    assert msg.sender == self.owner  # dev: only owner
    assert self.admin_actions_deadline == 0  # dev: active action
    assert new_fee <= MAX_FEE  # dev: fee exceeds maximum
    assert new_admin_fee <= MAX_ADMIN_FEE  # dev: admin fee exceeds maximum

    _deadline: uint256 = block.timestamp + ADMIN_ACTIONS_DELAY
    self.admin_actions_deadline = _deadline
    self.future_fee = new_fee
    self.future_admin_fee = new_admin_fee

    log CommitNewFee(_deadline, new_fee, new_admin_fee)


@external
def apply_new_fee():
    assert msg.sender == self.owner  # dev: only owner
    assert block.timestamp >= self.admin_actions_deadline  # dev: insufficient time
    assert self.admin_actions_deadline != 0  # dev: no active action

    self.admin_actions_deadline = 0
    _fee: uint256 = self.future_fee
    _admin_fee: uint256 = self.future_admin_fee
    self.fee = _fee
    self.admin_fee = _admin_fee

    log NewFee(_fee, _admin_fee)


@external
def revert_new_parameters():
    assert msg.sender == self.owner  # dev: only owner

    self.admin_actions_deadline = 0


@external
def commit_transfer_ownership(_owner: address):
    assert msg.sender == self.owner  # dev: only owner
    assert self.transfer_ownership_deadline == 0  # dev: active transfer

    _deadline: uint256 = block.timestamp + ADMIN_ACTIONS_DELAY
    self.transfer_ownership_deadline = _deadline
    self.future_owner = _owner

    log CommitNewAdmin(_deadline, _owner)


@external
def apply_transfer_ownership():
    assert msg.sender == self.owner  # dev: only owner
    assert block.timestamp >= self.transfer_ownership_deadline  # dev: insufficient time
    assert self.transfer_ownership_deadline != 0  # dev: no active transfer

    self.transfer_ownership_deadline = 0
    _owner: address = self.future_owner
    self.owner = _owner

    log NewAdmin(_owner)


@external
def revert_transfer_ownership():
    assert msg.sender == self.owner  # dev: only owner

    self.transfer_ownership_deadline = 0


@view
@external
def admin_balances(i: uint256) -> uint256:
    return ERC20(self.coins[i]).balanceOf(self) - self.balances[i]


@external
def withdraw_admin_fees():
    assert msg.sender == self.owner  # dev: only owner

    for i in range(N_COINS):
        coin: address = self.coins[i]
        value: uint256 = ERC20(coin).balanceOf(self) - self.balances[i]
        if value > 0:
            assert cyToken(coin).transfer(msg.sender, value)


@external
def kill_me():
    assert msg.sender == self.owner  # dev: only owner
    assert self.kill_deadline > block.timestamp  # dev: deadline has passed
    self.is_killed = True


@external
def unkill_me():
    assert msg.sender == self.owner  # dev: only owner
    self.is_killed = False