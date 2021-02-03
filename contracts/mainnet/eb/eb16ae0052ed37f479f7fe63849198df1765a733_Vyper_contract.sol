# @version 0.2.8
"""
@title Curve saPool
@author Curve.Fi
@license Copyright (c) Curve.Fi, 2020 - all rights reserved
@notice Pool implementation with aToken-style lending
"""

from vyper.interfaces import ERC20


interface LendingPool:
    def withdraw(_underlying_asset: address, _amount: uint256, _receiver: address): nonpayable

interface CurveToken:
    def mint(_to: address, _value: uint256) -> bool: nonpayable
    def burnFrom(_to: address, _value: uint256) -> bool: nonpayable


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
    offpeg_fee_multiplier: uint256

event NewFee:
    fee: uint256
    admin_fee: uint256
    offpeg_fee_multiplier: uint256

event RampA:
    old_A: uint256
    new_A: uint256
    initial_time: uint256
    future_time: uint256

event StopRampA:
    A: uint256
    t: uint256


N_COINS: constant(int128) = 2

# fixed constants
FEE_DENOMINATOR: constant(uint256) = 10 ** 10
PRECISION: constant(uint256) = 10 ** 18

MAX_ADMIN_FEE: constant(uint256) = 10 * 10 ** 9
MAX_FEE: constant(uint256) = 5 * 10 ** 9

MAX_A: constant(uint256) = 10 ** 6
MAX_A_CHANGE: constant(uint256) = 10
A_PRECISION: constant(uint256) = 100

ADMIN_ACTIONS_DELAY: constant(uint256) = 3 * 86400
MIN_RAMP_TIME: constant(uint256) = 86400

coins: public(address[N_COINS])
underlying_coins: public(address[N_COINS])
admin_balances: public(uint256[N_COINS])

fee: public(uint256)  # fee * 1e10
offpeg_fee_multiplier: public(uint256)  # * 1e10
admin_fee: public(uint256)  # admin_fee * 1e10

owner: public(address)
lp_token: public(address)

aave_lending_pool: address
aave_referral: uint256

initial_A: public(uint256)
future_A: public(uint256)
initial_A_time: public(uint256)
future_A_time: public(uint256)

admin_actions_deadline: public(uint256)
transfer_ownership_deadline: public(uint256)
future_fee: public(uint256)
future_admin_fee: public(uint256)
future_offpeg_fee_multiplier: public(uint256)  # * 1e10
future_owner: public(address)

is_killed: bool
kill_deadline: uint256
KILL_DEADLINE_DT: constant(uint256) = 2 * 30 * 86400


@external
def __init__(
    _coins: address[N_COINS],
    _underlying_coins: address[N_COINS],
    _pool_token: address,
    _aave_lending_pool: address,
    _A: uint256,
    _fee: uint256,
    _admin_fee: uint256,
    _offpeg_fee_multiplier: uint256,
):
    """
    @notice Contract constructor
    @param _coins List of wrapped coin addresses
    @param _underlying_coins List of underlying coin addresses
    @param _pool_token Pool LP token address
    @param _aave_lending_pool Aave lending pool address
    @param _A Amplification coefficient multiplied by n * (n - 1)
    @param _fee Swap fee expressed as an integer with 1e10 precision
    @param _admin_fee Percentage of fee taken as an admin fee,
                      expressed as an integer with 1e10 precision
    @param _offpeg_fee_multiplier Offpeg fee multiplier
    """
    for i in range(N_COINS):
        assert _coins[i] != ZERO_ADDRESS
        assert _underlying_coins[i] != ZERO_ADDRESS

    self.coins = _coins
    self.underlying_coins = _underlying_coins
    self.initial_A = _A * A_PRECISION
    self.future_A = _A * A_PRECISION
    self.fee = _fee
    self.admin_fee = _admin_fee
    self.offpeg_fee_multiplier = _offpeg_fee_multiplier
    self.owner = msg.sender
    self.kill_deadline = block.timestamp + KILL_DEADLINE_DT
    self.lp_token = _pool_token
    self.aave_lending_pool = _aave_lending_pool

    # approve transfer of underlying coin to aave lending pool
    for coin in _underlying_coins:
        assert ERC20(coin).approve(_aave_lending_pool, MAX_UINT256)


