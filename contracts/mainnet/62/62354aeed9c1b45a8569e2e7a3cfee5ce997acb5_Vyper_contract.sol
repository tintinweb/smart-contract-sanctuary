# @version 0.3.1
"""
@title Simple ENS Registrar
@license MIT
@author Wacky Bear
"""
from vyper.interfaces import ERC721


interface ENSRegistry:
    def setSubnodeOwner(_node: bytes32, _label: bytes32, _owner: address): nonpayable
    def setOwner(_node: bytes32, _owner: address): nonpayable

interface ENSResolver:
    def setAddr(_node: bytes32, _addr: address): nonpayable

interface TokenReceiver:
    def onERC721Received(
        _operator: address,
        _from: address,
        _token_id: uint256,
        _data: Bytes[4096]
    ) -> uint256: nonpayable


event Approval:
    _owner: indexed(address)
    _approved: indexed(address)
    _token_id: indexed(uint256)

event ApprovalForAll:
    _owner: indexed(address)
    _operator: indexed(address)
    _approved: bool

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _token_id: indexed(uint256)

event TransferOwnership:
    _old_owner: address
    _new_owner: address


# Interface IDs
EIP165: constant(uint256) = 33540519  # 0x01ffc9a7
EIP721: constant(uint256) = 2158778573  # 0x80ac58cd


BASE_NODE: immutable(bytes32)
DEFAULT_RESOLVER: immutable(address)
ENS_REGISTRY: immutable(address)


balanceOf: public(HashMap[address, uint256])
getApproved: public(HashMap[uint256, address])
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])
ownerOf: public(HashMap[uint256, address])

owner: public(address)
future_owner: public(address)


@external
def __init__(_base_node: bytes32, _default_resolver: address, _ens_registry: address):
    BASE_NODE = _base_node
    DEFAULT_RESOLVER = _default_resolver
    ENS_REGISTRY = _ens_registry

    self.owner = msg.sender
    log TransferOwnership(ZERO_ADDRESS, msg.sender)


@internal
def _transfer_from(_from: address, _to: address, _token_id: uint256, _msg_sender: address):
    assert _from == self.ownerOf[_token_id]

    approved: address = self.getApproved[_token_id]
    assert (
        _msg_sender == _from
        or self.isApprovedForAll[_from][_msg_sender]
        or _msg_sender == approved
    )

    # reset allowance if destination isn't current owner or approved address
    if _to != _from or _to != approved:
        self.getApproved[_token_id] = ZERO_ADDRESS
        log Approval(_from, ZERO_ADDRESS, _token_id)

    # change balances/owner in storage only if _to isn't the current owner
    if _to != _from:
        self.ownerOf[_token_id] = _to
        self.balanceOf[_from] -= 1

        # transfers to address(0) burn the token, dont increase the balance
        if _to != ZERO_ADDRESS:
            self.balanceOf[_to] += 1

        log Transfer(_from, _to, _token_id)


@external
def safeTransferFrom(_from: address, _to: address, _token_id: uint256, _data: Bytes[4096] = b""):
    """
    @notice Transfers the ownership of an NFT from one address to another address
    @dev Throws unless `msg.sender` is the current owner, an authorized
        operator, or the approved address for this NFT. Throws if `_from` is
        not the current owner. Throws if `_tokenId` is not a valid NFT.
        When transfer is complete, this function checks if `_to` is a smart
        contract (code size > 0). If so, it calls `onERC721Received` on `_to` and
        throws if the return value is not
        `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    @param _from The current owner of the NFT
    @param _to The new owner
    @param _token_id The NFT to transfer
    @param _data Additional data with no specified format, sent in call to `_to`
    """
    self._transfer_from(_from, _to, _token_id, msg.sender)

    if _to.is_contract:
        resp: uint256 = TokenReceiver(_to).onERC721Received(msg.sender, _from, _token_id, _data)
        assert shift(resp, -224) == 353073666  # 0x150b7a02


@external
def transferFrom(_from: address, _to: address, _token_id: uint256):
    """
    @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
        TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
        THEY MAY BE PERMANENTLY LOST
    @dev Throws unless `msg.sender` is the current owner, an authorized
        operator, or the approved address for this NFT. Throws if `_from` is
        not the current owner. Throws if `_token_id` is not a valid NFT.
    @param _from The current owner of the NFT
    @param _to The new owner
    @param _token_id The NFT to transfer
    """
    self._transfer_from(_from, _to, _token_id, msg.sender)


@external
def approve(_approved: address, _token_id: uint256):
    """
    @notice Change or reaffirm the approved address for an NFT
    @dev The zero address indicates there is no approved address.
        Throws unless `msg.sender` is the current NFT owner, or an authorized
        operator of the current owner.
    @param _approved The new approved NFT controller
    @param _token_id The NFT to approve
    """
    owner: address = self.ownerOf[_token_id]
    assert msg.sender == owner or self.isApprovedForAll[owner][msg.sender]

    self.getApproved[_token_id] = _approved
    log Approval(owner, _approved, _token_id)


