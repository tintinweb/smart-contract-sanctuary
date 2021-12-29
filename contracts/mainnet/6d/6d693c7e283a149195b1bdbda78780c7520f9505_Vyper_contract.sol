# @version 0.2.15
"""
@title USDC Burner
@notice Convert USDC into yVault.IB3CRV and send to receiver
"""

from vyper.interfaces import ERC20


interface IB3CRVPool:
    def add_liquidity(
        _amounts: uint256[3], _min_mint_amount: uint256, _use_underlying: bool
    ) -> uint256:
        nonpayable  # USDC index = 1


interface YVaultIB3CRV:
    def deposit(_amount: uint256, recipient: address) -> uint256:
        nonpayable


receiver: public(address)
recovery: public(address)
treasury: public(address)
owner: public(address)
is_killed: public(bool)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)
ratio: public(uint256)


USDC: constant(address) = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
IB3CRV_POOL: constant(address) = 0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF
YVAULT_IB3CRV: constant(address) = 0x27b7b1ad7288079A66d12350c828D3C00A6F07d7
IB3CRV:constant(address) = 0x5282a4eF67D9C33135340fB3289cc1711c13638C


event Burn:
    usdc_amount: uint256
    yvault_ib3_crv_amount: uint256


@external
def __init__(_receiver: address, _recovery: address, _owner: address, _emergency_owner: address, _treasury: address):
    """
    @notice Contract constructor
    @param _receiver the receiver address to which the resultant tokens will be sent, should be a FeeDistributor address
    @param _recovery Address that tokens are transferred to during an
                     emergency token recovery.
    @param _owner Owner address. Can kill the contract, recover tokens
                  and modify the recovery address.
    @param _emergency_owner Emergency owner address. Can kill the contract
                            and recover tokens.
    @param _treasury The treasury address.
    """
    self.receiver = _receiver
    self.recovery = _recovery
    self.owner = _owner
    self.emergency_owner = _emergency_owner
    self.treasury = _treasury


@external
@nonreentrant("lock")
def burn(_coin: address) -> bool:
    """
    @notice Convert `_coin` USDC into yVault.IB3CRV
    @param _coin Address of the coin being converted
    @return bool success
    """
    assert not self.is_killed  # dev: is killed
    assert _coin == USDC

    # transfer coins from caller
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    if amount != 0:
        ERC20(_coin).transferFrom(msg.sender, self, amount)

    # get actual balance in case of transfer fee or pre-existing balance
    amount = ERC20(_coin).balanceOf(self)

    if amount != 0:
        _treasury_amount: uint256 = amount * self.ratio / 10000
        if _treasury_amount > 0:
            ERC20(_coin).transfer(self.treasury, _treasury_amount)

        _burn_amount: uint256 = amount - _treasury_amount
        if _burn_amount > 0:
            # convert usdc to ib3crv
            ERC20(_coin).approve(IB3CRV_POOL, _burn_amount)
            amounts: uint256[3] = [0, _burn_amount, 0]
            ib3_crv_amount: uint256 = IB3CRVPool(IB3CRV_POOL).add_liquidity(amounts, 0, True)
            # convert ib3crv to yvib3crv, then send to receiver
            ERC20(IB3CRV).approve(YVAULT_IB3CRV, ib3_crv_amount)
            yvault_ib3_crv_amount: uint256 = YVaultIB3CRV(YVAULT_IB3CRV).deposit(
                ib3_crv_amount, self.receiver
            )
            log Burn(_burn_amount, yvault_ib3_crv_amount)
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


@external
def set_ratio(_ratio: uint256) -> bool:
    """
    @notice Set the ratio
    @param _ratio The ratio in bps
    @return bool success
    """
    assert msg.sender == self.owner  # dev: only owner
    assert _ratio <= 10000
    self.ratio = _ratio

    return True