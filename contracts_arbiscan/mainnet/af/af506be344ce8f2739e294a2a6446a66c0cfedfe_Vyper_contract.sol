# @version 0.3.0
"""
@title Tricrypto Burner
@notice Converts tricrypto LP tokens to USDT
"""

from vyper.interfaces import ERC20

interface CryptoSwap:
    def remove_liquidity_one_coin(token_amount: uint256, i: uint256, min_amount: uint256): nonpayable


receiver: public(address)
is_killed: public(bool)

owner: public(address)
future_owner: public(address)

TRICRYPTO: constant(address) = 0x960ea3e3C7FB317332d990873d354E18d7645590
USDT: constant(address) = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9


@external
def __init__(_receiver: address, _owner: address):
    """
    @notice Contract constructor
    @param _receiver Address that converted tokens are transferred to.
                     Should be set to the `ChildBurner` deployment.
    @param _owner Owner address. Can kill the contract and recover tokens.
    """
    self.receiver = _receiver
    self.owner = _owner


@external
def burn(_coin: address) -> bool:
    """
    @notice Unwrap `_coin` and transfer to the receiver
    @param _coin Address of the coin being unwrapped
    @return bool success
    """
    assert not self.is_killed  # dev: is killed

    # transfer coins from caller
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    ERC20(_coin).transferFrom(msg.sender, self, amount)

    # get actual balance in case of transfer fee or pre-existing balance
    amount = ERC20(_coin).balanceOf(self)

    # withdraw from tricrypto as AM3CRV
    CryptoSwap(TRICRYPTO).remove_liquidity_one_coin(amount, 0, 0)

    # withdraw from aave as USDT
    amount = ERC20(USDT).balanceOf(self)
    ERC20(USDT).transfer(self.receiver, amount)

    return True


@external
def recover_balance(_coin: address) -> bool:
    """
    @notice Recover ERC20 tokens from this contract
    @param _coin Token address
    @return bool success
    """
    assert msg.sender == self.owner  # dev: only owner

    amount: uint256 = ERC20(_coin).balanceOf(self)
    response: Bytes[32] = raw_call(
        _coin,
        _abi_encode(msg.sender, amount, method_id=method_id("transfer(address,uint256)")),
        max_outsize=32,
    )
    if len(response) != 0:
        assert convert(response, bool)

    return True


@external
def set_receiver(_receiver: address):
    assert msg.sender == self.owner
    self.receiver = _receiver


@external
def set_killed(_is_killed: bool) -> bool:
    """
    @notice Set killed status for this contract
    @dev When killed, the `burn` function cannot be called
    @param _is_killed Killed status
    @return bool success
    """
    assert msg.sender == self.owner  # dev: only owner
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