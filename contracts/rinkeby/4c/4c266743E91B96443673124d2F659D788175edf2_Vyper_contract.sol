# @version 0.3.0

TRANSFER_MID: constant(Bytes[4]) = method_id("transfer(address,uint256)")
MERKLE_TREE_DEPTH: constant(uint256) = 15

somm_token: public(address)
received: public(HashMap[address, bool])
deadline: public(uint256)
gravity_bridge: public(address)
merkle_root: public(bytes32)

interface IERC20:
    def balanceOf(owner: address) -> uint256: view

@external
def __init__(_somm_token: address, _merkle_root: bytes32, _gravity_bridge: address):
    self.somm_token = _somm_token
    self.deadline = block.timestamp + 60 * 60 * 24 * 30 * 6 # 6 months
    self.gravity_bridge = _gravity_bridge
    self.merkle_root = _merkle_root

@internal
def _safe_transfer(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            TRANSFER_MID,
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )  # dev: failed approve
    if len(_response) > 0:
        assert convert(_response, bool), "Transfer failed"  # dev: failed approve

@internal
@pure
def verify(proof:bytes32[MERKLE_TREE_DEPTH], root: bytes32, leaf: bytes32) -> bool:
    computed_hash: bytes32 = leaf
    for i in range(MERKLE_TREE_DEPTH):
        proof_element: bytes32 = proof[i]
        if convert(proof_element, uint256) != 0:
            if convert(computed_hash, uint256) <= convert(proof_element, uint256):
                computed_hash = keccak256(concat(computed_hash, proof_element))
            else:
                computed_hash = keccak256(concat(proof_element, computed_hash))
    return computed_hash == root

@external
def claim(receiver: address, amount: uint256, merkle_proof: bytes32[MERKLE_TREE_DEPTH]):
    assert block.timestamp <= self.deadline
    assert not self.received[receiver], "Already received"
    node: bytes32 = keccak256(concat(slice(convert(receiver, bytes32), 12, 20), convert(amount, bytes32)))
    assert self.verify(merkle_proof, self.merkle_root, node), "Invalid proof"
    self._safe_transfer(self.somm_token, receiver, amount)
    self.received[receiver] = True

@external
def return_token():
    assert self.deadline < block.timestamp, "Not finished"
    _token: address = self.somm_token
    bal: uint256 = IERC20(_token).balanceOf(self)
    assert bal > 0, "Insufficient balance"
    self._safe_transfer(_token, self.gravity_bridge, bal)