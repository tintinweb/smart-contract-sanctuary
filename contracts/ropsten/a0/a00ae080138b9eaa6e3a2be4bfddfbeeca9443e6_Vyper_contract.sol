# @version ^0.2.12

MAX_OWNER_COUNT: constant(uint256) = 50

owners: public(address[MAX_OWNER_COUNT])
isOwner: public(HashMap[address, bool])
required: public(uint256)

struct Transaction:
    destination: address
    value: uint256
    data: Bytes[100]
    executed: bool


event Response:
    response: Bytes[32]


transactions: public(HashMap[uint256, Transaction])
transactionsCount: public(uint256)


@external
def __init__():
    pass


@external
def test(_index: uint256, _target: address, _value: uint256, _calldata: Bytes[100]) -> Bytes[32]:
    self.transactions[_index].destination = _target
    self.transactions[_index].value = _value
    self.transactions[_index].data = _calldata
    self.transactions[_index].executed = False

    response: Bytes[32] = raw_call(_target, self.transactions[_index].data, max_outsize=32, value=self.transactions[_index].value)

    log Response(response)

    return response