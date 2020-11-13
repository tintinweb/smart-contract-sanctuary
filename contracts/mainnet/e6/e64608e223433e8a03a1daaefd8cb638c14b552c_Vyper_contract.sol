# @version 0.2.7
"""
@title Curve Registry PoolInfo
@license MIT
@author Curve.Fi
@notice Large getters designed for off-chain use
"""

MAX_COINS: constant(int128) = 8


interface AddressProvider:
    def get_registry() -> address: view

interface Registry:
    def get_coins(_pool: address) -> address[MAX_COINS]: view
    def get_underlying_coins(_pool: address) -> address[MAX_COINS]: view
    def get_decimals(_pool: address) -> uint256[MAX_COINS]: view
    def get_underlying_decimals(_pool: address) -> uint256[MAX_COINS]: view
    def get_balances(_pool: address) -> uint256[MAX_COINS]: view
    def get_underlying_balances(_pool: address) -> uint256[MAX_COINS]: view
    def get_rates(_pool: address) -> uint256[MAX_COINS]: view
    def get_lp_token(_pool: address) -> address: view
    def get_parameters(_pool: address) -> PoolParams: view


struct PoolParams:
    A: uint256
    future_A: uint256
    fee: uint256
    admin_fee: uint256
    future_fee: uint256
    future_admin_fee: uint256
    future_owner: address
    initial_A: uint256
    initial_A_time: uint256
    future_A_time: uint256

struct PoolInfo:
    balances: uint256[MAX_COINS]
    underlying_balances: uint256[MAX_COINS]
    decimals: uint256[MAX_COINS]
    underlying_decimals: uint256[MAX_COINS]
    rates: uint256[MAX_COINS]
    lp_token: address
    params: PoolParams

struct PoolCoins:
    coins: address[MAX_COINS]
    underlying_coins: address[MAX_COINS]
    decimals: uint256[MAX_COINS]
    underlying_decimals: uint256[MAX_COINS]


address_provider: public(AddressProvider)


@external
def __init__(_provider: address):
    self.address_provider = AddressProvider(_provider)


@view
@external
def get_pool_coins(_pool: address) -> PoolCoins:
    """
    @notice Get information on coins in a pool
    @dev Empty values in the returned arrays may be ignored
    @param _pool Pool address
    @return Coin addresses, underlying coin addresses, underlying coin decimals
    """
    registry: address = self.address_provider.get_registry()

    return PoolCoins({
        coins: Registry(registry).get_coins(_pool),
        underlying_coins: Registry(registry).get_underlying_coins(_pool),
        decimals: Registry(registry).get_decimals(_pool),
        underlying_decimals: Registry(registry).get_underlying_decimals(_pool),
    })


@view
@external
def get_pool_info(_pool: address) -> PoolInfo:
    """
    @notice Get information on a pool
    @dev Reverts if the pool address is unknown
    @param _pool Pool address
    @return balances, underlying balances, decimals, underlying decimals,
            lp token, amplification coefficient, fees
    """
    registry: address = self.address_provider.get_registry()

    return PoolInfo({
        balances: Registry(registry).get_balances(_pool),
        underlying_balances: Registry(registry).get_underlying_balances(_pool),
        decimals: Registry(registry).get_decimals(_pool),
        underlying_decimals: Registry(registry).get_underlying_decimals(_pool),
        rates: Registry(registry).get_rates(_pool),
        lp_token: Registry(registry).get_lp_token(_pool),
        params: Registry(registry).get_parameters(_pool),
    })