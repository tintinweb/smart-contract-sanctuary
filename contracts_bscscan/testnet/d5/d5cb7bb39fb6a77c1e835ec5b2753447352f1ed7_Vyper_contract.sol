# @version 0.2.12
"""
@title Kurve StableSwap DEX : Kast.vy
@author Sam4x, for Guru Network
@website https://kcc.guru
@frontend https://kcc.guru/kurve
@contact [email protected]
@discord 543#3017 at https://discord.com/invite/QpyfMarNrV
@telegram kccguru, kucino, ftm1337, ftmguru, fmcguru
@twitter KCCguru, FTM1337
@license No License 
@reference file://Kurve/Kast.vy
@notice Pool Caster (Kast) & Tokens ("KARD") Creator
@impressum 

KKKKKKKKK    KKKKKKKUUUUUUUU     UUUUUUUURRRRRRRRRRRRRRRRR   VVVVVVVV           VVVVVVVVEEEEEEEEEEEEEEEEEEEEEE
K:::::::K    K:::::KU::::::U     U::::::UR::::::::::::::::R  V::::::V           V::::::VE::::::::::::::::::::E
K:::::::K    K:::::KU::::::U     U::::::UR::::::RRRRRR:::::R V::::::V           V::::::VE::::::::::::::::::::E
K:::::::K   K::::::KUU:::::U     U:::::UURR:::::R     R:::::RV::::::V           V::::::VEE::::::EEEEEEEEE::::E
KK::::::K  K:::::KKK U:::::U     U:::::U   R::::R     R:::::R V:::::V           V:::::V   E:::::E       EEEEEE
  K:::::K K:::::K    U:::::D     D:::::U   R::::R     R:::::R  V:::::V         V:::::V    E:::::E             
  K::::::K:::::K     U:::::D     D:::::U   R::::RRRRRR:::::R    V:::::V       V:::::V     E::::::EEEEEEEEEE   
  K:::::::::::K      U:::::D     D:::::U   R:::::::::::::RR      V:::::V     V:::::V      E:::::::::::::::E   
  K:::::::::::K      U:::::D     D:::::U   R::::RRRRRR:::::R      V:::::V   V:::::V       E:::::::::::::::E   
  K::::::K:::::K     U:::::D     D:::::U   R::::R     R:::::R      V:::::V V:::::V        E::::::EEEEEEEEEE   
  K:::::K K:::::K    U:::::D     D:::::U   R::::R     R:::::R       V:::::V:::::V         E:::::E             
KK::::::K  K:::::KKK U::::::U   U::::::U   R::::R     R:::::R        V:::::::::V          E:::::E       EEEEEE
K:::::::K   K::::::K U:::::::UUU:::::::U RR:::::R     R:::::R         V:::::::V         EE::::::EEEEEEEE:::::E
K:::::::K    K:::::K  UU:::::::::::::UU  R::::::R     R:::::R          V:::::V          E::::::::::::::::::::E
K:::::::K    K:::::K    UU:::::::::UU    R::::::R     R:::::R           V:::V           E::::::::::::::::::::E
KKKKKKKKK    KKKKKKK      UUUUUUUUU      RRRRRRRR     RRRRRRR            VVV            EEEEEEEEEEEEEEEEEEEEEE


KURVE : StableSwap DEX
Created By : KCC.guru

Say goodbye to AMMs that steal 0.25 - 0.3% in the name of trade fee.
Swap Stablecoins and other similar-valued tokens with ultra-low fees!
Get the most optimal output on your Stablecoins with our game-changing Kurve DEX.
Extremely low Slippage and near-zero price impacts, even for those Huge swaps.

Also, Earn rewards for pooling your resources in any ratio with our YGP*.
*Incentivised pools ("Kards") may vary over time due to demand & on-chain volume.

Visit https://kcc.guru/kurve to get a hands-on experience.
Or call "exchange" directly on any of our "Kurve Kard" pools' smart contracts.

"""

