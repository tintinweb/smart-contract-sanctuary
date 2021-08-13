# @version 0.2.15
"""
@title Uniswap Burner
@notice Swap coins to USDC using Uniswap or Sushi, and send to receiver
"""

from vyper.interfaces import ERC20


interface UniswapV2Pair:
    def token0() -> address:
        view

    def token1() -> address:
        view

    def factory() -> address:
        view


interface UniswapV2Router02:
    def removeLiquidity(
        tokenA: address,
        tokenB: address,
        liquidity: uint256,
        amountAMin: uint256,
        amountBMin: uint256,
        to: address,
        deadline: uint256,
    ) -> uint256[2]:
        nonpayable

    def factory() -> address:
        view


interface UniswapV2Factory:
    def getPair(tokenA: address, tokenB: address) -> address:
        view


is_approved: HashMap[address, HashMap[address, bool]]
receiver: public(address)
recovery: public(address)
is_killed: public(bool)
owner: public(address)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)


WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
USDC: constant(address) = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
ROUTERS: constant(address[2]) = [
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,  # uniswap
    0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F,  # sushi
]


@internal
def _swap_for_usdc(_coin: address, amount: uint256, router: address):
    # vyper doesnt support dynamic array. build calldata manually
    if _coin == WETH:
        raw_call(
            router,
            concat(
                method_id("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"),
                convert(amount, bytes32),  # swap amount
                EMPTY_BYTES32,  # min expected
                convert(160, bytes32),  # offset pointer to path array
                convert(self.receiver, bytes32),  # receiver of the swap
                convert(block.timestamp, bytes32),  # swap deadline
                convert(2, bytes32),  # path length
                convert(_coin, bytes32),  # input token
                convert(USDC, bytes32),  # usdc (final output)
            ),
        )
    else:
        raw_call(
            router,
            concat(
                method_id("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"),
                convert(amount, bytes32),  # swap amount
                EMPTY_BYTES32,  # min expected
                convert(160, bytes32),  # offset pointer to path array
                convert(self.receiver, bytes32),  # receiver of the swap
                convert(block.timestamp, bytes32),  # swap deadline
                convert(3, bytes32),  # path length
                convert(_coin, bytes32),  # input token
                convert(WETH, bytes32),  # weth (intermediate swap)
                convert(USDC, bytes32),  # usdc (final output)
            ),
        )


@internal
def _get_amounts_out(_coin: address, amount: uint256, router: address) -> uint256:
    # vyper doesnt support dynamic array. build calldata manually
    call_data: Bytes[256] = 0x00
    if _coin == WETH:
        call_data = concat(
            method_id("getAmountsOut(uint256,address[])"),
            convert(amount, bytes32),
            convert(64, bytes32),
            convert(2, bytes32),
            convert(_coin, bytes32),
            convert(USDC, bytes32),
        )
    else:
        call_data = concat(
            method_id("getAmountsOut(uint256,address[])"),
            convert(amount, bytes32),
            convert(64, bytes32),
            convert(3, bytes32),
            convert(_coin, bytes32),
            convert(WETH, bytes32),
            convert(USDC, bytes32),
        )
    response: Bytes[128] = raw_call(router, call_data, max_outsize=128)
    response_bytes_start_index: uint256 = 0
    if _coin == WETH:
        response_bytes_start_index = 64
    else:
        response_bytes_start_index = 96
    return convert(slice(response, response_bytes_start_index, 32), uint256)


@external
def __init__(_receiver: address, _recovery: address, _owner: address, _emergency_owner: address):
    """
    @notice Contract constructor
    @param _receiver Address that converted tokens are transferred to.
                     Should be set to an USDCBurner.
    @param _recovery Address that tokens are transferred to during an
                     emergency token recovery.
    @param _owner Owner address. Can kill the contract, recover tokens
                  and modify the recovery address.
    @param _emergency_owner Emergency owner address. Can kill the contract
                            and recover tokens.
    """
    self.receiver = _receiver
    self.recovery = _recovery
    self.owner = _owner
    self.emergency_owner = _emergency_owner


