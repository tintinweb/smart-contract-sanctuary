owner: public(address)

token_owner_by_id:   public(HashMap[uint256, address])
token_owner_by_hash: public(HashMap[uint256, address])
token_id_to_hash:    public(HashMap[uint256, uint256])
balance_of:          public(HashMap[address, uint256])

last_id: uint256



event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    token_id: indexed(uint256)


@external
def __init__():
    self.owner = msg.sender
    self.last_id = 1



@external
def mint(_hash: uint256, _to: address) -> bool:
    assert self.owner == msg.sender
    assert self.token_owner_by_hash[_hash] == ZERO_ADDRESS

    self.token_id_to_hash[self.last_id] = _hash
    self.token_owner_by_id[self.last_id] = _to
    self.token_owner_by_hash[_hash]      = _to

    self.balance_of[_to] += 1
    self.last_id += 1

    return True



@external
def transfer(_to: address, token_id: uint256) -> bool:
    assert self.token_owner_by_id[token_id] == msg.sender
    assert _to != ZERO_ADDRESS


    self.token_owner_by_id[token_id] = _to
    self.token_owner_by_hash[self.token_id_to_hash[token_id]] = _to


    self.balance_of[msg.sender] -= 1
    self.balance_of[_to] += 1

    return True