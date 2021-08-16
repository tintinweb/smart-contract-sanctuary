# @version 0.2.15
"""
@title Uniswap LP Burner
@notice Given a Uniswap LP token, withdraw from the pool, and send the withdrawn two tokens to receiver
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


receiver: public(address)
recovery: public(address)
owner: public(address)
is_killed: public(bool)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)


routers: constant(address[2]) = [
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, # uniswap
    0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F, # sushiswap
]


event Burn:
    lp_token: address
    amount: uint256
    token0_amount: uint256
    token1_amount: uint256


@external
def __init__(_receiver: address, _recovery: address, _owner: address, _emergency_owner: address):
    """
    @notice Contract constructor
    @param _receiver the receiver address to which the resultant tokens will be sent
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
    @notice Convert `_coin` by removing liquidity and send the resultant tokens to receiver
    @param _coin Address of the coin being converted
    @return bool success
    """
    assert not self.is_killed  # dev: is killed

    # transfer coins from caller
    lp_amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    if lp_amount != 0:
        ERC20(_coin).transferFrom(msg.sender, self, lp_amount)

    # get actual balance in case of transfer fee or pre-existing balance
    lp_amount = ERC20(_coin).balanceOf(self)

    if lp_amount != 0:
        # remove liquidity and pass to receiver
        token0: address = UniswapV2Pair(_coin).token0()
        token1: address = UniswapV2Pair(_coin).token1()
        router: address = ZERO_ADDRESS
        for r in routers:
            if UniswapV2Router02(r).factory() == UniswapV2Pair(_coin).factory():
                router = r
        assert router != ZERO_ADDRESS
        ERC20(_coin).approve(router, lp_amount)
        token_amounts: uint256[2] = UniswapV2Router02(router).removeLiquidity(
            token0, token1, lp_amount, 0, 0, self.receiver, block.timestamp
        )
        log Burn(_coin, lp_amount, token_amounts[0], token_amounts[1])
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