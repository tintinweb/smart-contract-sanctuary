# @version 0.2.12
# (c) Curve.Fi, 2021

# This contract contains view-only external methods which can be gas-inefficient
# when called from smart contracts but ok to use from frontend
# Called only from Curve contract as it uses msg.sender as the contract address
from vyper.interfaces import ERC20

interface Curve:
    def A_precise() -> uint256: view
    def gamma() -> uint256: view
    def price_scale(i: uint256) -> uint256: view
    def balances(i: uint256) -> uint256: view
    def D() -> uint256: view
    def fee_calc(xp: uint256[N_COINS]) -> uint256: view
    def calc_token_fee(amounts: uint256[N_COINS], xp: uint256[N_COINS]) -> uint256: view
    def token() -> address: view

interface Math:
    def newton_D(ANN: uint256, gamma: uint256, x_unsorted: uint256[N_COINS]) -> uint256: view
    def newton_y(ANN: uint256, gamma: uint256, x: uint256[N_COINS], D: uint256, i: uint256) -> uint256: view

N_COINS: constant(int128) = 3  # <- change
PRECISION: constant(uint256) = 10 ** 18  # The precision to convert to
PRECISIONS: constant(uint256[N_COINS]) = [
    10**12, # USDT
    10**10, # WBTC
    1, # WETH
]

math: address


@external
def __init__(math: address):
    self.math = math


@external
@view
def get_dy(i: uint256, j: uint256, dx: uint256) -> uint256:
    assert i != j and i < N_COINS and j < N_COINS, "coin index out of range"
    assert dx > 0, "do not exchange 0 coins"

    precisions: uint256[N_COINS] = PRECISIONS

    price_scale: uint256[N_COINS-1] = empty(uint256[N_COINS-1])
    for k in range(N_COINS-1):
        price_scale[k] = Curve(msg.sender).price_scale(k)
    xp: uint256[N_COINS] = empty(uint256[N_COINS])
    for k in range(N_COINS):
        xp[k] = Curve(msg.sender).balances(k)
    y0: uint256 = xp[j]
    xp[i] += dx
    xp[0] *= precisions[0]
    for k in range(N_COINS-1):
        xp[k+1] = xp[k+1] * price_scale[k] * precisions[k+1] / PRECISION

    A: uint256 = Curve(msg.sender).A_precise()
    gamma: uint256 = Curve(msg.sender).gamma()

    y: uint256 = Math(self.math).newton_y(A, gamma, xp, Curve(msg.sender).D(), j)
    dy: uint256 = xp[j] - y - 1
    xp[j] = y
    if j > 0:
        dy = dy * PRECISION / price_scale[j-1]
    dy /= precisions[j]
    dy -= Curve(msg.sender).fee_calc(xp) * dy / 10**10

    return dy


@view
@external
def calc_token_amount(amounts: uint256[N_COINS], deposit: bool) -> uint256:
    precisions: uint256[N_COINS] = PRECISIONS
    token_supply: uint256 = ERC20(Curve(msg.sender).token()).totalSupply()
    xp: uint256[N_COINS] = empty(uint256[N_COINS])
    for k in range(N_COINS):
        xp[k] = Curve(msg.sender).balances(k)
    amountsp: uint256[N_COINS] = amounts
    if deposit:
        for k in range(N_COINS):
            xp[k] += amounts[k]
    else:
        for k in range(N_COINS):
            xp[k] -= amounts[k]
    xp[0] *= precisions[0]
    amountsp[0] *= precisions[0]
    for k in range(N_COINS-1):
        p: uint256 = Curve(msg.sender).price_scale(k) * precisions[k+1]
        xp[k+1] = xp[k+1] * p / PRECISION
        amountsp[k+1] = amountsp[k+1] * p / PRECISION
    A: uint256 = Curve(msg.sender).A_precise()
    gamma: uint256 = Curve(msg.sender).gamma()
    D: uint256 = Math(self.math).newton_D(A, gamma, xp)
    d_token: uint256 = token_supply * D / Curve(msg.sender).D()
    if deposit:
        d_token -= token_supply
    else:
        d_token = token_supply - d_token
    d_token -= Curve(msg.sender).calc_token_fee(amountsp, xp) * d_token / 10**10 + 1
    return d_token