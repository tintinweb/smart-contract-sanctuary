# @version 0.2.4

from vyper.interfaces import ERC20

lp_token: public(address)
balanceOf: public(HashMap[address, uint256])
totalSupply: public(uint256)

working_balances: public(HashMap[address, uint256])
working_supply: public(uint256)

@external
def __init__(lp_addr: address):
    self.lp_token = lp_addr
   
@external
@nonreentrant('lock')
def deposit(_value: uint256, addr: address = msg.sender):
    if _value != 0:
        _balance: uint256 = self.balanceOf[addr] + _value
        _supply: uint256 = self.totalSupply + _value
        self.balanceOf[addr] = _balance
        self.totalSupply = _supply
        assert ERC20(self.lp_token).transferFrom(msg.sender, self, _value)

@external
@nonreentrant('lock')
def withdraw(_value: uint256):
    _balance: uint256 = self.balanceOf[msg.sender] - _value
    _supply: uint256 = self.totalSupply - _value
    self.balanceOf[msg.sender] = _balance
    self.totalSupply = _supply
    assert ERC20(self.lp_token).transfer(msg.sender, _value)