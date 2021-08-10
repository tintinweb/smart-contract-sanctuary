# @version 0.2.7
"""
@title Curve StableSwap Proxy
@author Curve Finance
@license MIT
"""

interface Burner:
    def burn(_coin: address) -> bool: payable

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
    def set_aave_referral(referral_code: uint256): nonpayable
    def donate_admin_fees(): nonpayable

interface AddressProvider:
    def get_registry() -> address: view

interface Registry:
    def get_decimals(_pool: address) -> uint256[8]: view
    def get_underlying_balances(_pool: address) -> uint256[8]: view


MAX_COINS: constant(int128) = 8
ADDRESS_PROVIDER: constant(address) = 0x0000000022D53366457F9d5E68Ec105046FC4383

struct PoolInfo:
    balances: uint256[MAX_COINS]
    underlying_balances: uint256[MAX_COINS]
    decimals: uint256[MAX_COINS]
    underlying_decimals: uint256[MAX_COINS]
    lp_token: address
    A: uint256
    fee: uint256

event CommitAdmins:
    ownership_admin: address
    parameter_admin: address
    emergency_admin: address

event ApplyAdmins:
    ownership_admin: address
    parameter_admin: address
    emergency_admin: address

event AddBurner:
    burner: address


ownership_admin: public(address)
parameter_admin: public(address)
emergency_admin: public(address)

future_ownership_admin: public(address)
future_parameter_admin: public(address)
future_emergency_admin: public(address)

min_asymmetries: public(HashMap[address, uint256])

burners: public(HashMap[address, address])
burner_kill: public(bool)

# pool -> caller -> can call `donate_admin_fees`
donate_approval: public(HashMap[address, HashMap[address, bool]])

@external
def __init__(
    _ownership_admin: address,
    _parameter_admin: address,
    _emergency_admin: address
):
    self.ownership_admin = _ownership_admin
    self.parameter_admin = _parameter_admin
    self.emergency_admin = _emergency_admin


@payable
@external
def __default__():
    # required to receive ETH fees
    pass


@external
def commit_set_admins(_o_admin: address, _p_admin: address, _e_admin: address):
    """
    @notice Set ownership admin to `_o_admin`, parameter admin to `_p_admin` and emergency admin to `_e_admin`
    @param _o_admin Ownership admin
    @param _p_admin Parameter admin
    @param _e_admin Emergency admin
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    self.future_ownership_admin = _o_admin
    self.future_parameter_admin = _p_admin
    self.future_emergency_admin = _e_admin

    log CommitAdmins(_o_admin, _p_admin, _e_admin)


@external
def apply_set_admins():
    """
    @notice Apply the effects of `commit_set_admins`
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    _o_admin: address = self.future_ownership_admin
    _p_admin: address = self.future_parameter_admin
    _e_admin: address = self.future_emergency_admin
    self.ownership_admin = _o_admin
    self.parameter_admin = _p_admin
    self.emergency_admin = _e_admin

    log ApplyAdmins(_o_admin, _p_admin, _e_admin)