@external
def setApprovalForAll(_operator: address, _approved: bool):
    """
    @notice Enable or disable approval for a third party ("operator") to manage
        all of `msg.sender`'s assets
    @param _operator Address to add to the set of authorized operators
    @param _approved True if the operator is approved, false to revoke approval
    """
    self.isApprovedForAll[msg.sender][_operator] = _approved

    log ApprovalForAll(msg.sender, _operator, _approved)


@external
def register(_label: bytes32, _owner: address, _resolver: address, _ttl: uint256):
    """
    @notice Register a new subdomain
    @param _label The labelhash of the subdomain to register
    @param _owner The address to grant ownership to
    @param _resolver The address of the resolver to use, if address(0) will use the
        default resolver
    @param _ttl The TTL (in seconds) of the record
    """
    assert msg.sender == self.owner
    assert _owner != ZERO_ADDRESS
    assert self.ownerOf[convert(_label, uint256)] == ZERO_ADDRESS

    self.ownerOf[convert(_label, uint256)] = _owner
    self.balanceOf[_owner] += 1

    owner: address = _owner
    resolver: address = _resolver
    if _resolver == ZERO_ADDRESS:
        owner = self
        resolver = DEFAULT_RESOLVER

    raw_call(
        ENS_REGISTRY,
        _abi_encode(
            BASE_NODE,
            _label,
            owner,
            resolver,
            _ttl,
            method_id=method_id("setSubnodeRecord(bytes32,bytes32,address,address,uint64)")
        )
    )

    if _resolver == ZERO_ADDRESS:
        subnode: bytes32 = keccak256(concat(BASE_NODE, _label))
        ENSResolver(resolver).setAddr(subnode, _owner)
        ENSRegistry(ENS_REGISTRY).setOwner(subnode, _owner)


@external
def reclaim(_label: bytes32, _owner: address):
    """
    @notice Reclaim ownership of a subnode
    @param _label The label of the subdomain to reclaim
    @param _owner The address to set as the new owner
    """
    owner: address = self.ownerOf[convert(_label, uint256)]
    assert (
        msg.sender == owner
        or self.isApprovedForAll[owner][msg.sender]
        or msg.sender == self.getApproved[convert(_label, uint256)]
    )

    ENSRegistry(ENS_REGISTRY).setSubnodeOwner(BASE_NODE, _label, _owner)


@external
def commit_transfer_ownership(_future_owner: address):
    """
    @notice Commit the transfer of ownership
    @param _future_owner Address of the future owner, which has to accept
    """
    assert msg.sender == self.owner

    self.future_owner = _future_owner


@external
def accept_transfer_ownership():
    """
    @notice Accept the transfer of ownership, only callable by future owner
    """
    assert msg.sender == self.future_owner

    log TransferOwnership(self.owner, msg.sender)
    self.owner = msg.sender


@external
def recover20(_token: address, _to: address, _amount: uint256):
    """
    @notice Recover ERC20 tokens from this contract
    """
    assert msg.sender == self.owner

    resp: Bytes[32] = raw_call(
        _token,
        _abi_encode(_to, _amount, method_id=method_id("transfer(address,uint256)")),
        max_outsize=32
    )
    if len(resp) != 0:
        assert convert(resp, bool)


@external
def recover721(_token: address, _to: address, _token_id: uint256, _data: Bytes[1024] = b""):
    """
    @notice Recover an ERC721 token from this contract
    """
    assert msg.sender == self.owner

    ERC721(_token).safeTransferFrom(self, _to, _token_id, _data)


@pure
@external
def pizza_mandate_apology(_interface_id: uint256) -> bool:
    """
    @notice Query if a contract implements an interface
    @dev Vyper version 0.3.1 lacks a bytes4 type preventing the implementation in source code
        of `supportsInterface(bytes4)`. However, this method signature collides with EIP165
        allowing the compiled source code to abide by the EIP165 interface at the bytecode level.
    @param _interface_id The bytes4 interface id casted as a uint256 (padded to the right 28 bytes)
    """
    return shift(_interface_id, -224) in [EIP165, EIP721]


@pure
@external
def base_node() -> bytes32:
    """
    @notice Get the node managed by this contract
    """
    return BASE_NODE


@pure
@external
def default_resolver() -> address:
    """
    @notice Get the address of the default resolver used
    """
    return DEFAULT_RESOLVER


@pure
@external
def ens_registry() -> address:
    """
    @notice Get the address of the ENS registry as stored in this contract
    """
    return ENS_REGISTRY