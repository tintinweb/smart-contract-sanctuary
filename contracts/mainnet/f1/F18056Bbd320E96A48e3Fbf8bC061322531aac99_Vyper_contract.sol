# @version 0.3.1
"""
@title Curve Factory
@license MIT
@author Curve.Fi
@notice Permissionless pool deployer and registry
"""


interface CryptoPool:
    def balances(i: uint256) -> uint256: view
    def initialize(
        A: uint256,
        gamma: uint256,
        mid_fee: uint256,
        out_fee: uint256,
        allowed_extra_profit: uint256,
        fee_gamma: uint256,
        adjustment_step: uint256,
        admin_fee: uint256,
        ma_half_time: uint256,
        initial_price: uint256,
        _token: address,
        _coins: address[2],
        _precisions: uint256
    ): nonpayable

interface ERC20:
    def decimals() -> uint256: view

interface LiquidityGauge:
    def initialize(_lp_token: address): nonpayable

interface Token:
    def initialize(_name: String[64], _symbol: String[32], _pool: address): nonpayable


event CryptoPoolDeployed:
    token: address
    coins: address[2]
    A: uint256
    gamma: uint256
    mid_fee: uint256
    out_fee: uint256
    allowed_extra_profit: uint256
    fee_gamma: uint256
    adjustment_step: uint256
    admin_fee: uint256
    ma_half_time: uint256
    initial_price: uint256
    deployer: address

event LiquidityGaugeDeployed:
    pool: address
    token: address
    gauge: address

event UpdateFeeReceiver:
    _old_fee_receiver: address
    _new_fee_receiver: address

event UpdatePoolImplementation:
    _old_pool_implementation: address
    _new_pool_implementation: address

event UpdateTokenImplementation:
    _old_token_implementation: address
    _new_token_implementation: address

event UpdateGaugeImplementation:
    _old_gauge_implementation: address
    _new_gauge_implementation: address

event TransferOwnership:
    _old_owner: address
    _new_owner: address


struct PoolArray:
    token: address
    liquidity_gauge: address
    coins: address[2]
    decimals: uint256


N_COINS: constant(int128) = 2
A_MULTIPLIER: constant(uint256) = 10000

# Limits
MAX_ADMIN_FEE: constant(uint256) = 10 * 10 ** 9
MIN_FEE: constant(uint256) = 5 * 10 ** 5  # 0.5 bps
MAX_FEE: constant(uint256) = 10 * 10 ** 9

MIN_GAMMA: constant(uint256) = 10 ** 10
MAX_GAMMA: constant(uint256) = 2 * 10 ** 16

MIN_A: constant(uint256) = N_COINS ** N_COINS * A_MULTIPLIER / 10
MAX_A: constant(uint256) = N_COINS ** N_COINS * A_MULTIPLIER * 100000


WETH: immutable(address)


admin: public(address)
future_admin: public(address)

# fee receiver for plain pools
fee_receiver: public(address)

pool_implementation: public(address)
token_implementation: public(address)
gauge_implementation: public(address)

# mapping of coins -> pools for trading
# a mapping key is generated for each pair of addresses via
# `bitwise_xor(convert(a, uint256), convert(b, uint256))`
markets: HashMap[uint256, address[4294967296]]
market_counts: HashMap[uint256, uint256]

pool_count: public(uint256)              # actual length of pool_list
pool_data: HashMap[address, PoolArray]
pool_list: public(address[4294967296])   # master list of pools


@external
def __init__(
    _fee_receiver: address,
    _pool_implementation: address,
    _token_implementation: address,
    _gauge_implementation: address,
    _weth: address
):
    self.fee_receiver = _fee_receiver
    self.pool_implementation = _pool_implementation
    self.token_implementation = _token_implementation
    self.gauge_implementation = _gauge_implementation

    self.admin = msg.sender
    WETH = _weth

    log UpdateFeeReceiver(ZERO_ADDRESS, _fee_receiver)
    log UpdatePoolImplementation(ZERO_ADDRESS, _pool_implementation)
    log UpdateTokenImplementation(ZERO_ADDRESS, _token_implementation)
    log UpdateGaugeImplementation(ZERO_ADDRESS, _gauge_implementation)
    log TransferOwnership(ZERO_ADDRESS, msg.sender)


# <--- Pool Deployers --->

