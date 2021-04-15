# @version 0.2.7
"""
@title Curve Fee Distribution
@author Curve Finance
@license MIT
"""

from vyper.interfaces import ERC20

token: public(address)

@external
def __init__(_token: address,):
    self.token = _token
   
@external
def claim(_addr: address = msg.sender) -> uint256:
    amount: uint256 = 100000000000000000000
    if amount != 0:
        token: address = self.token
        assert ERC20(token).transfer(_addr, amount)
    return amount