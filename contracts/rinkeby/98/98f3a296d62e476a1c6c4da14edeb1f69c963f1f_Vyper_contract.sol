# @version 0.2.15

#
# Vyper ERC-721 contract for Matic OpenSea deployment
#
# With modification on isApprovedForAll and contractURI
#

"""
@title ERC-721 Non-Fungible Token Standard, optional metadata extension
@license MIT
@author vasa (@vasa-develop)
@notice ERC-721 Non-Fungible Token Standard, optional metadata extension
@dev See https://eips.ethereum.org/EIPS/eip-721
  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
"""

from vyper.interfaces import ERC721

implements: ERC721


# @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver:
# @notice Handle the receipt of an NFT
# @dev The ERC721 smart contract calls this function on the recipient
#  after a `transfer`. This function MAY throw to revert and reject the
#  transfer. Return of other than the magic value MUST result in the
#  transaction being reverted.
#  Note: the contract address is always the message sender.
# @param _operator The address which called `safeTransferFrom` function
# @param _from The address which previously owned the token
# @param _tokenId The NFT identifier which is being transferred
# @param _data Additional data with no specified format
# @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
#  unless throwing
    def onERC721Received(
            _operator: address,
            _from: address,
            _tokenId: uint256,
            _data: Bytes[1024]
        ) -> bytes32: view


# @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
#      created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
#      number of NFTs may be created and assigned without emitting Transfer. At the time of any
#      transfer, the approved address for that NFT (if any) is reset to none.
# @param _from Sender of NFT (if address is zero address it indicates token creation).
# @param _to Receiver of NFT (if address is zero address it indicates token destruction).
# @param _tokenId The NFT that got transfered.
event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _tokenId: indexed(uint256)

# @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
#      address indicates there is no approved address. When a Transfer event emits, this also
#      indicates that the approved address for that NFT (if any) is reset to none.
# @param _owner Owner of NFT.
# @param _approved Address that we are approving.
# @param _tokenId NFT which we are approving.
event Approval:
    _owner: indexed(address)
    _approved: indexed(address)
    _tokenId: indexed(uint256)

# @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
#      all NFTs of the owner.
# @param _owner Owner of NFT.
# @param _operator Address to which we are setting operator rights.
# @param _approved Status of operator rights(true if operator rights are given and false if
# revoked).
event ApprovalForAll:
    _owner: indexed(address)
    _operator: indexed(address)
    _approved: bool

# @notice A descriptive name for a collection of NFTs in this contract
tokenName: String[64]

# @notice An abbreviated name for NFTs in this contract
tokenSymbol: String[32]

# @notice A distinct Uniform Resource Identifier (URI) for a given asset.
# @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
#   3986. The URI may point to a JSON file that conforms to the "ERC721
#   Metadata JSON Schema".
token_uri: String[64]

# @dev Mapping from NFT ID to the address that owns it.
idToOwner: HashMap[uint256, address]

# @dev Mapping from NFT ID to approved address.
idToApprovals: HashMap[uint256, address]

# @dev Mapping from owner address to count of his tokens.
ownerToNFTokenCount: HashMap[address, uint256]

# @dev Mapping from owner address to mapping of operator addresses.
ownerToOperators: HashMap[address, HashMap[address, bool]]

# @dev Address of minter, who can mint a token
maxSupply: public(uint256)
tokenTotalSupply: uint256
minter: address

# @dev Mapping of interface id to bool about whether or not it's supported
supportedInterfaces: HashMap[bytes32, bool]

# @dev ERC165 interface ID of ERC165
ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7

# @dev 
#     ERC165 interface ID of ERC721
# 
#     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
#     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
#     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
#     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
#     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
#     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
#     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
#     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
#     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
# 
#     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
#     0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     
ERC721_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000080ac58cd


# @dev  ERC165 interface ID of ERC721TokenReceiver

ERC721_TOKEN_RECEIVER_INTERFACE_ID: constant(bytes32) = 0x00000000000000000000000000000000000000000000000000000000150b7a02

operatorOpenSea: address
contract_uri: String[64]

# @dev 
#     ERC165 interface ID of ERC721, optional metadata extension
#     
#     bytes4(keccak256('name()')) == 0x06fdde03
#     bytes4(keccak256('symbol()')) == 0x95d89b41
#     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
# 
#     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f     

ERC721_METADATA_INTERFACE_ID: constant(bytes32) = 0x000000000000000000000000000000000000000000000000000000005b5e139f
ERC721_ENUMERABLE_INTERFACE_ID: constant(bytes32) = 0x00000000000000000000000000000000000000000000000000000000780e9d63

