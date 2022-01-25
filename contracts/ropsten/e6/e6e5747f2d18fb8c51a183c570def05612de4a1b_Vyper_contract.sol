approved_addresses: public(address[6])
graffiti_wall: public(String[100])
owner: public(address)

@external
def __init__():
    self.owner = msg.sender
    assert chain.id == 3

@external
def add_approved_address(new_address: address):
    i: uint256 = 0
    for approved_address in self.approved_addresses:
        if approved_address != 0x0000000000000000000000000000000000000000:
            i += 1
    self.approved_addresses[i] = new_address

@external
def set_graffiti(graffiti: String[100]):
    self.graffiti_wall = graffiti