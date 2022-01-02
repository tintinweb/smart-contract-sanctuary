# @version 0.3.0


event Callback:
    _to: address
    _data: Bytes[2048]
    _nonces: uint256
    _from_chain_id: uint256
    _success: bool
    _result: Bytes[2048]


@external
def callback(_to: address, _data: Bytes[2048], _nonces: uint256, _from_chain_id: uint256, _success: bool, _result: Bytes[2048]):
    log Callback(_to, _data, _nonces, _from_chain_id, _success, _result)