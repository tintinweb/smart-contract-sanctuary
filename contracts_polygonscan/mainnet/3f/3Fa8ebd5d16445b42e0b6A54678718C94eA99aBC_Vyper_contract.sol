# @version 0.2.15

from vyper.interfaces import ERC20

interface CurveCryptoSwap:
    def token() -> address: view
    def coins(i: uint256) -> address: view
    def get_dy(i: uint256, j: uint256, dx: uint256) -> uint256: view
    def calc_token_amount(amounts: uint256[N_COINS], is_deposit: bool) -> uint256: view
    def calc_withdraw_one_coin(token_amount: uint256, i: uint256) -> uint256: view
    def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256): nonpayable
    def exchange(i: uint256, j: uint256, dx: uint256, min_dy: uint256): nonpayable
    def remove_liquidity(amount: uint256, min_amounts: uint256[N_COINS]): nonpayable
    def remove_liquidity_one_coin(token_amount: uint256, i: uint256, min_amount: uint256): nonpayable

interface StableSwap:
    def underlying_coins(i: uint256) -> address: view
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view
    def calc_token_amount(amounts: uint256[N_COINS], is_deposit: bool) -> uint256: view
    def calc_withdraw_one_coin(token_amount: uint256, i: int128) -> uint256: view
    def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256, use_underlying: bool) -> uint256: nonpayable
    def remove_liquidity_one_coin(token_amount: uint256, i: int128, min_amount: uint256, use_underlying: bool) -> uint256: nonpayable
    def remove_liquidity(amount: uint256, min_amounts: uint256[N_COINS], use_underlying: bool) -> uint256[N_COINS]: nonpayable


interface LendingPool:
    def withdraw(underlying_asset: address, amount: uint256, receiver: address): nonpayable

interface aToken:
    def UNDERLYING_ASSET_ADDRESS() -> address: view


N_COINS: constant(int128) = 3
N_STABLECOINS: constant(int128) = 3
N_UL_COINS: constant(int128) = N_COINS + N_STABLECOINS - 1
AAVE_LENDING_POOL: constant(address) = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf

aave_referral: uint256
coins: public(address[N_COINS])
underlying_coins: public(address[N_UL_COINS])

pool: public(address)
base_pool: public(address)
token: public(address)


@external
def __init__(_pool: address, _base_pool: address):
    self.pool = _pool
    self.base_pool = _base_pool
    self.token = CurveCryptoSwap(_pool).token()

    for i in range(N_STABLECOINS):
        coin: address = StableSwap(_base_pool).underlying_coins(i)
        self.underlying_coins[i] = coin
        # approve transfer of underlying coin to base pool
        response: Bytes[32] = raw_call(
            coin,
            concat(
                method_id("approve(address,uint256)"),
                convert(_base_pool, bytes32),
                convert(MAX_UINT256, bytes32)
            ),
            max_outsize=32
        )
        if len(response) != 0:
            assert convert(response, bool)

    for i in range(N_COINS):
        coin: address = CurveCryptoSwap(_pool).coins(i)
        self.coins[i] = coin
        # approve transfer of coin to main pool
        response: Bytes[32] = raw_call(
            coin,
            concat(
                method_id("approve(address,uint256)"),
                convert(_pool, bytes32),
                convert(MAX_UINT256, bytes32)
            ),
            max_outsize=32
        )
        if len(response) != 0:
            assert convert(response, bool)

        if i != 0:
            # coins >= 1 are aTokens, we must get the underlying asset address
            # and approve transfer into the aave lending pool
            coin = aToken(coin).UNDERLYING_ASSET_ADDRESS()
            self.underlying_coins[i+(N_STABLECOINS-1)] = coin
            response = raw_call(
                coin,
                concat(
                    method_id("approve(address,uint256)"),
                    convert(AAVE_LENDING_POOL, bytes32),
                    convert(MAX_UINT256, bytes32)
                ),
                max_outsize=32
            )
            if len(response) != 0:
                assert convert(response, bool)


