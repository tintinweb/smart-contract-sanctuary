# @version 0.2.12
# @author skozin <[email protected]>
# @licence MIT
from vyper.interfaces import ERC20


interface ShuttleAsset:
    def burn(amount: uint256, terra_address: bytes32): nonpayable


beth_token: public(address)
beth_token_vault: public(address)
ust_wrapper_token: public(address)


@external
def __init__(beth_token: address, beth_token_vault: address, ust_wrapper_token: address):
    self.beth_token = beth_token
    self.beth_token_vault = beth_token_vault
    self.ust_wrapper_token = ust_wrapper_token


@external
def forward_beth(terra_address: bytes32, amount: uint256, extra_data: Bytes[1024]):
    beth_vault: address = self.beth_token_vault
    ERC20(self.beth_token).approve(beth_vault, amount)
    ShuttleAsset(beth_vault).burn(amount, terra_address)


@external
def forward_ust(terra_address: bytes32, amount: uint256, extra_data: Bytes[1024]):
    ShuttleAsset(self.ust_wrapper_token).burn(amount, terra_address)


@external
@view
def adjust_amount(amount: uint256, _decimals: uint256) -> uint256:
    return amount