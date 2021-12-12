# @version 0.3.0
"""
@title Eurs Crypto Burner
@notice Converts eurs LP tokens to 2CRV
"""

from vyper.interfaces import ERC20

interface CryptoSwap:
    def remove_liquidity_one_coin(token_amount: uint256, i: uint256, min_amount: uint256): nonpayable


receiver: public(address)
is_killed: public(bool)

owner: public(address)
future_owner: public(address)

CRYPTOLP: constant(address) = 0xA827a652Ead76c6B0b3D19dba05452E06e25c27e
SSLP: constant(address) = 0x7f90122BF0700F9E7e1F688fe926940E8839F353


@external
def __init__(_receiver: address, _owner: address):
    """
    @notice Contract constructor
    @param _receiver Address that converted tokens are transferred to.
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

    # withdraw from pool as 2crv
    CryptoSwap(CRYPTOLP).remove_liquidity_one_coin(amount, 1, 0)

    # transfer 2crv to receiver
    amount = ERC20(SSLP).balanceOf(self)
    ERC20(SSLP).transfer(self.receiver, amount)

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