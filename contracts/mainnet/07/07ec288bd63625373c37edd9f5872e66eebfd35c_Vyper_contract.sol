# @version 0.3.1
"""
@title Simple Staker
@license MIT
@author Wacky Bear
"""
from vyper.interfaces import ERC20


interface Exchange:
    def exchange(_i: int128, _j: int128, _dx: uint256, _min_dy: uint256) -> uint256: nonpayable

interface RewardPool:
    def stakeFor(_for: address, _amount: uint256): nonpayable


CRV: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
CVXCRV: constant(address) = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7

EXCHANGE: constant(address) = 0x9D0464996170c6B9e75eED71c68B99dDEDf279e8
REWARD_POOL: constant(address) = 0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e


@external
def __init__():
    ERC20(CRV).approve(EXCHANGE, MAX_UINT256)
    ERC20(CVXCRV).approve(REWARD_POOL, MAX_UINT256)


@external
def stake(_dx: uint256, _min_dy: uint256, _for: address = msg.sender):
    """
    @notice Exchange CRV for cvxCRV and stake in the reward pool
    """
    assert ERC20(CRV).transferFrom(msg.sender, self, _dx)

    # convert CRV -> cvxCRV and stake in reward pool
    amount: uint256 = Exchange(EXCHANGE).exchange(0, 1, _dx, _min_dy)
    RewardPool(REWARD_POOL).stakeFor(_for, amount)