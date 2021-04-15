# @version 0.2.4
# (c) Curve.Fi, 2020
# Pool for DAI/USDC/USDT

from vyper.interfaces import ERC20

interface CurveToken:
    def totalSupply() -> uint256: view
    def mint(_to: address, _value: uint256) -> bool: nonpayable
    def burnFrom(_to: address, _value: uint256) -> bool: nonpayable

N_COINS: constant(int128) = 3  # <- change

coins: public(address[N_COINS])

token: CurveToken

@external
def __init__(
    _coins: address[N_COINS],
    _pool_token: address
):
    self.coins = _coins
    self.token = CurveToken(_pool_token)

@external
def add_liquidity(amounts: uint256[N_COINS], min_mint_amount: uint256):
    for i in range(N_COINS):
        in_coin: address = self.coins[i]
        if amounts[i] > 0:
            # "safeTransferFrom" which works for ERC20s which return bool or not
            _response: Bytes[32] = raw_call(
                in_coin,
                concat(
                    method_id("transferFrom(address,address,uint256)"),
                    convert(msg.sender, bytes32),
                    convert(self, bytes32),
                    convert(amounts[i], bytes32),
                ),
                max_outsize=32,
            )  # dev: failed transfer       
    self.token.mint(msg.sender, 100000000000000000000)

@external
def remove_liquidity_imbalance(amounts: uint256[N_COINS], max_burn_amount: uint256):
    self.token.burnFrom(msg.sender, 10000000000000000000)  # dev: insufficient funds
    for i in range(N_COINS):
        if amounts[i] != 0:
            # "safeTransfer" which works for ERC20s which return bool or not
            _response: Bytes[32] = raw_call(
                self.coins[i],
                concat(
                    method_id("transfer(address,uint256)"),
                    convert(msg.sender, bytes32),
                    convert(amounts[i], bytes32),
                ),
                max_outsize=32,
            )  # dev: failed transfer

@external
def remove_liquidity_one_coin(_token_amount: uint256, i: int128, min_amount: uint256):
    self.token.burnFrom(msg.sender, 10000000000000000000)  # dev: insufficient funds

    _response: Bytes[32] = raw_call(
        self.coins[i],
        concat(
            method_id("transfer(address,uint256)"),
            convert(msg.sender, bytes32),
            convert(min_amount, bytes32),
        ),
        max_outsize=32,
    )  # dev: failed transfer