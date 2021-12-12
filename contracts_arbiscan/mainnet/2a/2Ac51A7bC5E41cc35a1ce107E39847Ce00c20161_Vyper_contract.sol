# @version 0.3.0
"""
@title LP Burner
"""

from vyper.interfaces import ERC20


interface Registry:
    def get_pool_from_lp_token(_token: address) -> address: view
    def get_coins(_swap: address) -> address[8]: view

interface AddressProvider:
    def get_registry() -> address: view

interface StableSwap2:
    def remove_liquidity(_amount: uint256, _min_amounts: uint256[2]): nonpayable

interface StableSwap3:
    def remove_liquidity(_amount: uint256, _min_amounts: uint256[3]): nonpayable

interface StableSwap4:
    def remove_liquidity(_amount: uint256, _min_amounts: uint256[4]): nonpayable


receiver: public(address)
is_killed: public(bool)

owner: public(address)
future_owner: public(address)

is_approved: HashMap[address, HashMap[address, bool]]

ADDRESS_PROVIDER: constant(address) = 0x0000000022D53366457F9d5E68Ec105046FC4383


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

    registry: address = AddressProvider(ADDRESS_PROVIDER).get_registry()

    swap: address = Registry(registry).get_pool_from_lp_token(_coin)
    coins: address[8] = Registry(registry).get_coins(swap)

    if coins[2] == ZERO_ADDRESS:
        StableSwap2(swap).remove_liquidity(amount, [0, 0])
    elif coins[3] == ZERO_ADDRESS:
        StableSwap3(swap).remove_liquidity(amount, [0, 0, 0])
    else:
        StableSwap4(swap).remove_liquidity(amount, [0, 0, 0, 0])

    for coin in coins:
        if coin == ZERO_ADDRESS:
            break
        amount = ERC20(coin).balanceOf(self)
        if amount > 0:
            ERC20(coin).transfer(self.receiver, amount)

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