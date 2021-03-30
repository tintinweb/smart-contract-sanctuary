# @version ^0.2.6


interface csmerc20:
    def transfer(_to : address, _value : uint256) -> bool: nonpayable
    def approve(_spender : address, _value : uint256) -> bool: nonpayable
    def transferFrom(_from : address, _to : address, _value : uint256) -> bool: nonpayable
    def balanceOf(_account: address) -> uint256: view
    def allowance(owner: address, spender: address) -> uint256: view

event Buy:
    buyer: indexed(address)
    value: uint256

event Sell:
    seller: indexed(address)
    value: uint256

event Aprobado:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256


token_address: constant(address) = 0x51F1Ec421f760A8B3e0c1f8b3Ee260F183c6a720
owner: address

@external
def __init__():
    self.owner = msg.sender

@external
@payable
def buy():
    # The price of this ICO is 1 eth == 1 CSMtoken
    assert msg.value != 0, 'You are not sending ethers'    # Sender must send ether to buy CSM
    assert csmerc20(token_address).balanceOf(self) >= msg.value, 'Contract does not have that liquidity'  # Contract must have the sufficient liquidity
    csmerc20(token_address).transfer(msg.sender, msg.value)
    log Buy(msg.sender, msg.value)

@external
def aprobar(_amount: uint256):

    csmerc20(token_address).approve(self, _amount)
    log Aprobado(msg.sender, self, _amount)

@external
def sell(amountTokens: uint256):
    assert csmerc20(token_address).allowance(msg.sender, self) >= amountTokens, 'Insufficient allowance'
    assert self.balance >= amountTokens, 'Contract lacks of Eth'
    csmerc20(token_address).transferFrom(msg.sender, self, amountTokens)
    send(msg.sender, amountTokens)
    log Sell(msg.sender, amountTokens)