# @version 0.2.12
# (c) Curve.Fi, 2021
# Math for crypto pools
#
# Unless otherwise agreed on, only contracts owned by Curve DAO or
# Swiss Stake GmbH are allowed to call this contract.

N_COINS: constant(int128) = 3  # <- change
A_MULTIPLIER: constant(uint256) = 10000

MIN_GAMMA: constant(uint256) = 10**10
MAX_GAMMA: constant(uint256) = 5 * 10**16

MIN_A: constant(uint256) = N_COINS**N_COINS * A_MULTIPLIER / 100
MAX_A: constant(uint256) = N_COINS**N_COINS * A_MULTIPLIER * 1000


@internal
@pure
def sort(A0: uint256[N_COINS]) -> uint256[N_COINS]:
    """
    Insertion sort from high to low
    """
    A: uint256[N_COINS] = A0
    for i in range(1, N_COINS):
        x: uint256 = A[i]
        cur: uint256 = i
        for j in range(N_COINS):
            y: uint256 = A[cur-1]
            if y > x:
                break
            A[cur] = y
            cur -= 1
            if cur == 0:
                break
        A[cur] = x
    return A


@internal
@view
def _geometric_mean(unsorted_x: uint256[N_COINS], sort: bool = True) -> uint256:
    """
    (x[0] * x[1] * ...) ** (1/N)
    """
    x: uint256[N_COINS] = unsorted_x
    if sort:
        x = self.sort(x)
    D: uint256 = x[0]
    diff: uint256 = 0
    for i in range(255):
        D_prev: uint256 = D
        tmp: uint256 = 10**18
        for _x in x:
            tmp = tmp * _x / D
        D = D * ((N_COINS - 1) * 10**18 + tmp) / (N_COINS * 10**18)
        if D > D_prev:
            diff = D - D_prev
        else:
            diff = D_prev - D
        if diff <= 1 or diff * 10**18 < D:
            return D
    raise "Did not converge"


@external
@view
def geometric_mean(unsorted_x: uint256[N_COINS], sort: bool = True) -> uint256:
    return self._geometric_mean(unsorted_x, sort)


@external
@view
def reduction_coefficient(x: uint256[N_COINS], fee_gamma: uint256) -> uint256:
    """
    fee_gamma / (fee_gamma + (1 - K))
    where
    K = prod(x) / (sum(x) / N)**N
    (all normalized to 1e18)
    """
    K: uint256 = 10**18
    S: uint256 = 0
    for x_i in x:
        S += x_i
    # Could be good to pre-sort x, but it is used only for dynamic fee,
    # so that is not so important
    for x_i in x:
        K = K * N_COINS * x_i / S
    if fee_gamma > 0:
        K = fee_gamma * 10**18 / (fee_gamma + 10**18 - K)
    return K


@external
@view
def newton_D(ANN: uint256, gamma: uint256, x_unsorted: uint256[N_COINS]) -> uint256:
    """
    Finding the invariant using Newton method.
    ANN is higher by the factor A_MULTIPLIER
    ANN is already A * N**N

    Currently uses 60k gas
    """
    # Safety checks
    assert ANN > MIN_A - 1 and ANN < MAX_A + 1  # dev: unsafe values A
    assert gamma > MIN_GAMMA - 1 and gamma < MAX_GAMMA + 1  # dev: unsafe values gamma

    # Initial value of invariant D is that for constant-product invariant
    x: uint256[N_COINS] = self.sort(x_unsorted)

    assert x[0] > 10**9 - 1 and x[0] < 10**15 * 10**18 + 1  # dev: unsafe values x[0]
    for i in range(1, N_COINS):
        frac: uint256 = x[i] * 10**18 / x[0]
        assert frac > 10**11-1  # dev: unsafe values x[i]

    D: uint256 = N_COINS * self._geometric_mean(x, False)
    S: uint256 = 0
    for x_i in x:
        S += x_i

    for i in range(255):
        D_prev: uint256 = D

        K0: uint256 = 10**18
        for _x in x:
            K0 = K0 * _x * N_COINS / D

        _g1k0: uint256 = gamma + 10**18
        if _g1k0 > K0:
            _g1k0 = _g1k0 - K0 + 1
        else:
            _g1k0 = K0 - _g1k0 + 1

        # D / (A * N**N) * _g1k0**2 / gamma**2
        mul1: uint256 = 10**18 * D / gamma * _g1k0 / gamma * _g1k0 * A_MULTIPLIER / ANN

        # 2*N*K0 / _g1k0
        mul2: uint256 = (2 * 10**18) * N_COINS * K0 / _g1k0

        neg_fprime: uint256 = (S + S * mul2 / 10**18) + mul1 * N_COINS / K0 - mul2 * D / 10**18

        # D -= f / fprime
        D_plus: uint256 = D * (neg_fprime + S) / neg_fprime
        D_minus: uint256 = D*D / neg_fprime
        if 10**18 > K0:
            D_minus += D * (mul1 / neg_fprime) / 10**18 * (10**18 - K0) / K0
        else:
            D_minus -= D * (mul1 / neg_fprime) / 10**18 * (K0 - 10**18) / K0

        if D_plus > D_minus:
            D = D_plus - D_minus
        else:
            D = (D_minus - D_plus) / 2

        diff: uint256 = 0
        if D > D_prev:
            diff = D - D_prev
        else:
            diff = D_prev - D
        if diff * 10**14 < max(10**16, D):  # Could reduce precision for gas efficiency here
            # Test that we are safe with the next newton_y
            for _x in x:
                frac: uint256 = _x * 10**18 / D
                assert (frac > 10**16 - 1) and (frac < 10**20 + 1)  # dev: unsafe values x[i]
            return D

    raise "Did not converge"


