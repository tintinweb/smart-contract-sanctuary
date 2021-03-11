# @version 0.2.8
"""
@title Unagii ZapStEth
@author stakewith.us
@license AGPL-3.0-or-later
"""


from vyper.interfaces import ERC20

interface ETHVault:
    def token() -> address: view
    def deposit(): payable
    def withdraw(_shares: uint256, _min: uint256): nonpayable

interface StableSwapSTETH:
    def exchange(_i: int128, _j: int128, _dx: uint256, _min_dy: uint256): nonpayable

interface StEth:
    # returns amount of StEth minted
    def submit(_referral: address) -> uint256: payable 

ETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE

ST_ETH: constant(address) = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
# Curve StableSwapSTETH
SWAP: constant(address) = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022

vault: public(address)

@external
def __init__(_vault: address):
    assert ETHVault(_vault).token() == ETH, "!ETH vault"
    self.vault = _vault

@external
@payable
def __default__():
    # Prevent accidental ETH sent from user
    assert msg.sender == self.vault or msg.sender == SWAP, "!(vault or swap)"

@external
@nonreentrant("lock")
def zapStEthIn(_stEthAmount: uint256, _minEth: uint256, _minShares: uint256):
    """
    @notice deposit StETH, exchange to ETH, deposit ETH into vault
    @param _stEthAmount Amount of StETH to deposit
    @param _minEth Minimum ETH to get from exchange
    @param _minShares Minimum Unagii shares to mint
    """
    assert msg.sender == tx.origin, "!EOA"

    assert ERC20(ST_ETH).transferFrom(msg.sender, self, _stEthAmount), "stEth transfer from failed"

    assert ERC20(ST_ETH).approve(SWAP, _stEthAmount), "stEth approve failed"
    StableSwapSTETH(SWAP).exchange(1, 0, _stEthAmount, _minEth)

    ETHVault(self.vault).deposit(value=self.balance)

    shares: uint256 = ERC20(self.vault).balanceOf(self)
    assert shares >= _minShares, "shares < min"

    assert ERC20(self.vault).transfer(msg.sender, shares), "uEth transfer failed"

@external
@nonreentrant("lock")
def zapStEthOut(_shares: uint256, _ethMin: uint256, _stEthMin: uint256):
    """
    @notice withdraw ETH from vault, buy StETH, transfer StETH to msg.sender
    @param _shares Unagii shares to burn
    @param _ethMin Minimum ETH to wtihdraw
    @param _stEthMin Minimum StETH to buy
    """
    assert msg.sender == tx.origin, "!EOA"

    assert ERC20(self.vault).transferFrom(msg.sender, self, _shares), "uEth transfer from failed"
    ETHVault(self.vault).withdraw(_shares, _ethMin)

    # ignore amount of StEth minted
    StEth(ST_ETH).submit(self, value=self.balance)
    # get balance to transfer all StEth including any dust
    stEthBal: uint256 = ERC20(ST_ETH).balanceOf(self) 
    
    assert stEthBal >= _stEthMin, "StEth < min"
    assert ERC20(ST_ETH).transfer(msg.sender, stEthBal), "stEth transfer failed"