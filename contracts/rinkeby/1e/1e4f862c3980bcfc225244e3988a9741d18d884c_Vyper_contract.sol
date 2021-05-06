# @dev Implementation of ERC-721 non-fungible token standard.
# @author Ryuya Nakamura (@nrryuya)
# Modified from: https://github.com/vyperlang/vyper/blob/3e1ff1eb327e9017c5758e24db4bdf66bbfae371/examples/tokens/ERC721.vy
# TODO: submit PR

from vyper.interfaces import ERC721

implements: ERC721

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
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
    sender: indexed(address)
    receiver: indexed(address)
    tokenId: indexed(uint256)

# @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
#      address indicates there is no approved address. When a Transfer event emits, this also
#      indicates that the approved address for that NFT (if any) is reset to none.
# @param _owner Owner of NFT.
# @param _approved Address that we are approving.
# @param _tokenId NFT which we are approving.
event Approval:
    owner: indexed(address)
    approved: indexed(address)
    tokenId: indexed(uint256)

# @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
#      all NFTs of the owner.
# @param _owner Owner of NFT.
# @param _operator Address to which we are setting operator rights.
# @param _approved Status of operator rights(true if operator rights are given and false if
# revoked).
event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool

# interface URI:
#     def tokenURI(_tokenId: uint256) -> String[128]: view

interface FungibleContract:
    def totalSupply() -> uint256: view
    def burnFrom(_from: address, _amount: uint256): nonpayable

ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7 # ERC165 interface ID of ERC165
ERC721_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000080ac58cd # ERC165 interface ID of ERC721
ERC721_ENUMERABLE_INTERFACE_ID: constant(bytes32) = 0x00000000000000000000000000000000000000000000000000000000780e9d63 # ERC165 interface ID of ERC721Enumerable
ERC721_METADATA_INTERFACE_ID: constant(bytes32) = 0x000000000000000000000000000000000000000000000000000000005b5e139f # ERC165 interface ID of ERC721Metadata

# @dev Mapping from NFT ID to the address that owns it.
idToOwner: HashMap[uint256, address]
# @dev Mapping from NFT ID to approved address.
idToApprovals: HashMap[uint256, address]
# @dev Mapping from owner address to count of his tokens.
ownerToTokenCount: HashMap[address, uint256]
# @dev Mapping from owner address to mapping of operator addresses.
ownerToOperators: HashMap[address, HashMap[address, bool]]
# @dev Address of minter, who can mint a token
minter: address
# @dev Mapping of interface id to bool about whether or not it's supported
supportedInterfaces: HashMap[bytes32, bool]

##############
### Fields ###
##############

### ERC721Metadata - https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#ERC721Metadata ###
name: public(String[64])
symbol: public(String[32])
### ERC721Enumerable - https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#ERC721Enumerable ###
totalSupply: public(uint256)
### custom stuff ###
fungibleContract: public(FungibleContract)
shipmentRequested: public(HashMap[uint256, bool]) # map(tokenId, shippedFlag)

### Internal variables ###
# newURI: public(address) # TODO: public needed? - we don't need a getter
ipfsBaseUri: String[100]
# mappings for Enumerable
ownerIndexToTokenId: HashMap[address, HashMap[uint256, uint256]]   # map(owner, map(ownerIndex, tokenId))
tokenIdToOwnerIndex: HashMap[uint256, uint256] # map(tokenId, ownerIndex)

###################
### Constructor ###
###################

