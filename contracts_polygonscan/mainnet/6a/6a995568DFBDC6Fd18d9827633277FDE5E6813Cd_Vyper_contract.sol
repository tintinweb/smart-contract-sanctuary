# @version 0.2.16
"""
@title "Zap" Depositer for permissionless factory metapools
@author Curve.Fi
@license Copyright (c) Curve.Fi, 2021 - all rights reserved
"""

interface ERC20:
    def approve(_spender: address, _amount: uint256): nonpayable
    def balanceOf(_owner: address) -> uint256: view

interface CurveMeta:
    def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256, _receiver: address) -> uint256: nonpayable
    def remove_liquidity(_amount: uint256, min_amounts: uint256[N_COINS]): nonpayable
    def remove_liquidity_one_coin(_token_amount: uint256, i: int128, min_amount: uint256, _receiver: address) -> uint256: nonpayable
    def remove_liquidity_imbalance(amounts: uint256[N_COINS], max_burn_amount: uint256) -> uint256: nonpayable
    def exchange_underlying(i: int128, j: int128, dx: uint256, min_dy: uint256, receiver: address) -> uint256: nonpayable
    def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256: view
    def calc_token_amount(amounts: uint256[N_COINS], deposit: bool) -> uint256: view
    def coins(i: uint256) -> address: view

interface CurveBase:
    def add_liquidity(amounts: uint256[BASE_N_COINS], min_mint_amount: uint256, use_underlying: bool): nonpayable
    def remove_liquidity(_amount: uint256, min_amounts: uint256[BASE_N_COINS], use_underlying: bool): nonpayable
    def remove_liquidity_one_coin(_token_amount: uint256, i: int128, min_amount: uint256, use_underlying: bool): nonpayable
    def remove_liquidity_imbalance(amounts: uint256[BASE_N_COINS], max_burn_amount: uint256, use_underlying: bool): nonpayable
    def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256: view
    def calc_token_amount(amounts: uint256[BASE_N_COINS], deposit: bool) -> uint256: view
    def coins(i: uint256) -> address: view
    def fee() -> uint256: view

interface LendingPool:
    def withdraw(_underlying_asset: address, _amount: uint256, _receiver: address): nonpayable


BASE_N_COINS: constant(int128) = 2
BASE_POOL: constant(address) = 0xC2d95EEF97Ec6C17551d45e77B590dc1F9117C67
BASE_LP_TOKEN: constant(address) = 0xf8a57c1d3b9629b77b6726a042ca48990A84Fb49
BASE_COINS: constant(address[BASE_N_COINS]) = [0x5c2ed810328349100A66B82b78a1791B101C9D61, 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501]
UNDERLYING_COINS: constant(address[BASE_N_COINS]) = [0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6, 0xDBf31dF14B66535aF65AaC99C32e9eA844e14501]

LENDING_POOL: constant(address) = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf

N_COINS: constant(int128) = 2
MAX_COIN: constant(int128) = N_COINS-1
N_ALL_COINS: constant(int128) = N_COINS + BASE_N_COINS - 1

FEE_DENOMINATOR: constant(uint256) = 10 ** 10
FEE_IMPRECISION: constant(uint256) = 100 * 10 ** 8  # % of the fee


# coin -> pool -> is approved to transfer?
is_approved: HashMap[address, HashMap[address, bool]]


@external
def __init__():
    """
    @notice Contract constructor
    """
    for coin in BASE_COINS:
        ERC20(coin).approve(BASE_POOL, MAX_UINT256)
    for coin in UNDERLYING_COINS:
        ERC20(coin).approve(BASE_POOL, MAX_UINT256)


