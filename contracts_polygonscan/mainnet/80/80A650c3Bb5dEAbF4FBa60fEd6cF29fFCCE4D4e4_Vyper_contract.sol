# @version 0.3.0
"""
@title BTC Burner
@notice Converts BTC lending coins to USDC and transfers to `ChildBurner`
"""

from vyper.interfaces import ERC20


interface RegistrySwap:
    def exchange_with_best_rate(
        _from: address,
        _to: address,
        _amount: uint256,
        _expected: uint256
    ) -> uint256: payable

interface CryptoSwap:
    def exchange(i: uint256, j: uint256, dx: uint256, min_dy: uint256): nonpayable

interface StableSwap:
    def remove_liquidity_one_coin(
        _token_amount: uint256,
        i: int128,
        _min_amount: uint256,
        _use_underlying: bool,
    ) -> uint256: nonpayable


interface AddressProvider:
    def get_address(_id: uint256) -> address: view


receiver: public(address)
is_killed: public(bool)

owner: public(address)
future_owner: public(address)

is_approved: HashMap[address, HashMap[address, bool]]

ADDRESS_PROVIDER: constant(address) = 0x0000000022D53366457F9d5E68Ec105046FC4383
AMWBTC: constant(address) = 0x5c2ed810328349100A66B82b78a1791B101C9D61
USDC: constant(address) = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174

ATRICRYPTO3: constant(address) = 0x92215849c439E1f8612b6646060B4E3E5ef822cC
AM3CRV: constant(address) = 0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171

SS_AAVE: constant(address) = 0x445FE580eF8d70FF569aB36e80c647af338db351

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
    ERC20(AMWBTC).approve(ATRICRYPTO3, MAX_UINT256)


@internal
def _approve(_coin: address, _spender: address):
    if not self.is_approved[_spender][_coin]:
        response: Bytes[32] = raw_call(
            _coin,
            _abi_encode(_spender, MAX_UINT256, method_id=method_id("approve(address,uint256)")),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)
        self.is_approved[_spender][_coin] = True


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
    if amount > 0:
        ERC20(_coin).transferFrom(msg.sender, self, amount)

    # get actual balance in case of transfer fee or pre-existing balance
    amount = ERC20(_coin).balanceOf(self)

    # swap for amWBTC
    if _coin != AMWBTC:
        registry_swap: address = AddressProvider(ADDRESS_PROVIDER).get_address(2)
        self._approve(_coin, registry_swap)

        RegistrySwap(registry_swap).exchange_with_best_rate(_coin, AMWBTC, amount, 0)
        amount = ERC20(AMWBTC).balanceOf(self)

    # amWBTC -> am3CRV
    CryptoSwap(ATRICRYPTO3).exchange(1, 0, amount, 0)

    # am3CRV -> USDC
    amount = ERC20(AM3CRV).balanceOf(self)
    StableSwap(SS_AAVE).remove_liquidity_one_coin(amount, 1, 0, True)

    # transfer USDC to receiver
    amount = ERC20(USDC).balanceOf(self)
    ERC20(USDC).transfer(self.receiver, amount)

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