@view
@internal
def _A() -> uint256:
    t1: uint256 = self.future_A_time
    A1: uint256 = self.future_A

    if block.timestamp < t1:
        # handle ramping up and down of A
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


@pure
@internal
def _dynamic_fee(xpi: uint256, xpj: uint256, _fee: uint256, _feemul: uint256) -> uint256:
    if _feemul <= FEE_DENOMINATOR:
        return _fee
    else:
        xps2: uint256 = (xpi + xpj)
        xps2 *= xps2  # Doing just ** 2 can overflow apparently
        return (_feemul * _fee) / (
            (_feemul - FEE_DENOMINATOR) * 4 * xpi * xpj / xps2 + \
            FEE_DENOMINATOR)


@view
@external
def dynamic_fee(i: int128, j: int128) -> uint256:
    """
    @notice Return the fee for swapping between `i` and `j`
    @param i Index value for the coin to send
    @param j Index value of the coin to recieve
    @return Swap fee expressed as an integer with 1e10 precision
    """
    xpi: uint256 = (ERC20(self.coins[i]).balanceOf(self) - self.admin_balances[i])
    xpj: uint256 = (ERC20(self.coins[j]).balanceOf(self) - self.admin_balances[j])
    return self._dynamic_fee(xpi, xpj, self.fee, self.offpeg_fee_multiplier)


@view
@external
def balances(i: uint256) -> uint256:
    """
    @notice Get the current balance of a coin within the
            pool, less the accrued admin fees
    @param i Index value for the coin to query balance of
    @return Token balance
    """
    return ERC20(self.coins[i]).balanceOf(self) - self.admin_balances[i]


@view
@internal
def _balances() -> uint256[N_COINS]:
    result: uint256[N_COINS] = empty(uint256[N_COINS])
    for i in range(N_COINS):
        result[i] = ERC20(self.coins[i]).balanceOf(self) - self.admin_balances[i]
    return result


@pure
@internal
def get_D(xp: uint256[N_COINS], amp: uint256) -> uint256:
    """
    D invariant calculation in non-overflowing integer operations
    iteratively

    A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))

    Converging solution:
    D[j+1] = (A * n**n * sum(x_i) - D[j]**(n+1) / (n**n prod(x_i))) / (A * n**n - 1)
    """
    S: uint256 = 0

    for _x in xp:
        S += _x
    if S == 0:
        return 0

    Dprev: uint256 = 0
    D: uint256 = S
    Ann: uint256 = amp * N_COINS
    for _i in range(255):
        D_P: uint256 = D
        for _x in xp:
            D_P = D_P * D / (_x * N_COINS + 1)  # +1 is to prevent /0
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
@external
def get_virtual_price() -> uint256:
    """
    @notice The current virtual price of the pool LP token
    @dev Useful for calculating profits
    @return LP token virtual price normalized to 1e18
    """
    D: uint256 = self.get_D(self._balances(), self._A())
    # D is in the units similar to DAI (e.g. converted to precision 1e18)
    # When balanced, D = n * x_u - total virtual value of the portfolio
    token_supply: uint256 = ERC20(self.lp_token).totalSupply()
    return D * PRECISION / token_supply


@view
@external
def calc_token_amount(_amounts: uint256[N_COINS], is_deposit: bool) -> uint256:
    """
    @notice Calculate addition or reduction in token supply from a deposit or withdrawal
    @dev This calculation accounts for slippage, but not fees.
         Needed to prevent front-running, not for precise calculations!
    @param _amounts Amount of each coin being deposited
    @param is_deposit set True for deposits, False for withdrawals
    @return Expected amount of LP tokens received
    """
    coin_balances: uint256[N_COINS] = self._balances()
    amp: uint256 = self._A()
    D0: uint256 = self.get_D(coin_balances, amp)
    for i in range(N_COINS):
        if is_deposit:
            coin_balances[i] += _amounts[i]
        else:
            coin_balances[i] -= _amounts[i]
    D1: uint256 = self.get_D(coin_balances, amp)
    token_amount: uint256 = ERC20(self.lp_token).totalSupply()
    diff: uint256 = 0
    if is_deposit:
        diff = D1 - D0
    else:
        diff = D0 - D1
    return diff * token_amount / D0


