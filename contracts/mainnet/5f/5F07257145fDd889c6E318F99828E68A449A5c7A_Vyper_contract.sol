# @version 0.2.4
from vyper.interfaces import ERC20

interface USDT:
    def transferFrom(_from: address, _to: address, _value: uint256): nonpayable
    def approve(_spender: address, _value: uint256): nonpayable

interface yCurveDeposit:
    def add_liquidity(uamounts: uint256[4], min_mint_amount: uint256): nonpayable

interface yVault:
    def deposit(amount: uint256): nonpayable

event Recycled:
    user: indexed(address)
    sent_dai: uint256
    sent_usdc: uint256
    sent_usdt: uint256
    sent_tusd: uint256
    sent_ycrv: uint256
    received_yusd: uint256


ydeposit: constant(address) = 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3
ycrv: constant(address) = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8
yusd: constant(address) = 0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c

dai: constant(address) = 0x6B175474E89094C44Da98b954EedeAC495271d0F
usdc: constant(address) = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
usdt: constant(address) = 0xdAC17F958D2ee523a2206206994597C13D831ec7
tusd: constant(address) = 0x0000000000085d4780B73119b644AE5ecd22b376


@external
def __init__():
    ERC20(dai).approve(ydeposit, MAX_UINT256)
    ERC20(usdc).approve(ydeposit, MAX_UINT256)
    USDT(usdt).approve(ydeposit, MAX_UINT256)
    ERC20(tusd).approve(ydeposit, MAX_UINT256)
    ERC20(ycrv).approve(yusd, MAX_UINT256)


@internal
def recycle_exact_amounts(sender: address, _dai: uint256, _usdc: uint256, _usdt: uint256, _tusd: uint256, _ycrv: uint256):
    if _dai > 0:
        ERC20(dai).transferFrom(sender, self, _dai)
    if _usdc > 0:
        ERC20(usdc).transferFrom(sender, self, _usdc)
    if _usdt > 0:
        USDT(usdt).transferFrom(sender, self, _usdt)
    if _tusd > 0:
        ERC20(tusd).transferFrom(sender, self, _tusd)
    if _ycrv > 0:
        ERC20(ycrv).transferFrom(sender, self, _ycrv)

    deposit_amounts: uint256[4] = [_dai, _usdc, _usdt, _tusd]
    if _dai + _usdc + _usdt + _tusd > 0:
        yCurveDeposit(ydeposit).add_liquidity(deposit_amounts, 0)

    ycrv_balance: uint256 = ERC20(ycrv).balanceOf(self)       
    if ycrv_balance > 0:
        yVault(yusd).deposit(ycrv_balance)

    _yusd: uint256 = ERC20(yusd).balanceOf(self)
    ERC20(yusd).transfer(sender, _yusd)

    assert ERC20(yusd).balanceOf(self) == 0, "leftover yUSD balance"

    log Recycled(sender, _dai, _usdc, _usdt, _tusd, _ycrv, _yusd)


@external
def recycle():
    _dai: uint256 = min(ERC20(dai).balanceOf(msg.sender), ERC20(dai).allowance(msg.sender, self))
    _usdc: uint256 = min(ERC20(usdc).balanceOf(msg.sender), ERC20(usdc).allowance(msg.sender, self))
    _usdt: uint256 = min(ERC20(usdt).balanceOf(msg.sender), ERC20(usdt).allowance(msg.sender, self))
    _tusd: uint256 = min(ERC20(tusd).balanceOf(msg.sender), ERC20(tusd).allowance(msg.sender, self))
    _ycrv: uint256 = min(ERC20(ycrv).balanceOf(msg.sender), ERC20(ycrv).allowance(msg.sender, self))

    self.recycle_exact_amounts(msg.sender, _dai, _usdc, _usdt, _tusd, _ycrv)


@external
def recycle_exact(_dai: uint256, _usdc: uint256, _usdt: uint256, _tusd: uint256, _ycrv: uint256):
    self.recycle_exact_amounts(msg.sender, _dai, _usdc, _usdt, _tusd, _ycrv)