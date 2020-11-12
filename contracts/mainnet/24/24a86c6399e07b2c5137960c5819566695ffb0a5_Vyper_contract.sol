# @version 0.2.7

from vyper.interfaces import ERC20

interface Vault:
    def deposit(amount: uint256): nonpayable
    def transfer(addr: address, amount: uint256) -> bool: nonpayable
    def balanceOf(addr: address) -> uint256: view

interface Claimable:
    def claimFor(recipient: address): nonpayable
    def claim(recipient: address): nonpayable

threeCrv: public(ERC20)
threeCrvVault: public(Vault)
vecrvVault: public(Claimable)

@external
def __init__():
    self.threeCrv = ERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490)
    self.vecrvVault = Claimable(0xc5bDdf9843308380375a611c18B50Fb9341f502A)
    self.threeCrvVault = Vault(0x9cA85572E6A3EbF24dEDd195623F188735A5179f)
    self.threeCrv.approve(self.vecrvVault.address, MAX_UINT256)

@external
def zap():
    before: uint256 = self.threeCrv.balanceOf(msg.sender)
    self.vecrvVault.claimFor(msg.sender)
    after: uint256 = self.threeCrv.balanceOf(msg.sender)
    self.threeCrv.transferFrom(msg.sender, self, after - before)
    self.threeCrvVault.deposit(self.threeCrv.balanceOf(self))
    self.threeCrvVault.transfer(msg.sender, self.threeCrvVault.balanceOf(self))