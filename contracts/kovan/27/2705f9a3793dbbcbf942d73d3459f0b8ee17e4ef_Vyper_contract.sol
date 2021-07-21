# @version 0.2.12

from vyper.interfaces import ERC20
N_ALL_COINS: constant(int128) = 4
fee: public(uint256)  

@external
def __init__(
  _fee: uint256
):
    self.fee = _fee
   

@external
@nonreentrant('lock')
def add_liquidity(amounts: uint256[N_ALL_COINS], min_mint_amount: uint256) -> uint256:
    self.fee = 5
    return 5