struct PoolArray:
    base_pool: address
    implementation: address
    liquidity_gauge: address
    coins: address[MAX_PLAIN_COINS]
    decimals: uint256[MAX_PLAIN_COINS]
    n_coins: uint256
    asset_type: uint256

struct BasePoolArray:
    implementations: address[10]
    lp_token: address
    fee_receiver: address
    coins: address[MAX_COINS]
    decimals: uint256
    n_coins: uint256
    asset_type: uint256


interface AddressProvider:
    def admin() -> address: view
    def get_registry() -> address: view

interface Registry:
    def get_lp_token(pool: address) -> address: view
    def get_n_coins(pool: address) -> uint256: view
    def get_coins(pool: address) -> address[MAX_COINS]: view
    def get_pool_from_lp_token(lp_token: address) -> address: view

interface ERC20:
    def balanceOf(_addr: address) -> uint256: view
    def decimals() -> uint256: view
    def totalSupply() -> uint256: view
    def approve(_spender: address, _amount: uint256): nonpayable

interface KurvePlainPool:
    def initialize(
        _name: String[32],
        _symbol: String[10],
        _coins: address[4],
        _rate_multipliers: uint256[4],
        _A: uint256,
        _fee: uint256,
    ): nonpayable

interface KurvePool:
    def A() -> uint256: view
    def fee() -> uint256: view
    def admin_fee() -> uint256: view
    def balances(i: uint256) -> uint256: view
    def admin_balances(i: uint256) -> uint256: view
    def get_virtual_price() -> uint256: view
    def initialize(
        _name: String[32],
        _symbol: String[10],
        _coin: address,
        _rate_multiplier: uint256,
        _A: uint256,
        _fee: uint256,
    ): nonpayable
    def exchange(
        i: int128,
        j: int128,
        dx: uint256,
        min_dy: uint256,
        _receiver: address,
    ) -> uint256: nonpayable

interface KurveFactoryMetapool:
    def coins(i :uint256) -> address: view
    def decimals() -> uint256: view

interface OldFactory:
    def get_coins(_pool: address) -> address[2]: view

interface LiquidityGauge:
    def initialize(_lp_token: address): nonpayable


event BasePoolAdded:
    base_pool: address

event PlainPoolDeployed:
    coins: address[MAX_PLAIN_COINS]
    A: uint256
    fee: uint256
    deployer: address

event MetaPoolDeployed:
    coin: address
    base_pool: address
    A: uint256
    fee: uint256
    deployer: address

event LiquidityGaugeDeployed:
    pool: address
    gauge: address


MAX_COINS: constant(int128) = 8
MAX_PLAIN_COINS: constant(int128) = 4  # max coins in a plain pool
ADDRESS_PROVIDER: constant(address) = 0x0000000022D53366457F9d5E68Ec105046FC4383

admin: public(address)
future_admin: public(address)
manager: public(address)

pool_list: public(address[4294967296])   # master list of pools
pool_count: public(uint256)              # actual length of pool_list
pool_data: HashMap[address, PoolArray]

base_pool_list: public(address[4294967296])   # master list of pools
base_pool_count: public(uint256)         # actual length of pool_list
base_pool_data: HashMap[address, BasePoolArray]

# number of coins -> implementation addresses
# for "plain pools" (as opposed to metapools), implementation contracts
# are organized according to the number of coins in the pool
plain_implementations: public(HashMap[uint256, address[10]])

# fee receiver for plain pools
fee_receiver: public(address)

gauge_implementation: public(address)

# mapping of coins -> pools for trading
# a mapping key is generated for each pair of addresses via
# `bitwise_xor(convert(a, uint256), convert(b, uint256))`
markets: HashMap[uint256, address[4294967296]]
market_counts: HashMap[uint256, uint256]


@external
def __init__(_fee_receiver: address):
    self.admin = msg.sender
    self.manager = msg.sender
    self.fee_receiver = _fee_receiver


# <--- Factory Getters --->

