# @version 0.3.1
"""
@title Crypto Pool Factory Single Tx Gauge Depositor
"""
from vyper.interfaces import ERC20


interface EIP2612:
    def permit(
        _owner: address,
        _spender: address,
        _value: uint256,
        _deadline: uint256,
        _v: uint8,
        _r: bytes32,
        _s: bytes32
    ): nonpayable

interface Factory:
    def get_gauge(_pool: address) -> address: view
    def get_token(_pool: address) -> address: view

interface LiquidityGauge:
    def deposit(_value: uint256, _addr: address, _claim_rewards: bool): nonpayable


FACTORY: constant(address) = 0xF18056Bbd320E96A48e3Fbf8bC061322531aac99


is_approved: public(HashMap[address, bool])


@external
def deposit(
    _pool: address,
    _value: uint256,
    _deadline: uint256,
    _v: uint8,
    _r: bytes32,
    _s: bytes32,
):
    """
    @notice Deposit into a gauge with an LP token in a single tx
    @dev Query the LP token for values required to create permit signature
    """
    gauge: address = Factory(FACTORY).get_gauge(_pool)
    lp_token: address = Factory(FACTORY).get_token(_pool)

    EIP2612(lp_token).permit(msg.sender, self, _value, _deadline, _v, _r, _s)
    ERC20(lp_token).transferFrom(msg.sender, self, _value)

    if not self.is_approved[gauge]:
        ERC20(lp_token).approve(gauge, MAX_UINT256)
        self.is_approved[gauge] = True

    LiquidityGauge(gauge).deposit(_value, msg.sender, False)