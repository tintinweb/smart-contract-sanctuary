# @version 0.2.12


event Transfer:
    sender: indexed(address)
    recipient: indexed(address)
    amount: uint256


event Approval:
    owner: indexed(address)
    spender: indexed(address)
    amount: uint256


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowances: HashMap[address, HashMap[address, uint256]]
totalSupply: public(uint256)
# test helpers
fee: public(uint256)


@external
def __init__(name: String[64], symbol: String[32], decimals: uint256):
    self.name = name
    self.symbol = symbol
    self.decimals = decimals


@external
@view
def allowance(owner: address, spender: address) -> uint256:
    return self.allowances[owner][spender]


@internal
def _transfer(_from: address, _to: address, amount: uint256):
    fee: uint256 = min(self.fee, amount)

    self.balanceOf[_from] -= amount
    self.balanceOf[_to] += amount - fee
    self.balanceOf[self] += fee
    log Transfer(_from, _to, amount)


@external
def transfer(_to: address, amount: uint256) -> bool:
    self._transfer(msg.sender, _to, amount)
    return True


@external
def transferFrom(_from: address, _to: address, amount: uint256) -> bool:
    self._transfer(_from, _to, amount)
    self.allowances[_from][msg.sender] -= amount
    log Transfer(_from, _to, amount)
    return True


@external
def approve(spender: address, amount: uint256) -> bool:
    self.allowances[msg.sender][spender] = amount
    log Approval(msg.sender, spender, amount)
    return True


### Test helpers ###
@external
def mint(_to: address, amount: uint256):
    self.totalSupply += amount
    self.balanceOf[_to] += amount
    log Transfer(ZERO_ADDRESS, _to, amount)


@external
def burn(_from: address, amount: uint256):
    self.totalSupply -= amount
    self.balanceOf[_from] -= amount
    log Transfer(_from, ZERO_ADDRESS, amount)


@external
def setFeeOnTransfer(fee: uint256):
    self.fee = fee