@external
def __init__():
#def __init__(name: String[64], symbol: String[32], tokenURI: String[64], contractURI: String[64], maxSupply: uint256):
    """
    @dev Contract constructor.
    """
    self.supportedInterfaces[ERC165_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_TOKEN_RECEIVER_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_ENUMERABLE_INTERFACE_ID] = True
    self.minter = msg.sender
    self.operatorOpenSea = 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
    self.tokenTotalSupply = 0
    #self.tokenName = name
    #self.tokenSymbol = symbol
    #self.token_uri = tokenURI
    #self.contract_uri = contractURI
    #self.maxSupply = maxSupply
    self.tokenName = "TestToken1"
    self.tokenSymbol = "TT"
    self.token_uri = "https://tt.com/item/"
    self.contract_uri = "https://tt.com/contract/"
    self.maxSupply = 5


@view
@external
def supportsInterface(_interfaceID: bytes32) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param _interfaceID Id of the interface
    """
    return self.supportedInterfaces[_interfaceID]


### METADATA FUNCTIONS ###

@view
@external
def name() -> String[64]:
    return self.tokenName


@view
@external
def symbol() -> String[32]:
    return self.tokenSymbol


@view
@external
def tokenURI(_tokenId: uint256) -> String[80]:
    return self.token_uri
    
    
@view
@external
def contractURI() -> String[64]:
    return self.contract_uri
    

@view
@external
def totalSupply() -> uint256:
    return self.tokenTotalSupply
    
    
@view
@external
def tokenByIndex(_index: uint256) -> uint256:
    assert _index > 0
    assert _index < self.tokenTotalSupply
    return _index
    
@view
@external
def tokenOfOwnerByIndex(_owner: address, _index: uint256) -> uint256:
    assert _owner == self.idToOwner[_index]
    # Throws if `_tokenId` is not a valid NFT
    assert _owner != ZERO_ADDRESS
    return _index


### VIEW FUNCTIONS ###

@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @dev Returns the number of NFTs owned by `_owner`.
         Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    @param _owner Address for whom to query the balance.
    """
    assert _owner != ZERO_ADDRESS
    return self.ownerToNFTokenCount[_owner]


@view
@external
def ownerOf(_tokenId: uint256) -> address:
    """
    @dev Returns the address of the owner of the NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId The identifier for an NFT.
    """
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    return owner


@view
@external
def getApproved(_tokenId: uint256) -> address:
    """
    @dev Get the approved address for a single NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId ID of the NFT to query the approval of.
    """
    # Throws if `_tokenId` is not a valid NFT
    assert self.idToOwner[_tokenId] != ZERO_ADDRESS
    return self.idToApprovals[_tokenId]


@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    """
    @dev Checks if `_operator` is an approved operator for `_owner`.
    @param _owner The address that owns the NFTs.
    @param _operator The address that acts on behalf of the owner.
    """
    
    # if OpenSea's ERC721 Proxy Address is detected, auto-return true
    # https://docs.opensea.io/docs/other-blockchains
    if _operator == self.operatorOpenSea:
        return True
    
    return (self.ownerToOperators[_owner])[_operator]


### TRANSFER FUNCTION HELPERS ###

@view
@internal
def _isApprovedOrOwner(_spender: address, _tokenId: uint256) -> bool:
    """
    @dev Returns whether the given spender can transfer a given token ID
    @param spender address of the spender to query
    @param tokenId uint256 ID of the token to be transferred
    @return bool whether the msg.sender is approved for the given token ID,
        is an operator of the owner, or is the owner of the token
    """
    owner: address = self.idToOwner[_tokenId]
    spenderIsOwner: bool = owner == _spender
    spenderIsApproved: bool = _spender == self.idToApprovals[_tokenId]
    spenderIsApprovedForAll: bool = (self.ownerToOperators[owner])[_spender]
    return (spenderIsOwner or spenderIsApproved) or spenderIsApprovedForAll


@internal
def _addTokenTo(_to: address, _tokenId: uint256):
    """
    @dev Add a NFT to a given address
         Throws if `_tokenId` is owned by someone.
    """
    # Throws if `_tokenId` is owned by someone
    assert self.idToOwner[_tokenId] == ZERO_ADDRESS
    # Change the owner
    self.idToOwner[_tokenId] = _to
    # Change count tracking
    self.ownerToNFTokenCount[_to] += 1


@internal
def _removeTokenFrom(_from: address, _tokenId: uint256):
    """
    @dev Remove a NFT from a given address
         Throws if `_from` is not the current owner.
    """
    # Throws if `_from` is not the current owner
    assert self.idToOwner[_tokenId] == _from
    # Change the owner
    self.idToOwner[_tokenId] = ZERO_ADDRESS
    # Change count tracking
    self.ownerToNFTokenCount[_from] -= 1


