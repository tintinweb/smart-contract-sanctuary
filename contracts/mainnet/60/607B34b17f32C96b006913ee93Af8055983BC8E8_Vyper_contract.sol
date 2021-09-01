# @version 0.2.15
"""
@title VVSP Burner
@notice Withdraw from Vvsp and send VSP to receiver
"""

from vyper.interfaces import ERC20


interface Vvsp:
    def withdraw(shares: uint256):
        nonpayable


receiver: public(address)
recovery: public(address)
owner: public(address)
is_killed: public(bool)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)


VSP: constant(address) = 0x1b40183EFB4Dd766f11bDa7A7c3AD8982e998421
VVSP: constant(address) = 0xbA4cFE5741b357FA371b506e5db0774aBFeCf8Fc


event Burn:
    lp_token: address
    amount: uint256
    token0_amount: uint256


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
    @notice Convert `_coin` by withdrawing vvsp and get vsp, then send it to receiver
    @param _coin Address of the coin being converted
    @return bool success
    """
    assert not self.is_killed  # dev: is killed
    assert _coin == VVSP, "only allows burning vvsp"

    # transfer coins from caller
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    if amount != 0:
        ERC20(_coin).transferFrom(msg.sender, self, amount)

    # get actual balance in case of transfer fee or pre-existing balance
    amount = ERC20(_coin).balanceOf(self)

    if amount != 0:
        Vvsp(_coin).withdraw(amount)
        vsp_amount: uint256 = ERC20(VSP).balanceOf(self)
        assert ERC20(VSP).transfer(self.receiver, vsp_amount)
        log Burn(_coin, amount, vsp_amount)
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