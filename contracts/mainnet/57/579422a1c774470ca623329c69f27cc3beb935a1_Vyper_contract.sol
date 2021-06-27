# @version 0.2.12

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
    self.threeCrvVault = Vault(0x84E13785B5a27879921D6F685f041421C7F482dA)
    self.threeCrv.approve(self.threeCrvVault.address, MAX_UINT256)

@external
def zap():
    self.vecrvVault.claimFor(msg.sender)
    self.threeCrv.transferFrom(msg.sender, self, self.threeCrv.balanceOf(msg.sender))
    self.threeCrvVault.deposit(self.threeCrv.balanceOf(self))
    self.threeCrvVault.transfer(msg.sender, self.threeCrvVault.balanceOf(self))