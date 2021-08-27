# @version 0.2.15
"""
@title Pool Migrator
@author Curve.fi
@notice Zap for moving liquidity between Curve tricrypto pools in a single transaction
@license MIT
"""

N_COINS: constant(int128) = 3  # <- change

OLD_POOL: constant(address) = 0x92577943c7aC4accb35288aB2CC84D75feC330aF
OLD_TOKEN: constant(address) = 0xbece5d20A8a104c54183CC316C8286E3F00ffC71
OLD_GAUGE: constant(address) = 0x9bd996Db02b3f271c6533235D452a56bc2Cd195a

NEW_POOL: constant(address) = 0x92215849c439E1f8612b6646060B4E3E5ef822cC
NEW_TOKEN: constant(address) = 0xdAD97F7713Ae9437fa9249920eC8507e5FbB23d3
NEW_GAUGE: constant(address) = 0x3B6B158A76fd8ccc297538F454ce7B4787778c7C

COINS: constant(address[N_COINS]) = [
    0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171,  # am3crv
    0x5c2ed810328349100A66B82b78a1791B101C9D61,  # amWBTC
    0x28424507fefb6f7f8E9D3860F56504E4e5f5f390,  # amWETH
]


# For flash loan protection
PRECISIONS: constant(uint256[N_COINS]) = [
    1,
    10000000000,
    1,
]
ALLOWED_DEVIATION: constant(uint256) = 3 * 10**16  # 3% * 1e18


interface ERC20:
    def approve(_spender: address, _amount: uint256): nonpayable
    def transfer(_to: address, _amount: uint256): nonpayable
    def transferFrom(_owner: address, _spender: address, _amount: uint256) -> bool: nonpayable
    def balanceOf(_user: address) -> uint256: view

interface Gauge:
    def withdraw(_value: uint256): nonpayable
    def deposit(_value: uint256, _addr: address, _claim_rewards: bool): nonpayable

interface Swap:
    def add_liquidity(_amounts: uint256[N_COINS], _min_mint_amount: uint256): nonpayable
    def remove_liquidity(_burn_amount: uint256, _min_amounts: uint256[N_COINS]): nonpayable
    def balances(i: uint256) -> uint256: view
    def price_oracle(i: uint256) -> uint256: view


@external
def __init__():
    for c in COINS:
        ERC20(c).approve(NEW_POOL, MAX_UINT256)
    ERC20(NEW_TOKEN).approve(NEW_GAUGE, MAX_UINT256)


@internal
@view
def is_safe():
    balances: uint256[N_COINS] = PRECISIONS
    S: uint256 = 0
    for i in range(N_COINS):
        balances[i] *= Swap(NEW_POOL).balances(i)
        if i > 0:
            balances[i] = balances[i] * Swap(NEW_POOL).price_oracle(i-1) / 10**18
        S += balances[i]
    for i in range(N_COINS):
        ratio: uint256 = balances[i] * 10**18 / S
        assert ratio > 10**18/N_COINS - ALLOWED_DEVIATION and ratio < 10**18/N_COINS + ALLOWED_DEVIATION, "Target pool might be under attack now - wait"


@external
def migrate_to_new_pool():
    """
    @notice Migrate liquidity between two pools
    Better to transfer 1 wei of old gauge and old LP to the zap
    """
    self.is_safe()

    old_amount: uint256 = 0
    bal: uint256 = ERC20(OLD_GAUGE).balanceOf(msg.sender)

    coins: address[N_COINS] = COINS
    coin_balances: uint256[N_COINS] = empty(uint256[N_COINS])

    # Transfer the gauge in and withdraw if we have something
    if bal > 0:
        ERC20(OLD_GAUGE).transferFrom(msg.sender, self, bal)
        Gauge(OLD_GAUGE).withdraw(bal)
        old_amount += bal

    # Transfer LP in if we have something
    bal = ERC20(OLD_TOKEN).balanceOf(msg.sender)
    if bal > 0:
        ERC20(OLD_TOKEN).transferFrom(msg.sender, self, bal)
        old_amount += bal

    # Get usdt/wbtc/weth
    if old_amount > 0:
        Swap(OLD_POOL).remove_liquidity(old_amount, empty(uint256[N_COINS]))

    # Deposit
    for i in range(N_COINS):
        bal = ERC20(coins[i]).balanceOf(self)
        if bal > 0:
            bal -= 1
        coin_balances[i] = bal
    Swap(NEW_POOL).add_liquidity(coin_balances, 0)

    # Put in the gauge
    bal = ERC20(NEW_TOKEN).balanceOf(self)
    if bal > 1:
        Gauge(NEW_GAUGE).deposit(bal - 1, msg.sender, False)