@external
@nonreentrant('lock')
def add_liquidity(_amounts: uint256[N_COINS], _min_mint_amount: uint256, _use_underlying: bool = False) -> uint256:
    """
    @notice Deposit coins into the pool
    @param _amounts List of amounts of coins to deposit
    @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
    @param _use_underlying If True, deposit underlying assets instead of aTokens
    @return Amount of LP tokens received by depositing
    """

    assert not self.is_killed  # dev: is killed

    # Initial invariant
    amp: uint256 = self._A()
    old_balances: uint256[N_COINS] = self._balances()
    lp_token: address = self.lp_token
    token_supply: uint256 = ERC20(lp_token).totalSupply()
    D0: uint256 = 0
    if token_supply != 0:
        D0 = self.get_D(old_balances, amp)

    new_balances: uint256[N_COINS] = old_balances
    for i in range(N_COINS):
        if token_supply == 0:
            assert _amounts[i] != 0  # dev: initial deposit requires all coins
        new_balances[i] += _amounts[i]

    # Invariant after change
    D1: uint256 = self.get_D(new_balances, amp)
    assert D1 > D0

    # We need to recalculate the invariant accounting for fees
    # to calculate fair user's share
    fees: uint256[N_COINS] = empty(uint256[N_COINS])
    mint_amount: uint256 = 0
    if token_supply != 0:
        # Only account for fees if we are not the first to deposit
        ys: uint256 = (D0 + D1) / N_COINS
        _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
        _feemul: uint256 = self.offpeg_fee_multiplier
        _admin_fee: uint256 = self.admin_fee
        difference: uint256 = 0
        for i in range(N_COINS):
            ideal_balance: uint256 = D1 * old_balances[i] / D0
            new_balance: uint256 = new_balances[i]
            if ideal_balance > new_balance:
                difference = ideal_balance - new_balance
            else:
                difference = new_balance - ideal_balance
            xs: uint256 = old_balances[i] + new_balance
            fees[i] = self._dynamic_fee(xs, ys, _fee, _feemul) * difference / FEE_DENOMINATOR
            if _admin_fee != 0:
                self.admin_balances[i] += fees[i] * _admin_fee / FEE_DENOMINATOR
            new_balances[i] = new_balance - fees[i]
        D2: uint256 = self.get_D(new_balances, amp)
        mint_amount = token_supply * (D2 - D0) / D0
    else:
        mint_amount = D1  # Take the dust if there was any

    assert mint_amount >= _min_mint_amount, "Slippage screwed you"

    # Take coins from the sender
    if _use_underlying:
        lending_pool: address = self.aave_lending_pool
        aave_referral: bytes32 = convert(self.aave_referral, bytes32)

        # Take coins from the sender
        for i in range(N_COINS):
            amount: uint256 = _amounts[i]
            if amount != 0:
                coin: address = self.underlying_coins[i]
                # transfer underlying coin from msg.sender to self
                assert ERC20(coin).transferFrom(msg.sender, self, amount)

                # deposit to aave lending pool
                raw_call(
                    lending_pool,
                    concat(
                        method_id("deposit(address,uint256,address,uint16)"),
                        convert(coin, bytes32),
                        convert(amount, bytes32),
                        convert(self, bytes32),
                        aave_referral,
                    )
                )
    else:
        for i in range(N_COINS):
            amount: uint256 = _amounts[i]
            if amount != 0:
                assert ERC20(self.coins[i]).transferFrom(msg.sender, self, amount) # dev: failed transfer

    # Mint pool tokens
    CurveToken(lp_token).mint(msg.sender, mint_amount)

    log AddLiquidity(msg.sender, _amounts, fees, D1, token_supply + mint_amount)

    return mint_amount


