# @version 0.2.5
"""
@title Curve StableSwap Proxy
@author Curve Finance
@license MIT
"""

from vyper.interfaces import ERC20

interface Burner:
    def burn() -> bool: nonpayable
    def burn_eth() -> bool: payable
    def burn_coin(_coin: address)-> bool: nonpayable

interface Curve:
    def withdraw_admin_fees(): nonpayable
    def kill_me(): nonpayable
    def unkill_me(): nonpayable
    def commit_transfer_ownership(new_owner: address): nonpayable
    def apply_transfer_ownership(): nonpayable
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


interface Registry:
    def get_pool_info(_pool: address) -> PoolInfo: view


MAX_COINS: constant(int128) = 8

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

registry: Registry


@external
def __init__(_registry: address, _ownership_admin: address, _parameter_admin: address, _emergency_admin: address):
    self.ownership_admin = _ownership_admin
    self.parameter_admin = _parameter_admin
    self.emergency_admin = _emergency_admin
    self.registry = Registry(_registry)


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


@external
@nonreentrant('lock')
def set_burner(_token: address, _burner: address):
    """
    @notice Set burner of `_token` to `_burner` address
    @param _token Token address
    @param _burner Burner contract address
    """
    assert msg.sender == self.emergency_admin, "Access denied"

    _old_burner: address = self.burners[_token]

    if _token != ZERO_ADDRESS:
        if _old_burner != ZERO_ADDRESS:
            ERC20(_token).approve(_old_burner, 0)
        if _burner != ZERO_ADDRESS:
            ERC20(_token).approve(_burner, MAX_UINT256)

    self.burners[_token] = _burner

    log AddBurner(_burner)


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
def burn(_burner: address):
    """
    @notice Burn CRV tokens using `_burner` contract
    @param _burner Burner contract
    """
    Burner(_burner).burn()  # dev: should implement burn()


@external
@nonreentrant('lock')
def burn_coin(_coin: address):
    """
    @notice Burn CRV tokens and buy `_coin`
    @param _coin Coin address
    """
    Burner(self.burners[_coin]).burn_coin(_coin)  # dev: should implement burn_coin()


@external
@payable
@nonreentrant('lock')
def burn_eth():
    """
    @notice Burn the full ETH balance of this contract
    """
    Burner(self.burners[ZERO_ADDRESS]).burn_eth(value=self.balance)  # dev: should implement burn_eth()


@external
@nonreentrant('lock')
def kill_me(_pool: address):
    """
    @notice Pause the pool `_pool` - only remove_liquidity will be callable
    @param _pool Pool address to pause
    """
    assert msg.sender == self.ownership_admin, "Access denied"
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
@nonreentrant('lock')
def commit_transfer_ownership(_pool: address, new_owner: address):
    """
    @notice Transfer ownership for `_pool` pool to `new_owner` address
    @param _pool Pool which ownership is to be transferred
    @param new_owner New pool owner address
    """
    assert msg.sender == self.emergency_admin, "Access denied"
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
def revert_transfer_ownership(_pool: address):
    """
    @notice Revert commited transferring ownership for `_pool`
    @param _pool Pool address
    """
    assert msg.sender == self.ownership_admin, "Access denied"
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
    @param _pool Pool address
    """
    min_asymmetry: uint256 = self.min_asymmetries[_pool]

    if min_asymmetry > 0:
        pool_info: PoolInfo = self.registry.get_pool_info(_pool)
        balances: uint256[MAX_COINS] = empty(uint256[MAX_COINS])
        # asymmetry = prod(x_i) / (sum(x_i) / N) ** N =
        # = prod( (N * x_i) / sum(x_j) )
        S: uint256 = 0
        N: uint256 = 0
        for i in range(MAX_COINS):
            x: uint256 = pool_info.underlying_balances[i]
            if x == 0:
                N = convert(i, uint256)
                break
            x *= 10 ** (18 - pool_info.decimals[i])
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
    assert msg.sender == self.parameter_admin, "Access denied"
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
    assert msg.sender == self.parameter_admin, "Access denied"
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
@nonreentrant('lock')
def donate_admin_fees(_pool: address):
    """
    @notice Donate admin fees of `_pool` pool
    @param _pool Pool address
    """
    assert msg.sender == self.ownership_admin, "Access denied"
    Curve(_pool).donate_admin_fees()  # dev: if implemented by the pool