@view
@external
def metapool_implementations(_base_pool: address) -> address[10]:
    """
    @notice Get a list of implementation contracts for metapools targetting the given base pool
    @dev A base pool is the pool for the LP token contained within the metapool
    @param _base_pool Address of the base pool
    @return List of implementation contract addresses
    """
    return self.base_pool_data[_base_pool].implementations


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
def get_base_pool(_pool: address) -> address:
    """
    @notice Get the base pool for a given factory metapool
    @param _pool Metapool address
    @return Address of base pool
    """
    return self.pool_data[_pool].base_pool


@view
@external
def get_n_coins(_pool: address) -> (uint256):
    """
    @notice Get the number of coins in a pool
    @param _pool Pool address
    @return Number of coins
    """
    return self.pool_data[_pool].n_coins


@view
@external
def get_meta_n_coins(_pool: address) -> (uint256, uint256):
    """
    @notice Get the number of coins in a metapool
    @param _pool Pool address
    @return Number of wrapped coins, number of underlying coins
    """
    base_pool: address = self.pool_data[_pool].base_pool
    return 2, self.base_pool_data[base_pool].n_coins + 1


@view
@external
def get_coins(_pool: address) -> address[MAX_PLAIN_COINS]:
    """
    @notice Get the coins within a pool
    @param _pool Pool address
    @return List of coin addresses
    """
    return self.pool_data[_pool].coins


@view
@external
def get_underlying_coins(_pool: address) -> address[MAX_COINS]:
    """
    @notice Get the underlying coins within a pool
    @dev Reverts if a pool does not exist or is not a metapool
    @param _pool Pool address
    @return List of coin addresses
    """
    coins: address[MAX_COINS] = empty(address[MAX_COINS])
    base_pool: address = self.pool_data[_pool].base_pool
    assert base_pool != ZERO_ADDRESS  # dev: pool is not metapool
    coins[0] = self.pool_data[_pool].coins[0]
    for i in range(1, MAX_COINS):
        coins[i] = self.base_pool_data[base_pool].coins[i - 1]
        if coins[i] == ZERO_ADDRESS:
            break

    return coins


@view
@external
def get_decimals(_pool: address) -> uint256[MAX_PLAIN_COINS]:
    """
    @notice Get decimal places for each coin within a pool
    @param _pool Pool address
    @return uint256 list of decimals
    """
    if self.pool_data[_pool].base_pool != ZERO_ADDRESS:
        decimals: uint256[MAX_PLAIN_COINS] = empty(uint256[MAX_PLAIN_COINS])
        decimals = self.pool_data[_pool].decimals
        decimals[1] = 18
        return decimals
    return self.pool_data[_pool].decimals


@view
@external
def get_underlying_decimals(_pool: address) -> uint256[MAX_COINS]:
    """
    @notice Get decimal places for each underlying coin within a pool
    @param _pool Pool address
    @return uint256 list of decimals
    """
    # decimals are tightly packed as a series of uint8 within a little-endian bytes32
    # the packed value is stored as uint256 to simplify unpacking via shift and modulo
    pool_decimals: uint256[MAX_PLAIN_COINS] = empty(uint256[MAX_PLAIN_COINS])
    pool_decimals = self.pool_data[_pool].decimals
    decimals: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    decimals[0] = pool_decimals[0]
    base_pool: address = self.pool_data[_pool].base_pool
    packed_decimals: uint256 = self.base_pool_data[base_pool].decimals
    for i in range(MAX_COINS):
        unpacked: uint256 = shift(packed_decimals, -8 * i) % 256
        if unpacked == 0:
            break
        decimals[i+1] = unpacked

    return decimals


@view
@external
def get_metapool_rates(_pool: address) -> uint256[2]:
    """
    @notice Get rates for coins within a metapool
    @param _pool Pool address
    @return Rates for each coin, precision normalized to 10**18
    """
    rates: uint256[2] = [10**18, 0]
    rates[1] = KurvePool(self.pool_data[_pool].base_pool).get_virtual_price()
    return rates


