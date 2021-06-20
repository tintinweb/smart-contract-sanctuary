# @version 0.2.12
"""
@title Crypto LP Burner
@notice Converts Crypto Pool LP tokens to a single asset and forwards to another burner
"""

from vyper.interfaces import ERC20


interface AddressProvider:
    def get_registry() -> address: view

interface Registry:
    def get_pool_from_lp_token(_lp_token: address) -> address: view
    def get_coins(_pool: address) -> address[8]: view

interface StableSwap:
    def remove_liquidity_one_coin(_amount: uint256, i: uint256, _min_amount: uint256): nonpayable


struct SwapData:
    pool: address
    coin: address
    burner: address
    i: uint256


ADDRESS_PROVIDER: constant(address) = 0x0000000022D53366457F9d5E68Ec105046FC4383


swap_data: public(HashMap[address, SwapData])
recovery: public(address)
is_killed: public(bool)

owner: public(address)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)


@external
def __init__(_recovery: address, _owner: address, _emergency_owner: address):
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
    self.recovery = _recovery
    self.owner = _owner
    self.emergency_owner = _emergency_owner



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
        # remove liquidity and pass to the next burner
        swap_data: SwapData = self.swap_data[_coin]
        StableSwap(swap_data.pool).remove_liquidity_one_coin(amount, swap_data.i, 0)

        amount = ERC20(swap_data.coin).balanceOf(self)
        response: Bytes[32] = raw_call(
            swap_data.coin,
            concat(
                method_id("transfer(address,uint256)"),
                convert(swap_data.burner, bytes32),
                convert(amount, bytes32),
            ),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)

    return True


@external
def set_swap_data(_lp_token: address, _coin: address, _burner: address) -> bool:
    """
    @notice Set conversion and transfer data for `_lp_token`
    @param _lp_token LP token address
    @param _coin Underlying coin to remove liquidity in
    @param _burner Burner to transfer `_coin` to
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner

    # find `i` for `_coin` within the pool
    registry: address = AddressProvider(ADDRESS_PROVIDER).get_registry()
    pool: address = Registry(registry).get_pool_from_lp_token(_lp_token)
    coins: address[8] = Registry(registry).get_coins(pool)
    for i in range(8):
        if coins[i] == ZERO_ADDRESS:
            raise
        if coins[i] == _coin:
            self.swap_data[_lp_token] = SwapData({
                pool: pool,
                coin: _coin,
                burner: _burner,
                i: i
            })
            return True
    raise


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