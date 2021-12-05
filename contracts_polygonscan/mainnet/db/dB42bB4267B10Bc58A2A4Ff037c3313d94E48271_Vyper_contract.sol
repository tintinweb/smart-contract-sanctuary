# @version 0.3.0
"""
@title Curve CryptoSwap Registry
@license MIT
@author Curve.Fi
"""

MAX_COINS: constant(int128) = 8
CALC_INPUT_SIZE: constant(int128) = 100


struct CoinInfo:
    index: uint256
    register_count: uint256
    swap_count: uint256
    swap_for: address[MAX_INT128]

struct PoolArray:
    location: uint256
    decimals: uint256
    coins: address[MAX_COINS]
    n_coins: uint256
    name: String[64]


interface AddressProvider:
    def admin() -> address: view
    def get_address(_id: uint256) -> address: view
    def get_registry() -> address: view

interface ERC20:
    def balanceOf(_addr: address) -> uint256: view
    def decimals() -> uint256: view
    def totalSupply() -> uint256: view

interface CurvePool:
    def token() -> address: view
    def coins(i: uint256) -> address: view
    def A() -> uint256: view
    def gamma() -> uint256: view
    def fee() -> uint256: view
    def get_virtual_price() -> uint256: view
    def mid_fee() -> uint256: view
    def out_fee() -> uint256: view
    def admin_fee() -> uint256: view
    def balances(i: uint256) -> uint256: view
    def D() -> uint256: view

interface LiquidityGauge:
    def lp_token() -> address: view

interface GaugeController:
    def gauge_types(gauge: address) -> int128: view


event PoolAdded:
    pool: indexed(address)

event PoolRemoved:
    pool: indexed(address)


address_provider: public(AddressProvider)
pool_list: public(address[65536])   # master list of pools
pool_count: public(uint256)         # actual length of pool_list

pool_data: HashMap[address, PoolArray]

coin_count: public(uint256)  # total unique coins registered
coins: HashMap[address, CoinInfo]
get_coin: public(address[65536])  # unique list of registered coins
# bitwise_xor(coina, coinb) -> (coina_pos, coinb_pos) sorted
# stored as uint128[2]
coin_swap_indexes: HashMap[uint256, uint256]

# lp token -> pool
get_pool_from_lp_token: public(HashMap[address, address])

# pool -> lp token
get_lp_token: public(HashMap[address, address])

# mapping of coins -> pools for trading
# a mapping key is generated for each pair of addresses via
# `bitwise_xor(convert(a, uint256), convert(b, uint256))`
markets: HashMap[uint256, address[65536]]
market_counts: HashMap[uint256, uint256]

liquidity_gauges: HashMap[address, address[10]]

last_updated: public(uint256)


@external
def __init__(_address_provider: AddressProvider):
    """
    @notice Constructor function
    """
    self.address_provider = _address_provider

# internal functionality for getters

@view
@internal
def _get_balances(_pool: address) -> uint256[MAX_COINS]:
    balances: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    for i in range(MAX_COINS):
        if self.pool_data[_pool].coins[i] == ZERO_ADDRESS:
            assert i != 0
            break

        balances[i] = CurvePool(_pool).balances(i)

    return balances


# targetted external getters, optimized for on-chain calls

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


@view
@external
def get_n_coins(_pool: address) -> uint256:
    """
    @notice Get the number of coins in a pool
    @dev For non-metapools, both returned values are identical
         even when the pool does not use wrapping/lending
    @param _pool Pool address
    @return Number of wrapped coins, number of underlying coins
    """
    return self.pool_data[_pool].n_coins


@view
@external
def get_coins(_pool: address) -> address[MAX_COINS]:
    """
    @notice Get the coins within a pool
    @dev For pools using lending, these are the wrapped coin addresses
    @param _pool Pool address
    @return List of coin addresses
    """
    coins: address[MAX_COINS] = empty(address[MAX_COINS])
    n_coins: uint256 = self.pool_data[_pool].n_coins
    for i in range(MAX_COINS):
        if i == n_coins:
            break
        coins[i] = self.pool_data[_pool].coins[i]

    return coins


