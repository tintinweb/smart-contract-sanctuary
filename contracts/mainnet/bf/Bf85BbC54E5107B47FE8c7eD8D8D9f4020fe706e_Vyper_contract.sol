# @version 0.2.7

from vyper.interfaces import ERC20


interface VestingEscrow:
    def balanceOf(addr: address) -> uint256: view
    def claim(addr: address): nonpayable


interface Vault:
    def deposit(amount: uint256): nonpayable
    def transfer(addr: address, amount: uint256) -> bool: nonpayable
    def balanceOf(addr: address) -> uint256: view


crv: public(ERC20)
vault: public(Vault)
vesting: public(VestingEscrow)


@external
def __init__():
    self.crv = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52)
    self.vault = Vault(0xc5bDdf9843308380375a611c18B50Fb9341f502A)
    self.vesting = VestingEscrow(0x575CCD8e2D300e2377B43478339E364000318E2c)
    self.crv.approve(self.vault.address, MAX_UINT256)


@external
def zap():
    self.vesting.claim(msg.sender)
    self.crv.transferFrom(msg.sender, self, self.crv.balanceOf(msg.sender))
    self.vault.deposit(self.crv.balanceOf(self))
    self.vault.transfer(msg.sender, self.vault.balanceOf(self))