@external
def add_liquidity(
    _pool: address,
    _deposit_amounts: uint256[N_ALL_COINS],
    _min_mint_amount: uint256,
    _receiver: address = msg.sender,
    _use_underlying: bool = True
) -> uint256:
    """
    @notice Wrap underlying coins and deposit them into `_pool`
    @param _pool Address of the pool to deposit into
    @param _deposit_amounts List of amounts of underlying coins to deposit
    @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
    @param _receiver Address that receives the LP tokens
    @param _use_underlying Flag determining the usage of underlying coins for deposit
    @return Amount of LP tokens received by depositing
    """
    meta_amounts: uint256[N_COINS] = empty(uint256[N_COINS])
    base_amounts: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
    deposit_base: bool = False
    base_coins: address[BASE_N_COINS] = empty(address[BASE_N_COINS])
    if _use_underlying:
        base_coins = UNDERLYING_COINS
    else:
        base_coins = BASE_COINS

    if _deposit_amounts[0] != 0:
        coin: address = CurveMeta(_pool).coins(0)
        if not self.is_approved[coin][_pool]:
            ERC20(coin).approve(_pool, MAX_UINT256)
            self.is_approved[coin][_pool] = True
        response: Bytes[32] = raw_call(
            coin,
            _abi_encode(
                msg.sender,
                self,
                _deposit_amounts[0],
                method_id=method_id("transferFrom(address,address,uint256)"),
            ),
            max_outsize=32
        )
        if len(response) != 0:
            assert convert(response, bool)
        # handle fee on transfer
        meta_amounts[0] = ERC20(coin).balanceOf(self)

    for i in range(1, N_ALL_COINS):
        amount: uint256 = _deposit_amounts[i]
        if amount == 0:
            continue
        deposit_base = True
        base_idx: uint256 = i - 1
        coin: address = base_coins[base_idx]

        response: Bytes[32] = raw_call(
            coin,
            _abi_encode(
                msg.sender,
                self,
                amount,
                method_id=method_id("transferFrom(address,address,uint256)"),
            ),
            max_outsize=32
        )
        if len(response) != 0:
            assert convert(response, bool)

        # Handle potential transfer fees (i.e. Tether/renBTC)
        base_amounts[base_idx] = ERC20(coin).balanceOf(self)

    # Deposit to the base pool
    if deposit_base:
        coin: address = BASE_LP_TOKEN
        CurveBase(BASE_POOL).add_liquidity(base_amounts, 0, _use_underlying)
        meta_amounts[MAX_COIN] = ERC20(coin).balanceOf(self)
        if not self.is_approved[coin][_pool]:
            ERC20(coin).approve(_pool, MAX_UINT256)
            self.is_approved[coin][_pool] = True

    # Deposit to the meta pool
    return CurveMeta(_pool).add_liquidity(meta_amounts, _min_mint_amount, _receiver)


@external
def remove_liquidity(
    _pool: address,
    _burn_amount: uint256,
    _min_amounts: uint256[N_ALL_COINS],
    _receiver: address = msg.sender,
    _use_underlying: bool = True
) -> uint256[N_ALL_COINS]:
    """
    @notice Withdraw and unwrap coins from the pool
    @dev Withdrawal amounts are based on current deposit ratios
    @param _pool Address of the pool to deposit into
    @param _burn_amount Quantity of LP tokens to burn in the withdrawal
    @param _min_amounts Minimum amounts of underlying coins to receive
    @param _receiver Address that receives the LP tokens
    @return List of amounts of underlying coins that were withdrawn
    """
    response: Bytes[32] = raw_call(
        _pool,
        _abi_encode(
            msg.sender,
            self,
            _burn_amount,
            method_id=method_id("transferFrom(address,address,uint256)"),
        ),
        max_outsize=32
    )
    if len(response) != 0:
        assert convert(response, bool)

    min_amounts_base: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
    amounts: uint256[N_ALL_COINS] = empty(uint256[N_ALL_COINS])

    # Withdraw from meta
    meta_received: uint256[N_COINS] = empty(uint256[N_COINS])
    CurveMeta(_pool).remove_liquidity(_burn_amount, [_min_amounts[0], convert(0, uint256)])

    coins: address[N_COINS] = empty(address[N_COINS])
    for i in range(N_COINS):
        coin: address = CurveMeta(_pool).coins(i)
        coins[i] = coin
        # Handle fee on transfer for the first coin
        meta_received[i] = ERC20(coin).balanceOf(self)

    # Withdraw from base
    for i in range(BASE_N_COINS):
        min_amounts_base[i] = _min_amounts[MAX_COIN+i]
    CurveBase(BASE_POOL).remove_liquidity(meta_received[MAX_COIN], min_amounts_base, _use_underlying)

    # Transfer all coins out
    response = raw_call(
        coins[0],  # metapool coin 0
        _abi_encode(
            _receiver,
            meta_received[0],
            method_id=method_id("transfer(address,uint256)"),
        ),
        max_outsize=32
    )
    if len(response) != 0:
        assert convert(response, bool)

    amounts[0] = meta_received[0]

    base_coins: address[BASE_N_COINS] = empty(address[BASE_N_COINS])
    if _use_underlying:
        base_coins = UNDERLYING_COINS
    else:
        base_coins = BASE_COINS
    for i in range(1, N_ALL_COINS):
        coin: address = base_coins[i-1]
        # handle potential fee on transfer
        amounts[i] = ERC20(coin).balanceOf(self)
        response = raw_call(
            coin,
            _abi_encode(
                _receiver,
                amounts[i],
                method_id=method_id("transfer(address,uint256)"),
            ),
            max_outsize=32
        )
        if len(response) != 0:
            assert convert(response, bool)


    return amounts


