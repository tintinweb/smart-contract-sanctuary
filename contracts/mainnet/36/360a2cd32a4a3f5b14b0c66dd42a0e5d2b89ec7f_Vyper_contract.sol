# @version 0.2.16

from vyper.interfaces import ERC20


interface HarmonyBridge:
    def lockToken(ethTokenAddr: address, amount: uint256, recipient: address): nonpayable


CRV: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
BRIDGE: constant(address) = 0x2dCCDB493827E15a5dC8f8b72147E6c4A5620857


@external
def __init__():
    ERC20(CRV).approve(BRIDGE, MAX_UINT256)


@external
def checkpoint() -> bool:
    amount: uint256 = ERC20(CRV).balanceOf(self)
    HarmonyBridge(BRIDGE).lockToken(CRV, amount, self)
    return True