@external
@nonreentrant("lock")
def burn(_coin: address) -> bool:
    """
    @notice Receive `_coin` and swap it for USDC using Uniswap or Sushi
    @param _coin Address of the coin being converted
    @return bool success
    """
    assert not self.is_killed  # dev: is killed

    # transfer coins from caller
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)

    if amount != 0:
        response: Bytes[32] = raw_call(
            _coin,
            concat(
                method_id("transferFrom(address,address,uint256)"),
                convert(msg.sender, bytes32),
                convert(self, bytes32),
                convert(amount, bytes32),
            ),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)

    # get actual balance in case of transfer fee or pre-existing balance
    amount = ERC20(_coin).balanceOf(self)

    best_expected: uint256 = 0
    router: address = ZERO_ADDRESS

    # check the rates on uniswap and sushi to see which is the better option
    for addr in ROUTERS:
        if _coin != WETH:
            factory: address = UniswapV2Router02(addr).factory()
            coin_weth_pair: address = UniswapV2Factory(factory).getPair(_coin, WETH)
            if coin_weth_pair == ZERO_ADDRESS:
                continue
        expected: uint256 = self._get_amounts_out(_coin, amount, addr)
        if expected > best_expected:
            best_expected = expected
            router = addr

    assert router != ZERO_ADDRESS, "neither Uniswap nor Sushiswap has liquidity pool for this token"
    # make sure the router is approved to transfer the coin
    if not self.is_approved[router][_coin]:
        response: Bytes[32] = raw_call(
            _coin,
            concat(
                method_id("approve(address,uint256)"),
                convert(router, bytes32),
                convert(MAX_UINT256, bytes32),
            ),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)
        self.is_approved[router][_coin] = True
    # swap for USDC on the best dex protocol
    self._swap_for_usdc(_coin, amount, router)
    return True


@external
def recover_balance(_coin: address) -> bool:
    """
    @notice Recover ERC20 tokens from this contract
    @dev Tokens are sent to the recovery address
    @param _coin Token address
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner

    amount: uint256 = ERC20(_coin).balanceOf(self)
    response: Bytes[32] = raw_call(
        _coin,
        concat(
            method_id("transfer(address,uint256)"),
            convert(self.recovery, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) != 0:
        assert convert(response, bool)

    return True


@external
def set_recovery(_recovery: address) -> bool:
    """
    @notice Set the token recovery address
    @param _recovery Token recovery address
    @return bool success
    """
    assert msg.sender == self.owner  # dev: only owner
    self.recovery = _recovery

    return True


@external
def set_killed(_is_killed: bool) -> bool:
    """
    @notice Set killed status for this contract
    @dev When killed, the `burn` function cannot be called
    @param _is_killed Killed status
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    self.is_killed = _is_killed

    return True


@external
def commit_transfer_ownership(_future_owner: address) -> bool:
    """
    @notice Commit a transfer of ownership
    @dev Must be accepted by the new owner via `accept_transfer_ownership`
    @param _future_owner New owner address
    @return bool success
    """
    assert msg.sender == self.owner  # dev: only owner
    self.future_owner = _future_owner

    return True


@external
def accept_transfer_ownership() -> bool:
    """
    @notice Accept a transfer of ownership
    @return bool success
    """
    assert msg.sender == self.future_owner  # dev: only owner
    self.owner = msg.sender

    return True


@external
def commit_transfer_emergency_ownership(_future_owner: address) -> bool:
    """
    @notice Commit a transfer of ownership
    @dev Must be accepted by the new owner via `accept_transfer_ownership`
    @param _future_owner New owner address
    @return bool success
    """
    assert msg.sender == self.emergency_owner  # dev: only owner
    self.future_emergency_owner = _future_owner

    return True


@external
def accept_transfer_emergency_ownership() -> bool:
    """
    @notice Accept a transfer of ownership
    @return bool success
    """
    assert msg.sender == self.future_emergency_owner  # dev: only owner
    self.emergency_owner = msg.sender

    return True