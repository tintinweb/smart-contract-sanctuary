# @version 0.2.4


interface ERC20:
    def decimals() -> uint256: view
    def name() -> String[64]: view
    def symbol() -> String[32]: view
    def transfer(to: address, amount: uint256) -> bool: nonpayable
    def transferFrom(spender: address, to: address, amount: uint256) -> bool: nonpayable

name: public(String[64])
MAXTIME: constant(uint256) = 4 * 365 * 86400  # 4 years
symbol: public(String[32])
version: public(String[32])
decimals: public(uint256)
token: public(address)
balanceOf: public(HashMap[address, uint256])

@external
def __init__(token_addr: address, _name: String[64], _symbol: String[32], _version: String[32]):
    self.token = token_addr
    _decimals: uint256 = ERC20(token_addr).decimals()
    self.decimals = _decimals

    self.name = _name
    self.symbol = _symbol
    self.version = _version

@external
def create_lock(_value: uint256, _unlock_time: uint256):
    assert _unlock_time > block.timestamp, "Can only lock until time in the future"
    assert _unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 4 years max"
    self.balanceOf[msg.sender] += _value
    assert ERC20(self.token).transferFrom(msg.sender, self, _value)

@external
def increase_amount(_value: uint256):
    self.balanceOf[msg.sender] += _value
    assert ERC20(self.token).transferFrom(msg.sender, self, _value)

@external
@nonreentrant('lock')
def increase_unlock_time(_unlock_time: uint256):
    unlock_time: uint256 = 10000

@external
@nonreentrant('lock')
def withdraw():
    assert ERC20(self.token).transfer(msg.sender, self.balanceOf[msg.sender])
    self.balanceOf[msg.sender] = 0