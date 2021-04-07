# @version ^0.2.11
# 
#
#
#
#
#
# Events


event Deposit:
    _amount: uint256 
    _msg: bytes32

event Withdrawal:
    _to: bytes32
    _amount: uint256
    _msg: bytes32


interface IERC20:
    def balanceOf(account: address) -> (uint256): view

interface IGateway:
    def mint(_pHash: bytes32, _amount: uint256, _nHash: bytes32, _sig: bytes32) -> uint256: nonpayable
    def burn(_to: bytes32, _amount: uint256) -> uint256: nonpayable

interface IGatewayRegistry:
    def getGatewayBySymbol(_tokenSymbol: String[8]) -> address: view  # (IGateway)
    def getTokenBySymbol(_tokenSymbol: String[8]) -> address: view  # (IERC20)





#Variables
registry: public(address)
owner: public(address)


@external
def setRegistry(reg: address):
    self.registry = reg


@external
def deposit(
    _msg: bytes32,
    _amount: uint256,
    _nHash: bytes32,
    _sig: bytes32
):
    pHash: bytes32  = keccak256(_msg)

    IGatewayAddress: address = IGatewayRegistry(self.registry).getGatewayBySymbol("BTC")

    mintedAmount: uint256  = IGateway(IGatewayAddress).mint(pHash, _amount, _nHash, _sig)

    log Deposit(mintedAmount, _msg)







# # Set up the owner.
@external
def __init__():
    self.owner = msg.sender