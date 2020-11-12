# @version 0.1.0b17
# A "zap" to deposit/withdraw Curve contract without too many transactions
# (c) Curve.Fi, 2020
from vyper.interfaces import ERC20

# External Contracts
contract yERC20:
    def totalSupply() -> uint256: constant
    def allowance(_owner: address, _spender: address) -> uint256: constant
    def transfer(_to: address, _value: uint256) -> bool: modifying
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: modifying
    def approve(_spender: address, _value: uint256) -> bool: modifying
    def name() -> string[64]: constant
    def symbol() -> string[32]: constant
    def decimals() -> uint256: constant
    def balanceOf(arg0: address) -> uint256: constant
    def deposit(depositAmount: uint256): modifying
    def withdraw(withdrawTokens: uint256): modifying
    def getPricePerFullShare() -> uint256: constant




# Tether transfer-only ABI
contract USDT:
    def transfer(_to: address, _value: uint256): modifying
    def transferFrom(_from: address, _to: address, _value: uint256): modifying


contract Curve:
    def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256): modifying
    def remove_liquidity(_amount: uint256, min_amounts: uint256[N_COINS]): modifying
    def remove_liquidity_imbalance(amounts: uint256[N_COINS], max_burn_amount: uint256): modifying
    def balances(i: int128) -> uint256: constant
    def A() -> uint256: constant
    def fee() -> uint256: constant
    def owner() -> address: constant


N_COINS: constant(int128) = 3
TETHERED: constant(bool[N_COINS]) = [False, False, True]
ZERO256: constant(uint256) = 0  # This hack is really bad XXX
ZEROS: constant(uint256[N_COINS]) = [ZERO256, ZERO256, ZERO256]  # <- change
LENDING_PRECISION: constant(uint256) = 10 ** 18
PRECISION: constant(uint256) = 10 ** 18
PRECISION_MUL: constant(uint256[N_COINS]) = [convert(1, uint256), convert(1000000000000, uint256), convert(1000000000000, uint256)]
FEE_DENOMINATOR: constant(uint256) = 10 ** 10
FEE_IMPRECISION: constant(uint256) = 25 * 10 ** 8  # % of the fee

coins: public(address[N_COINS])
underlying_coins: public(address[N_COINS])
curve: public(address)
token: public(address)


@public
def __init__(_coins: address[N_COINS], _underlying_coins: address[N_COINS],
             _curve: address, _token: address):
    self.coins = _coins
    self.underlying_coins = _underlying_coins
    self.curve = _curve
    self.token = _token


@public
@nonreentrant('lock')
def add_liquidity(uamounts: uint256[N_COINS], min_mint_amount: uint256):
    tethered: bool[N_COINS] = TETHERED
    amounts: uint256[N_COINS] = ZEROS

    for i in range(N_COINS):
        uamount: uint256 = uamounts[i]

        if uamount > 0:
            # Transfer the underlying coin from owner
            if tethered[i]:
                USDT(self.underlying_coins[i]).transferFrom(
                    msg.sender, self, uamount)
            else:
                assert_modifiable(ERC20(self.underlying_coins[i])\
                    .transferFrom(msg.sender, self, uamount))

            # Mint if needed
            ERC20(self.underlying_coins[i]).approve(self.coins[i], uamount)
            yERC20(self.coins[i]).deposit(uamount)
            amounts[i] = yERC20(self.coins[i]).balanceOf(self)
            ERC20(self.coins[i]).approve(self.curve, amounts[i])

    Curve(self.curve).add_liquidity(amounts, min_mint_amount)

    tokens: uint256 = ERC20(self.token).balanceOf(self)
    assert_modifiable(ERC20(self.token).transfer(msg.sender, tokens))