@external
@view
def newton_y(ANN: uint256, gamma: uint256, x: uint256[N_COINS], D: uint256, i: uint256) -> uint256:
    """
    Calculating x[i] given other balances x[0..N_COINS-1] and invariant D
    ANN = A * N**N
    """
    # Safety checks
    assert ANN > MIN_A - 1 and ANN < MAX_A + 1  # dev: unsafe values A
    assert gamma > MIN_GAMMA - 1 and gamma < MAX_GAMMA + 1  # dev: unsafe values gamma
    assert D > 10**17 - 1 and D < 10**15 * 10**18 + 1 # dev: unsafe values D
    for k in range(3):
        if k != i:
            frac: uint256 = x[k] * 10**18 / D
            assert (frac > 10**16 - 1) and (frac < 10**20 + 1)  # dev: unsafe values x[i]

    y: uint256 = D / N_COINS
    K0_i: uint256 = 10**18
    S_i: uint256 = 0

    x_sorted: uint256[N_COINS] = x
    x_sorted[i] = 0
    x_sorted = self.sort(x_sorted)  # From high to low

    convergence_limit: uint256 = max(max(x_sorted[0] / 10**14, D / 10**14), 100)
    for j in range(2, N_COINS+1):
        _x: uint256 = x_sorted[N_COINS-j]
        y = y * D / (_x * N_COINS)  # Small _x first
        S_i += _x
    for j in range(N_COINS-1):
        K0_i = K0_i * x_sorted[j] * N_COINS / D  # Large _x first

    for j in range(255):
        y_prev: uint256 = y

        K0: uint256 = K0_i * y * N_COINS / D
        S: uint256 = S_i + y

        _g1k0: uint256 = gamma + 10**18
        if _g1k0 > K0:
            _g1k0 = _g1k0 - K0 + 1
        else:
            _g1k0 = K0 - _g1k0 + 1

        # D / (A * N**N) * _g1k0**2 / gamma**2
        mul1: uint256 = 10**18 * D / gamma * _g1k0 / gamma * _g1k0 * A_MULTIPLIER / ANN

        # 2*K0 / _g1k0
        mul2: uint256 = 10**18 + (2 * 10**18) * K0 / _g1k0

        yfprime: uint256 = 10**18 * y + S * mul2 + mul1
        _dyfprime: uint256 = D * mul2
        if yfprime < _dyfprime:
            y = y_prev / 2
            continue
        else:
            yfprime -= _dyfprime
        fprime: uint256 = yfprime / y

        # y -= f / f_prime;  y = (y * fprime - f) / fprime
        # y = (yfprime + 10**18 * D - 10**18 * S) // fprime + mul1 // fprime * (10**18 - K0) // K0
        y_minus: uint256 = mul1 / fprime
        y_plus: uint256 = (yfprime + 10**18 * D) / fprime + y_minus * 10**18 / K0
        y_minus += 10**18 * S / fprime

        if y_plus < y_minus:
            y = y_prev / 2
        else:
            y = y_plus - y_minus

        diff: uint256 = 0
        if y > y_prev:
            diff = y - y_prev
        else:
            diff = y_prev - y
        if diff < max(convergence_limit, y / 10**14):
            frac: uint256 = y * 10**18 / D
            assert (frac > 10**16 - 1) and (frac < 10**20 + 1)  # dev: unsafe value for y
            return y

    raise "Did not converge"


@external
@view
def halfpow(power: uint256, precision: uint256) -> uint256:
    """
    1e18 * 0.5 ** (power/1e18)

    Inspired by: https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol#L128
    """
    intpow: uint256 = power / 10**18
    otherpow: uint256 = power - intpow * 10**18
    if intpow > 59:
        return 0
    result: uint256 = 10**18 / (2**intpow)
    if otherpow == 0:
        return result

    term: uint256 = 10**18
    x: uint256 = 5 * 10**17
    S: uint256 = 10**18
    neg: bool = False

    for i in range(1, 256):
        K: uint256 = i * 10**18
        c: uint256 = K - 10**18
        if otherpow > c:
            c = otherpow - c
            neg = not neg
        else:
            c -= otherpow
        term = term * (c * x / 10**18) / K
        if neg:
            S -= term
        else:
            S += term
        if term < precision:
            return result * S / 10**18

    raise "Did not converge"


@external
@view
def sqrt_int(x: uint256) -> uint256:
    """
    Originating from: https://github.com/vyperlang/vyper/issues/1266
    """

    if x == 0:
        return 0

    z: uint256 = (x + 10**18) / 2
    y: uint256 = x

    for i in range(256):
        if z == y:
            return y
        y = z
        z = (x * 10**18 / z + z) / 2

    raise "Did not converge"