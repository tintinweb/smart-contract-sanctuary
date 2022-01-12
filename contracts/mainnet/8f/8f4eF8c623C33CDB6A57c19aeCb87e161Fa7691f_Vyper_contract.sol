# @version 0.3.1
"""
@title Curve Factory
@license MIT
@author Curve.Fi
@notice Permissionless pool deployer and registry
"""

struct PoolArray:
    token: address
    liquidity_gauge: address
    coins: address[2]
    decimals: uint256[2]

interface ERC20:
    def balanceOf(_addr: address) -> uint256: view
    def decimals() -> uint256: view
    def totalSupply() -> uint256: view
    def approve(_spender: address, _amount: uint256): nonpayable
    def initialize(_name: String[64], _symbol: String[32], _pool: address): nonpayable

interface CryptoPool:
    def A() -> uint256: view
    def gamma() -> uint256: view
    def mid_fee() -> uint256: view
    def out_fee() -> uint256: view
    def fee() -> uint256: view
    def allowed_extra_profit() -> uint256: view
    def fee_gamma() -> uint256: view
    def adjustment_step() -> uint256: view
    def admin_fee() -> uint256: view
    def ma_half_time() -> uint256: view
    def price_scale() -> uint256: view
    def price_oracle() -> uint256: view
    def last_prices() -> uint256: view
    def token() -> address: view
    def coins(i: uint256) -> address: view
    def get_virtual_price() -> uint256: view
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
        _coins: address[2]
    ): nonpayable
    def exchange(
        i: uint256, j: uint256, dx: uint256, min_dy: uint256,
        use_eth: bool, receiver: address, cb: Bytes[4]
    ) -> uint256: payable

interface LiquidityGauge:
    def initialize(_lp_token: address): nonpayable

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


admin: public(address)
future_admin: public(address)

pool_list: public(address[4294967296])   # master list of pools
pool_count: public(uint256)              # actual length of pool_list
pool_data: HashMap[address, PoolArray]

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

WETH: immutable(address)

N_COINS: constant(int128) = 2
A_MULTIPLIER: constant(uint256) = 10000

# Limits
MAX_ADMIN_FEE: constant(uint256) = 10 * 10 ** 9
MIN_FEE: constant(uint256) = 5 * 10 ** 5  # 0.5 bps
MAX_FEE: constant(uint256) = 10 * 10 ** 9

MIN_GAMMA: constant(uint256) = 10**10
MAX_GAMMA: constant(uint256) = 2 * 10**16

MIN_A: constant(uint256) = N_COINS**N_COINS * A_MULTIPLIER / 10
MAX_A: constant(uint256) = N_COINS**N_COINS * A_MULTIPLIER * 100000


@external
def __init__(_fee_receiver: address,
             _pool_implementation: address,
             _token_implementation: address,
             _gauge_implementation: address,
             _weth: address):
    self.admin = msg.sender
    self.fee_receiver = _fee_receiver
    self.pool_implementation = _pool_implementation
    self.token_implementation = _token_implementation
    self.gauge_implementation = _gauge_implementation
    WETH = _weth


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
    return self.pool_data[_pool].decimals


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
    for i in range(2):
        if self.pool_data[_pool].coins[i] == WETH:
            return i
    return MAX_UINT256


@view
@external
def get_token(_pool: address) -> address:
    return self.pool_data[_pool].token


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
    @param _symbol Symbol for the new plain pool - will be
                   concatenated with factory symbol
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

    decimals: uint256[2] = empty(uint256[2])
    for i in range(2):
        d: uint256 = ERC20(_coins[i]).decimals()
        assert d < 19, "Max 18 decimals for coins"
        decimals[i] = d
    assert _coins[0] != _coins[1], "Duplicate coins"

    name: String[64] = concat("Curve.fi Factory Crypto Pool: ", _name)
    symbol: String[32] = concat(_symbol, "-f")

    token: address = create_forwarder_to(self.token_implementation)
    pool: address = create_forwarder_to(self.pool_implementation)

    ERC20(token).initialize(name, symbol, pool)
    CryptoPool(pool).initialize(
        A, gamma, mid_fee, out_fee, allowed_extra_profit, fee_gamma,
        adjustment_step, admin_fee, ma_half_time, initial_price,
        token, _coins)

    length: uint256 = self.pool_count
    self.pool_list[length] = pool
    self.pool_count = length + 1
    self.pool_data[pool].token = token
    self.pool_data[pool].decimals = decimals
    self.pool_data[pool].coins = _coins

    for i in range(2):
        coin: address = _coins[i]
        raw_call(
            coin,
            concat(
                method_id("approve(address,uint256)"),
                convert(pool, bytes32),
                convert(MAX_UINT256, bytes32)
            )
        )

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
def set_gauge_implementation(_gauge_implementation: address):
    assert msg.sender == self.admin  # dev: admin-only function

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
    _admin: address = self.future_admin
    assert msg.sender == _admin  # dev: future admin only

    self.admin = _admin
    self.future_admin = ZERO_ADDRESS


@external
def set_fee_receiver(_fee_receiver: address):
    """
    @notice Set fee receiver for base and plain pools
    @param _fee_receiver Address that fees are sent to
    """
    assert msg.sender == self.admin  # dev: admin only
    self.fee_receiver = _fee_receiver