@view
@internal
def get_y(i: int128, j: int128, x: uint256, xp: uint256[N_COINS]) -> uint256:
    """
    Calculate x[j] if one makes x[i] = x

    Done by solving quadratic equation iteratively.
    x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
    x_1**2 + b*x_1 = c

    x_1 = (x_1**2 + c) / (2*x_1 + b)
    """
    # x in the input is converted to the same price/precision

    assert i != j       # dev: same coin
    assert j >= 0       # dev: j below zero
    assert j < N_COINS  # dev: j above N_COINS

    # should be unreachable, but good for safety
    assert i >= 0
    assert i < N_COINS

    amp: uint256 = self._A()
    D: uint256 = self.get_D(xp, amp)
    Ann: uint256 = amp * N_COINS
    c: uint256 = D
    S_: uint256 = 0
    _x: uint256 = 0
    y_prev: uint256 = 0

    for _i in range(N_COINS):
        if _i == i:
            _x = x
        elif _i != j:
            _x = xp[_i]
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
@internal
def _get_dy(i: int128, j: int128, dx: uint256) -> uint256:
    xp: uint256[N_COINS] = self._balances()

    x: uint256 = xp[i] + dx
    y: uint256 = self.get_y(i, j, x, xp)
    dy: uint256 = (xp[j] - y)
    _fee: uint256 = self._dynamic_fee(
            (xp[i] + x) / 2, (xp[j] + y) / 2, self.fee, self.offpeg_fee_multiplier
        ) * dy / FEE_DENOMINATOR
    return dy - _fee


@view
@external
def get_dy(i: int128, j: int128, dx: uint256) -> uint256:
    return self._get_dy(i, j, dx)


@view
@external
def get_dy_underlying(i: int128, j: int128, dx: uint256) -> uint256:
    return self._get_dy(i, j, dx)


@internal
def _exchange(i: int128, j: int128, dx: uint256) -> uint256:
    assert not self.is_killed  # dev: is killed
    # dx and dy are in aTokens

    xp: uint256[N_COINS] = self._balances()

    x: uint256 = xp[i] + dx
    y: uint256 = self.get_y(i, j, x, xp)
    dy: uint256 = xp[j] - y
    dy_fee: uint256 = dy * self._dynamic_fee(
            (xp[i] + x) / 2, (xp[j] + y) / 2, self.fee, self.offpeg_fee_multiplier
        ) / FEE_DENOMINATOR

    admin_fee: uint256 = self.admin_fee
    if admin_fee != 0:
        dy_admin_fee: uint256 = dy_fee * admin_fee / FEE_DENOMINATOR
        if dy_admin_fee != 0:
            self.admin_balances[j] += dy_admin_fee

    return dy - dy_fee


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
    assert dy >= min_dy, "Exchange resulted in fewer coins than expected"

    assert ERC20(self.coins[i]).transferFrom(msg.sender, self, dx)
    assert ERC20(self.coins[j]).transfer(msg.sender, dy)

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
    dy: uint256 = self._exchange(i, j, dx)
    assert dy >= min_dy, "Exchange resulted in fewer coins than expected"

    u_coin_i: address = self.underlying_coins[i]
    lending_pool: address = self.aave_lending_pool

    # transfer underlying coin from msg.sender to self
    assert ERC20(u_coin_i).transferFrom(msg.sender, self, dx)

    # deposit to aave lending pool
    raw_call(
        lending_pool,
        concat(
            method_id("deposit(address,uint256,address,uint16)"),
            convert(u_coin_i, bytes32),
            convert(dx, bytes32),
            convert(self, bytes32),
            convert(self.aave_referral, bytes32),
        )
    )
    # withdraw `j` underlying from lending pool and transfer to caller
    LendingPool(lending_pool).withdraw(self.underlying_coins[j], dy, msg.sender)

    log TokenExchangeUnderlying(msg.sender, i, dx, j, dy)

    return dy


