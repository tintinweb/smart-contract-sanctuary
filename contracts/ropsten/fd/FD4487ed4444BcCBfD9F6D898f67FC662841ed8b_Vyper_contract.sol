# @version 0.2.12
from vyper.interfaces import ERC20


event Test__Liquidated:
    amount: uint256
    ust_recipient: address


SINKHOLE: constant(address) = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF
STETH_TOKEN: constant(address) = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84


@external
def liquidate(ust_recipient: address) -> uint256:
    steth_amount: uint256 = ERC20(STETH_TOKEN).balanceOf(self)
    ERC20(STETH_TOKEN).transfer(SINKHOLE, steth_amount)
    log Test__Liquidated(steth_amount, ust_recipient)
    return 42 * 10**18