@view
@external
def get_decimals(_pool: address) -> uint256[MAX_COINS]:
    """
    @notice Get decimal places for each coin within a pool
    @dev For pools using lending, these are the wrapped coin decimal places
    @param _pool Pool address
    @return uint256 list of decimals
    """

    # decimals are tightly packed as a series of uint8 within a little-endian bytes32
    # the packed value is stored as uint256 to simplify unpacking via shift and modulo
    packed: uint256 = self.pool_data[_pool].decimals
    decimals: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
    n_coins: int128 = convert(self.pool_data[_pool].n_coins, int128)
    for i in range(MAX_COINS):
        if i == n_coins:
            break
        decimals[i] = shift(packed, -8 * i) % 256

    return decimals


@view
@external
def get_gauges(_pool: address) -> (address[10], int128[10]):
    """
    @notice Get a list of LiquidityGauge contracts associated with a pool
    @param _pool Pool address
    @return address[10] of gauge addresses, int128[10] of gauge types
    """
    liquidity_gauges: address[10] = empty(address[10])
    gauge_types: int128[10] = empty(int128[10])
    for i in range(10):
        gauge: address = self.liquidity_gauges[_pool][i]
        if gauge == ZERO_ADDRESS:
            break
        liquidity_gauges[i] = gauge

    return liquidity_gauges, gauge_types


@view
@external
def get_balances(_pool: address) -> uint256[MAX_COINS]:
    """
    @notice Get balances for each coin within a pool
    @dev For pools using lending, these are the wrapped coin balances
    @param _pool Pool address
    @return uint256 list of balances
    """
    return self._get_balances(_pool)


@view
@external
def get_virtual_price_from_lp_token(_token: address) -> uint256:
    """
    @notice Get the virtual price of a pool LP token
    @param _token LP token address
    @return uint256 Virtual price
    """
    return CurvePool(self.get_pool_from_lp_token[_token]).get_virtual_price()


@view
@external
def get_A(_pool: address) -> uint256:
    return CurvePool(_pool).A()


@view
@external
def get_D(_pool: address) -> uint256:
    return CurvePool(_pool).D()


@view
@external
def get_gamma(_pool: address) -> uint256:
    return CurvePool(_pool).gamma()


@view
@external
def get_fees(_pool: address) -> uint256[4]:
    """
    @notice Get the fees for a pool
    @dev Fees are expressed as integers
    @return Pool fee as uint256 with 1e10 precision
            Admin fee as 1e10 percentage of pool fee
            Mid fee
            Out fee
    """
    return [CurvePool(_pool).fee(), CurvePool(_pool).admin_fee(), CurvePool(_pool).mid_fee(), CurvePool(_pool).out_fee()]


@view
@external
def get_admin_balances(_pool: address) -> uint256[MAX_COINS]:
    """
    @notice Get the current admin balances (uncollected fees) for a pool
    @param _pool Pool address
    @return List of uint256 admin balances
    """
    balances: uint256[MAX_COINS] = self._get_balances(_pool)
    n_coins: uint256 = self.pool_data[_pool].n_coins
    for i in range(MAX_COINS):
        coin: address = self.pool_data[_pool].coins[i]
        if i == n_coins:
            break
        if coin == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
            balances[i] = _pool.balance - balances[i]
        else:
            balances[i] = ERC20(coin).balanceOf(_pool) - balances[i]

    return balances