@external
def __init__(_name: String[64], _symbol: String[32], _fungibleContract: address, _ipfsBaseUri: String[100]):
    """
    @dev Contract constructor.
    @param _name Contract address of the ERC20
    @param _symbol Contract address of the ERC20
    @param _fungibleContract Contract address of the ERC20
    """
    self.name = _name
    self.symbol = _symbol
    self.fungibleContract = FungibleContract(_fungibleContract)
    self.ipfsBaseUri = _ipfsBaseUri
    self.supportedInterfaces[ERC165_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_ENUMERABLE_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = True
    self.minter = msg.sender

# Custom addition to be able to transfer ownership        
@external
def changeMinter(_minter: address):
    assert msg.sender == self.minter
    self.minter = _minter


######################
### VIEW FUNCTIONS ###
######################

@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @dev Returns the number of NFTs owned by `_owner`.
         Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    @param _owner Address for whom to query the balance.
    """
    assert _owner != ZERO_ADDRESS
    return self.ownerToTokenCount[_owner]

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
    # Throws if `_tokenId` is not in the list
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
    return (self.ownerToOperators[_owner])[_operator]

######################
### ERC721Metadata ###
######################

@view 
@external
def artworkId(_tokenId: uint256) -> uint256:
     #TODO: constant vs baseURI vs dynamically generated from source code? (storage costs)
    # if (self.newURI == ZERO_ADDRESS):
    return _tokenId % 6

@view 
@external
def tokenURI(_tokenId: uint256) -> String[256]:
    return concat(self.ipfsBaseUri, 'QmYhmDicxBw42ExLTPxGn6nvKJEGoVLgEhy5BaW5yb1vcg/0.json')

    # if (self.newURI != ZERO_ADDRESS):
    #     return URI(self.newURI).tokenURI(_tokenId)
    # else:

    # _artworkId: uint256 = _tokenId % 6
    # _artworkString: bytes32 = convert(_artworkId + 48, bytes32) # https://github.com/vyperlang/vyper/discussions/2363
    # _artworkStringNoPad: Bytes[1] = slice( _artworkString, 31, 1) # otherwise it's prefixed with 31x "\u0000"
    # return concat(
    #     convert(self.ipfsBaseUri, Bytes[100]),
    #     b'QmYhmDicxBw42ExLTPxGn6nvKJEGoVLgEhy5BaW5yb1vcg/',
    #     _artworkStringNoPad,
    #     b'.json'
    # )

@external
def changeIpfsBaseURI(_newURI: String[100]):
    assert msg.sender == self.minter
    self.ipfsBaseUri = _newURI

# @external
# def setURIContract(_newURI: address):
#     assert msg.sender == self.minter
#     self.newURI = _newURI

########################
### ERC721Enumerable ###
########################

@view
@external
def tokenByIndex(_index: uint256) -> uint256:
    # Token index is same as ID and can't change
    assert _index < self.totalSupply
    return _index

@view
@external
def tokenOfOwnerByIndex(_owner: address, _index: uint256) -> uint256:
    assert _owner != ZERO_ADDRESS
    assert _index < self.ownerToTokenCount[_owner]
    return self.ownerIndexToTokenId[_owner][_index]

#################################
### TRANSFER FUNCTION HELPERS ###
#################################

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
    self.ownerToTokenCount[_to] += 1

    # Update total count
    self.totalSupply += 1
    
    # Update mappings for Enumerable
    _indexForOwner: uint256 = self.ownerToTokenCount[_to]
    self.ownerIndexToTokenId[_to][_indexForOwner] = _tokenId
    self.tokenIdToOwnerIndex[_tokenId] = _indexForOwner

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
    self.ownerToTokenCount[_from] -= 1

    # Update total count
    self.totalSupply += 1

    # Update mappings for Enumerable
    _highestIndexOfOwner: uint256 = self.ownerToTokenCount[_from] - 1   # get highest index of _from
    _tokenIdIndexOfOwner: uint256 = self.tokenIdToOwnerIndex[_tokenId] # get index of _from where _tokenId is
    if _highestIndexOfOwner == _tokenIdIndexOfOwner:               
        # token is the last in owner's list, just set it to zero
        self.ownerIndexToTokenId[_from][_highestIndexOfOwner] = 0
    else:
        # token is not the last, so move the last one in it's place so that no gap is created (and ordering doesn't matter)
        self.ownerIndexToTokenId[_from][_tokenIdIndexOfOwner] = self.ownerIndexToTokenId[_from][_highestIndexOfOwner]
        self.ownerIndexToTokenId[_from][_highestIndexOfOwner] = 0

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


#############################
### MINT & BURN FUNCTIONS ###
#############################

@external
def mint(_to: address) -> bool: # , _tokenId: uint256
    """
    @dev Function to mint tokens
         Throws if `msg.sender` is not the minter.
         Throws if `_to` is zero address.
         Throws if `_tokenId` is owned by someone.
         Also checks if the
    @param _to The address that will receive the minted tokens.
    #@param _tokenId The token id to mint.
    @return A boolean that indicates if the operation was successful.
    """
    # Throws if `msg.sender` is not the minter
    assert msg.sender == self.minter
    # Throws if `_to` is zero address
    assert _to != ZERO_ADDRESS
    _tokenId: uint256 = self.totalSupply

    # Check if a FungibleToken has been burned
    # TODO: validate that this is safe (unisocks doing it doesn't mean it is) (concern: frontrunning attack)
    _winesSupply: uint256 = self.fungibleContract.totalSupply()
    _winesBurned: uint256 = 216 * 10**18 - _winesSupply #TODO define in fungible contract (or init param)
    assert _tokenId * 10**18 < _winesBurned

    self._addTokenTo(_to, _tokenId)
    log Transfer(ZERO_ADDRESS, _to, _tokenId)
    return True

@external
def claimFromFT(_to: address) -> uint256: #  , _tokenId: uint256
    """
    @dev Function to burn FT & mint tokens
         Throws if `_to` is zero address.
         Throws if `_amount` is not > 0.
         Throws if `_tokenId` is > maxSupply.
    @param _to The address that will receive the minted tokens.
    @return A boolean that indicates if the operation was successful.
    """
    # # Throws if `msg.sender` is not the minter
    # assert msg.sender == self.minter
    # Throws if `_to` is zero address
    assert _to != ZERO_ADDRESS
    # assert _tokenId > self.maxSupply
    _tokenId: uint256 = self.totalSupply

    # Perform burn of one full FT
    self.fungibleContract.burnFrom(msg.sender, 10**18)

    # Check if a FungibleToken has been burned
    # TODO: if we call the burn function ourselves, we could skip this check...?
    _winesSupply: uint256 = self.fungibleContract.totalSupply()
    _winesBurned: uint256 = 108 * 10**18 - _winesSupply #TODO define in fungible contract (or init param)
    assert _tokenId * 10**18 < _winesBurned

    self._addTokenTo(msg.sender, _tokenId)
    log Transfer(ZERO_ADDRESS, msg.sender, _tokenId)
    return _tokenId

@external
def burn(_tokenId: uint256):
    """
    @dev Burns a specific ERC721 token.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId uint256 id of the ERC721 token to be burned.
    """
    # Check requirements
    assert self._isApprovedOrOwner(msg.sender, _tokenId)
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    self._clearApproval(owner, _tokenId)
    self._removeTokenFrom(owner, _tokenId)
    log Transfer(owner, ZERO_ADDRESS, _tokenId)

##########################    
### TRANSFER FUNCTIONS ###
##########################    

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
        _data: Bytes[1024]=b""
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
        returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
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
    @param _approved True if the operators is approved, false to revoke approval.
    """
    # Throws if `_operator` is the `msg.sender`
    assert _operator != msg.sender
    self.ownerToOperators[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)


##############
### ERC165 ###
##############

@view
@external
def supportsInterface(_interfaceID: bytes32) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param _interfaceID Id of the interface
    """
    return self.supportedInterfaces[_interfaceID]