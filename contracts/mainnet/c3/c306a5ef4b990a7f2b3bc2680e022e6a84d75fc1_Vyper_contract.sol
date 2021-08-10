# @version 0.2.12
"""
@title triCrypto Vault Migrator
@author yearn.finance, adapted from Curve.fi's Pool Migrator contract
@notice Zap for moving liquidity between Curve tricrypto vaults in a single transaction
@license MIT
"""

N_COINS: constant(int128) = 3  # <- change

OLD_POOL: constant(address) = 0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5
OLD_TOKEN: constant(address) = 0xcA3d75aC011BF5aD07a98d02f18225F9bD9A6BDF
OLD_VAULT: constant(address) = 0x3D980E50508CFd41a13837A60149927a11c03731

NEW_POOL: constant(address) = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46
NEW_TOKEN: constant(address) = 0xc4AD29ba4B3c580e6D59105FFf484999997675Ff
NEW_VAULT: constant(address) = 0xE537B5cc158EB71037D4125BDD7538421981E6AA

COINS: constant(address[N_COINS]) = [
    0xdAC17F958D2ee523a2206206994597C13D831ec7,
    0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
]


# For flash loan protection
PRECISIONS: constant(uint256[N_COINS]) = [
    1000000000000,
    10000000000,
    1,
]
ALLOWED_DEVIATION: constant(uint256) = 10**16  # 1% * 1e18


interface ERC20:
    def approve(_spender: address, _amount: uint256): nonpayable
    def transfer(_to: address, _amount: uint256): nonpayable
    def transferFrom(_owner: address, _spender: address, _amount: uint256) -> bool: nonpayable
    def balanceOf(_user: address) -> uint256: view

interface Vault:
    def withdraw(amount: uint256): nonpayable
    def deposit(amount: uint256, recipient: address): nonpayable

interface Swap:
    def add_liquidity(_amounts: uint256[N_COINS], _min_mint_amount: uint256): nonpayable
    def remove_liquidity(_burn_amount: uint256, _min_amounts: uint256[N_COINS]): nonpayable
    def balances(i: uint256) -> uint256: view
    def price_oracle(i: uint256) -> uint256: view


@external
def __init__():
    for c in COINS:
        ERC20(c).approve(NEW_POOL, MAX_UINT256)
    ERC20(NEW_TOKEN).approve(NEW_VAULT, MAX_UINT256)


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
def migrate_to_new_vault():
    """
    @notice Migrate liquidity between two pools
    Better to transfer 1 wei of old LP to the zap and keep 1 wei of each token
    """
    self.is_safe()

    old_amount: uint256 = 0
    bal: uint256 = ERC20(OLD_VAULT).balanceOf(msg.sender)

    coins: address[N_COINS] = COINS
    coin_balances: uint256[N_COINS] = empty(uint256[N_COINS])

    # Transfer the vault tokens in and withdraw if we hold any
    if bal > 0:
        ERC20(OLD_VAULT).transferFrom(msg.sender, self, bal)
        Vault(OLD_VAULT).withdraw(bal)
        bal = ERC20(OLD_TOKEN).balanceOf(self)
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

    # Deposit to our new vault
    bal = ERC20(NEW_TOKEN).balanceOf(self)
    if bal > 1:
        Vault(NEW_VAULT).deposit(bal - 1, msg.sender)