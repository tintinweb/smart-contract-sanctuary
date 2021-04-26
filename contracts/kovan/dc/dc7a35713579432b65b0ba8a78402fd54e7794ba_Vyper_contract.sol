# @version ^0.2.12
implementation: public(address)
owner: public(address)


@external
def __init__():
    self.owner = msg.sender


@external
def __default__() -> Bytes[32]:
    responce: Bytes[32] = raw_call(self.implementation, slice(msg.data,0,128), max_outsize=32, is_delegate_call=True)
    return responce
    

@external
def upgradeTo(_newAddr: address):
    assert msg.sender == self.owner
    self.implementation = _newAddr