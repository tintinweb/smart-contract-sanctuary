# @version 0.3.0
"""
@title Curve Sidechain StableSwap Proxy
@author Curve Finance
@license MIT
"""

from vyper.interfaces import ERC20

interface Burner:
    def burn(_coin: address) -> bool: payable

interface Bridger:
    def bridge(_coin: address) -> bool: nonpayable
    def set_root_receiver(_receiver: address): nonpayable

interface Curve:
    def withdraw_admin_fees(): nonpayable
    def kill_me(): nonpayable
    def unkill_me(): nonpayable
    def commit_transfer_ownership(new_owner: address): nonpayable
    def apply_transfer_ownership(): nonpayable
    def accept_transfer_ownership(): nonpayable
    def revert_transfer_ownership(): nonpayable
    def commit_new_parameters(amplification: uint256, new_fee: uint256, new_admin_fee: uint256): nonpayable
    def apply_new_parameters(): nonpayable
    def revert_new_parameters(): nonpayable
    def commit_new_fee(new_fee: uint256, new_admin_fee: uint256): nonpayable
    def apply_new_fee(): nonpayable
    def ramp_A(_future_A: uint256, _future_time: uint256): nonpayable
    def stop_ramp_A(): nonpayable
    def donate_admin_fees(): nonpayable
    def set_reward_receiver(_receiver: address): nonpayable
    def set_admin_fee_receiver(_receiver: address): nonpayable


interface AddressProvider:
    def get_registry() -> address: view

interface Registry:
    def get_decimals(_pool: address) -> uint256[8]: view
    def get_underlying_balances(_pool: address) -> uint256[8]: view


event AddBurner:
    burner: address

event CommitOwnership:
    admin: address

event ApplyOwnership:
    admin: address


burners: public(HashMap[address, address])
burner_kill: public(bool)

bridging_contract: public(address)
bridge_minimums: public(HashMap[address, uint256])


admin: public(address)
future_admin: public(address)


@external
def __init__(_admin: address, _bridging_contract: address):
    self.admin = _admin
    self.bridging_contract = _bridging_contract


@payable
@external
def __default__():
    # required to receive fees in the native protocol token
    pass


@external
def commit_new_admin(addr: address):
    """
    @notice Transfer ownership of GaugeController to `addr`
    @param addr Address to have ownership transferred to
    """
    assert msg.sender == self.admin  # dev: admin only

    self.future_admin = addr
    log CommitOwnership(addr)


@external
def accept_new_admin():
    """
    @notice Accept a pending ownership transfer
    """
    _admin: address = self.future_admin
    assert msg.sender == _admin  # dev: future admin only

    self.admin = _admin
    log ApplyOwnership(_admin)


@internal
def _set_burner(_coin: address, _burner: address):
    old_burner: address = self.burners[_coin]
    if _coin != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
        if old_burner != ZERO_ADDRESS:
            # revoke approval on previous burner
            response: Bytes[32] = raw_call(
                _coin,
                _abi_encode(old_burner, EMPTY_BYTES32, method_id=method_id("approve(address,uint256)")),
                max_outsize=32,
            )
            if len(response) != 0:
                assert convert(response, bool)

        if _burner != ZERO_ADDRESS:
            # infinite approval for current burner
            response: Bytes[32] = raw_call(
                _coin,
                _abi_encode(_burner, MAX_UINT256, method_id=method_id("approve(address,uint256)")),
                max_outsize=32,
            )
            if len(response) != 0:
                assert convert(response, bool)

    self.burners[_coin] = _burner

    log AddBurner(_burner)


@external
@nonreentrant('lock')
def set_burner(_coin: address, _burner: address):
    """
    @notice Set burner of `_coin` to `_burner` address
    @param _coin Token address
    @param _burner Burner contract address
    """
    assert msg.sender == self.admin, "Access denied"

    self._set_burner(_coin, _burner)


@external
@nonreentrant('lock')
def set_many_burners(_coins: address[20], _burners: address[20]):
    """
    @notice Set burner of `_coin` to `_burner` address
    @param _coins Token address
    @param _burners Burner contract address
    """
    assert msg.sender == self.admin, "Access denied"

    for i in range(20):
        coin: address = _coins[i]
        if coin == ZERO_ADDRESS:
            break
        self._set_burner(coin, _burners[i])