@private
def _send_all(_addr: address, min_uamounts: uint256[N_COINS], one: int128):
    tethered: bool[N_COINS] = TETHERED

    for i in range(N_COINS):
        if (one < 0) or (i == one):
            _coin: address = self.coins[i]
            _balance: uint256 = yERC20(_coin).balanceOf(self)
            if _balance == 0:  # Do nothing for 0 coins
                continue
            yERC20(_coin).withdraw(_balance)

            _ucoin: address = self.underlying_coins[i]
            _uamount: uint256 = ERC20(_ucoin).balanceOf(self)
            assert _uamount >= min_uamounts[i], "Not enough coins withdrawn"

            if tethered[i]:
                USDT(_ucoin).transfer(_addr, _uamount)
            else:
                assert_modifiable(ERC20(_ucoin).transfer(_addr, _uamount))


@public
@nonreentrant('lock')
def remove_liquidity(_amount: uint256, min_uamounts: uint256[N_COINS]):
    zeros: uint256[N_COINS] = ZEROS

    assert_modifiable(ERC20(self.token).transferFrom(msg.sender, self, _amount))
    Curve(self.curve).remove_liquidity(_amount, zeros)

    self._send_all(msg.sender, min_uamounts, -1)


@public
@nonreentrant('lock')
def remove_liquidity_imbalance(uamounts: uint256[N_COINS], max_burn_amount: uint256):
    """
    Get max_burn_amount in, remove requested liquidity and transfer back what is left
    """
    tethered: bool[N_COINS] = TETHERED
    _token: address = self.token

    amounts: uint256[N_COINS] = uamounts
    for i in range(N_COINS):
        if amounts[i] > 0:
            rate: uint256 = yERC20(self.coins[i]).getPricePerFullShare()
            amounts[i] = amounts[i] * LENDING_PRECISION / rate

    # Transfrer max tokens in
    _tokens: uint256 = ERC20(_token).balanceOf(msg.sender)
    if _tokens > max_burn_amount:
        _tokens = max_burn_amount
    assert_modifiable(ERC20(_token).transferFrom(msg.sender, self, _tokens))

    Curve(self.curve).remove_liquidity_imbalance(amounts, max_burn_amount)

    # Transfer unused tokens back
    _tokens = ERC20(_token).balanceOf(self)
    assert_modifiable(ERC20(_token).transfer(msg.sender, _tokens))

    # Unwrap and transfer all the coins we've got
    self._send_all(msg.sender, ZEROS, -1)


@private
@constant
def _xp_mem(rates: uint256[N_COINS], _balances: uint256[N_COINS]) -> uint256[N_COINS]:
    result: uint256[N_COINS] = rates
    for i in range(N_COINS):
        result[i] = result[i] * _balances[i] / PRECISION
    return result


@private
@constant
def get_D(A: uint256, xp: uint256[N_COINS]) -> uint256:
    S: uint256 = 0
    for _x in xp:
        S += _x
    if S == 0:
        return 0

    Dprev: uint256 = 0
    D: uint256 = S
    Ann: uint256 = A * N_COINS
    for _i in range(255):
        D_P: uint256 = D
        for _x in xp:
            D_P = D_P * D / (_x * N_COINS + 1)  # +1 is to prevent /0
        Dprev = D
        D = (Ann * S + D_P * N_COINS) * D / ((Ann - 1) * D + (N_COINS + 1) * D_P)
        # Equality with the precision of 1
        if D > Dprev:
            if D - Dprev <= 1:
                break
        else:
            if Dprev - D <= 1:
                break
    return D


@private
@constant
def get_y(A: uint256, i: int128, _xp: uint256[N_COINS], D: uint256) -> uint256:
    """
    Calculate x[i] if one reduces D from being calculated for _xp to D
    Done by solving quadratic equation iteratively.
    x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
    x_1**2 + b*x_1 = c
    x_1 = (x_1**2 + c) / (2*x_1 + b)
    """
    # x in the input is converted to the same price/precision

    assert (i >= 0) and (i < N_COINS)

    c: uint256 = D
    S_: uint256 = 0
    Ann: uint256 = A * N_COINS

    _x: uint256 = 0
    for _i in range(N_COINS):
        if _i != i:
            _x = _xp[_i]
        else:
            continue
        S_ += _x
        c = c * D / (_x * N_COINS)
    c = c * D / (Ann * N_COINS)
    b: uint256 = S_ + D / Ann
    y_prev: uint256 = 0
    y: uint256 = D
    for _i in range(255):
        y_prev = y
        y = (y*y + c) / (2 * y + b - D)
        # Equality with the precision of 1
        if y > y_prev:
            if y - y_prev <= 1:
                break
        else:
            if y_prev - y <= 1:
                break
    return y