@view
@external
def get_balances(_pool: address) -> uint256[MAX_PLAIN_COINS]:
    """
    @notice Get balances for each coin within a pool
    @dev For pools using lending, these are the wrapped coin balances
    @param _pool Pool address
    @return uint256 list of balances
    """
    if self.pool_data[_pool].base_pool != ZERO_ADDRESS:
        return [KurvePool(_pool).balances(0), KurvePool(_pool).balances(1), 0, 0]
    n_coins: uint256 = self.pool_data[_pool].n_coins
    balances: uint256[MAX_PLAIN_COINS] = empty(uint256[MAX_PLAIN_COINS])
    for i in range(MAX_PLAIN_COINS):
        if i < n_coins:
            balances[i] = KurvePool(_pool).balances(i)
        else:
            balances[i] = 0
    return balances


@view
@external
def get_underlying_balances(_pool: address) -> uint256[MAX_COINS]:
    """
    @notice Get balances for each underlying coin within a metapool
    @param _pool Metapool address
    @return uint256 list of underlying balances
    """

    underlying_balances: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    underlying_balances[0] = KurvePool(_pool).balances(0)

    base_total_supply: uint256 = ERC20(self.pool_data[_pool].coins[1]).totalSupply()
    if base_total_supply > 0:
        underlying_pct: uint256 = KurvePool(_pool).balances(1) * 10**36 / base_total_supply
        base_pool: address = self.pool_data[_pool].base_pool
        assert base_pool != ZERO_ADDRESS  # dev: pool is not a metapool
        n_coins: uint256 = self.base_pool_data[base_pool].n_coins
        for i in range(MAX_COINS):
            if i == n_coins:
                break
            underlying_balances[i + 1] = KurvePool(base_pool).balances(i) * underlying_pct / 10**36

    return underlying_balances


@view
@external
def get_A(_pool: address) -> uint256:
    """
    @notice Get the amplfication co-efficient for a pool
    @param _pool Pool address
    @return uint256 A
    """
    return KurvePool(_pool).A()


@view
@external
def get_fees(_pool: address) -> (uint256, uint256):
    """
    @notice Get the fees for a pool
    @dev Fees are expressed as integers
    @return Pool fee and admin fee as uint256 with 1e10 precision
    """
    return KurvePool(_pool).fee(), KurvePool(_pool).admin_fee()


@view
@external
def get_admin_balances(_pool: address) -> uint256[MAX_PLAIN_COINS]:
    """
    @notice Get the current admin balances (uncollected fees) for a pool
    @param _pool Pool address
    @return List of uint256 admin balances
    """
    n_coins: uint256 = self.pool_data[_pool].n_coins
    admin_balances: uint256[MAX_PLAIN_COINS] = empty(uint256[MAX_PLAIN_COINS])
    for i in range(MAX_PLAIN_COINS):
        if i == n_coins:
            break
        admin_balances[i] = KurvePool(_pool).admin_balances(i)
    return admin_balances


@view
@external
def get_coin_indices(
    _pool: address,
    _from: address,
    _to: address
) -> (int128, int128, bool):
    """
    @notice Convert coin addresses to indices for use with pool methods
    @param _pool Pool address
    @param _from Coin address to be used as `i` within a pool
    @param _to Coin address to be used as `j` within a pool
    @return int128 `i`, int128 `j`, boolean indicating if `i` and `j` are underlying coins
    """
    coin: address = self.pool_data[_pool].coins[0]
    base_pool: address = self.pool_data[_pool].base_pool
    if coin in [_from, _to] and base_pool != ZERO_ADDRESS:
        base_lp_token: address = self.pool_data[_pool].coins[1]
        if base_lp_token in [_from, _to]:
            # True and False convert to 1 and 0 - a bit of voodoo that
            # works because we only ever have 2 non-underlying coins if base pool is ZERO_ADDRESS
            return convert(_to == coin, int128), convert(_from == coin, int128), False

    found_market: bool = False
    i: int128 = 0
    j: int128 = 0
    for x in range(MAX_COINS):
        if base_pool == ZERO_ADDRESS:
            if x >= MAX_PLAIN_COINS:
                raise "No available market"
            if x != 0:
                coin = self.pool_data[_pool].coins[x]
        else:
            if x != 0:
                coin = self.base_pool_data[base_pool].coins[x-1]
        if coin == ZERO_ADDRESS:
            raise "No available market"
        if coin == _from:
            i = x
        elif coin == _to:
            j = x
        else:
            continue
        if found_market:
            # the second time we find a match, break out of the loop
            break
        # the first time we find a match, set `found_market` to True
        found_market = True

    return i, j, True


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
def get_implementation_address(_pool: address) -> address:
    """
    @notice Get the address of the implementation contract used for a factory pool
    @param _pool Pool address
    @return Implementation contract address
    """
    return self.pool_data[_pool].implementation


