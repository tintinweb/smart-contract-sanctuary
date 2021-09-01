# @version 0.2.15
"""
@title Synth Burner
@notice Convert Synth to SUSD
"""

from vyper.interfaces import ERC20


interface Synthetix:
    def exchange(
        sourceCurrencyKey: bytes32, sourceAmount: uint256, destinationCurrencyKey: bytes32
    ) -> uint256:
        nonpayable

    def settle(currencyKey: bytes32) -> uint256[3]:
        nonpayable


interface Synth:
    def currencyKey() -> bytes32:
        nonpayable

    def transferAndSettle(to: address, amount: uint256) -> bool:
        nonpayable


receiver: public(address)
recovery: public(address)
owner: public(address)
is_killed: public(bool)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)
currency_keys: public(HashMap[address, bytes32])


USDC: constant(address) = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
SNX: constant(address) = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F
SUSD: constant(address) = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51
SUSD_CURRENCY_KEY: constant(
    bytes32
) = 0x7355534400000000000000000000000000000000000000000000000000000000


event Burn:
    token: address
    amount: uint256
    result_amount: uint256


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
    @notice Convert `_coin` to SUSD
    @param _coin Address of the coin being converted
    @return bool success
    """
    assert not self.is_killed  # dev: is killed

    # Synthetix imposes a waiting period on any action of exchange (10 min)
    # https://blog.synthetix.io/how-fee-reclamation-rebates-work/
    initial_balance: uint256 = ERC20(SUSD).balanceOf(self)
    if initial_balance > 0:
        Synth(SUSD).transferAndSettle(self.receiver, initial_balance)

    currency_key: bytes32 = self.currency_keys[_coin]
    assert currency_key != EMPTY_BYTES32, "currency key not set, please call add_synths first"

    # transfer coins from caller
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)

    if amount != 0:
        ERC20(_coin).transferFrom(msg.sender, self, amount)

    # get actual balance in case of transfer fee or pre-existing balance
    amount = ERC20(_coin).balanceOf(self)

    if amount != 0:
        Synthetix(SNX).exchange(currency_key, amount, SUSD_CURRENCY_KEY)
        susd_amount: uint256 = ERC20(SUSD).balanceOf(self)
        # Due to Synthetix's waiting period. Do nothing after exchanging for SUSD
        log Burn(_coin, amount, susd_amount)
    return True


@external
def add_synths(_synths: address[10]) -> bool:
    """
    @notice Registry synth token addresses
    @param _synths List of synth tokens to register
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    for synth in _synths:
        if synth == ZERO_ADDRESS:
            break
        # this will revert if `_synth` is not actually a synth
        self.currency_keys[synth] = Synth(synth).currencyKey()

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
@nonreentrant("lock")
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