@external
def remove_liquidity_one_coin(
    _pool: address,
    _burn_amount: uint256,
    i: int128,
    _min_amount: uint256,
    _receiver: address = msg.sender,
    _use_underlying: bool = True,
) -> uint256:
    """
    @notice Withdraw and unwrap a single coin from the pool
    @param _pool Address of the pool to deposit into
    @param _burn_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the coin to withdraw
    @param _min_amount Minimum amount of underlying coin to receive
    @param _receiver Address that receives the LP tokens
    @return Amount of underlying coin received
    """
    response: Bytes[32] = raw_call(
        _pool,
        _abi_encode(
            msg.sender,
            self,
            _burn_amount,
            method_id=method_id("transferFrom(address,address,uint256)"),
        ),
        max_outsize=32
    )
    if len(response) != 0:
        assert convert(response, bool)


    coin_amount: uint256 = 0
    if i == 0:
        coin_amount = CurveMeta(_pool).remove_liquidity_one_coin(_burn_amount, i, _min_amount, _receiver)
    else:
        base_coins: address[BASE_N_COINS] = empty(address[BASE_N_COINS])
        if _use_underlying:
            base_coins = UNDERLYING_COINS
        else:
            base_coins = BASE_COINS
        coin: address = base_coins[i - MAX_COIN]
        # Withdraw a base pool coin
        coin_amount = CurveMeta(_pool).remove_liquidity_one_coin(_burn_amount, MAX_COIN, 0, self)
        CurveBase(BASE_POOL).remove_liquidity_one_coin(coin_amount, i-MAX_COIN, _min_amount, _use_underlying)
        coin_amount = ERC20(coin).balanceOf(self)
        response = raw_call(
            coin,
            _abi_encode(
                _receiver,
                coin_amount,
                method_id=method_id("transfer(address,uint256)"),
            ),
            max_outsize=32
        )
        if len(response) != 0:
            assert convert(response, bool)


    return coin_amount


