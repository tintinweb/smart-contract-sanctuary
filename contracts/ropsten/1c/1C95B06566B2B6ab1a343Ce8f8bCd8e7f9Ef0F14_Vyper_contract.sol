# @version 0.2.12
from vyper.interfaces import ERC20


event Test__Forwarded:
    asset_name: String[100]
    terra_address: bytes32
    amount: uint256
    extra_data: Bytes[1024]


UST_TOKEN: constant(address) = 0xa47c8bf37f92aBed4A126BDA807A7b7498661acD

terra_beth_balances: HashMap[bytes32, uint256]

beth_token: address
bridge: address


@external
def __init__(beth_token: address, bridge: address):
    self.beth_token = beth_token
    self.bridge = bridge


@external
def forward_beth(terra_address: bytes32, amount: uint256, extra_data: Bytes[1024]):
    ERC20(self.beth_token).transfer(self.bridge, amount)
    self.terra_beth_balances[terra_address] += amount
    log Test__Forwarded("bETH", terra_address, amount, extra_data)


@external
def forward_ust(terra_address: bytes32, amount: uint256, extra_data: Bytes[1024]):
    ERC20(UST_TOKEN).transfer(self.bridge, amount)
    log Test__Forwarded("UST", terra_address, amount, extra_data)


@external
@view
def adjust_amount(_amount: uint256, _decimals: uint256) -> uint256:
    mult: uint256 = 10 ** (_decimals - 9)
    return (_amount / mult) * mult


@external
def mock_beth_withdraw(terra_address: bytes32, recepient: address, amount: uint256):
    assert msg.sender == self.bridge
    assert self.terra_beth_balances[terra_address] >= amount
    ERC20(self.beth_token).transferFrom(self.bridge, recepient, amount)
    self.terra_beth_balances[terra_address] -= amount


@external
@view
def terra_beth_balance_of(terra_address: bytes32) -> uint256:
    return self.terra_beth_balances[terra_address]