# @version 0.2.15
"""
@title Uniswap Burner
@notice Swap coins to USDC using Uniswap V3, and transfer to receiver
"""

from vyper.interfaces import ERC20


is_approved: HashMap[address, bool]
receiver: public(address)
recovery: public(address)
is_killed: public(bool)
owner: public(address)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)
burnable_coins: public(HashMap[address, uint256])


USDC: constant(address) = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
ROUTER: constant(address) = 0xE592427A0AEce92De3Edee1F18E0157C05861564  # uniswap v3 swap router


@external
def __init__(_receiver: address, _recovery: address, _owner: address, _emergency_owner: address):
    """
    @notice Contract constructor
    @param _receiver Address that converted tokens are transferred to.
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
    @notice Receive `_coin` and swap it for USDC using Uniswap V3
    @param _coin Address of the coin being converted
    @return bool success
    """
    assert not self.is_killed  # dev: is killed

    # transfer coins from caller
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    fee: uint256 = self.burnable_coins[_coin]
    assert fee != 0, "coin is not yet added to burnable_coins for this burner"
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
    if not self.is_approved[_coin]:
        response: Bytes[32] = raw_call(
            _coin,
            concat(
                method_id("approve(address,uint256)"),
                convert(ROUTER, bytes32),
                convert(MAX_UINT256, bytes32),
            ),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)
        self.is_approved[_coin] = True

    # vyper doesn't support uint24 so we build the calldata manually
    response: Bytes[32] = raw_call(
        ROUTER,
        concat(
            method_id(
                "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))"
            ),
            convert(_coin, bytes32),  # tokenIn:address
            convert(USDC, bytes32),  # tokenOut:address
            convert(fee, bytes32),  # fee:uint24
            convert(self.receiver, bytes32),  # recipient:address
            convert(block.timestamp, bytes32),  # deadline:uint256
            convert(amount, bytes32),  # amountIn:uint256
            convert(0, bytes32),  # amountOutMinimum:uint256
            convert(0, bytes32),  # sqrtPriceLimitX96:uint160
        ),
        max_outsize=32,
    )
    assert len(response) > 0, "no response from exactInputSingle call"
    assert convert(response, uint256) > 0, "swap output amount cannot be zero"
    return True


@external
def add_burnable_coin(_coin: address, _fee: uint256) -> bool:
    """
    @notice add coin and fee for uniswap v3 pool
    @param _coin coin to be swapped for usdc
    @param _fee the fee rate for coin-USDC pool
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    self.burnable_coins[_coin] = _fee
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


@external
def set_receiver(_receiver: address) -> bool:
    """
    @notice Set receiver
    @param _receiver Receiver address
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    self.receiver = _receiver
    return True