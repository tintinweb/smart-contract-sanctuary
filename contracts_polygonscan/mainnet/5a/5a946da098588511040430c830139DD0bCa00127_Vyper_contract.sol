# @version 0.3.0
"""
@title Curve Registry Calculator
@license (c) Curve.Fi, 2020
@author Curve.Fi
@notice Stateless bulk calculator of prices for stablecoin-to-stablecoin pools
"""

MAX_COINS: constant(int128) = 8
INPUT_SIZE: constant(int128) = 100
FEE_DENOMINATOR: constant(uint256) = 10 ** 10


@pure
@internal
def get_D(n_coins: uint256, xp: uint256[MAX_COINS], amp: uint256) -> uint256:
    """
    @notice Calculating the invariant (D)
    @param n_coins Number of coins in the pool
    @param xp Array with coin balances made into the same (1e18) digits
    @param amp Amplification coefficient
    @return The value of invariant
    """
    S: uint256 = 0
    for _x in xp:
        if _x == 0:
            break
        S += _x
    if S == 0:
        return 0

    Dprev: uint256 = 0
    D: uint256 = S
    Ann: uint256 = amp * n_coins
    for _i in range(255):
        D_P: uint256 = D
        for _x in xp:
            if _x == 0:
                break
            D_P = D_P * D / (_x * n_coins)  # If division by 0, this will be borked: only withdrawal will work. And that is good
        Dprev = D
        D = (Ann * S + D_P * n_coins) * D / ((Ann - 1) * D + (n_coins + 1) * D_P)
        # Equality with the precision of 1
        if D > Dprev:
            if D - Dprev <= 1:
                break
        else:
            if Dprev - D <= 1:
                break
    return D


@pure
@internal
def get_y(D: uint256, n_coins: uint256, xp: uint256[MAX_COINS], amp: uint256,
          i: int128, j: int128, x: uint256) -> uint256:
    """
    @notice Bulk-calculate new balance of coin j given a new value of coin i
    @param D The Invariant
    @param n_coins Number of coins in the pool
    @param xp Array with coin balances made into the same (1e18) digits
    @param amp Amplification coefficient
    @param i Index of the changed coin (trade in)
    @param j Index of the other changed coin (trade out)
    @param x Amount of coin i (trade in)
    @return Amount of coin j (trade out)
    """
    n_coins_int: int128 = convert(n_coins, int128)
    assert (i != j) and (i >= 0) and (j >= 0) and (i < n_coins_int) and (j < n_coins_int)

    Ann: uint256 = amp * n_coins

    _x: uint256 = 0
    S_: uint256 = 0
    c: uint256 = D
    for _i in range(MAX_COINS):
        if _i == n_coins_int:
            break
        if _i == i:
            _x = x
        elif _i != j:
            _x = xp[_i]
        else:
            continue
        S_ += _x
        c = c * D / (_x * n_coins)
    c = c * D / (Ann * n_coins)
    b: uint256 = S_ + D / Ann  # - D
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


@view
@external
def get_dy(n_coins: uint256, balances: uint256[MAX_COINS], amp: uint256, fee: uint256,
           rates: uint256[MAX_COINS], precisions: uint256[MAX_COINS],
           i: int128, j: int128, dx: uint256[INPUT_SIZE]) -> uint256[INPUT_SIZE]:
    """
    @notice Bulk-calculate amount of of coin j given in exchange for coin i
    @param n_coins Number of coins in the pool
    @param balances Array with coin balances
    @param amp Amplification coefficient
    @param fee Pool's fee at 1e10 basis
    @param rates Array with rates for "lent out" tokens
    @param precisions Precision multipliers to get the coin to 1e18 basis
    @param i Index of the changed coin (trade in)
    @param j Index of the other changed coin (trade out)
    @param dx Array of values of coin i (trade in)
    @return Array of values of coin j (trade out)
    """

    xp: uint256[MAX_COINS] = balances
    ratesp: uint256[MAX_COINS] = precisions
    for k in range(MAX_COINS):
        xp[k] = xp[k] * rates[k] * precisions[k] / 10 ** 18
        ratesp[k] *= rates[k]
    D: uint256 = self.get_D(n_coins, xp, amp)

    dy: uint256[INPUT_SIZE] = dx
    for k in range(INPUT_SIZE):
        if dx[k] == 0:
            break
        else:
            x_after_trade: uint256 = dx[k] * ratesp[i] / 10 ** 18 + xp[i]
            dy[k] = self.get_y(D, n_coins, xp, amp, i, j, x_after_trade)
            dy[k] = (xp[j] - dy[k] - 1) * 10 ** 18 / ratesp[j]
            dy[k] -= dy[k] * fee / FEE_DENOMINATOR

    return dy


@view
@external
def get_dx(n_coins: uint256, balances: uint256[MAX_COINS], amp: uint256, fee: uint256,
           rates: uint256[MAX_COINS], precisions: uint256[MAX_COINS],
           i: int128, j: int128, dy: uint256) -> uint256:
    """
    @notice Calculate amount of of coin i taken when exchanging for coin j
    @param n_coins Number of coins in the pool
    @param balances Array with coin balances
    @param amp Amplification coefficient
    @param fee Pool's fee at 1e10 basis
    @param rates Array with rates for "lent out" tokens
    @param precisions Precision multipliers to get the coin to 1e18 basis
    @param i Index of the changed coin (trade in)
    @param j Index of the other changed coin (trade out)
    @param dy Amount of coin j (trade out)
    @return Amount of coin i (trade in)
    """

    xp: uint256[MAX_COINS] = balances
    ratesp: uint256[MAX_COINS] = precisions
    for k in range(MAX_COINS):
        xp[k] = xp[k] * rates[k] * precisions[k] / 10 ** 18
        ratesp[k] *= rates[k]
    D: uint256 = self.get_D(n_coins, xp, amp)

    y_after_trade: uint256 = xp[j] - dy * ratesp[j] / 10 ** 18 * FEE_DENOMINATOR / (FEE_DENOMINATOR - fee)
    x: uint256 = self.get_y(D, n_coins, xp, amp, j, i, y_after_trade)
    dx: uint256 = (x - xp[i]) * 10 ** 18 / ratesp[i]

    return dx