@view
@external
def get_coin_indices(
    _pool: address,
    _from: address,
    _to: address
) -> (uint256, uint256):
    """
    @notice Convert coin addresses to indices for use with pool methods
    @param _from Coin address to be used as `i` within a pool
    @param _to Coin address to be used as `j` within a pool
    @return int128 `i`, int128 `j`, boolean indicating if `i` and `j` are underlying coins
    """
    # the return value is stored as `uint256[3]` to reduce gas costs
    # from index, to index, is the market underlying?
    result: uint256[2] = empty(uint256[2])

    found_market: bool = False

    # check coin markets
    for x in range(MAX_COINS):
        coin: address = self.pool_data[_pool].coins[x]
        if coin == ZERO_ADDRESS:
            # if we reach the end of the coins, reset `found_market` and try again
            # with the underlying coins
            found_market = False
            break
        if coin == _from:
            result[0] = x
        elif coin == _to:
            result[1] = x
        else:
            continue
        if found_market:
            # the second time we find a match, break out of the loop
            return result[0], result[1]
        # the first time we find a match, set `found_market` to True
        found_market = True

    raise "No available market"


@view
@external
def get_pool_name(_pool: address) -> String[64]:
    """
    @notice Get the given name for a pool
    @param _pool Pool address
    @return The name of a pool
    """
    return self.pool_data[_pool].name


@view
@external
def get_coin_swap_count(_coin: address) -> uint256:
    """
    @notice Get the number of unique coins available to swap `_coin` against
    @param _coin Coin address
    @return The number of unique coins available to swap for
    """
    return self.coins[_coin].swap_count


@view
@external
def get_coin_swap_complement(_coin: address, _index: uint256) -> address:
    """
    @notice Get the coin available to swap against `_coin` at `_index`
    @param _coin Coin address
    @param _index An index in the `_coin`'s set of available counter
        coin's
    @return Address of a coin available to swap against `_coin`
    """
    return self.coins[_coin].swap_for[_index]


# internal functionality used in admin setters


@internal
def _register_coin(_coin: address):
    if self.coins[_coin].register_count == 0:
        coin_count: uint256 = self.coin_count
        self.coins[_coin].index = coin_count
        self.get_coin[coin_count] = _coin
        self.coin_count += 1
    self.coins[_coin].register_count += 1


@internal
def _register_coin_pair(_coina: address, _coinb: address, _key: uint256):
    # register _coinb in _coina's array of coins
    coin_b_pos: uint256 = self.coins[_coina].swap_count
    self.coins[_coina].swap_for[coin_b_pos] = _coinb
    self.coins[_coina].swap_count += 1
    # register _coina in _coinb's array of coins
    coin_a_pos: uint256 = self.coins[_coinb].swap_count
    self.coins[_coinb].swap_for[coin_a_pos] = _coina
    self.coins[_coinb].swap_count += 1
    # register indexes (coina pos in coinb array, coinb pos in coina array)
    if convert(_coina, uint256) < convert(_coinb, uint256):
        self.coin_swap_indexes[_key] = shift(coin_a_pos, 128) + coin_b_pos
    else:
        self.coin_swap_indexes[_key] = shift(coin_b_pos, 128) + coin_a_pos


@internal
def _unregister_coin(_coin: address):
    self.coins[_coin].register_count -= 1

    if self.coins[_coin].register_count == 0:
        self.coin_count -= 1
        coin_count: uint256 = self.coin_count
        location: uint256 = self.coins[_coin].index

        if location < coin_count:
            coin_b: address = self.get_coin[coin_count]
            self.get_coin[location] = coin_b
            self.coins[coin_b].index = location

        self.coins[_coin].index = 0
        self.get_coin[coin_count] = ZERO_ADDRESS


