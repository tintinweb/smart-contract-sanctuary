# @version 0.2.7
"""
@title "Zap" Depositer for Curve pool
@author Curve.Fi
@license Copyright (c) Curve.Fi, 2020 - all rights reserved
"""

from vyper.interfaces import ERC20


interface CurveMeta:
    def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256) -> uint256: nonpayable
    def remove_liquidity(_amount: uint256, min_amounts: uint256[N_COINS]) -> uint256[N_COINS]: nonpayable
    def remove_liquidity_one_coin(_token_amount: uint256, i: int128, min_amount: uint256) -> uint256: nonpayable
    def remove_liquidity_imbalance(amounts: uint256[N_COINS], max_burn_amount: uint256) -> uint256: nonpayable
    def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256: view
    def calc_token_amount(amounts: uint256[N_COINS], deposit: bool) -> uint256: view
    def base_pool() -> address: view
    def coins(i: uint256) -> address: view

interface CurveBase:
    def add_liquidity(amounts: uint256[BASE_N_COINS], min_mint_amount: uint256): nonpayable
    def remove_liquidity(_amount: uint256, min_amounts: uint256[BASE_N_COINS]): nonpayable
    def remove_liquidity_one_coin(_token_amount: uint256, i: int128, min_amount: uint256): nonpayable
    def remove_liquidity_imbalance(amounts: uint256[BASE_N_COINS], max_burn_amount: uint256): nonpayable
    def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256: view
    def calc_token_amount(amounts: uint256[BASE_N_COINS], deposit: bool) -> uint256: view
    def coins(i: uint256) -> address: view
    def fee() -> uint256: view


N_COINS: constant(int128) = 2
MAX_COIN: constant(int128) = N_COINS-1
BASE_N_COINS: constant(int128) = 5
N_ALL_COINS: constant(int128) = N_COINS + BASE_N_COINS - 1

# An asset which may have a transfer fee (USDT)
FEE_ASSET: constant(address) = 0xdAC17F958D2ee523a2206206994597C13D831ec7

FEE_DENOMINATOR: constant(uint256) = 10 ** 10
FEE_IMPRECISION: constant(uint256) = 100 * 10 ** 8  # % of the fee


pool: public(address)
token: public(address)
base_pool: public(address)

coins: public(address[N_COINS])
base_coins: public(address[BASE_N_COINS])


@external
def __init__(_pool: address, _token: address):
    """
    @notice Contract constructor
    @param _pool Metapool address
    @param _token Pool LP token address
    """
    self.pool = _pool
    self.token = _token
    _base_pool: address = CurveMeta(_pool).base_pool()
    self.base_pool = _base_pool

    for i in range(N_COINS):
        coin: address = CurveMeta(_pool).coins(convert(i, uint256))
        self.coins[i] = coin
        # approve coins for infinite transfers
        _response: Bytes[32] = raw_call(
            coin,
            concat(
                method_id("approve(address,uint256)"),
                convert(_pool, bytes32),
                convert(MAX_UINT256, bytes32),
            ),
            max_outsize=32,
        )
        if len(_response) > 0:
            assert convert(_response, bool)

    for i in range(BASE_N_COINS):
        coin: address = CurveBase(_base_pool).coins(convert(i, uint256))
        self.base_coins[i] = coin
        # approve underlying coins for infinite transfers
        _response: Bytes[32] = raw_call(
            coin,
            concat(
                method_id("approve(address,uint256)"),
                convert(_base_pool, bytes32),
                convert(MAX_UINT256, bytes32),
            ),
            max_outsize=32,
        )
        if len(_response) > 0:
            assert convert(_response, bool)


@external
def add_liquidity(amounts: uint256[N_ALL_COINS], min_mint_amount: uint256) -> uint256:
    """
    @notice Wrap underlying coins and deposit them in the pool
    @param amounts List of amounts of underlying coins to deposit
    @param min_mint_amount Minimum amount of LP tokens to mint from the deposit
    @return Amount of LP tokens received by depositing
    """
    meta_amounts: uint256[N_COINS] = empty(uint256[N_COINS])
    base_amounts: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
    deposit_base: bool = False

    # Transfer all coins in
    for i in range(N_ALL_COINS):
        amount: uint256 = amounts[i]
        if amount == 0:
            continue
        coin: address = ZERO_ADDRESS
        if i < MAX_COIN:
            coin = self.coins[i]
            meta_amounts[i] = amount
        else:
            x: int128 = i - MAX_COIN
            coin = self.base_coins[x]
            base_amounts[x] = amount
            deposit_base = True
        # "safeTransferFrom" which works for ERC20s which return bool or not
        _response: Bytes[32] = raw_call(
            coin,
            concat(
                method_id("transferFrom(address,address,uint256)"),
                convert(msg.sender, bytes32),
                convert(self, bytes32),
                convert(amount, bytes32),
            ),
            max_outsize=32,
        )  # dev: failed transfer
        if len(_response) > 0:
            assert convert(_response, bool)  # dev: failed transfer
        # end "safeTransferFrom"
        # Handle potential Tether fees
        if coin == FEE_ASSET:
            amount = ERC20(FEE_ASSET).balanceOf(self)
            if i < MAX_COIN:
                meta_amounts[i] = amount
            else:
                base_amounts[i - MAX_COIN] = amount

    # Deposit to the base pool
    if deposit_base:
        CurveBase(self.base_pool).add_liquidity(base_amounts, 0)
        meta_amounts[MAX_COIN] = ERC20(self.coins[MAX_COIN]).balanceOf(self)

    # Deposit to the meta pool
    CurveMeta(self.pool).add_liquidity(meta_amounts, min_mint_amount)

    # Transfer meta token back
    _lp_token: address = self.token
    _lp_amount: uint256 = ERC20(_lp_token).balanceOf(self)
    assert ERC20(_lp_token).transfer(msg.sender, _lp_amount)

    return _lp_amount