@external
@nonreentrant('lock')
def withdraw_admin_fees(_pool: address):
    """
    @notice Withdraw admin fees from `_pool`
    @param _pool Pool address to withdraw admin fees from
    """
    Curve(_pool).withdraw_admin_fees()


@external
@nonreentrant('lock')
def withdraw_many(_pools: address[20]):
    """
    @notice Withdraw admin fees from multiple pools
    @param _pools List of pool address to withdraw admin fees from
    """
    for pool in _pools:
        if pool == ZERO_ADDRESS:
            break
        Curve(pool).withdraw_admin_fees()


@external
@nonreentrant('burn')
def burn(_coin: address):
    """
    @notice Burn accrued `_coin` via a preset burner
    @dev Only callable by an EOA to prevent flashloan exploits
    @param _coin Coin address
    """
    assert tx.origin == msg.sender
    assert not self.burner_kill

    _value: uint256 = 0
    if _coin == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
        _value = self.balance

    Burner(self.burners[_coin]).burn(_coin, value=_value)  # dev: should implement burn()


@external
@nonreentrant('burn')
def burn_many(_coins: address[20]):
    """
    @notice Burn accrued admin fees from multiple coins
    @dev Only callable by an EOA to prevent flashloan exploits
    @param _coins List of coin addresses
    """
    assert tx.origin == msg.sender
    assert not self.burner_kill

    for coin in _coins:
        if coin == ZERO_ADDRESS:
            break

        _value: uint256 = 0
        if coin == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
            _value = self.balance

        Burner(self.burners[coin]).burn(coin, value=_value)  # dev: should implement burn()


@external
@nonreentrant('lock')
def kill_me(_pool: address):
    """
    @notice Pause the pool `_pool` - only remove_liquidity will be callable
    @param _pool Pool address to pause
    """
    assert msg.sender == self.admin, "Access denied"
    Curve(_pool).kill_me()


@external
@nonreentrant('lock')
def unkill_me(_pool: address):
    """
    @notice Unpause the pool `_pool`, re-enabling all functionality
    @param _pool Pool address to unpause
    """
    assert msg.sender == self.admin, "Access denied"
    Curve(_pool).unkill_me()


@external
def set_burner_kill(_is_killed: bool):
    """
    @notice Kill or unkill `burn` functionality
    @param _is_killed Burner kill status
    """
    assert msg.sender == self.admin, "Access denied"
    self.burner_kill = _is_killed


@external
@nonreentrant('lock')
def commit_transfer_ownership(_pool: address, new_owner: address):
    """
    @notice Transfer ownership for `_pool` pool to `new_owner` address
    @param _pool Pool which ownership is to be transferred
    @param new_owner New pool owner address
    """
    assert msg.sender == self.admin, "Access denied"
    Curve(_pool).commit_transfer_ownership(new_owner)


@external
@nonreentrant('lock')
def apply_transfer_ownership(_pool: address):
    """
    @notice Apply transferring ownership of `_pool`
    @param _pool Pool address
    """
    Curve(_pool).apply_transfer_ownership()


@external
@nonreentrant('lock')
def accept_transfer_ownership(_pool: address):
    """
    @notice Apply transferring ownership of `_pool`
    @param _pool Pool address
    """
    Curve(_pool).accept_transfer_ownership()


@external
@nonreentrant('lock')
def revert_transfer_ownership(_pool: address):
    """
    @notice Revert commited transferring ownership for `_pool`
    @param _pool Pool address
    """
    assert msg.sender == self.admin, "Access denied"
    Curve(_pool).revert_transfer_ownership()


@external
@nonreentrant('lock')
def commit_new_parameters(_pool: address,
                          amplification: uint256,
                          new_fee: uint256,
                          new_admin_fee: uint256,
                          min_asymmetry: uint256):
    """
    @notice Commit new parameters for `_pool`, A: `amplification`, fee: `new_fee` and admin fee: `new_admin_fee`
    @param _pool Pool address
    @param amplification Amplification coefficient
    @param new_fee New fee
    @param new_admin_fee New admin fee
    @param min_asymmetry Minimal asymmetry factor allowed.
            Asymmetry factor is:
            Prod(balances) / (Sum(balances) / N) ** N
    """
    assert msg.sender == self.admin, "Access denied"
    Curve(_pool).commit_new_parameters(amplification, new_fee, new_admin_fee)  # dev: if implemented by the pool


