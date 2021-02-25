# @version 0.2.8
"""
@title Synth Burner
@notice Swaps non-USD denominated assets for synths, converts synths to sUSD,
        and transfers to `UnderlyingBurner`
"""

from vyper.interfaces import ERC20


interface AddressProvider:
    def get_registry() -> address: view
    def get_address(_id: uint256) -> address: view

interface Synth:
    def currencyKey() -> bytes32: nonpayable

interface Registry:
    def find_pool_for_coins(_from: address, _to: address) -> address: view

interface RegistrySwap:
    def exchange_with_best_rate(
        _from: address,
        _to: address,
        _amount: uint256,
        _expected: uint256,
    ) -> uint256: payable

interface UnderlyingBurner:
    def convert_synth(_currency_key: bytes32, _amount: uint256) -> bool: nonpayable


ETH_ADDRESS: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
ADDRESS_PROVIDER: constant(address) = 0x0000000022D53366457F9d5E68Ec105046FC4383

is_approved: HashMap[address, HashMap[address, bool]]
swap_for: public(HashMap[address, address])
currency_keys: public(HashMap[address, bytes32])

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


@payable
@external
def __default__():
    # required to receive ether during intermediate swaps
    pass


@external
def set_swap_for(_coins: address[10], _targets: address[10]) -> bool:
    """
    @notice Set target coins that will be swapped into
    @dev If any target coin is not a synth, it must have already
         had it's own target coin registered
    @param _coins List of coins to be burned
    @param _targets List of coins to be swapped for
    @return bool success
    """
    registry: address = AddressProvider(ADDRESS_PROVIDER).get_registry()
    for i in range(10):
        coin: address = _coins[i]
        if coin == ZERO_ADDRESS:
            break
        target: address = _targets[i]
        assert Registry(registry).find_pool_for_coins(coin, target) != ZERO_ADDRESS

        if self.currency_keys[target] == EMPTY_BYTES32:
            # if target is not a synth, ensure target already has a target set
            assert self.swap_for[target] != ZERO_ADDRESS
        self.swap_for[coin] = target

    return True


@external
@nonreentrant("lock")
def add_synths(_synths: address[10]) -> bool:
    """
    @notice Registry synth token addresses
    @param _synths List of synth tokens to register
    @return bool success
    """
    for synth in _synths:
        if synth == ZERO_ADDRESS:
            break
        # this will revert if `_synth` is not actually a synth
        self.currency_keys[synth] = Synth(synth).currencyKey()

    return True


@payable
@external
@nonreentrant("lock")
def burn(_coin: address) -> bool:
    """
    @notice Receive `_coin` and convert to sUSD via sEUR
    @param _coin Address of the coin being converted
    @return bool success
    """
    assert not self.is_killed  # dev: is killed

    # transfer coins from caller
    amount: uint256 = 0
    if _coin == ETH_ADDRESS:
        amount = self.balance
    else:
        amount = ERC20(_coin).balanceOf(msg.sender)
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

    if amount != 0:
        currency_key: bytes32 = self.currency_keys[_coin]
        if currency_key == EMPTY_BYTES32:
            registry_swap: address = AddressProvider(ADDRESS_PROVIDER).get_address(2)
            eth_amount: uint256 = 0
            if _coin == ETH_ADDRESS:
                eth_amount = amount
            elif not self.is_approved[registry_swap][_coin]:
                response: Bytes[32] = raw_call(
                    _coin,
                    concat(
                        method_id("approve(address,uint256)"),
                        convert(registry_swap, bytes32),
                        convert(MAX_UINT256, bytes32),
                    ),
                    max_outsize=32,
                )
                if len(response) != 0:
                    assert convert(response, bool)
                self.is_approved[registry_swap][_coin] = True

            RegistrySwap(registry_swap).exchange_with_best_rate(
                _coin,
                self.swap_for[_coin],
                amount,
                0,
                value=eth_amount
            )
        else:
            target: address = self.receiver
            ERC20(_coin).transfer(target, amount)
            UnderlyingBurner(target).convert_synth(currency_key, amount)
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

    if _coin == ETH_ADDRESS:
        raw_call(self.recovery, b"", value=self.balance)
    else:
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