@external
def remove_liquidity_imbalance(
    _pool: address,
    _amounts: uint256[N_ALL_COINS],
    _max_burn_amount: uint256,
    _receiver: address = msg.sender,
    _use_underlying: bool = True
) -> uint256:
    """
    @notice Withdraw coins from the pool in an imbalanced amount
    @param _pool Address of the pool to deposit into
    @param _amounts List of amounts of underlying coins to withdraw
    @param _max_burn_amount Maximum amount of LP token to burn in the withdrawal
    @param _receiver Address that receives the LP tokens
    @return Actual amount of the LP token burned in the withdrawal
    """
    fee: uint256 = CurveBase(BASE_POOL).fee() * BASE_N_COINS / (4 * (BASE_N_COINS - 1))
    fee += fee * FEE_IMPRECISION / FEE_DENOMINATOR  # Overcharge to account for imprecision

    # Transfer the LP token in
    response: Bytes[32] = raw_call(
        _pool,
        _abi_encode(
            msg.sender,
            self,
            _max_burn_amount,
            method_id=method_id("transferFrom(address,address,uint256)"),
        ),
        max_outsize=32
    )
    if len(response) != 0:
        assert convert(response, bool)

    withdraw_base: bool = False
    amounts_base: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
    amounts_meta: uint256[N_COINS] = empty(uint256[N_COINS])

    # determine amounts to withdraw from base pool
    for i in range(BASE_N_COINS):
        amount: uint256 = _amounts[MAX_COIN + i]
        if amount != 0:
            amounts_base[i] = amount
            withdraw_base = True

    # determine amounts to withdraw from metapool
    amounts_meta[0] = _amounts[0]
    if withdraw_base:
        amounts_meta[MAX_COIN] = CurveBase(BASE_POOL).calc_token_amount(amounts_base, False)
        amounts_meta[MAX_COIN] += amounts_meta[MAX_COIN] * fee / FEE_DENOMINATOR + 1

    # withdraw from metapool and return the remaining LP tokens
    burn_amount: uint256 = CurveMeta(_pool).remove_liquidity_imbalance(amounts_meta, _max_burn_amount)
    response = raw_call(
        _pool,
        _abi_encode(
            msg.sender,
            _max_burn_amount - burn_amount,
            method_id=method_id("transfer(address,uint256)"),
        ),
        max_outsize=32
    )
    if len(response) != 0:
        assert convert(response, bool)


    # withdraw from base pool
    if withdraw_base:
        CurveBase(BASE_POOL).remove_liquidity_imbalance(amounts_base, amounts_meta[MAX_COIN], _use_underlying)
        coin: address = BASE_LP_TOKEN
        leftover: uint256 = ERC20(coin).balanceOf(self)

        if leftover > 0:
            # if some base pool LP tokens remain, re-deposit them for the caller
            if not self.is_approved[coin][_pool]:
                ERC20(coin).approve(_pool, MAX_UINT256)
                self.is_approved[coin][_pool] = True
            burn_amount -= CurveMeta(_pool).add_liquidity([convert(0, uint256), leftover], 0, msg.sender)

        # transfer withdrawn base pool tokens to caller
        base_coins: address[BASE_N_COINS] = empty(address[BASE_N_COINS])
        if _use_underlying:
            base_coins = UNDERLYING_COINS
        else:
            base_coins = BASE_COINS

        for i in range(BASE_N_COINS):
            response = raw_call(
                base_coins[i],
                _abi_encode(
                    _receiver,
                    ERC20(base_coins[i]).balanceOf(self),  # handle potential transfer fees
                    method_id=method_id("transfer(address,uint256)"),
                ),
                max_outsize=32
            )
            if len(response) != 0:
                assert convert(response, bool)


    # transfer withdrawn metapool tokens to caller
    if _amounts[0] > 0:
        coin: address = CurveMeta(_pool).coins(0)
        response = raw_call(
            coin,
            _abi_encode(
                _receiver,
                ERC20(coin).balanceOf(self),  # handle potential fees
                method_id=method_id("transfer(address,uint256)"),
            ),
            max_outsize=32
        )
        if len(response) != 0:
            assert convert(response, bool)


    return burn_amount


@view
@external
def calc_withdraw_one_coin(_pool: address, _token_amount: uint256, i: int128) -> uint256:
    """
    @notice Calculate the amount received when withdrawing and unwrapping a single coin
    @param _pool Address of the pool to deposit into
    @param _token_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the underlying coin to withdraw
    @return Amount of coin received
    """
    if i < MAX_COIN:
        return CurveMeta(_pool).calc_withdraw_one_coin(_token_amount, i)
    else:
        _base_tokens: uint256 = CurveMeta(_pool).calc_withdraw_one_coin(_token_amount, MAX_COIN)
        return CurveBase(BASE_POOL).calc_withdraw_one_coin(_base_tokens, i-MAX_COIN)