@external
def remove_liquidity(_amount: uint256, min_amounts: uint256[N_ALL_COINS]) -> uint256[N_ALL_COINS]:
    """
    @notice Withdraw and unwrap coins from the pool
    @dev Withdrawal amounts are based on current deposit ratios
    @param _amount Quantity of LP tokens to burn in the withdrawal
    @param min_amounts Minimum amounts of underlying coins to receive
    @return List of amounts of underlying coins that were withdrawn
    """
    _token: address = self.token
    assert ERC20(_token).transferFrom(msg.sender, self, _amount)

    min_amounts_meta: uint256[N_COINS] = empty(uint256[N_COINS])
    min_amounts_base: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
    amounts: uint256[N_ALL_COINS] = empty(uint256[N_ALL_COINS])

    # Withdraw from meta
    for i in range(MAX_COIN):
        min_amounts_meta[i] = min_amounts[i]
    CurveMeta(self.pool).remove_liquidity(_amount, min_amounts_meta)

    # Withdraw from base
    _base_amount: uint256 = ERC20(self.coins[MAX_COIN]).balanceOf(self)
    for i in range(BASE_N_COINS):
        min_amounts_base[i] = min_amounts[MAX_COIN+i]
    CurveBase(self.base_pool).remove_liquidity(_base_amount, min_amounts_base)

    # Transfer all coins out
    for i in range(N_ALL_COINS):
        coin: address = ZERO_ADDRESS
        if i < MAX_COIN:
            coin = self.coins[i]
        else:
            coin = self.base_coins[i - MAX_COIN]
        amounts[i] = ERC20(coin).balanceOf(self)
        # "safeTransfer" which works for ERC20s which return bool or not
        _response: Bytes[32] = raw_call(
            coin,
            concat(
                method_id("transfer(address,uint256)"),
                convert(msg.sender, bytes32),
                convert(amounts[i], bytes32),
            ),
            max_outsize=32,
        )  # dev: failed transfer
        if len(_response) > 0:
            assert convert(_response, bool)  # dev: failed transfer
        # end "safeTransfer"

    return amounts


@external
def remove_liquidity_one_coin(_token_amount: uint256, i: int128, _min_amount: uint256) -> uint256:
    """
    @notice Withdraw and unwrap a single coin from the pool
    @param _token_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the coin to withdraw
    @param _min_amount Minimum amount of underlying coin to receive
    @return Amount of underlying coin received
    """
    assert ERC20(self.token).transferFrom(msg.sender, self, _token_amount)

    coin: address = ZERO_ADDRESS
    if i < MAX_COIN:
        coin = self.coins[i]
        # Withdraw a metapool coin
        CurveMeta(self.pool).remove_liquidity_one_coin(_token_amount, i, _min_amount)
    else:
        coin = self.base_coins[i - MAX_COIN]
        # Withdraw a base pool coin
        CurveMeta(self.pool).remove_liquidity_one_coin(_token_amount, MAX_COIN, 0)
        CurveBase(self.base_pool).remove_liquidity_one_coin(
            ERC20(self.coins[MAX_COIN]).balanceOf(self), i-MAX_COIN, _min_amount
        )

    # Tranfer the coin out
    coin_amount: uint256 = ERC20(coin).balanceOf(self)
    # "safeTransfer" which works for ERC20s which return bool or not
    _response: Bytes[32] = raw_call(
        coin,
        concat(
            method_id("transfer(address,uint256)"),
            convert(msg.sender, bytes32),
            convert(coin_amount, bytes32),
        ),
        max_outsize=32,
    )  # dev: failed transfer
    if len(_response) > 0:
        assert convert(_response, bool)  # dev: failed transfer
    # end "safeTransfer"

    return coin_amount


