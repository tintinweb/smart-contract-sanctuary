# @version 0.2.12
"""
@title Arbitrage V2
@dev Ability to route trades through multiple liquidity pools
"""
from vyper.interfaces import ERC20


MAX_SWAPS: constant(uint256) = 5
ZAP_COINS: constant(address[5]) = [0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063, 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, 0xc2132D05D31c914a87C6611C10748AEb04B58e8F, 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6, 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619]
FACTORY_ADDR: constant(address) = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32
ZAP_ADDR: constant(address) = 0x3Fa8ebd5d16445b42e0b6A54678718C94eA99aBC


interface QuickSwapFactory:
    def getPair(_token_a: address, _token_b: address) -> address: view

interface QuickSwapPair:
    def getReserves() -> (uint256, uint256, uint256): view
    def swap(_amount_0_Out: uint256, _amount_1_out: uint256, _to: address, _data: Bytes[64]): nonpayable
    def token0() -> address: view

interface Zap:
    def exchange_underlying(_i: uint256, _j: uint256, _dx: uint256, _min_dy: uint256, _receiver: address): nonpayable


owner: address


@external
def __init__():
    self.owner = msg.sender
    for coin in ZAP_COINS:
        ERC20(coin).approve(ZAP_ADDR, MAX_UINT256)


@pure
@internal
def get_amount_out(
    _amount_in: uint256, _reserve_in: uint256, _reserve_out: uint256
) -> uint256:
    """
    @dev Given an input amount of an asset and pair reserves, returns the maximum output
        amount of the other asset.
    """
    assert _amount_in > 0
    assert _reserve_in > 0 and _reserve_out > 0
    amount_in_with_fee: uint256 = _amount_in * 997
    numerator: uint256 = amount_in_with_fee * _reserve_out
    denominator: uint256 = _reserve_in * 1000 + amount_in_with_fee
    return numerator / denominator


@external
def arbitrage_curve(_i: uint256, _j: uint256, _dx: uint256, _min_amounts: uint256[MAX_SWAPS], _route: address[MAX_SWAPS]):
    """
    @param _i The input index for tricrypto zap
    @param _j The output indes for the tricrypto zap
    @param _dx The input amount for the tricrypto zap
    @param _min_amounts The minimum amount of the initial input token to receive back
    @param _route An array of coins to swap between. e.g. coin_a, coin_b, coin_c, coin_a.
        The first coin in the array should be the output of the initial tricrypto zap exchange.
        The last coin in the array should be the same as the input to the tricrypto zap.
        This means at minimum, the array should be populated with 2 values.
    """
    assert msg.sender == self.owner

    zap_coins: address[5] = ZAP_COINS
    ERC20(zap_coins[_i]).transferFrom(msg.sender, self, _dx)

    Zap(ZAP_ADDR).exchange_underlying(_i, _j, _dx, 0, self)

    # from the first asset to the second to last asset
    # the final swap will be the
    last_coin: address = ZERO_ADDRESS
    for i in range(MAX_SWAPS - 1):
        coin_a: address = _route[i]
        coin_b: address = _route[i + 1]
        if ZERO_ADDRESS in [coin_a, coin_b]:
            break
        last_coin = coin_b
        amount_in: uint256 = _min_amounts[i]

        pair_addr: address = QuickSwapFactory(FACTORY_ADDR).getPair(coin_a, coin_b)
        coin_a_balance: uint256 = ERC20(coin_a).balanceOf(self)
        if amount_in < coin_a_balance:
            ERC20(coin_a).transfer(msg.sender, coin_a_balance - amount_in)
        ERC20(coin_a).transfer(pair_addr, amount_in)

        reserve_0: uint256 = 0
        reserve_1: uint256 = 0
        timestamp_last: uint256 = 0
        expected_return: uint256 = 0

        reserve_0, reserve_1, timestamp_last = QuickSwapPair(pair_addr).getReserves()
        if coin_a == QuickSwapPair(pair_addr).token0():
            expected_return = self.get_amount_out(amount_in, reserve_0, reserve_1)
            QuickSwapPair(pair_addr).swap(0, expected_return, self, b"")
        else:
            expected_return = self.get_amount_out(amount_in, reserve_1, reserve_0)
            QuickSwapPair(pair_addr).swap(expected_return, 0, self, b"")


    bal: uint256 = ERC20(zap_coins[_i]).balanceOf(self)
    assert  bal >= _dx
    ERC20(zap_coins[_i]).transfer(msg.sender, bal)


@external
def arbitrage_quickswap(_i: uint256, _j: uint256, _dx: uint256, _min_amount: uint256, _route: address[MAX_SWAPS]):
    """
    @param _i The input index for tricrypto zap
    @param _j The output indes for the tricrypto zap
    @param _dx The initial input amount supplied to the quickswap pair
    @param _min_amount The minimum amount of the initial input token to receive back
    @param _route An array of coins to swap between. e.g. coin_a, coin_b, coin_c, coin_a.
        The first coin in the array should be the input of the initial quickswap exchange.
        The last coin in the array should be the same as the input to the tricrypto zap.
        This means at minimum, the array should be populated with 2 values.
    """
    assert msg.sender == self.owner

    ERC20(_route[0]).transferFrom(msg.sender, self, _dx)

    # from the first asset to the second to last asset
    last_coin: address = ZERO_ADDRESS
    for i in range(MAX_SWAPS - 1):
        coin_a: address = _route[i]
        coin_b: address = _route[i + 1]
        if ZERO_ADDRESS in [coin_a, coin_b]:
            break
        last_coin = coin_b

        pair_addr: address = QuickSwapFactory(FACTORY_ADDR).getPair(coin_a, coin_b)
        coin_a_balance: uint256 = ERC20(coin_a).balanceOf(self)

        ERC20(coin_a).transfer(pair_addr, coin_a_balance)

        reserve_0: uint256 = 0
        reserve_1: uint256 = 0
        timestamp_last: uint256 = 0
        expected_return: uint256 = 0

        reserve_0, reserve_1, timestamp_last = QuickSwapPair(pair_addr).getReserves()
        if coin_a == QuickSwapPair(pair_addr).token0():
            expected_return = self.get_amount_out(coin_a_balance, reserve_0, reserve_1)
            QuickSwapPair(pair_addr).swap(0, expected_return, self, b"")
        else:
            expected_return = self.get_amount_out(coin_a_balance, reserve_1, reserve_0)
            QuickSwapPair(pair_addr).swap(expected_return, 0, self, b"")
        
    last_balance: uint256 = ERC20(last_coin).balanceOf(self)

    Zap(ZAP_ADDR).exchange_underlying(_i, _j, last_balance, _min_amount, msg.sender)



@external
def withdraw_token(_token: address, _amount: uint256) -> bool:
    """
    @dev Safety function
    """
    assert msg.sender == self.owner  # dev: only owner
    assert ERC20(_token).transfer(msg.sender, _amount)  # dev: failed transfer
    return True