@external
def add_liquidity(_amounts: uint256[N_UL_COINS], _min_mint_amount: uint256, _receiver: address = msg.sender):
    base_deposit_amounts: uint256[N_STABLECOINS] = empty(uint256[N_STABLECOINS])
    deposit_amounts: uint256[N_COINS] = empty(uint256[N_COINS])
    is_base_deposit: bool = False

    # transfer base pool coins from caller and deposit to get LP tokens
    for i in range(N_STABLECOINS):
        amount: uint256 = _amounts[i]
        if amount != 0:
            coin: address = self.underlying_coins[i]
            # transfer underlying coin from msg.sender to self
            _response: Bytes[32] = raw_call(
                coin,
                concat(
                    method_id("transferFrom(address,address,uint256)"),
                    convert(msg.sender, bytes32),
                    convert(self, bytes32),
                    convert(amount, bytes32)
                ),
                max_outsize=32
            )
            if len(_response) != 0:
                assert convert(_response, bool)
            base_deposit_amounts[i] = ERC20(coin).balanceOf(self)
            is_base_deposit = True

    if is_base_deposit:
        deposit_amounts[0] = StableSwap(self.base_pool).add_liquidity(base_deposit_amounts, 0, True)

    # transfer remaining underlying coins and deposit into aave
    aave_referral: bytes32 = convert(self.aave_referral, bytes32)
    for i in range(N_STABLECOINS, N_UL_COINS):
        amount: uint256 = _amounts[i]
        if amount != 0:
            coin: address = self.underlying_coins[i]
            # transfer underlying coin from msg.sender to self
            _response: Bytes[32] = raw_call(
                coin,
                concat(
                    method_id("transferFrom(address,address,uint256)"),
                    convert(msg.sender, bytes32),
                    convert(self, bytes32),
                    convert(amount, bytes32)
                ),
                max_outsize=32
            )
            if len(_response) != 0:
                assert convert(_response, bool)

            # deposit to aave lending pool
            raw_call(
                AAVE_LENDING_POOL,
                concat(
                    method_id("deposit(address,uint256,address,uint16)"),
                    convert(coin, bytes32),
                    convert(amount, bytes32),
                    convert(self, bytes32),
                    aave_referral,
                )
            )
            deposit_amounts[i-(N_STABLECOINS-1)] = amount

    CurveCryptoSwap(self.pool).add_liquidity(deposit_amounts, _min_mint_amount)
    token: address = self.token
    amount: uint256 = ERC20(token).balanceOf(self)
    ERC20(token).transfer(_receiver, amount)


@external
def exchange_underlying(i: uint256, j: uint256, _dx: uint256, _min_dy: uint256, _receiver: address = msg.sender):
    # transfer `i` from caller into the zap
    response: Bytes[32] = raw_call(
        self.underlying_coins[i],
        concat(
            method_id("transferFrom(address,address,uint256)"),
            convert(msg.sender, bytes32),
            convert(self, bytes32),
            convert(_dx, bytes32)
        ),
        max_outsize=32
    )
    if len(response) != 0:
        assert convert(response, bool)

    dx: uint256 = _dx
    base_i: uint256 = 0
    base_j: uint256 = 0
    if j >= N_STABLECOINS:
        base_j = j - (N_STABLECOINS - 1)

    if i < N_STABLECOINS:
        # if `i` is in the base pool, deposit to get LP tokens
        base_deposit_amounts: uint256[N_STABLECOINS] = empty(uint256[N_STABLECOINS])
        base_deposit_amounts[i] = dx
        dx = StableSwap(self.base_pool).add_liquidity(base_deposit_amounts, 0, True)
    else:
        # if `i` is an aToken, deposit to the aave lending pool
        base_i = i - (N_STABLECOINS - 1)
        raw_call(
            AAVE_LENDING_POOL,
            concat(
                method_id("deposit(address,uint256,address,uint16)"),
                convert(self.underlying_coins[i], bytes32),
                convert(dx, bytes32),
                convert(self, bytes32),
                convert(self.aave_referral, bytes32),
            )
        )

    # perform the exchange
    if max(base_i, base_j) > 0:
        CurveCryptoSwap(self.pool).exchange(base_i, base_j, dx, 0)
    amount: uint256 = ERC20(self.coins[base_j]).balanceOf(self)

    if base_j == 0:
        # if `j` is in the base pool, withdraw the desired underlying asset and transfer to caller
        amount = StableSwap(self.base_pool).remove_liquidity_one_coin(amount, convert(j, int128), _min_dy, True)
        response = raw_call(
            self.underlying_coins[j],
            concat(
                method_id("transfer(address,uint256)"),
                convert(_receiver, bytes32),
                convert(amount, bytes32)
            ),
            max_outsize=32
        )
        if len(response) != 0:
            assert convert(response, bool)
    else:
        # withdraw `j` underlying from lending pool and transfer to caller
        assert amount >= _min_dy
        LendingPool(AAVE_LENDING_POOL).withdraw(self.underlying_coins[j], amount, _receiver)