@external
@nonreentrant('lock')
def remove_liquidity(
    _amount: uint256,
    _min_amounts: uint256[N_COINS],
    _use_underlying: bool = False,
) -> uint256[N_COINS]:
    """
    @notice Withdraw coins from the pool
    @dev Withdrawal amounts are based on current deposit ratios
    @param _amount Quantity of LP tokens to burn in the withdrawal
    @param _min_amounts Minimum amounts of underlying coins to receive
    @param _use_underlying If True, withdraw underlying assets instead of aTokens
    @return List of amounts of coins that were withdrawn
    """
    amounts: uint256[N_COINS] = self._balances()
    lp_token: address = self.lp_token
    total_supply: uint256 = ERC20(lp_token).totalSupply()
    CurveToken(lp_token).burnFrom(msg.sender, _amount)  # dev: insufficient funds

    lending_pool: address = ZERO_ADDRESS
    if _use_underlying:
        lending_pool = self.aave_lending_pool

    for i in range(N_COINS):
        value: uint256 = amounts[i] * _amount / total_supply
        assert value >= _min_amounts[i], "Withdrawal resulted in fewer coins than expected"
        amounts[i] = value
        if _use_underlying:
            LendingPool(lending_pool).withdraw(self.underlying_coins[i], value, msg.sender)
        else:
            assert ERC20(self.coins[i]).transfer(msg.sender, value)

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
    @param _use_underlying If True, withdraw underlying assets instead of aTokens
    @return Actual amount of the LP token burned in the withdrawal
    """
    assert not self.is_killed  # dev: is killed

    amp: uint256 = self._A()
    old_balances: uint256[N_COINS] = self._balances()
    D0: uint256 = self.get_D(old_balances, amp)
    new_balances: uint256[N_COINS] = old_balances
    for i in range(N_COINS):
        new_balances[i] -= _amounts[i]
    D1: uint256 = self.get_D(new_balances, amp)
    ys: uint256 = (D0 + D1) / N_COINS

    lp_token: address = self.lp_token
    token_supply: uint256 = ERC20(lp_token).totalSupply()
    assert token_supply != 0  # dev: zero total supply

    _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
    _feemul: uint256 = self.offpeg_fee_multiplier
    _admin_fee: uint256 = self.admin_fee
    fees: uint256[N_COINS] = empty(uint256[N_COINS])
    for i in range(N_COINS):
        ideal_balance: uint256 = D1 * old_balances[i] / D0
        new_balance: uint256 = new_balances[i]
        difference: uint256 = 0
        if ideal_balance > new_balance:
            difference = ideal_balance - new_balance
        else:
            difference = new_balance - ideal_balance
        xs: uint256 = new_balance + old_balances[i]
        fees[i] = self._dynamic_fee(xs, ys, _fee, _feemul) * difference / FEE_DENOMINATOR
        if _admin_fee != 0:
            self.admin_balances[i] += fees[i] * _admin_fee / FEE_DENOMINATOR
        new_balances[i] -= fees[i]
    D2: uint256 = self.get_D(new_balances, amp)

    token_amount: uint256 = (D0 - D2) * token_supply / D0
    assert token_amount != 0  # dev: zero tokens burned
    assert token_amount <= _max_burn_amount, "Slippage screwed you"

    CurveToken(lp_token).burnFrom(msg.sender, token_amount)  # dev: insufficient funds

    lending_pool: address = ZERO_ADDRESS
    if _use_underlying:
        lending_pool = self.aave_lending_pool

    for i in range(N_COINS):
        amount: uint256 = _amounts[i]
        if amount != 0:
            if _use_underlying:
                LendingPool(lending_pool).withdraw(self.underlying_coins[i], amount, msg.sender)
            else:
                assert ERC20(self.coins[i]).transfer(msg.sender, amount)

    log RemoveLiquidityImbalance(msg.sender, _amounts, fees, D1, token_supply - token_amount)

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

    assert i >= 0       # dev: i below zero
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
def _calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256:
    # First, need to calculate
    # * Get current D
    # * Solve Eqn against y_i for D - _token_amount
    amp: uint256 = self._A()
    xp: uint256[N_COINS] = self._balances()

    D0: uint256 = self.get_D(xp, amp)
    D1: uint256 = D0 - _token_amount * D0 / ERC20(self.lp_token).totalSupply()
    new_y: uint256 = self.get_y_D(amp, i, xp, D1)

    xp_reduced: uint256[N_COINS] = xp
    ys: uint256 = (D0 + D1) / (2 * N_COINS)

    _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
    feemul: uint256 = self.offpeg_fee_multiplier
    for j in range(N_COINS):
        dx_expected: uint256 = 0
        xavg: uint256 = 0
        if j == i:
            dx_expected = xp[j] * D1 / D0 - new_y
            xavg = (xp[j] + new_y) / 2
        else:
            dx_expected = xp[j] - xp[j] * D1 / D0
            xavg = xp[j]
        xp_reduced[j] -= self._dynamic_fee(xavg, ys, _fee, feemul) * dx_expected / FEE_DENOMINATOR

    dy: uint256 = xp_reduced[i] - self.get_y_D(amp, i, xp_reduced, D1)

    return dy - 1


@view
@external
def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256:
    """
    @notice Calculate the amount received when withdrawing a single coin
    @dev Result is the same for underlying or wrapped asset withdrawals
    @param _token_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the coin to withdraw
    @return Amount of coin received
    """
    return self._calc_withdraw_one_coin(_token_amount, i)


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
    @param _use_underlying If True, withdraw underlying assets instead of aTokens
    @return Amount of coin received
    """
    assert not self.is_killed  # dev: is killed

    dy: uint256 = self._calc_withdraw_one_coin(_token_amount, i)
    assert dy >= _min_amount, "Not enough coins removed"

    CurveToken(self.lp_token).burnFrom(msg.sender, _token_amount)  # dev: insufficient funds

    if _use_underlying:
        LendingPool(self.aave_lending_pool).withdraw(self.underlying_coins[i], dy, msg.sender)
    else:
        assert ERC20(self.coins[i]).transfer(msg.sender, dy)

    log RemoveLiquidityOne(msg.sender, _token_amount, dy)

    return dy


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
def commit_new_fee(new_fee: uint256, new_admin_fee: uint256, new_offpeg_fee_multiplier: uint256):
    assert msg.sender == self.owner  # dev: only owner
    assert self.admin_actions_deadline == 0  # dev: active action
    assert new_fee <= MAX_FEE  # dev: fee exceeds maximum
    assert new_admin_fee <= MAX_ADMIN_FEE  # dev: admin fee exceeds maximum
    assert new_offpeg_fee_multiplier * new_fee <= MAX_FEE * FEE_DENOMINATOR  # dev: offpeg multiplier exceeds maximum

    _deadline: uint256 = block.timestamp + ADMIN_ACTIONS_DELAY
    self.admin_actions_deadline = _deadline
    self.future_fee = new_fee
    self.future_admin_fee = new_admin_fee
    self.future_offpeg_fee_multiplier = new_offpeg_fee_multiplier

    log CommitNewFee(_deadline, new_fee, new_admin_fee, new_offpeg_fee_multiplier)


