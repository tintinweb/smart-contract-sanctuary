# @version 0.2.15
"""
@title Smart Wallet Checker
@author Hundred Finance
@license MIT
@notice Holds a list of whitelisted smart contract addresses that can 
        interact with the VotingEscrow contract
"""

admin: public(address)
whitelisted: public(HashMap[address, bool])

@external
def __init__(admin: address):
    self.admin = admin


@external
@view
def check(addr: address) -> bool:
    return self.whitelisted[addr]


@external
def add_to_whitelist(addr: address):
    assert msg.sender == self.admin  # dev: admin only
    self.whitelisted[addr] = True


@external
def revoke_from_whitelist(addr: address):
    assert msg.sender == self.admin  # dev: admin only
    self.whitelisted[addr] = False


@external
def set_admin(new_admin: address):
    assert msg.sender == self.admin  # dev: admin only
    self.admin = new_admin