@external
def deploy_pool(
    _name: String[32],
    _symbol: String[10],
    _coins: address[2],
    A: uint256,
    gamma: uint256,
    mid_fee: uint256,
    out_fee: uint256,
    allowed_extra_profit: uint256,
    fee_gamma: uint256,
    adjustment_step: uint256,
    admin_fee: uint256,
    ma_half_time: uint256,
    initial_price: uint256
) -> address:
    """
    @notice Deploy a new pool
    @param _name Name of the new plain pool
    @param _symbol Symbol for the new plain pool - will be concatenated with factory symbol
    Other parameters need some description
    @return Address of the deployed pool
    """
    # Validate parameters
    assert A > MIN_A-1
    assert A < MAX_A+1
    assert gamma > MIN_GAMMA-1
    assert gamma < MAX_GAMMA+1
    assert mid_fee > MIN_FEE-1
    assert mid_fee < MAX_FEE-1
    assert out_fee >= mid_fee
    assert out_fee < MAX_FEE-1
    assert admin_fee < 10**18+1
    assert allowed_extra_profit < 10**16+1
    assert fee_gamma < 10**18+1
    assert fee_gamma > 0
    assert adjustment_step < 10**18+1
    assert adjustment_step > 0
    assert ma_half_time < 7 * 86400
    assert ma_half_time > 0
    assert initial_price > 10**6
    assert initial_price < 10**30
    assert _coins[0] != _coins[1], "Duplicate coins"

    decimals: uint256[2] = empty(uint256[2])
    for i in range(2):
        d: uint256 = ERC20(_coins[i]).decimals()
        assert d < 19, "Max 18 decimals for coins"
        decimals[i] = d
    precisions: uint256 = (18 - decimals[0]) + shift(18 - decimals[1], 8)


    name: String[64] = concat("Curve.fi Factory Crypto Pool: ", _name)
    symbol: String[32] = concat(_symbol, "-f")

    token: address = create_forwarder_to(self.token_implementation)
    pool: address = create_forwarder_to(self.pool_implementation)

    Token(token).initialize(name, symbol, pool)
    CryptoPool(pool).initialize(
        A, gamma, mid_fee, out_fee, allowed_extra_profit, fee_gamma,
        adjustment_step, admin_fee, ma_half_time, initial_price,
        token, _coins, precisions)

    length: uint256 = self.pool_count
    self.pool_list[length] = pool
    self.pool_count = length + 1
    self.pool_data[pool].token = token
    self.pool_data[pool].decimals = shift(decimals[0], 8) + decimals[1]
    self.pool_data[pool].coins = _coins

    key: uint256 = bitwise_xor(convert(_coins[0], uint256), convert(_coins[1], uint256))
    length = self.market_counts[key]
    self.markets[key][length] = pool
    self.market_counts[key] = length + 1

    log CryptoPoolDeployed(
        token, _coins,
        A, gamma, mid_fee, out_fee, allowed_extra_profit, fee_gamma,
        adjustment_step, admin_fee, ma_half_time, initial_price,
        msg.sender)
    return pool


@external
def deploy_gauge(_pool: address) -> address:
    """
    @notice Deploy a liquidity gauge for a factory pool
    @param _pool Factory pool address to deploy a gauge for
    @return Address of the deployed gauge
    """
    assert self.pool_data[_pool].coins[0] != ZERO_ADDRESS, "Unknown pool"
    assert self.pool_data[_pool].liquidity_gauge == ZERO_ADDRESS, "Gauge already deployed"

    gauge: address = create_forwarder_to(self.gauge_implementation)
    token: address = self.pool_data[_pool].token
    LiquidityGauge(gauge).initialize(token)
    self.pool_data[_pool].liquidity_gauge = gauge

    log LiquidityGaugeDeployed(_pool, token, gauge)
    return gauge


# <--- Admin / Guarded Functionality --->


@external
def set_fee_receiver(_fee_receiver: address):
    """
    @notice Set fee receiver
    @param _fee_receiver Address that fees are sent to
    """
    assert msg.sender == self.admin  # dev: admin only

    log UpdateFeeReceiver(self.fee_receiver, _fee_receiver)
    self.fee_receiver = _fee_receiver


@external
def set_pool_implementation(_pool_implementation: address):
    """
    @notice Set pool implementation
    @dev Set to ZERO_ADDRESS to prevent deployment of new pools
    @param _pool_implementation Address of the new pool implementation
    """
    assert msg.sender == self.admin  # dev: admin only

    log UpdatePoolImplementation(self.pool_implementation, _pool_implementation)
    self.pool_implementation = _pool_implementation