@view
@external
def is_meta(_pool: address) -> bool:
    """
    @notice Verify `_pool` is a metapool
    @param _pool Pool address
    @return True if `_pool` is a metapool
    """
    return self.pool_data[_pool].base_pool != ZERO_ADDRESS


@view
@external
def get_pool_asset_type(_pool: address) -> uint256:
    """
    @notice Query the asset type of `_pool`
    @dev 0 = USD, 1 = ETH, 2 = BTC, 3 = Other
    @param _pool Pool Address
    @return Integer indicating the pool asset type
    """
    base_pool: address = self.pool_data[_pool].base_pool
    if base_pool == ZERO_ADDRESS:
        return self.pool_data[_pool].asset_type
    else:
        return self.base_pool_data[base_pool].asset_type


@view
@external
def get_fee_receiver(_pool: address) -> address:
    base_pool: address = self.pool_data[_pool].base_pool
    if base_pool == ZERO_ADDRESS:
        return self.fee_receiver
    else:
        return self.base_pool_data[base_pool].fee_receiver


# <--- Pool Deployers --->

@external
def deploy_plain_pool(
    _name: String[32],
    _symbol: String[10],
    _coins: address[MAX_PLAIN_COINS],
    _A: uint256,
    _fee: uint256,
    _asset_type: uint256 = 0,
    _implementation_idx: uint256 = 0,
) -> address:
    """
    @notice Deploy a new plain pool
    @param _name Name of the new plain pool
    @param _symbol Symbol for the new plain pool - will be
                   concatenated with factory symbol
    @param _coins List of addresses of the coins being used in the pool.
    @param _A Amplification co-efficient - a lower value here means
              less tolerance for imbalance within the pool's assets.
              Suggested values include:
               * Uncollateralized algorithmic stablecoins: 5-10
               * Non-redeemable, collateralized assets: 100
               * Redeemable assets: 200-400
    @param _fee Trade fee, given as an integer with 1e10 precision. The
                minimum fee is 0.04% (4000000), the maximum is 1% (100000000).
                50% of the fee is distributed to veCRV holders.
    @param _asset_type Asset type for pool, as an integer
                       0 = USD, 1 = ETH, 2 = BTC, 3 = Other
    @param _implementation_idx Index of the implementation to use. All possible
                implementations for a pool of N_COINS can be publicly accessed
                via `plain_implementations(N_COINS)`
    @return Address of the deployed pool
    """
    # fee must be between 0.04% and 1%
    assert _fee >= 4000000 and _fee <= 100000000, "Invalid fee"

    n_coins: uint256 = MAX_PLAIN_COINS
    rate_multipliers: uint256[MAX_PLAIN_COINS] = empty(uint256[MAX_PLAIN_COINS])
    decimals: uint256[MAX_PLAIN_COINS] = empty(uint256[MAX_PLAIN_COINS])

    for i in range(MAX_PLAIN_COINS):
        coin: address = _coins[i]
        if coin == ZERO_ADDRESS:
            assert i > 1, "Insufficient coins"
            n_coins = i
            break

        if _coins[i] == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
            assert i == 0, "ETH must be first coin"
            decimals[0] = 18
        else:
            decimals[i] = ERC20(coin).decimals()
            assert decimals[i] < 19, "Max 18 decimals for coins"

        rate_multipliers[i] = 10 ** (36 - decimals[i])

        for x in range(i, i+MAX_PLAIN_COINS):
            if x+1 == MAX_PLAIN_COINS:
                break
            if _coins[x+1] == ZERO_ADDRESS:
                break
            assert coin != _coins[x+1], "Duplicate coins"

    implementation: address = self.plain_implementations[n_coins][_implementation_idx]
    assert implementation != ZERO_ADDRESS, "Invalid implementation index"
    pool: address = create_forwarder_to(implementation)
    KurvePlainPool(pool).initialize(_name, _symbol, _coins, rate_multipliers, _A, _fee)

    length: uint256 = self.pool_count
    self.pool_list[length] = pool
    self.pool_count = length + 1
    self.pool_data[pool].decimals = decimals
    self.pool_data[pool].n_coins = n_coins
    self.pool_data[pool].base_pool = ZERO_ADDRESS
    self.pool_data[pool].implementation = implementation
    if _asset_type != 0:
        self.pool_data[pool].asset_type = _asset_type

    for i in range(MAX_PLAIN_COINS):
        coin: address = _coins[i]
        if coin == ZERO_ADDRESS:
            break
        self.pool_data[pool].coins[i] = coin
        raw_call(
            coin,
            concat(
                method_id("approve(address,uint256)"),
                convert(pool, bytes32),
                convert(MAX_UINT256, bytes32)
            )
        )
        for j in range(MAX_PLAIN_COINS):
            if i < j:
                swappable_coin: address = _coins[j]
                key: uint256 = bitwise_xor(convert(coin, uint256), convert(swappable_coin, uint256))
                length = self.market_counts[key]
                self.markets[key][length] = pool
                self.market_counts[key] = length + 1

    log PlainPoolDeployed(_coins, _A, _fee, msg.sender)
    return pool


