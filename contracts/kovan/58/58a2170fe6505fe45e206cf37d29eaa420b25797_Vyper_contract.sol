# @version ^0.2.12
implementation: public(address)
owner: public(address)


@external
def __init__():
    self.owner = msg.sender


@external
def __default__():
    raw_call(self.implementation, slice(msg.data,0,128), is_delegate_call=True)
    

@external
def upgradeTo(_newAddr: address):
    assert msg.sender == self.owner
    self.implementation = _newAddr