@private
@constant
def _calc_withdraw_one_coin(_token_amount: uint256, i: int128, rates: uint256[N_COINS]) -> uint256:
    # First, need to calculate
    # * Get current D
    # * Solve Eqn against y_i for D - _token_amount
    crv: address = self.curve
    A: uint256 = Curve(crv).A()
    fee: uint256 = Curve(crv).fee() * N_COINS / (4 * (N_COINS - 1))
    fee += fee * FEE_IMPRECISION / FEE_DENOMINATOR  # Overcharge to account for imprecision
    precisions: uint256[N_COINS] = PRECISION_MUL
    total_supply: uint256 = ERC20(self.token).totalSupply()

    xp: uint256[N_COINS] = PRECISION_MUL
    S: uint256 = 0
    for j in range(N_COINS):
        xp[j] *= Curve(crv).balances(j)
        xp[j] = xp[j] * rates[j] / LENDING_PRECISION
        S += xp[j]

    D0: uint256 = self.get_D(A, xp)
    D1: uint256 = D0 - _token_amount * D0 / total_supply
    xp_reduced: uint256[N_COINS] = xp

    # xp = xp - fee * | xp * D1 / D0 - (xp - S * dD / D0 * (0, ... 1, ..0))|
    for j in range(N_COINS):
        dx_expected: uint256 = 0
        b_ideal: uint256 = xp[j] * D1 / D0
        b_expected: uint256 = xp[j]
        if j == i:
            b_expected -= S * (D0 - D1) / D0
        if b_ideal >= b_expected:
            dx_expected += (b_ideal - b_expected)
        else:
            dx_expected += (b_expected - b_ideal)
        xp_reduced[j] -= fee * dx_expected / FEE_DENOMINATOR

    dy: uint256 = xp_reduced[i] - self.get_y(A, i, xp_reduced, D1)
    dy = dy / precisions[i]

    return dy


@public
@constant
def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256:
    rates: uint256[N_COINS] = ZEROS

    for j in range(N_COINS):
        rates[j] = yERC20(self.coins[j]).getPricePerFullShare()

    return self._calc_withdraw_one_coin(_token_amount, i, rates)


@public
@nonreentrant('lock')
def remove_liquidity_one_coin(_token_amount: uint256, i: int128, min_uamount: uint256, donate_dust: bool = False):
    """
    Remove _amount of liquidity all in a form of coin i
    """
    rates: uint256[N_COINS] = ZEROS
    _token: address = self.token

    for j in range(N_COINS):
        rates[j] = yERC20(self.coins[j]).getPricePerFullShare()

    dy: uint256 = self._calc_withdraw_one_coin(_token_amount, i, rates)
    assert dy >= min_uamount, "Not enough coins removed"

    assert_modifiable(
        ERC20(self.token).transferFrom(msg.sender, self, _token_amount))

    amounts: uint256[N_COINS] = ZEROS
    amounts[i] = dy * LENDING_PRECISION / rates[i]
    token_amount_before: uint256 = ERC20(_token).balanceOf(self)
    Curve(self.curve).remove_liquidity_imbalance(amounts, _token_amount)

    # Unwrap and transfer all the coins we've got
    self._send_all(msg.sender, ZEROS, i)

    if not donate_dust:
        # Transfer unused tokens back
        token_amount_after: uint256 = ERC20(_token).balanceOf(self)
        if token_amount_after > token_amount_before:
            assert_modifiable(ERC20(_token).transfer(
                msg.sender, token_amount_after - token_amount_before)
            )


@public
@nonreentrant('lock')
def withdraw_donated_dust():
    owner: address = Curve(self.curve).owner()
    assert msg.sender == owner

    _token: address = self.token
    assert_modifiable(
        ERC20(_token).transfer(owner, ERC20(_token).balanceOf(self)))