@external
def deploy_metapool(
    _base_pool: address,
    _name: String[32],
    _symbol: String[10],
    _coin: address,
    _A: uint256,
    _fee: uint256,
    _implementation_idx: uint256 = 0,
) -> address:
    """
    @notice Deploy a new metapool
    @param _base_pool Address of the base pool to use
                      within the metapool
    @param _name Name of the new metapool
    @param _symbol Symbol for the new metapool - will be
                   concatenated with the base pool symbol
    @param _coin Address of the coin being used in the metapool
    @param _A Amplification co-efficient - a higher value here means
              less tolerance for imbalance within the pool's assets.
              Suggested values include:
               * Uncollateralized algorithmic stablecoins: 5-10
               * Non-redeemable, collateralized assets: 100
               * Redeemable assets: 200-400
    @param _fee Trade fee, given as an integer with 1e10 precision. The
                minimum fee is 0.04% (4000000), the maximum is 1% (100000000).
                50% of the fee is distributed to veCRV holders.
    @param _implementation_idx Index of the implementation to use. All possible
                implementations for a BASE_POOL can be publicly accessed
                via `metapool_implementations(BASE_POOL)`
    @return Address of the deployed pool
    """
    # fee must be between 0.04% and 1%
    assert _fee >= 4000000 and _fee <= 100000000, "Invalid fee"

    implementation: address = self.base_pool_data[_base_pool].implementations[_implementation_idx]
    assert implementation != ZERO_ADDRESS, "Invalid implementation index"

    # things break if a token has >18 decimals
    decimals: uint256 = ERC20(_coin).decimals()
    assert decimals < 19, "Max 18 decimals for coins"

    pool: address = create_forwarder_to(implementation)
    KurvePool(pool).initialize(_name, _symbol, _coin, 10 ** (36 - decimals), _A, _fee)
    ERC20(_coin).approve(pool, MAX_UINT256)

    # add pool to pool_list
    length: uint256 = self.pool_count
    self.pool_list[length] = pool
    self.pool_count = length + 1

    base_lp_token: address = self.base_pool_data[_base_pool].lp_token

    self.pool_data[pool].decimals = [decimals, 0, 0, 0]
    self.pool_data[pool].n_coins = 2
    self.pool_data[pool].base_pool = _base_pool
    self.pool_data[pool].coins[0] = _coin
    self.pool_data[pool].coins[1] = self.base_pool_data[_base_pool].lp_token
    self.pool_data[pool].implementation = implementation

    is_finished: bool = False
    for i in range(MAX_COINS):
        swappable_coin: address = self.base_pool_data[_base_pool].coins[i]
        if swappable_coin == ZERO_ADDRESS:
            is_finished = True
            swappable_coin = base_lp_token

        key: uint256 = bitwise_xor(convert(_coin, uint256), convert(swappable_coin, uint256))
        length = self.market_counts[key]
        self.markets[key][length] = pool
        self.market_counts[key] = length + 1
        if is_finished:
            break

    log MetaPoolDeployed(_coin, _base_pool, _A, _fee, msg.sender)
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
    implementation: address = self.gauge_implementation
    assert implementation != ZERO_ADDRESS, "Gauge implementation not set"

    gauge: address = create_forwarder_to(implementation)
    LiquidityGauge(gauge).initialize(_pool)
    self.pool_data[_pool].liquidity_gauge = gauge

    log LiquidityGaugeDeployed(_pool, gauge)
    return gauge


