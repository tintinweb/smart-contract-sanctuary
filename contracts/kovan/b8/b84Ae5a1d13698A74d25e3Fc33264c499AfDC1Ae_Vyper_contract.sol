# @version ^0.2.15

# dao.vy

from vyper.interfaces import ERC20

name: public(String[64])
owner: public(address)

balances: HashMap[address,uint256]

@external
def __init__(_name:String[64]):
    self.name = _name
    self.owner = msg.sender

@view
@external
def balanceOf(_token_addr:address) -> uint256:
    return self.balances[_token_addr]