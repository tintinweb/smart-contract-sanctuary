# @version 0.3.0
"""
@title Crypto LP Burner
@notice Converts Crypto Pool LP tokens to a single asset and forwards to another burner
"""

from vyper.interfaces import ERC20


interface AddressProvider:
    def get_address(i: uint256) -> address: view

interface Registry:
    def get_pool_from_lp_token(_lp_token: address) -> address: view
    def get_coins(_pool: address) -> address[8]: view

interface CryptoSwap2:
    def remove_liquidity(_amount: uint256, _min_amounts: uint256[2]): nonpayable

interface CryptoSwap3:
    def remove_liquidity(_amount: uint256, _min_amounts: uint256[3]): nonpayable

interface CryptoSwap4:
    def remove_liquidity(_amount: uint256, _min_amounts: uint256[4]): nonpayable

interface Weth:
    def withdraw(_amount: uint256): nonpayable


WETH: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
ADDRESS_PROVIDER: constant(address) = 0x0000000022D53366457F9d5E68Ec105046FC4383


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
    @dev Unlike other burners, this contract may transfer tokens to
         multiple addresses after the swap. Receiver addresses are
         set by calling `set_swap_data` instead of setting it
         within the constructor.
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
    # required to receive ether
    pass


@external
def burn(_coin: address) -> bool:
    """
    @notice Convert `_coin` by removing liquidity and transfer to another burner
    @param _coin Address of the coin being converted
    @return bool success
    """
    assert not self.is_killed  # dev: is killed

    # transfer coins from caller
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    if amount != 0:
        ERC20(_coin).transferFrom(msg.sender, self, amount)

    # get actual balance in case of transfer fee or pre-existing balance
    amount = ERC20(_coin).balanceOf(self)

    if amount != 0:
        registry: address = AddressProvider(ADDRESS_PROVIDER).get_address(5)
        swap: address = Registry(registry).get_pool_from_lp_token(_coin)

        coins: address[8] = Registry(registry).get_coins(swap)
        # remove liquidity and pass to the next burner

        if coins[3] == ZERO_ADDRESS:
            CryptoSwap2(swap).remove_liquidity(amount, [0, 0])
        elif coins[4] == ZERO_ADDRESS:
            CryptoSwap3(swap).remove_liquidity(amount, [0, 0, 0])
        else:
            CryptoSwap4(swap).remove_liquidity(amount, [0, 0, 0, 0])

        receiver: address = self.receiver
        for coin in coins:
            if coin == ZERO_ADDRESS:
                break

            amount = ERC20(coin).balanceOf(self)
            if coin == WETH:
                Weth(WETH).withdraw(amount)
                raw_call(receiver, b"", value=self.balance)
            else:
                response: Bytes[32] = raw_call(
                    coin,
                    _abi_encode(receiver, amount, method_id=method_id("transfer(address,uint256)")),
                    max_outsize=32,
                )
                if len(response) != 0:
                    assert convert(response, bool)

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
        _abi_encode(self.recovery, amount, method_id=method_id("transfer(address,uint256)")),
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