# <--- Admin / Guarded Functionality --->

@external
def add_base_pool(
    _base_pool: address,
    _fee_receiver: address,
    _asset_type: uint256,
    _implementations: address[10],
):
    """
    @notice Add a base pool to the registry, which may be used in factory metapools
    @dev Only callable by admin
    @param _base_pool Pool address to add
    @param _fee_receiver Admin fee receiver address for metapools using this base pool
    @param _asset_type Asset type for pool, as an integer  0 = USD, 1 = ETH, 2 = BTC, 3 = Other
    @param _implementations List of implementation addresses that can be used with this base pool
    """
    assert msg.sender == self.admin  # dev: admin-only function
    assert self.base_pool_data[_base_pool].coins[0] == ZERO_ADDRESS  # dev: pool exists

    registry: address = AddressProvider(ADDRESS_PROVIDER).get_registry()
    n_coins: uint256 = Registry(registry).get_n_coins(_base_pool)
    assert n_coins > 0  # dev: pool not in registry

    # add pool to pool_list
    length: uint256 = self.base_pool_count
    self.base_pool_list[length] = _base_pool
    self.base_pool_count = length + 1
    self.base_pool_data[_base_pool].lp_token = Registry(registry).get_lp_token(_base_pool)
    self.base_pool_data[_base_pool].n_coins = n_coins
    self.base_pool_data[_base_pool].fee_receiver = _fee_receiver
    if _asset_type != 0:
        self.base_pool_data[_base_pool].asset_type = _asset_type

    for i in range(10):
        implementation: address = _implementations[i]
        if implementation == ZERO_ADDRESS:
            break
        self.base_pool_data[_base_pool].implementations[i] = implementation

    decimals: uint256 = 0
    coins: address[MAX_COINS] = Registry(registry).get_coins(_base_pool)
    for i in range(MAX_COINS):
        if i == n_coins:
            break
        coin: address = coins[i]
        self.base_pool_data[_base_pool].coins[i] = coin
        decimals += shift(ERC20(coin).decimals(), convert(i*8, int128))
    self.base_pool_data[_base_pool].decimals = decimals

    log BasePoolAdded(_base_pool)


