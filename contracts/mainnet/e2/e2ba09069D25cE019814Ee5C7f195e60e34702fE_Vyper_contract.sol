# @version 0.2.8
# @notice Replaces yGov, prevents TreasuryVault.toVoters()
from vyper.interfaces import ERC20

ychad: constant(address) = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52


@external
def notifyRewardAmount(reward: uint256):
    raise "reward not accepted"


@external
def sweep(token: address, amount: uint256 = MAX_UINT256):
    assert msg.sender == ychad
    value: uint256 = amount
    if value == MAX_UINT256:
        value = ERC20(token).balanceOf(self)
    assert ERC20(token).transfer(ychad, value)