@external
def remove_liquidity_imbalance(amounts: uint256[N_ALL_COINS], max_burn_amount: uint256) -> uint256:
    """
    @notice Withdraw coins from the pool in an imbalanced amount
    @param amounts List of amounts of underlying coins to withdraw
    @param max_burn_amount Maximum amount of LP token to burn in the withdrawal.
                           This value cannot exceed the caller's LP token balance.
    @return Actual amount of the LP token burned in the withdrawal
    """
    _base_pool: address = self.base_pool
    _meta_pool: address = self.pool
    _base_coins: address[BASE_N_COINS] = self.base_coins
    _meta_coins: address[N_COINS] = self.coins
    _lp_token: address = self.token

    fee: uint256 = CurveBase(_base_pool).fee() * BASE_N_COINS / (4 * (BASE_N_COINS - 1))
    fee += fee * FEE_IMPRECISION / FEE_DENOMINATOR  # Overcharge to account for imprecision

    # Transfer the LP token in
    assert ERC20(_lp_token).transferFrom(msg.sender, self, max_burn_amount)

    withdraw_base: bool = False
    amounts_base: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])
    amounts_meta: uint256[N_COINS] = empty(uint256[N_COINS])
    leftover_amounts: uint256[N_COINS] = empty(uint256[N_COINS])

    # Prepare quantities
    for i in range(MAX_COIN):
        amounts_meta[i] = amounts[i]

    for i in range(BASE_N_COINS):
        amount: uint256 = amounts[MAX_COIN + i]
        if amount != 0:
            amounts_base[i] = amount
            withdraw_base = True

    if withdraw_base:
        amounts_meta[MAX_COIN] = CurveBase(self.base_pool).calc_token_amount(amounts_base, False)
        amounts_meta[MAX_COIN] += amounts_meta[MAX_COIN] * fee / FEE_DENOMINATOR + 1

    # Remove liquidity and deposit leftovers back
    CurveMeta(_meta_pool).remove_liquidity_imbalance(amounts_meta, max_burn_amount)
    if withdraw_base:
        CurveBase(_base_pool).remove_liquidity_imbalance(amounts_base, amounts_meta[MAX_COIN])
        leftover_amounts[MAX_COIN] = ERC20(_meta_coins[MAX_COIN]).balanceOf(self)
        if leftover_amounts[MAX_COIN] > 0:
            CurveMeta(_meta_pool).add_liquidity(leftover_amounts, 0)

    # Transfer all coins out
    for i in range(N_ALL_COINS):
        coin: address = ZERO_ADDRESS
        amount: uint256 = 0
        if i < MAX_COIN:
            coin = _meta_coins[i]
            amount = amounts_meta[i]
        else:
            coin = _base_coins[i - MAX_COIN]
            amount = amounts_base[i - MAX_COIN]
        # "safeTransfer" which works for ERC20s which return bool or not
        if amount > 0:
            _response: Bytes[32] = raw_call(
                coin,
                concat(
                    method_id("transfer(address,uint256)"),
                    convert(msg.sender, bytes32),
                    convert(amount, bytes32),
                ),
                max_outsize=32,
            )  # dev: failed transfer
            if len(_response) > 0:
                assert convert(_response, bool)  # dev: failed transfer
            # end "safeTransfer"

    # Transfer the leftover LP token out
    leftover: uint256 = ERC20(_lp_token).balanceOf(self)
    if leftover > 0:
        assert ERC20(_lp_token).transfer(msg.sender, leftover)

    return max_burn_amount - leftover


@view
@external
def calc_withdraw_one_coin(_token_amount: uint256, i: int128) -> uint256:
    """
    @notice Calculate the amount received when withdrawing and unwrapping a single coin
    @param _token_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the underlying coin to withdraw
    @return Amount of coin received
    """
    if i < MAX_COIN:
        return CurveMeta(self.pool).calc_withdraw_one_coin(_token_amount, i)
    else:
        _base_tokens: uint256 = CurveMeta(self.pool).calc_withdraw_one_coin(_token_amount, MAX_COIN)
        return CurveBase(self.base_pool).calc_withdraw_one_coin(_base_tokens, i-MAX_COIN)


@view
@external
def calc_token_amount(amounts: uint256[N_ALL_COINS], is_deposit: bool) -> uint256:
    """
    @notice Calculate addition or reduction in token supply from a deposit or withdrawal
    @dev This calculation accounts for slippage, but not fees.
         Needed to prevent front-running, not for precise calculations!
    @param amounts Amount of each underlying coin being deposited
    @param is_deposit set True for deposits, False for withdrawals
    @return Expected amount of LP tokens received
    """
    meta_amounts: uint256[N_COINS] = empty(uint256[N_COINS])
    base_amounts: uint256[BASE_N_COINS] = empty(uint256[BASE_N_COINS])

    for i in range(MAX_COIN):
        meta_amounts[i] = amounts[i]

    for i in range(BASE_N_COINS):
        base_amounts[i] = amounts[i + MAX_COIN]

    _base_tokens: uint256 = CurveBase(self.base_pool).calc_token_amount(base_amounts, is_deposit)
    meta_amounts[MAX_COIN] = _base_tokens

    return CurveMeta(self.pool).calc_token_amount(meta_amounts, is_deposit)