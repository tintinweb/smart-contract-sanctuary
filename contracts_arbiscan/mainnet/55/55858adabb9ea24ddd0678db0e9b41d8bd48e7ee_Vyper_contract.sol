# @version 0.3.0

from vyper.interfaces import ERC20

@external
def burn(_coin: address) -> bool:
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    ERC20(_coin).transferFrom(msg.sender, 0x7EeAC6CDdbd1D0B8aF061742D41877D7F707289a, amount)
    return True