@internal
def _unregister_coin_pair(_coina: address, _coinb: address, _coinb_idx: uint256):
    """
    @param _coinb_idx the index of _coinb in _coina's array of unique coin's
    """
    # decrement swap counts for both coins
    self.coins[_coina].swap_count -= 1

    # retrieve the last currently occupied index in coina's array
    coina_arr_last_idx: uint256 = self.coins[_coina].swap_count

    # if coinb's index in coina's array is less than the last
    # overwrite it's position with the last coin
    if _coinb_idx < coina_arr_last_idx:
        # here's our last coin in coina's array
        coin_c: address = self.coins[_coina].swap_for[coina_arr_last_idx]
        # get the bitwise_xor of the pair to retrieve their indexes
        key: uint256 = bitwise_xor(convert(_coina, uint256), convert(coin_c, uint256))
        indexes: uint256 = self.coin_swap_indexes[key]

        # update the pairing's indexes
        if convert(_coina, uint256) < convert(coin_c, uint256):
            # least complicated most readable way of shifting twice to remove the lower order bits
            self.coin_swap_indexes[key] = shift(shift(indexes, -128), 128) + _coinb_idx
        else:
            self.coin_swap_indexes[key] = shift(_coinb_idx, 128) + indexes % 2 ** 128
        # set _coinb_idx in coina's array to coin_c
        self.coins[_coina].swap_for[_coinb_idx] = coin_c

    self.coins[_coina].swap_for[coina_arr_last_idx] = ZERO_ADDRESS


@internal
def _get_new_pool_coins(
    _pool: address,
    _n_coins: uint256,
) -> address[MAX_COINS]:
    coin_list: address[MAX_COINS] = empty(address[MAX_COINS])
    coin: address = ZERO_ADDRESS
    for i in range(MAX_COINS):
        if i == _n_coins:
            break
        coin = CurvePool(_pool).coins(i)
        self.pool_data[_pool].coins[i] = coin
        coin_list[i] = coin

    for i in range(MAX_COINS):
        if i == _n_coins:
            break

        self._register_coin(coin_list[i])
        # add pool to markets
        i2: uint256 = i + 1
        for x in range(i2, i2 + MAX_COINS):
            if x == _n_coins:
                break

            key: uint256 = bitwise_xor(convert(coin_list[i], uint256), convert(coin_list[x], uint256))
            length: uint256 = self.market_counts[key]
            self.markets[key][length] = _pool
            self.market_counts[key] = length + 1

            # register the coin pair
            if length == 0:
                self._register_coin_pair(coin_list[x], coin_list[i], key)

    return coin_list


@view
@internal
def _get_new_pool_decimals(_coins: address[MAX_COINS], _n_coins: uint256) -> uint256:
    packed: uint256 = 0
    value: uint256 = 0

    n_coins: int128 = convert(_n_coins, int128)
    for i in range(MAX_COINS):
        if i == n_coins:
            break
        coin: address = _coins[i]
        if coin == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
            value = 18
        else:
            value = ERC20(coin).decimals()
            assert value < 256  # dev: decimal overflow

        packed += shift(value, i * 8)

    return packed


@internal
def _remove_market(_pool: address, _coina: address, _coinb: address):
    key: uint256 = bitwise_xor(convert(_coina, uint256), convert(_coinb, uint256))
    length: uint256 = self.market_counts[key] - 1
    if length == 0:
        indexes: uint256 = self.coin_swap_indexes[key]
        if convert(_coina, uint256) < convert(_coinb, uint256):
            self._unregister_coin_pair(_coina, _coinb, indexes % 2 ** 128)
            self._unregister_coin_pair(_coinb, _coina, shift(indexes, -128))
        else:
            self._unregister_coin_pair(_coina, _coinb, shift(indexes, -128))
            self._unregister_coin_pair(_coinb, _coina, indexes % 2 ** 128)
        self.coin_swap_indexes[key] = 0
    for i in range(65536):
        if i > length:
            break
        if self.markets[key][i] == _pool:
            if i < length:
                self.markets[key][i] = self.markets[key][length]
            self.markets[key][length] = ZERO_ADDRESS
            self.market_counts[key] = length
            break


# admin functions

