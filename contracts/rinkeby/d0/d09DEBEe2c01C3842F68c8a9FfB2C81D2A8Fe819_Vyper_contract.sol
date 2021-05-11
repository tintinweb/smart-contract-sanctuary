# @version ^0.2.11



interface IERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def allowance(arg0: address, arg1: address) -> uint256: view



StakeHolders: public(int128[3])





@external
def isStakeHolder(_address: address):

  for i in range(2):
    self.StakeHolders[i] = i