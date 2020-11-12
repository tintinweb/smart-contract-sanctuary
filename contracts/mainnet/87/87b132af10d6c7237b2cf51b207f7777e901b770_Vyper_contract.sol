# @version 0.2.4

from vyper.interfaces import ERC20

interface Minter:
    def mint_for(gauge_addr: address, _for: address): nonpayable
    def minted(addr: address, gauge: address) -> uint256: view

interface Gauge:
    def claimable_tokens(addr: address) -> uint256: nonpayable
    def integrate_fraction(addr: address) -> uint256: view

interface VestingEscrow:
    def balanceOf(addr: address) -> uint256: view
    def claim(addr: address): nonpayable


crv: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
minter: constant(address) = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0
vesting: constant(address) = 0x575CCD8e2D300e2377B43478339E364000318E2c


@external
def claimable(addr: address, gauges: address[8]) -> uint256:
    total: uint256 = 0
    total += VestingEscrow(vesting).balanceOf(addr)
    for i in range(8):
        if gauges[i] == ZERO_ADDRESS:
            break
        total += Gauge(gauges[i]).claimable_tokens(addr)
    return total


@external
def claim(gauges: address[8]):
    if VestingEscrow(vesting).balanceOf(msg.sender) > 0:
        VestingEscrow(vesting).claim(msg.sender)

    # Enable with minter.toggle_approve_mint(self)
    for i in range(8):
        if gauges[i] == ZERO_ADDRESS:
            break
        Minter(minter).mint_for(gauges[i], msg.sender)