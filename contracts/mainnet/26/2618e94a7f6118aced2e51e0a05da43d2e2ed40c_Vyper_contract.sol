# @version 0.3.1
# @author skozin, hostgame, blitz-1306 <[email protected]>
# @licence MIT
from vyper.interfaces import ERC20

BETH_TOKEN: constant(address) = 0x707F9118e33A9B8998beA41dd0d46f38bb963FC8
UST_WRAPPER_TOKEN: constant(address) = 0xa693B19d2931d498c5B318dF961919BB4aee87a5

TERRA_CHAIN_ID: constant(uint256) = 3

# Max value of uint32 integer (4 bytes). Equivalent of 0xFFFFFFFF.
MAX_UINT32: constant(uint256) = 4294967295

# Address of currently used Wormhole token bridge implementation.
wormhole_token_bridge: public(address)

@external
def __init__(wormhole_token_bridge: address):
    assert wormhole_token_bridge != ZERO_ADDRESS, "bridge is zero address"

    self.wormhole_token_bridge = wormhole_token_bridge


# Prepares data and calls `Bridge.transferTokens()`.
#
# First 64 bytes of `_extra_data` argument are reserved for passing 
# `nonce` (first 32 bytes) and `arbiter_fee` (second 32 bytes) values.
#
# Vyper does not support few types (uint16 and uint32), that are available in Solidity.
# We encode a call payload manually for compatibility reasons.
#
# See target method signature: https://etherscan.io/address/0x6c4c12987303b2c94b2c76c612fc5f4d2f0360f7#code#F2#L93
@internal
@payable
def _transfer_asset(_bridge: address, _asset: address, _amount: uint256, _recipient: bytes32, _extra_data: Bytes[1024]):
    nonce: uint256 = 0
    arbiter_fee: uint256 = 0

    if len(_extra_data) >= 32:
        nonce = extract32(_extra_data, 0, output_type=uint256)

        assert nonce <= MAX_UINT32, "nonce exceeds size of uint32 (4 bytes)"

    if len(_extra_data) >= 64:
        arbiter_fee = extract32(_extra_data, 32, output_type=uint256)

    assert ERC20(_asset).approve(_bridge, _amount)

    raw_call(
        _bridge,
        concat(
            method_id('transferTokens(address,uint256,uint16,bytes32,uint256,uint32)'),
            convert(_asset, bytes32),
            convert(_amount, bytes32),
            convert(TERRA_CHAIN_ID, bytes32),
            _recipient,
            convert(arbiter_fee, bytes32),
            convert(nonce, bytes32)
        ),
        value=msg.value
    )


# Submits amount of bETH tokens to Terra address via token bridge.
@external
@payable
def forward_beth(_terra_address: bytes32, _amount: uint256, _extra_data: Bytes[1024]):
    self._transfer_asset(self.wormhole_token_bridge, BETH_TOKEN, _amount, _terra_address, _extra_data)

# Submits amount of UST tokens to Terra address via token bridge.
@external
@payable
def forward_ust(_terra_address: bytes32, _amount: uint256, _extra_data: Bytes[1024]):
    self._transfer_asset(self.wormhole_token_bridge, UST_WRAPPER_TOKEN, _amount, _terra_address, _extra_data)


# Adjusts amount, considering allowed decimals.
# Bridges have some limitations as target chain or token
# might not support an equivalent precision.
#
# Wormhole only supports the precision of 8 decimals.
# See https://etherscan.io/address/0x6c4c12987303b2c94b2c76c612fc5f4d2f0360f7#code#F2#L113
@external
@view
def adjust_amount(_amount: uint256, _decimals: uint256) -> uint256:
    if _decimals > 8:
        mult: uint256 = 10 ** (_decimals - 8)

        return (_amount / mult) * mult

    return _amount