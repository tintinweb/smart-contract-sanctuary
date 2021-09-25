# @version 0.2.16
# Curve.Fi, 2021
# Distributed under MIT license

interface Tricrypto:
    def virtual_price() -> uint256: view
    def price_oracle(k: uint256) -> uint256: view
    def A() -> uint256: view
    def gamma() -> uint256: view


POOL: constant(address) = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46
GAMMA0: constant(uint256) = 28000000000000  # 2.8e-5
A0: constant(uint256) = 2 * 3**3 * 10000
DISCOUNT0: constant(uint256) = 1087460000000000  # 0.00108..


@pure
@internal
def cubic_root(x: uint256) -> uint256:
    # x is taken at base 1e36
    # result is at base 1e18
    # Will have convergence problems when ETH*BTC is cheaper than 0.01 squared dollar
    # (for example, when BTC < $0.1 and ETH < $0.1)
    D: uint256 = x / 10**18
    for i in range(255):
        diff: uint256 = 0
        D_prev: uint256 = D
        D = D * (2 * 10**18 + x / D * 10**18 / D * 10**18 / D) / (3 * 10**18)
        if D > D_prev:
            diff = D - D_prev
        else:
            diff = D_prev - D
        if diff <= 1 or diff * 10**18 < D:
            return D
    raise "Did not converge"


@external
@view
def lp_price() -> uint256:
    vp: uint256 = Tricrypto(POOL).virtual_price()
    p1: uint256 = Tricrypto(POOL).price_oracle(0)
    p2: uint256 = Tricrypto(POOL).price_oracle(1)

    max_price: uint256 = 3 * vp * self.cubic_root(p1 * p2) / 10**18

    # ((A/A0) * (gamma/gamma0)**2) ** (1/3)
    g: uint256 = Tricrypto(POOL).gamma() * 10**18 / GAMMA0
    a: uint256 = Tricrypto(POOL).A() * 10**18 / A0
    discount: uint256 = max(g**2 / 10**18 * a, 10**34)  # handle qbrt nonconvergence
    # if discount is small, we take an upper bound
    discount = self.cubic_root(discount) * DISCOUNT0 / 10**18

    max_price -= max_price * discount / 10**18

    return max_price