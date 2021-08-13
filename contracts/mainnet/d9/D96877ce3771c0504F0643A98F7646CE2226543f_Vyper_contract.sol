# @version 0.2.15
"""
@title Curve LP Burner
@notice Convert Curve LP tokens to a single asset and send to the receiver
"""

from vyper.interfaces import ERC20


interface StableSwap:
    def remove_liquidity_one_coin(_amount: uint256, i: int128, _min_amount: uint256):
        nonpayable

    def coins(index: uint256) -> address:
        view


interface CurveLPToken:
    def minter() -> address:
        view


interface WETH9:
    def deposit():
        payable


struct SwapData:
    pool: address
    result_coin: address


recovery: public(address)
is_killed: public(bool)
receiver: public(address)
owner: public(address)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)
burnable_coins: public(HashMap[address, SwapData])


ETH:constant(address) =  0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
WETH:constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2


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
    @notice Convert `_coin` by removing liquidity and send to receiver
    @param _coin Address of the coin being converted
    @return bool success
    """
    assert not self.is_killed  # dev: is killed
    assert self.burnable_coins[_coin].pool != ZERO_ADDRESS, "token not burnable"

    # transfer coins from caller
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    if amount != 0:
        ERC20(_coin).transferFrom(msg.sender, self, amount)

    # get actual balance in case of transfer fee or pre-existing balance
    amount = ERC20(_coin).balanceOf(self)

    if amount != 0:
        # remove liquidity and pass to the next burner
        stable_swap_address: address = self.burnable_coins[_coin].pool
        result_coin_address: address = self.burnable_coins[_coin].result_coin
        StableSwap(stable_swap_address).remove_liquidity_one_coin(amount, 0, 0)
        # wrap eth into weth before sending it to receiver
        if result_coin_address == ETH:
            amount = self.balance
            WETH9(WETH).deposit(value=amount)
            result_coin_address = WETH
        # move resultalt token to receiver
        amount = ERC20(result_coin_address).balanceOf(self)
        response: Bytes[32] = raw_call(
            result_coin_address,
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
def add_swap_data(_coin: address) -> bool:
    """
    @notice allow more Curve LP Tokens to be burned
    @param _coin Curve LP token
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    stable_swap_address: address = CurveLPToken(_coin).minter()
    assert stable_swap_address != ZERO_ADDRESS
    self.burnable_coins[_coin].pool = stable_swap_address
    result_coin: address = StableSwap(stable_swap_address).coins(0)
    assert result_coin != ZERO_ADDRESS
    self.burnable_coins[_coin].result_coin = result_coin
    ERC20(_coin).approve(stable_swap_address, MAX_UINT256)
    return True


@external
def add_old_swap_data(_coin: address, _pool: address, _result_coin: address) -> bool:
    """
    @notice allow more Curve LP Tokens to be burned, this function is for old curve lp coin that has no minter function
    @param _coin Curve LP token
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    self.burnable_coins[_coin].pool = _pool
    self.burnable_coins[_coin].result_coin = _result_coin
    ERC20(_coin).approve(_pool, MAX_UINT256)
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


@external
@payable
def __default__():
    pass