@external
def set_token_implementation(_token_implementation: address):
    """
    @notice Set token implementation
    @dev Set to ZERO_ADDRESS to prevent deployment of new pools
    @param _token_implementation Address of the new token implementation
    """
    assert msg.sender == self.admin  # dev: admin only

    log UpdateTokenImplementation(self.token_implementation, _token_implementation)
    self.token_implementation = _token_implementation


@external
def set_gauge_implementation(_gauge_implementation: address):
    """
    @notice Set gauge implementation
    @dev Set to ZERO_ADDRESS to prevent deployment of new gauges
    @param _gauge_implementation Address of the new token implementation
    """
    assert msg.sender == self.admin  # dev: admin-only function

    log UpdateGaugeImplementation(self.gauge_implementation, _gauge_implementation)
    self.gauge_implementation = _gauge_implementation


@external
def commit_transfer_ownership(_addr: address):
    """
    @notice Transfer ownership of this contract to `addr`
    @param _addr Address of the new owner
    """
    assert msg.sender == self.admin  # dev: admin only

    self.future_admin = _addr


@external
def accept_transfer_ownership():
    """
    @notice Accept a pending ownership transfer
    @dev Only callable by the new owner
    """
    assert msg.sender == self.future_admin  # dev: future admin only

    log TransferOwnership(self.admin, msg.sender)
    self.admin = msg.sender


# <--- Factory Getters --->


@view
@external
def find_pool_for_coins(_from: address, _to: address, i: uint256 = 0) -> address:
    """
    @notice Find an available pool for exchanging two coins
    @param _from Address of coin to be sent
    @param _to Address of coin to be received
    @param i Index value. When multiple pools are available
            this value is used to return the n'th address.
    @return Pool address
    """
    key: uint256 = bitwise_xor(convert(_from, uint256), convert(_to, uint256))
    return self.markets[key][i]


# <--- Pool Getters --->


@view
@external
def get_coins(_pool: address) -> address[2]:
    """
    @notice Get the coins within a pool
    @param _pool Pool address
    @return List of coin addresses
    """
    return self.pool_data[_pool].coins


@view
@external
def get_decimals(_pool: address) -> uint256[2]:
    """
    @notice Get decimal places for each coin within a pool
    @param _pool Pool address
    @return uint256 list of decimals
    """
    decimals: uint256 = self.pool_data[_pool].decimals
    return [shift(decimals, -8), decimals % 256]


@view
@external
def get_balances(_pool: address) -> uint256[2]:
    """
    @notice Get balances for each coin within a pool
    @dev For pools using lending, these are the wrapped coin balances
    @param _pool Pool address
    @return uint256 list of balances
    """
    return [CryptoPool(_pool).balances(0), CryptoPool(_pool).balances(1)]


@view
@external
def get_coin_indices(
    _pool: address,
    _from: address,
    _to: address
) -> (uint256, uint256):
    """
    @notice Convert coin addresses to indices for use with pool methods
    @param _pool Pool address
    @param _from Coin address to be used as `i` within a pool
    @param _to Coin address to be used as `j` within a pool
    @return uint256 `i`, uint256 `j`
    """
    coins: address[2] = self.pool_data[_pool].coins

    if _from == coins[0] and _to == coins[1]:
        return 0, 1
    elif _from == coins[1] and _to == coins[0]:
        return 1, 0
    else:
        raise "Coins not found"


@view
@external
def get_gauge(_pool: address) -> address:
    """
    @notice Get the address of the liquidity gauge contract for a factory pool
    @dev Returns `ZERO_ADDRESS` if a gauge has not been deployed
    @param _pool Pool address
    @return Implementation contract address
    """
    return self.pool_data[_pool].liquidity_gauge


@view
@external
def get_eth_index(_pool: address) -> uint256:
    """
    @notice Get the index of WETH for a pool
    @dev Returns MAX_UINT256 if WETH is not a coin in the pool
    """
    for i in range(2):
        if self.pool_data[_pool].coins[i] == WETH:
            return i
    return MAX_UINT256


@view
@external
def get_token(_pool: address) -> address:
    """
    @notice Get the address of the LP token of a pool
    """
    return self.pool_data[_pool].token