@external
def set_metapool_implementations(
    _base_pool: address,
    _implementations: address[10],
):
    """
    @notice Set implementation contracts for a metapool
    @dev Only callable by admin
    @param _base_pool Pool address to add
    @param _implementations Implementation address to use when deploying metapools
    """
    assert msg.sender == self.admin  # dev: admin-only function
    assert self.base_pool_data[_base_pool].coins[0] != ZERO_ADDRESS  # dev: base pool does not exist

    for i in range(10):
        new_imp: address = _implementations[i]
        current_imp: address = self.base_pool_data[_base_pool].implementations[i]
        if new_imp == current_imp:
            if new_imp == ZERO_ADDRESS:
                break
        else:
            self.base_pool_data[_base_pool].implementations[i] = new_imp


@external
def set_plain_implementations(
    _n_coins: uint256,
    _implementations: address[10],
):
    assert msg.sender == self.admin  # dev: admin-only function

    for i in range(10):
        new_imp: address = _implementations[i]
        current_imp: address = self.plain_implementations[_n_coins][i]
        if new_imp == current_imp:
            if new_imp == ZERO_ADDRESS:
                break
        else:
            self.plain_implementations[_n_coins][i] = new_imp


@external
def set_gauge_implementation(_gauge_implementation: address):
    assert msg.sender == self.admin  # dev: admin-only function

    self.gauge_implementation = _gauge_implementation


@external
def set_gauge(_pool: address, _gauge: address):
    assert msg.sender == self.admin  # dev: admin-only function
    assert self.pool_data[_pool].coins[0] != ZERO_ADDRESS, "Unknown pool"

    self.pool_data[_pool].liquidity_gauge = _gauge
    log LiquidityGaugeDeployed(_pool, _gauge)


@external
def batch_set_pool_asset_type(_pools: address[32], _asset_types: uint256[32]):
    """
    @notice Batch set the asset type for factory pools
    @dev Used to modify asset types that were set incorrectly at deployment
    """
    assert msg.sender in [self.manager, self.admin]  # dev: admin-only function

    for i in range(32):
        if _pools[i] == ZERO_ADDRESS:
            break
        self.pool_data[_pools[i]].asset_type = _asset_types[i]


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
def set_manager(_manager: address):
    """
    @notice Set the manager
    @dev Callable by the admin or existing manager
    @param _manager Manager address
    """
    assert msg.sender in [self.manager, self.admin]  # dev: admin-only function

    self.manager = _manager


@external
def set_fee_receiver(_base_pool: address, _fee_receiver: address):
    """
    @notice Set fee receiver for base and plain pools
    @param _base_pool Address of base pool to set fee receiver for.
                      For plain pools, leave as `ZERO_ADDRESS`.
    @param _fee_receiver Address that fees are sent to
    """
    assert msg.sender == self.admin  # dev: admin only
    if _base_pool == ZERO_ADDRESS:
        self.fee_receiver = _fee_receiver
    else:
        self.base_pool_data[_base_pool].fee_receiver = _fee_receiver


@external
def convert_metapool_fees() -> bool:
    """
    @notice Convert the fees of a metapool and transfer to
            the metapool's fee receiver
    @dev All fees are converted to LP token of base pool
    """
    base_pool: address = self.pool_data[msg.sender].base_pool
    assert base_pool != ZERO_ADDRESS  # dev: sender must be metapool
    coin: address = self.pool_data[msg.sender].coins[0]

    amount: uint256 = ERC20(coin).balanceOf(self)
    receiver: address = self.base_pool_data[base_pool].fee_receiver

    KurvePool(msg.sender).exchange(0, 1, amount, 0, receiver)
    return True


#    @notice Kurve Kast and Kurve Kards are products developed for the E.L.I.T.E. D.A.O.
#        Special mention to Curve.fi for inspiration.
#        Heartfelt gratitute to ELITE and KUCINO holders for encouragement.
#        Come, join our community: Guru Network
#    @contact [email protected]
#    @discord https://discord.com/invite/QpyfMarNrV
#    @telegram kucino, ftm1337, ftmguru, kccguru, fmcguru
#    @twitter KCCguru, FTM1337