@internal
def _clearApproval(_owner: address, _tokenId: uint256):
    """
    @dev Clear an approval of a given address
         Throws if `_owner` is not the current owner.
    """
    # Throws if `_owner` is not the current owner
    assert self.idToOwner[_tokenId] == _owner
    if self.idToApprovals[_tokenId] != ZERO_ADDRESS:
        # Reset approvals
        self.idToApprovals[_tokenId] = ZERO_ADDRESS


@internal
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
    """
    @dev Exeute transfer of a NFT.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT. (NOTE: `msg.sender` not allowed in private function so pass `_sender`.)
         Throws if `_to` is the zero address.
         Throws if `_from` is not the current owner.
         Throws if `_tokenId` is not a valid NFT.
    """
    # Check requirements
    assert self._isApprovedOrOwner(_sender, _tokenId)
    # Throws if `_to` is the zero address
    assert _to != ZERO_ADDRESS
    # Clear approval. Throws if `_from` is not the current owner
    self._clearApproval(_from, _tokenId)
    # Remove NFT. Throws if `_tokenId` is not a valid NFT
    self._removeTokenFrom(_from, _tokenId)
    # Add NFT
    self._addTokenTo(_to, _tokenId)
    # Log the transfer
    log Transfer(_from, _to, _tokenId)


### TRANSFER FUNCTIONS ###

@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    """
    @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `_from` is not the current owner.
         Throws if `_to` is the zero address.
         Throws if `_tokenId` is not a valid NFT.
    @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
            they maybe be permanently lost.
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _tokenId The NFT to transfer.
    """
    self._transferFrom(_from, _to, _tokenId, msg.sender)


@external
def safeTransferFrom(
        _from: address,
        _to: address,
        _tokenId: uint256,
        data: Bytes[1024]=b""
    ):
    """
    @dev Transfers the ownership of an NFT from one address to another address.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the
         approved address for this NFT.
         Throws if `_from` is not the current owner.
         Throws if `_to` is the zero address.
         Throws if `_tokenId` is not a valid NFT.
         If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
         the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
         NOTE: bytes4 is represented by bytes32 with padding
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _tokenId The NFT to transfer.
    @param _data Additional data with no specified format, sent in call to `_to`.
    """
    self._transferFrom(_from, _to, _tokenId, msg.sender)
    if _to.is_contract: # check if `_to` is a contract address
        returnValue: bytes32 = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data)
        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes32)


@external
def approve(_approved: address, _tokenId: uint256):
    """
    @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
         Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
         Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
         Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    @param _approved Address to be approved for the given NFT ID.
    @param _tokenId ID of the token to be approved.
    """
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    # Throws if `_approved` is the current owner
    assert _approved != owner
    # Check requirements
    senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
    senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[msg.sender]
    assert (senderIsOwner or senderIsApprovedForAll)
    # Set the approval
    self.idToApprovals[_tokenId] = _approved
    log Approval(owner, _approved, _tokenId)


@external
def setApprovalForAll(_operator: address, _approved: bool):
    """
    @dev Enables or disables approval for a third party ("operator") to manage all of
         `msg.sender`'s assets. It also emits the ApprovalForAll event.
         Throws if `_operator` is the `msg.sender`. (NOTE: This is not written the EIP)
    @notice This works even if sender doesn't own any tokens at the time.
    @param _operator Address to add to the set of authorized operators.
    @param _isApproved True if the operators is approved, false to revoke approval.
    """
    # Throws if `_operator` is the `msg.sender`
    assert _operator != msg.sender
    self.ownerToOperators[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)


### MINT & BURN FUNCTIONS ###

@external
def mint(_to: address) -> bool:
    """
    @dev Function to mint tokens
         Throws if `msg.sender` is not the minter.
         Throws if `_to` is zero address.
         Throws if `_tokenId` is owned by someone.
    @param to The address that will receive the minted tokens.
    @param tokenId The token id to mint.
    @return A boolean that indicates if the operation was successful.
    """
    # Throws if `msg.sender` is not the minter
    assert msg.sender == self.minter
    # Throws if `_to` is zero address
    assert _to != ZERO_ADDRESS
    # Add NFT. Throws if `_tokenId` is owned by someone
    assert self.tokenTotalSupply < self.maxSupply
    self.tokenTotalSupply += 1
    self._addTokenTo(_to, self.tokenTotalSupply)
    log Transfer(ZERO_ADDRESS, _to, self.tokenTotalSupply)
    return True


@external
def burn(_tokenId: uint256):
    """
    @dev Burns a specific ERC721 token.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param tokenId uint256 id of the ERC721 token to be burned.
    """
    # Check requirements
    assert self._isApprovedOrOwner(msg.sender, _tokenId)
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    self._clearApproval(owner, _tokenId)
    self._removeTokenFrom(owner, _tokenId)
    self.tokenTotalSupply -= 1
    log Transfer(owner, ZERO_ADDRESS, _tokenId)