@external
def add_pool(
    _pool: address,
    _n_coins: uint256,
    _lp_token: address,
    _decimals: uint256,
    _name: String[64],
):
    """
    @notice Add a pool to the registry
    @dev Only callable by admin
    @param _pool Pool address to add
    @param _n_coins Number of coins in the pool
    @param _lp_token Pool deposit token address
    @param _decimals Coin decimal values, tightly packed as uint8 in a little-endian bytes32
    @param _name The name of the pool
    """
    assert msg.sender == self.address_provider.admin()  # dev: admin-only function
    assert _lp_token != ZERO_ADDRESS
    assert self.pool_data[_pool].coins[0] == ZERO_ADDRESS  # dev: pool exists
    assert self.get_pool_from_lp_token[_lp_token] == ZERO_ADDRESS

    # add pool to pool_list
    length: uint256 = self.pool_count
    self.pool_list[length] = _pool
    self.pool_count = length + 1
    self.pool_data[_pool].location = length
    self.pool_data[_pool].n_coins = _n_coins
    self.pool_data[_pool].name = _name

    # update public mappings
    self.get_pool_from_lp_token[_lp_token] = _pool
    self.get_lp_token[_pool] = _lp_token

    coins: address[MAX_COINS] = self._get_new_pool_coins(_pool, _n_coins)
    decimals: uint256 = _decimals
    if decimals == 0:
        decimals = self._get_new_pool_decimals(coins, _n_coins)
    self.pool_data[_pool].decimals = decimals

    self.last_updated = block.timestamp
    log PoolAdded(_pool)


@external
def remove_pool(_pool: address):
    """
    @notice Remove a pool to the registry
    @dev Only callable by admin
    @param _pool Pool address to remove
    """
    assert msg.sender == self.address_provider.admin()  # dev: admin-only function
    assert self.pool_data[_pool].coins[0] != ZERO_ADDRESS  # dev: pool does not exist


    self.get_pool_from_lp_token[self.get_lp_token[_pool]] = ZERO_ADDRESS
    self.get_lp_token[_pool] = ZERO_ADDRESS

    # remove _pool from pool_list
    location: uint256 = self.pool_data[_pool].location
    length: uint256 = self.pool_count - 1

    if location < length:
        # replace _pool with final value in pool_list
        addr: address = self.pool_list[length]
        self.pool_list[location] = addr
        self.pool_data[addr].location = location

    # delete final pool_list value
    self.pool_list[length] = ZERO_ADDRESS
    self.pool_count = length

    self.pool_data[_pool].decimals = 0
    self.pool_data[_pool].n_coins = 0
    self.pool_data[_pool].name = ""

    coins: address[MAX_COINS] = empty(address[MAX_COINS])

    for i in range(MAX_COINS):
        coins[i] = self.pool_data[_pool].coins[i]
        if coins[i] == ZERO_ADDRESS:
            break
        # delete coin address from pool_data
        self.pool_data[_pool].coins[i] = ZERO_ADDRESS
        self._unregister_coin(coins[i])

    for i in range(MAX_COINS):
        coin: address = coins[i]
        if coin == ZERO_ADDRESS:
            break

        # remove pool from markets
        i2: uint256 = i + 1
        for x in range(i2, i2 + MAX_COINS):
            coinx: address = coins[x]
            if coinx == ZERO_ADDRESS:
                break
            self._remove_market(_pool, coin, coinx)

    self.last_updated = block.timestamp
    log PoolRemoved(_pool)


@external
def set_liquidity_gauges(_pool: address, _liquidity_gauges: address[10]):
    """
    @notice Set liquidity gauge contracts``
    @param _pool Pool address
    @param _liquidity_gauges Liquidity gauge address
    """
    assert msg.sender == self.address_provider.admin()  # dev: admin-only function

    _lp_token: address = self.get_lp_token[_pool]
    for i in range(10):
        _gauge: address = _liquidity_gauges[i]
        if _gauge != ZERO_ADDRESS:
            assert LiquidityGauge(_gauge).lp_token() == _lp_token  # dev: wrong token
            self.liquidity_gauges[_pool][i] = _gauge
        elif self.liquidity_gauges[_pool][i] != ZERO_ADDRESS:
            self.liquidity_gauges[_pool][i] = ZERO_ADDRESS
        else:
            break
    self.last_updated = block.timestamp