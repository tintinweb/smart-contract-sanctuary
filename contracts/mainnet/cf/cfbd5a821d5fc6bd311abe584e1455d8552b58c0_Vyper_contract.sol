# @version 0.2.8
"""
@title Synth Burner
@notice Converts EUR denominated coins to sEUR and transfers to `UnderlyingBurner`
"""

from vyper.interfaces import ERC20


interface AddressProvider:
    def get_registry() -> address: view
    def get_address(_id: uint256) -> address: view

interface Registry:
    def find_pool_for_coins(_from: address, _to: address) -> address: view

interface RegistrySwap:
    def exchange_with_best_rate(
        _from: address,
        _to: address,
        _amount: uint256,
        _expected: uint256,
        _receiver: address,
    ) -> uint256: payable

interface UnderlyingBurner:
    def convert_synth(_currency_key: bytes32, _amount: uint256) -> bool: nonpayable


ADDRESS_PROVIDER: constant(address) = 0x0000000022D53366457F9d5E68Ec105046FC4383
SEUR: constant(address) = 0xD71eCFF9342A5Ced620049e616c5035F1dB98620

# currency keys used to identify synths during exchange
SEUR_CURRENCY_KEY: constant(bytes32) = 0x7345555200000000000000000000000000000000000000000000000000000000


is_approved: HashMap[address, HashMap[address, bool]]
swap_for: HashMap[address, address]

receiver: public(address)
recovery: public(address)
is_killed: public(bool)

owner: public(address)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)


@external
def __init__(_receiver: address, _recovery: address, _owner: address, _emergency_owner: address):
    """
    @notice Contract constructor
    @param _receiver Address that converted tokens are transferred to.
                     Should be set to an `UnderlyingBurner` deployment.
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
def set_swap_for(_coin: address, _swap_for: address) -> bool:
    """
    @notice Set an intermediate swap coin for coins that cannot
            directly swap to sEUR
    @param _coin Coin being burned
    @param _swap_for Intermediate coin that can be swapped for
            both `_coin` and sEUR
    @return bool success
    """
    registry: address = AddressProvider(ADDRESS_PROVIDER).get_registry()
    direct_pool: address = Registry(registry).find_pool_for_coins(_coin, SEUR)

    if _swap_for == ZERO_ADDRESS:
        # removing an intermediary swap, ensure direct swap is possible
        assert direct_pool != ZERO_ADDRESS
    else:
        # adding an intermediary swap, ensure direct swap is not possible
        # and that intermediate route exists
        assert direct_pool == ZERO_ADDRESS
        assert Registry(registry).find_pool_for_coins(_coin, _swap_for) != ZERO_ADDRESS
        assert Registry(registry).find_pool_for_coins(_swap_for, SEUR) != ZERO_ADDRESS

    self.swap_for[_coin] = _swap_for

    return True


@internal
def _swap(_registry_swap: address, _from: address, _to: address, _amount: uint256, _receiver: address):
    if not self.is_approved[_registry_swap][_from]:
        response: Bytes[32] = raw_call(
            _from,
            concat(
                method_id("approve(address,uint256)"),
                convert(_registry_swap, bytes32),
                convert(MAX_UINT256, bytes32),
            ),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)
        self.is_approved[_registry_swap][_from] = True

    RegistrySwap(_registry_swap).exchange_with_best_rate(_from, _to, _amount, 0, _receiver)


@external
def burn(_coin: address) -> bool:
    """
    @notice Receive `_coin` and convert to sUSD via sEUR
    @param _coin Address of the coin being converted
    @return bool success
    """
    assert not self.is_killed  # dev: is killed
    coin: address = _coin

    # transfer coins from caller
    amount: uint256 = ERC20(coin).balanceOf(msg.sender)
    if amount != 0:
        response: Bytes[32] = raw_call(
            coin,
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
    amount = ERC20(coin).balanceOf(self)

    if amount != 0:
        if coin == SEUR:
            # transfer sEUR to underlying burner and convert to sUSD
            target: address = self.receiver
            ERC20(SEUR).transfer(target, amount)
            UnderlyingBurner(target).convert_synth(SEUR_CURRENCY_KEY, amount)
        else:
            registry_swap: address = AddressProvider(ADDRESS_PROVIDER).get_address(2)
            swap_for: address = self.swap_for[coin]
            if swap_for != ZERO_ADDRESS:
                # sometimes an intermediate swap is required to get to sEUR
                self._swap(registry_swap, coin, swap_for, amount, self)
                coin = swap_for
                amount = ERC20(coin).balanceOf(self)

            # swap to sEUR
            self._swap(registry_swap, coin, SEUR, amount, self)

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