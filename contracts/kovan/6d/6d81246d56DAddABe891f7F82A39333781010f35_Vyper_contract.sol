"""
@title Simple contract for handling aave flash loans
@author NKota
@notice Not intended for production use
"""
#interfaces
from vyper.interfaces import ERC20

interface IERC3156FlashLender:
    def flashLoan(
        receiver: address, 
        token: address,
        amount: uint256, 
        data: bytes32
        ): nonpayable
    def flashFee(
        token: address,
        amount: uint256
        ) -> uint256: view
    def flashSupply(token: address) -> uint256: view

interface IERC3156FlashBorrower:
    def onFlashLoan(
        initiator: address,
        token: address,
        amount: uint256,
        fee: uint256,
        data: bytes32
		) -> bytes32: nonpayable

implements: IERC3156FlashBorrower

#variables
owner: address

#events
event onFlashLoan_event:
    lender: address
    time: uint256
    data: bytes32
event flashSupply_event:
    supply: uint256
event flashFee_event:
    fee: uint256
    
#logic
@payable
@external
def __init__():
    self.owner = msg.sender

@external
def get_supply(
    lender: address, 
    token: address
    ) -> uint256:
    supply: uint256 = IERC3156FlashLender(lender).flashSupply(token)
    log flashSupply_event(supply)
    
    return supply
@external
def get_fee(
    lender: address,
    token: address,
    amount: uint256
    ) -> uint256:
    fee: uint256 = IERC3156FlashLender(lender).flashFee(token, amount)
    log flashFee_event(fee)
    
    return fee
@external
def flashBorrow(
        lender: address,
        token: address,
        amount: uint256,
        data: bytes32 = EMPTY_BYTES32
        ):
    fee: uint256 = IERC3156FlashLender(lender).flashFee(token, amount)
    repay_amount: uint256 = amount + fee
    ERC20(token).approve(lender, repay_amount)
    IERC3156FlashLender(lender).flashLoan(
                                    self, 
                                    token, 
                                    amount,
                                    data
                                    )
@external    
def onFlashLoan(
        initiator: address,
        token: address,
        amount: uint256,
        fee: uint256,
        data: bytes32
		) -> bytes32:
    
    repay_amount: uint256 = amount + fee
    ERC20(token).transfer(msg.sender, repay_amount)
    log onFlashLoan_event(msg.sender, block.timestamp, data)
    
    return keccak256('ERC3156FlashBorrower.onFlashLoan')