# @version 0.2.12
"""
@title Curve CryptoSwap Deposit Zap
@author Curve.Fi
@license Copyright (c) Curve.Fi, 2020 - all rights reserved
@dev Wraps / unwraps Ether, and redirects deposits / withdrawals
"""

from vyper.interfaces import ERC20

interface CurveCryptoSwap:
    def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256): nonpayable
    def remove_liquidity(_amount: uint256, min_amounts: uint256[N_COINS]): nonpayable
    def remove_liquidity_one_coin(token_amount: uint256, i: uint256, min_amount: uint256): nonpayable
    def token() -> address: view
    def coins(i: uint256) -> address: view

interface wETH:
    def deposit(): payable
    def withdraw(_amount: uint256): nonpayable


N_COINS: constant(uint256) = 3
WETH_IDX: constant(uint256) = N_COINS - 1
WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

pool: public(address)
token: public(address)
coins: public(address[N_COINS])


@payable
@external
def __default__():
    assert msg.sender == WETH


@external
def __init__(_pool: address):
    """
    @notice Contract constructor
    @param _pool `CurveCryptoSwap` deployment to target
    """
    self.pool = _pool
    self.token = CurveCryptoSwap(_pool).token()

    for i in range(N_COINS):
        coin: address = CurveCryptoSwap(_pool).coins(i)
        response: Bytes[32] = raw_call(
            coin,
            concat(
                method_id("approve(address,uint256)"),
                convert(_pool, bytes32),
                convert(MAX_UINT256, bytes32)
            ),
            max_outsize=32
        )
        if len(response) > 0:
            assert convert(response, bool)  # dev: bad response
        self.coins[i] = coin

    assert self.coins[WETH_IDX] == WETH


@payable
@external
def add_liquidity(
    _amounts: uint256[N_COINS],
    _min_mint_amount: uint256,
    _receiver: address = msg.sender
) -> uint256:
    """
    @notice Add liquidity and wrap Ether to wETH
    @param _amounts Amount of each token to deposit. `msg.value` must be
                    equal to the given amount of Ether.
    @param _min_mint_amount Minimum amount of LP token to receive
    @param _receiver Receiver of the LP tokens
    @return Amount of LP tokens received
    """
    assert msg.value == _amounts[WETH_IDX]
    wETH(WETH).deposit(value=msg.value)

    for i in range(N_COINS-1):
        if _amounts[i] > 0:
            response: Bytes[32] = raw_call(
                self.coins[i],
                concat(
                    method_id("transferFrom(address,address,uint256)"),
                    convert(msg.sender, bytes32),
                    convert(self, bytes32),
                    convert(_amounts[i], bytes32)
                ),
                max_outsize=32
            )
            if len(response) > 0:
                assert convert(response, bool)  # dev: bad response

    CurveCryptoSwap(self.pool).add_liquidity(_amounts, _min_mint_amount)
    token: address = self.token
    amount: uint256 = ERC20(token).balanceOf(self)
    response: Bytes[32] = raw_call(
        token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(_receiver, bytes32),
            convert(amount, bytes32)
        ),
        max_outsize=32
    )
    if len(response) > 0:
        assert convert(response, bool)  # dev: bad response

    return amount


@external
def remove_liquidity(
    _amount: uint256,
    _min_amounts: uint256[N_COINS],
    _receiver: address = msg.sender
) -> uint256[N_COINS]:
    """
    @notice Withdraw coins from the pool, unwrapping wETH to Ether
    @dev Withdrawal amounts are based on current deposit ratios
    @param _amount Quantity of LP tokens to burn in the withdrawal
    @param _min_amounts Minimum amounts of coins to receive
    @param _receiver Receiver of the withdrawn tokens
    @return Amounts of coins that were withdrawn
    """
    ERC20(self.token).transferFrom(msg.sender, self, _amount)
    CurveCryptoSwap(self.pool).remove_liquidity(_amount, _min_amounts)

    amounts: uint256[N_COINS] = empty(uint256[N_COINS])
    for i in range(N_COINS-1):
        coin: address = self.coins[i]
        amounts[i] = ERC20(coin).balanceOf(self)
        response: Bytes[32] = raw_call(
            coin,
            concat(
                method_id("transfer(address,uint256)"),
                convert(_receiver, bytes32),
                convert(amounts[i], bytes32)
            ),
            max_outsize=32
        )
        if len(response) > 0:
            assert convert(response, bool)  # dev: bad response

    amounts[WETH_IDX] = ERC20(WETH).balanceOf(self)
    wETH(WETH).withdraw(amounts[WETH_IDX])
    raw_call(_receiver, b"", value=self.balance)

    return amounts


@external
def remove_liquidity_one_coin(
    _token_amount: uint256,
    i: uint256,
    _min_amount: uint256,
    _receiver: address = msg.sender
) -> uint256:
    """
    @notice Withdraw a single coin from the pool, unwrapping wETH to Ether
    @param _token_amount Amount of LP tokens to burn in the withdrawal
    @param i Index value of the coin to withdraw
    @param _min_amount Minimum amount of coin to receive
    @param _receiver Receiver of the withdrawn token
    @return Amount of underlying coin received
    """
    ERC20(self.token).transferFrom(msg.sender, self, _token_amount)
    CurveCryptoSwap(self.pool).remove_liquidity_one_coin(_token_amount, i, _min_amount)

    coin: address = self.coins[i]
    amount: uint256 = ERC20(coin).balanceOf(self)
    if i == WETH_IDX:
        wETH(WETH).withdraw(amount)
        raw_call(_receiver, b"", value=self.balance)
    else:
        response: Bytes[32] = raw_call(
            coin,
            concat(
                method_id("transfer(address,uint256)"),
                convert(_receiver, bytes32),
                convert(amount, bytes32)
            ),
            max_outsize=32
        )
        if len(response) > 0:
            assert convert(response, bool)  # dev: bad response
    return amount