@internal
def _set_burner(_coin: address, _burner: address):
    old_burner: address = self.burners[_coin]
    if _coin != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
        if old_burner != ZERO_ADDRESS:
            # revoke approval on previous burner
            response: Bytes[32] = raw_call(
                _coin,
                concat(
                    method_id("approve(address,uint256)"),
                    convert(old_burner, bytes32),
                    convert(0, bytes32),
                ),
                max_outsize=32,
            )
            if len(response) != 0:
                assert convert(response, bool)

        if _burner != ZERO_ADDRESS:
            # infinite approval for current burner
            response: Bytes[32] = raw_call(
                _coin,
                concat(
                    method_id("approve(address,uint256)"),
                    convert(_burner, bytes32),
                    convert(MAX_UINT256, bytes32),
                ),
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
    assert msg.sender == self.ownership_admin, "Access denied"

    self._set_burner(_coin, _burner)


@external
@nonreentrant('lock')
def set_many_burners(_coins: address[20], _burners: address[20]):
    """
    @notice Set burner of `_coin` to `_burner` address
    @param _coins Token address
    @param _burners Burner contract address
    """
    assert msg.sender == self.ownership_admin, "Access denied"

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
    assert msg.sender == self.emergency_admin, "Access denied"
    Curve(_pool).kill_me()


@external
@nonreentrant('lock')
def unkill_me(_pool: address):
    """
    @notice Unpause the pool `_pool`, re-enabling all functionality
    @param _pool Pool address to unpause
    """
    assert msg.sender == self.emergency_admin or msg.sender == self.ownership_admin, "Access denied"
    Curve(_pool).unkill_me()


@external
def set_burner_kill(_is_killed: bool):
    """
    @notice Kill or unkill `burn` functionality
    @param _is_killed Burner kill status
    """
    assert msg.sender == self.emergency_admin or msg.sender == self.ownership_admin, "Access denied"
    self.burner_kill = _is_killed


@external
@nonreentrant('lock')
def commit_transfer_ownership(_pool: address, new_owner: address):
    """
    @notice Transfer ownership for `_pool` pool to `new_owner` address
    @param _pool Pool which ownership is to be transferred
    @param new_owner New pool owner address
    """
    assert msg.sender == self.ownership_admin, "Access denied"
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
    assert msg.sender in [self.ownership_admin, self.emergency_admin], "Access denied"
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
    assert msg.sender == self.parameter_admin, "Access denied"
    self.min_asymmetries[_pool] = min_asymmetry
    Curve(_pool).commit_new_parameters(amplification, new_fee, new_admin_fee)  # dev: if implemented by the pool


@external
@nonreentrant('lock')
def apply_new_parameters(_pool: address):
    """
    @notice Apply new parameters for `_pool` pool
    @dev Only callable by an EOA
    @param _pool Pool address
    """
    assert msg.sender == tx.origin

    min_asymmetry: uint256 = self.min_asymmetries[_pool]

    if min_asymmetry > 0:
        registry: address = AddressProvider(ADDRESS_PROVIDER).get_registry()
        underlying_balances: uint256[8] = Registry(registry).get_underlying_balances(_pool)
        decimals: uint256[8] = Registry(registry).get_decimals(_pool)

        balances: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
        # asymmetry = prod(x_i) / (sum(x_i) / N) ** N =
        # = prod( (N * x_i) / sum(x_j) )
        S: uint256 = 0
        N: uint256 = 0
        for i in range(MAX_COINS):
            x: uint256 = underlying_balances[i]
            if x == 0:
                N = i
                break
            x *= 10 ** (18 - decimals[i])
            balances[i] = x
            S += x

        asymmetry: uint256 = N * 10 ** 18
        for i in range(MAX_COINS):
            x: uint256 = balances[i]
            if x == 0:
                break
            asymmetry = asymmetry * x / S

        assert asymmetry >= min_asymmetry, "Unsafe to apply"

    Curve(_pool).apply_new_parameters()  # dev: if implemented by the pool


@external
@nonreentrant('lock')
def revert_new_parameters(_pool: address):
    """
    @notice Revert comitted new parameters for `_pool` pool
    @param _pool Pool address
    """
    assert msg.sender in [self.ownership_admin, self.parameter_admin, self.emergency_admin], "Access denied"
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
    assert msg.sender == self.parameter_admin, "Access denied"
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
    assert msg.sender == self.parameter_admin, "Access denied"
    Curve(_pool).ramp_A(_future_A, _future_time)


@external
@nonreentrant('lock')
def stop_ramp_A(_pool: address):
    """
    @notice Stop gradually increasing A of `_pool`
    @param _pool Pool address
    """
    assert msg.sender in [self.parameter_admin, self.emergency_admin], "Access denied"
    Curve(_pool).stop_ramp_A()


@external
@nonreentrant('lock')
def set_aave_referral(_pool: address, referral_code: uint256):
    """
    @notice Set Aave referral for undelying tokens of `_pool` to `referral_code`
    @param _pool Pool address
    @param referral_code Aave referral code
    """
    assert msg.sender == self.ownership_admin, "Access denied"
    Curve(_pool).set_aave_referral(referral_code)  # dev: if implemented by the pool


@external
def set_donate_approval(_pool: address, _caller: address, _is_approved: bool):
    """
    @notice Set approval of `_caller` to donate admin fees for `_pool`
    @param _pool Pool address
    @param _caller Adddress to set approval for
    @param _is_approved Approval status
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    self.donate_approval[_pool][_caller] = _is_approved


@external
@nonreentrant('lock')
def donate_admin_fees(_pool: address):
    """
    @notice Donate admin fees of `_pool` pool
    @param _pool Pool address
    """
    if msg.sender != self.ownership_admin:
        assert self.donate_approval[_pool][msg.sender], "Access denied"

    Curve(_pool).donate_admin_fees()  # dev: if implemented by the pool