@external
@nonreentrant('lock')
def apply_new_parameters(_pool: address):
    """
    @notice Apply new parameters for `_pool` pool
    @dev Only callable by an EOA
    @param _pool Pool address
    """
    assert msg.sender == self.admin, "Access denied"
    Curve(_pool).apply_new_parameters()  # dev: if implemented by the pool


@external
@nonreentrant('lock')
def revert_new_parameters(_pool: address):
    """
    @notice Revert comitted new parameters for `_pool` pool
    @param _pool Pool address
    """
    assert msg.sender == self.admin, "Access denied"
    Curve(_pool).revert_new_parameters()  # dev: if implemented by the pool


@external
@nonreentrant('lock')
def commit_new_fee(_pool: address, new_fee: uint256, new_admin_fee: uint256):
    """
    @notice Commit new fees for `_pool` pool, fee: `new_fee` and admin fee: `new_admin_fee`
    @param _pool Pool address
    @param new_fee New fee
    @param new_admin_fee New admin fee
    """
    assert msg.sender == self.admin, "Access denied"
    Curve(_pool).commit_new_fee(new_fee, new_admin_fee)


@external
@nonreentrant('lock')
def apply_new_fee(_pool: address):
    """
    @notice Apply new fees for `_pool` pool
    @param _pool Pool address
    """
    Curve(_pool).apply_new_fee()


@external
@nonreentrant('lock')
def ramp_A(_pool: address, _future_A: uint256, _future_time: uint256):
    """
    @notice Start gradually increasing A of `_pool` reaching `_future_A` at `_future_time` time
    @param _pool Pool address
    @param _future_A Future A
    @param _future_time Future time
    """
    assert msg.sender == self.admin, "Access denied"
    Curve(_pool).ramp_A(_future_A, _future_time)


@external
@nonreentrant('lock')
def stop_ramp_A(_pool: address):
    """
    @notice Stop gradually increasing A of `_pool`
    @param _pool Pool address
    """
    assert msg.sender == self.admin, "Access denied"
    Curve(_pool).stop_ramp_A()


@external
@nonreentrant('lock')
def donate_admin_fees(_pool: address):
    """
    @notice Donate admin fees of `_pool` pool
    @param _pool Pool address
    """
    assert msg.sender == self.admin, "Access denied"

    Curve(_pool).donate_admin_fees()  # dev: if implemented by the pool


@external
def set_reward_receiver(_pool: address, _receiver: address):
    assert msg.sender == self.admin, "Access denied"

    Curve(_pool).set_reward_receiver(_receiver)


@external
def set_admin_fee_receiver(_pool: address, _receiver: address):
    assert msg.sender == self.admin, "Access denied"

    Curve(_pool).set_admin_fee_receiver(_receiver)


@external
def set_bridging_contract(_bridging_contract: address):
    assert msg.sender == self.admin, "Access denied"

    self.bridging_contract = _bridging_contract


@external
def set_bridge_minimum(_coin: address, _min_amount: uint256):
    assert msg.sender == self.admin, "Access denied"

    self.bridge_minimums[_coin] = _min_amount


@external
def set_bridge_root_receiver(_receiver: address):
    assert msg.sender == self.admin, "Access denied"
    Bridger(self.bridging_contract).set_root_receiver(_receiver)


@external
def bridge(_coin: address):
    """
    @notice Transfer a coin to the root chain via the bridging contract.
    @dev The contract owner can bridge any token in any quantity,
         other accounts can only bridge approved tokens, where
         the balance exceeds a minimum amount defined by the owner.
         This prevents bridging tokens when the amount is so small
         that claiming on the root chain becomes economically unfeasible.
    @param _coin Address of the coin to be bridged.
    """
    bridging_contract: address = self.bridging_contract
    amount: uint256 = ERC20(_coin).balanceOf(self)
    if amount > 0:
        response: Bytes[32] = raw_call(
            _coin,
            _abi_encode(bridging_contract, amount, method_id=method_id("transfer(address,uint256)")),
            max_outsize=32,
        )

    if msg.sender != self.admin:
        minimum: uint256 = self.bridge_minimums[_coin]
        assert minimum != 0,  "Coin not approved for bridging"
        assert minimum >= ERC20(_coin).balanceOf(bridging_contract), "Balance below minimum bridge amount"

    Bridger(bridging_contract).bridge(_coin)