@external
def remove_liquidity(_amount: uint256, _min_amounts: uint256[N_UL_COINS], _receiver: address = msg.sender):
    # transfer LP token from caller and remove liquidity
    ERC20(self.token).transferFrom(msg.sender, self, _amount)
    min_amounts: uint256[N_COINS] = [0, _min_amounts[3], _min_amounts[4]]
    CurveCryptoSwap(self.pool).remove_liquidity(_amount, min_amounts)

    # withdraw from base pool and transfer underlying assets to receiver
    value: uint256 = ERC20(self.coins[0]).balanceOf(self)
    base_min_amounts: uint256[N_STABLECOINS] = [_min_amounts[0], _min_amounts[1], _min_amounts[2]]
    received: uint256[N_STABLECOINS] = StableSwap(self.base_pool).remove_liquidity(value, base_min_amounts, True)
    for i in range(N_STABLECOINS):
        response: Bytes[32] = raw_call(
            self.underlying_coins[i],
            concat(
                method_id("transfer(address,uint256)"),
                convert(_receiver, bytes32),
                convert(received[i], bytes32)
            ),
            max_outsize=32
        )
        if len(response) != 0:
            assert convert(response, bool)

    # withdraw from aave lending pool and transfer to receiver
    for i in range(N_STABLECOINS, N_UL_COINS):
        value = ERC20(self.coins[i-(N_STABLECOINS-1)]).balanceOf(self)
        LendingPool(AAVE_LENDING_POOL).withdraw(self.underlying_coins[i], value, _receiver)


@external
def remove_liquidity_one_coin(_token_amount: uint256, i: uint256, _min_amount: uint256, _receiver: address = msg.sender):
    ERC20(self.token).transferFrom(msg.sender, self, _token_amount)
    base_i: uint256 = 0
    if i >= N_STABLECOINS:
        base_i = i - (N_STABLECOINS-1)
    CurveCryptoSwap(self.pool).remove_liquidity_one_coin(_token_amount, base_i, 0)

    value: uint256 = ERC20(self.coins[base_i]).balanceOf(self)
    if base_i == 0:
        value = StableSwap(self.base_pool).remove_liquidity_one_coin(value, convert(i, int128), _min_amount, True)
        response: Bytes[32] = raw_call(
            self.underlying_coins[i],
            concat(
                method_id("transfer(address,uint256)"),
                convert(_receiver, bytes32),
                convert(value, bytes32)
            ),
            max_outsize=32
        )
        if len(response) != 0:
            assert convert(response, bool)
    else:
        assert value >= _min_amount
        LendingPool(AAVE_LENDING_POOL).withdraw(self.underlying_coins[i], value, _receiver)


@view
@external
def get_dy_underlying(i: uint256, j: uint256, _dx: uint256) -> uint256:
    if max(i, j) < N_STABLECOINS:
        return StableSwap(self.base_pool).get_dy(convert(i, int128), convert(j, int128), _dx)

    dx: uint256 = _dx
    base_i: uint256 = 0
    base_j: uint256 = 0
    if j >= N_STABLECOINS:
        base_j = j - (N_STABLECOINS - 1)

    if i < N_STABLECOINS:
        amounts: uint256[N_STABLECOINS] = empty(uint256[N_STABLECOINS])
        amounts[i] = dx
        dx = StableSwap(self.base_pool).calc_token_amount(amounts, True)
    else:
        base_i = i - (N_STABLECOINS - 1)

    dy: uint256 = CurveCryptoSwap(self.pool).get_dy(base_i, base_j, dx)
    if base_j == 0:
        return StableSwap(self.base_pool).calc_withdraw_one_coin(dy, convert(j, int128))
    else:
        return dy


@view
@external
def calc_token_amount(_amounts: uint256[N_UL_COINS], _is_deposit: bool) -> uint256:
    base_amounts: uint256[N_COINS] = [_amounts[0], _amounts[1], _amounts[2]]
    base_lp: uint256 = StableSwap(self.base_pool).calc_token_amount(base_amounts, _is_deposit)
    amounts: uint256[N_COINS] = [base_lp, _amounts[3], _amounts[4]]
    return CurveCryptoSwap(self.pool).calc_token_amount(amounts, _is_deposit)


@view
@external
def calc_withdraw_one_coin(token_amount: uint256, i: uint256) -> uint256:
    if i >= N_STABLECOINS:
        return CurveCryptoSwap(self.pool).calc_withdraw_one_coin(token_amount, i - (N_STABLECOINS - 1))

    base_amount: uint256 = CurveCryptoSwap(self.pool).calc_withdraw_one_coin(token_amount, 0)
    return StableSwap(self.base_pool).calc_withdraw_one_coin(base_amount, convert(i, int128))