@view
@external
def calc_token_amount(_pool: address, _amounts: uint256[N_ALL_COINS], _is_deposit: bool) -> uint256:
    """
    @notice Calculate addition or reduction in token supply from a deposit or withdrawal
    @dev This calculation accounts for slippage, but not fees.
         Needed to prevent front-running, not for precise calculations!
    @param _pool Address of the pool to deposit into
    @param _amounts Amount of each underlying coin being deposited
    @param _is_deposit set True for deposits, False for withdrawals
    @return Expected amount of LP tokens received
    """
    meta_amounts: uint256[N_COINS] = empty(uint256[N_COINS])
    base_amounts: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])

    meta_amounts[0] = _amounts[0]
    for i in range(BASE_N_COINS):
        base_amounts[i] = _amounts[i + MAX_COIN]

    base_tokens: uint256 = CurveBase(BASE_POOL).calc_token_amount(base_amounts, _is_deposit)
    meta_amounts[MAX_COIN] = base_tokens

    return CurveMeta(_pool).calc_token_amount(meta_amounts, _is_deposit)


@external
def exchange_underlying(
    _pool: address,
    _i: int128,
    _j: int128,
    _dx: uint256,
    _min_dy: uint256,
    _receiver: address = msg.sender,
    _use_underlying: bool = True
) -> uint256:

    base_coins: address[BASE_N_COINS] = BASE_COINS
    underlying_coins: address[BASE_N_COINS] = UNDERLYING_COINS

    input_coin: address = ZERO_ADDRESS
    should_wrap: bool = False

    if _i == 0:
        input_coin = CurveMeta(_pool).coins(0)
        # approve the input coin for exchange
        if not self.is_approved[input_coin][_pool]:
            ERC20(input_coin).approve(_pool, MAX_UINT256)
            self.is_approved[input_coin][_pool] = True
    else:
        base_i: int128 = _i - MAX_COIN
        base_coin: address = base_coins[base_i]
        if _use_underlying:
            underlying_coin: address = underlying_coins[base_i]
            # if the base and underlying coin are equal we can't wrap
            should_wrap = base_coin != underlying_coin
            input_coin = underlying_coin
        else:
            input_coin = base_coin

        # approve the base coin to be exchanged irregardless of underlying/base status
        if not self.is_approved[base_coin][_pool]:
            ERC20(base_coin).approve(_pool, MAX_UINT256)
            self.is_approved[base_coin][_pool] = True

    response: Bytes[32] = raw_call(
        input_coin,
        _abi_encode(
            msg.sender,
            self,
            _dx,
            method_id=method_id("transferFrom(address,address,uint256)"),
        ),
        max_outsize=32
    )
    if len(response) != 0:
        assert convert(response, bool)

    if not _use_underlying:
        return CurveMeta(_pool).exchange_underlying(_i, _j, _dx, _min_dy, _receiver)
    
    # we are using underlying so we potentially have to wrap
    if should_wrap:
        # approve for wrapping
        if not self.is_approved[input_coin][LENDING_POOL]:
            ERC20(input_coin).approve(LENDING_POOL, MAX_UINT256)
            self.is_approved[input_coin][LENDING_POOL] = True
        raw_call(
            LENDING_POOL,
            # deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)
            _abi_encode(input_coin, _dx, self, convert(0, uint256), method_id=method_id("deposit(address,uint256,address,uint16)"))
        )
    dy: uint256 = CurveMeta(_pool).exchange_underlying(_i, _j, _dx, _min_dy, self)

    # need to potentially unwrap now
    output_coin: address = ZERO_ADDRESS

    if _j == 0:
        output_coin = CurveMeta(_pool).coins(0)
    else:
        # we for sure are operating on underlying coins
        base_j: int128 = _j - MAX_COIN
        base_coin: address = base_coins[base_j]
        underlying_coin: address = underlying_coins[base_j]
        # if the base and underlying coin are equal we can't wrap
        should_wrap = base_coin != underlying_coin
        output_coin = underlying_coin
    
    if should_wrap:
        LendingPool(LENDING_POOL).withdraw(output_coin, dy, _receiver)
    else:
        response = raw_call(
            output_coin,
            _abi_encode(_receiver, dy, method_id=method_id("transfer(address,uint256)")),
            max_outsize=32
        )
        if len(response) != 0:
            assert convert(response, bool)
    return dy