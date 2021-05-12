# @version 0.2.12

from vyper.interfaces import ERC20


CRV: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
BRIDGE: constant(address) = 0xC564EE9f21Ed8A2d8E7e76c085740d5e4c5FaFbE


@external
def checkpoint() -> bool:
    amount: uint256 = ERC20(CRV).balanceOf(self)
    ERC20(CRV).transfer(BRIDGE, amount)
    return True