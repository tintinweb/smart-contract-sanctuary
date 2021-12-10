# @version 0.3.0
"""
@notice Anyswap v4 Bridger
@dev FTM -> BSC
"""


interface AnySwap:
    def anySwapOutUnderlying(_token: address, _to: address, _amount: uint256, _chain_id: uint256): nonpayable

interface ERC20:
    def approve(_spender: address, _amount: uint256): nonpayable
    def transferFrom(_from: address, _to: address, _amount: uint256): nonpayable


BRIDGE: constant(address) = 0xb576C9403f39829565BD6051695E2AC7Ecf850E2


@view
@external
def cost() -> uint256:
    return 0


@external
def bridge(_token: address, _dst: address, _amount: uint256):
    ERC20(_token).transferFrom(msg.sender, self, _amount)
    ERC20(_token).approve(BRIDGE, _amount)

    # transfer to BSC
    AnySwap(BRIDGE).anySwapOutUnderlying(_token, _dst, _amount, 56)