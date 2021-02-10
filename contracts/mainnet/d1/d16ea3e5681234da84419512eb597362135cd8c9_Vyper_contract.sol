# @version 0.2.8
"""
@title yToken Burner
@notice Converts yTokens to USDC and transfers to `UnderlyingBurner`
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
    ) -> uint256: payable

interface yERC20:
    def withdraw(withdrawTokens: uint256): nonpayable
    def token() -> address: view


ADDRESS_PROVIDER: constant(address) = 0x0000000022D53366457F9d5E68Ec105046FC4383

TRIPOOL_COINS: constant(address[3]) = [
    0x6B175474E89094C44Da98b954EedeAC495271d0F,
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
    0xdAC17F958D2ee523a2206206994597C13D831ec7,
]
USDC: constant(address) = TRIPOOL_COINS[1]


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

    # yTUSD -> yUSDC
    self.swap_for[0x73a052500105205d34Daf004eAb301916DA8190f] = 0xd6aD7a6750A7593E092a9B218d66C0A814a3436e
    # yBUSD -> yUSDC
    self.swap_for[0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE] = 0x26EA744E5B887E5205727f55dFBE8685e3b21951


@external
def burn(_coin: address) -> bool:
    """
    @notice Unwrap `_coin` and transfer to the underlying burner
    @param _coin Address of the coin being unwrapped
    @return bool success
    """
    assert not self.is_killed  # dev: is killed

    # transfer coins from caller
    coin: address = _coin
    amount: uint256 = ERC20(coin).balanceOf(msg.sender)
    if amount != 0:
        ERC20(coin).transferFrom(msg.sender, self, amount)

    # get actual balance in case of transfer fee or pre-existing balance
    amount = ERC20(coin).balanceOf(self)

    if amount != 0:
        # if underlying asset is not DAI/USDC/USDT, swap yUSDC prior to unwrap
        swap_for: address = self.swap_for[coin]
        if swap_for != ZERO_ADDRESS:
            registry_swap: address = AddressProvider(ADDRESS_PROVIDER).get_address(2)

            if not self.is_approved[registry_swap][coin]:
                ERC20(coin).approve(registry_swap, MAX_UINT256)
                self.is_approved[registry_swap][coin] = True

            amount = RegistrySwap(registry_swap).exchange_with_best_rate(coin, swap_for, amount, 0)
            coin = swap_for

        # unwrap yTokens for underlying asset
        yERC20(coin).withdraw(amount)
        underlying: address = yERC20(coin).token()

        # transfer underlying to underlying burner
        amount = ERC20(underlying).balanceOf(self)
        response: Bytes[32] = raw_call(
            underlying,
            concat(
                method_id("transfer(address,uint256)"),
                convert(self.receiver, bytes32),
                convert(amount, bytes32),
            ),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)

    return True


@external
def set_swap_for(_coin: address, _swap_for: address) -> bool:
    """
    @notice Set an intermediate coin for coins that do not unwrap
                to DAI/USDC/USDT
    @param _coin Coin being burned
    @param _swap_for Intermediate coin that can be swapped for
                     `_coin` and unwraps to USDC
    @return bool success
    """
    registry: address = AddressProvider(ADDRESS_PROVIDER).get_registry()

    if _swap_for == ZERO_ADDRESS:
        # removing an intermediary swap, ensure the token unwraps to USDC
        assert yERC20(_coin).token() == USDC
    else:
        # adding an intermediary swap, ensure the token does not unwrap to USDC,
        # the target tokens does unwrap to USDC, and a pool exists for the swap
        assert not yERC20(_coin).token() in TRIPOOL_COINS
        assert yERC20(_swap_for).token() == USDC
        assert Registry(registry).find_pool_for_coins(_coin, _swap_for) != ZERO_ADDRESS

    self.swap_for[_coin] = _swap_for

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