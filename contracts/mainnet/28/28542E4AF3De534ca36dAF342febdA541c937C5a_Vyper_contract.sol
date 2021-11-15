# @version 0.3.0
"""
@title Root Forwarder
@author Curve Finance
@license MIT
@notice Reciever contract for sidechain fees. Must be deployed to the same
        address as the sidechain bridger, when using a bridge that does not
        allow specificying a receiver on the root chain.
"""


from vyper.interfaces import ERC20


owner: public(address)
future_owner: public(address)

pool_proxy: public(address)


@external
def __init__(_owner: address, _pool_proxy: address):
    self.owner = _owner
    self.pool_proxy = _pool_proxy


@external
def transfer(_token: address) -> bool:
    # transfer underlying coin from msg.sender to self
    amount: uint256 = ERC20(_token).balanceOf(self)
    response: Bytes[32] = raw_call(
        _token,
        _abi_encode(self.pool_proxy, amount, method_id=method_id("transfer(address,uint256)")),
        max_outsize=32
    )
    if len(response) != 0:
        assert convert(response, bool)

    return True


@external
def transfer_many(_tokens: address[10]) -> bool:
    pool_proxy: address = self.pool_proxy
    for token in _tokens:
        if token == ZERO_ADDRESS:
            break

        # transfer underlying coin from msg.sender to self
        amount: uint256 = ERC20(token).balanceOf(self)
        response: Bytes[32] = raw_call(
            token,
            _abi_encode(self.pool_proxy, amount, method_id=method_id("transfer(address,uint256)")),
            max_outsize=32
        )
        if len(response) != 0:
            assert convert(response, bool)

    return True


@external
def set_pool_proxy(_pool_proxy: address):
    assert msg.sender == self.owner
    self.pool_proxy = _pool_proxy


@external
def commit_transfer_ownership(_owner: address):
    assert msg.sender == self.owner
    self.future_owner = _owner


@external
def accept_transfer_ownership():
    assert msg.sender == self.future_owner
    self.owner = self.future_owner