@external
def apply_new_fee():
    assert msg.sender == self.owner  # dev: only owner
    assert block.timestamp >= self.admin_actions_deadline  # dev: insufficient time
    assert self.admin_actions_deadline != 0  # dev: no active action

    self.admin_actions_deadline = 0
    _fee: uint256 = self.future_fee
    _admin_fee: uint256 = self.future_admin_fee
    _fml: uint256 = self.future_offpeg_fee_multiplier
    self.fee = _fee
    self.admin_fee = _admin_fee
    self.offpeg_fee_multiplier = _fml

    log NewFee(_fee, _admin_fee, _fml)


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


@external
def withdraw_admin_fees():
    assert msg.sender == self.owner  # dev: only owner

    for i in range(N_COINS):
        value: uint256 = self.admin_balances[i]
        if value != 0:
            assert ERC20(self.coins[i]).transfer(msg.sender, value)
            self.admin_balances[i] = 0


@external
def donate_admin_fees():
    """
    Just in case admin balances somehow become higher than total (rounding error?)
    this can be used to fix the state, too
    """
    assert msg.sender == self.owner  # dev: only owner
    self.admin_balances = empty(uint256[N_COINS])


@external
def kill_me():
    assert msg.sender == self.owner  # dev: only owner
    assert self.kill_deadline > block.timestamp  # dev: deadline has passed
    self.is_killed = True


@external
def unkill_me():
    assert msg.sender == self.owner  # dev: only owner
    self.is_killed = False


@external
def set_aave_referral(referral_code: uint256):
    assert msg.sender == self.owner  # dev: only owner
    assert referral_code < 2 ** 16  # dev: uint16 overflow
    self.aave_referral = referral_code