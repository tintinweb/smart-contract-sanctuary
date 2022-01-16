# @version ^0.3.0

# Adapted from official ERC721 Vyper example at https://github.com/vyperlang/vyper/blob/master/examples/tokens/ERC721.vy

# @dev Implementation of ERC-721 non-fungible token standard.

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

# Interface for ERC721Metadata

interface ERC721Metadata:
	def name() -> String[64]: view

	def symbol() -> String[32]: view

	def tokenURI(
		_tokenId: uint256
	) -> String[128]: view

interface ERC721Enumerable:

	def totalSupply() -> uint256: view

	def tokenByIndex(
		_index: uint256
	) -> uint256: view

	def tokenOfOwnerByIndex(
		_address: address,
		_index: uint256
	) -> uint256: view

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


tokenName: String[64]
tokenSymbol: String[32]
baseTokenURI: String[100]

# @dev value to be sent to the contract for minting
mintPrice: public(uint256)

# @dev current count of token
tokenId: uint256

# @dev Maximum supply of token
maxSupply: public(uint256)

# @dev Beneficiary for withdrawal of funds
beneficiary: address

# @dev count of burnt tokens
burntCount: uint256

# @dev Mapping from index to token ID
indexToTokenId: HashMap[uint256, uint256]

# @dev Mapping from token ID to index
tokenIdToIndex: HashMap[uint256, uint256]

# @dev Mapping from NFT ID to the address that owns it.
idToOwner: HashMap[uint256, address]

# @dev Mapping from NFT ID to approved address.
idToApprovals: HashMap[uint256, address]

# @dev Mapping from owner address to count of his tokens.
ownerToNFTokenCount: HashMap[address, uint256]

# @dev Mapping from owner address to mapping of index to tokenIds
ownerToNFTokenIdList: HashMap[address, HashMap[uint256, uint256]]

# @dev Mapping from NFT ID to index of owner
tokenToOwnerIndex: HashMap[uint256, uint256]

# @dev Mapping from owner address to mapping of operator addresses.
ownerToOperators: HashMap[address, HashMap[address, bool]]

# @dev Mapping from NFT ID to token URI
idToURI: HashMap[uint256, String[100]]

# @dev ERC165 interface ID of ERC165
ERC165_INTERFACE_ID: constant(Bytes[32]) = b"\x01\xff\xc9\xa7"

# @dev ERC165 interface ID of ERC721
ERC721_INTERFACE_ID: constant(Bytes[32]) = b"\x80\xac\x58\xcd"

# @dev ERC165 interface ID of ERC721Metadata
ERC721_METADATA_INTERFACE_ID: constant(Bytes[32]) = b'[^\x13\x9f'

# @dev ERC165 interface ID of ERC721Enumerable
ERC721_ENUMERABLE_INTERFACE_ID: constant(Bytes[32]) = b'x\x0e\x9dc'

# @dev ERC165 interface ID of ERC721TokenReceiver
ERC721_TOKEN_RECEIVER_INTERFACE_ID: constant(Bytes[32]) = b'\x15\x0bz\x02'


@external
def __init__() -> bool:
    """
    @notice Initialize the NFT contract
	@dev Separate from `__init__` method to facilitate factory pattern in `ConditionalNFTFactory`
    """
    self.tokenName = "Taxidermeme"
    self.tokenSymbol = "TXM"
    self.baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmSYsK5avTsXZkNj9nC7rZktxa2An6zmotEhvyVLuso92G/"
    self.tokenId = 0
    self.burntCount = 0
    self.maxSupply = 150
    self.beneficiary = msg.sender
    self.mintPrice = 20000000000000000

    return True

@view
@internal
def _balanceOf(_owner: address) -> uint256:
	"""
	@dev 	Returns number of tokens held by '_owner'
			Throws if '_owner' is ZERO_ADDRESS.
	@param 	_owner Address to query
	"""
	assert _owner != ZERO_ADDRESS
	return self.ownerToNFTokenCount[_owner]

@view
@internal
def _totalSupply() -> uint256:
	"""
	@dev Returns total supply
	"""
	return self.tokenId - self.burntCount

@view
@internal
def _supportsInterface(_interfaceID: Bytes[4]) -> bool:
    """
    @dev Internal function to check interface
	@param _interfaceID Id of the interface in Bytes[4]
	"""

    return (_interfaceID == ERC165_INTERFACE_ID) or (_interfaceID == ERC721_INTERFACE_ID) or \
		(_interfaceID == ERC721_METADATA_INTERFACE_ID) or (_interfaceID == ERC721_ENUMERABLE_INTERFACE_ID) or \
		(_interfaceID == ERC721_TOKEN_RECEIVER_INTERFACE_ID)

@view
@external
def supportsInterface(_interfaceID: bytes32) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param _interfaceID Id of the interface
    """
    return self._supportsInterface(slice(_interfaceID, 28, 4))

@external
@payable
def __default__() -> bool:
    if (slice(msg.data, 0, 4) == ERC165_INTERFACE_ID) or (slice(msg.data, 0, 4) == ERC721_INTERFACE_ID) or \
		(slice(msg.data, 0, 4) == ERC721_METADATA_INTERFACE_ID) or (slice(msg.data, 0, 4) == ERC721_ENUMERABLE_INTERFACE_ID) or \
		(slice(msg.data, 0, 4) == ERC721_TOKEN_RECEIVER_INTERFACE_ID):
        return self._supportsInterface(slice(msg.data, 4, 4))
    else:
        return False

### VIEW FUNCTIONS ###

@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @dev Returns the number of NFTs owned by `_owner`.
         Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    @param _owner Address for whom to query the balance.
    """

    return self._balanceOf(_owner)


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
    return (self.ownerToOperators[_owner])[_operator]

@view
@external
def name() -> String[64]:
	"""
	@dev Get the name of the token
	"""
	return self.tokenName

@view
@external
def symbol() -> String[32]:
	"""
	@dev Get the symbol of the token
	"""
	return self.tokenSymbol

@view
@external
def tokenURI(_tokenId: uint256) -> String[200]:
	"""
	@dev Returns the URI for the token ID
	@param _tokenId id of the ERC721 token
	"""
	assert self.idToOwner[_tokenId] != ZERO_ADDRESS

	return concat(
			self.baseTokenURI,
			self.idToURI[_tokenId]
		)

@view
@external
def totalSupply() -> uint256:
	"""
	@dev Returns total supply
	"""
	return self._totalSupply()

@view
@external
def tokenByIndex(_index: uint256) -> uint256:
	"""
	@dev Get token by index
		Throws if '_index' is larger than totalSupply()
	"""
	assert _index <= self._totalSupply() - self.burntCount
	assert _index > 0

	return self.indexToTokenId[_index]

@view
@external
def tokenOfOwnerByIndex(_owner: address, _index: uint256) -> uint256:
	"""
	@dev	Get token by index
			Throws if '_index' is larger than balance of '_owner'
			Throws if value has been set to 0
	"""
	assert _index <= self._balanceOf(_owner)

	assert self.ownerToNFTokenIdList[_owner][_index] != 0
	return self.ownerToNFTokenIdList[_owner][_index]


@view
@external
def baseURI() -> String[100]:
	return self.baseTokenURI


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
def _addTokenToOwnerList(_to: address, _tokenId: uint256):
	"""
	@dev Add a NFT to an index mapping to a given address
	@param to address of the receiver
	@param tokenId uint256 ID Of the token to be added
	"""
	current_count: uint256 = self._balanceOf(_to)

	self.ownerToNFTokenIdList[_to][current_count] = _tokenId
	self.tokenToOwnerIndex[_tokenId] = current_count


@internal
def _removeTokenFromOwnerList(_from: address, _tokenId: uint256):
    """
    @dev Remove a NFT from an index mapping to a given address
    @param from address of the sender
    @param tokenId uint256 ID Of the token to be removed
    """
    # Delete
    current_count: uint256 = self._balanceOf(_from)
    current_index: uint256 = self.tokenToOwnerIndex[_tokenId]

    if current_count == current_index:
        # update ownerToNFTokenIdList
        self.ownerToNFTokenIdList[_from][current_count] = 0
        # update tokenToOwnerIndex
        self.tokenToOwnerIndex[_tokenId] = 0

    else:
        lastTokenId: uint256 = self.ownerToNFTokenIdList[_from][current_count]

        # Add
        # update ownerToNFTokenIdList
        self.ownerToNFTokenIdList[_from][current_index] = lastTokenId
        # update tokenToOwnerIndex
        self.tokenToOwnerIndex[lastTokenId] = current_index

        # Delete
        # update ownerToNFTokenIdList
        self.ownerToNFTokenIdList[_from][current_count] = 0
        # update tokenToOwnerIndex
        self.tokenToOwnerIndex[_tokenId] = 0

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
	# Update owner token index tracking
    self._addTokenToOwnerList(_to, _tokenId)


@internal
def _removeTokenFrom(_from: address, _tokenId: uint256):
    """
    @dev Remove a NFT from a given address
         Throws if `_from` is not the current owner.
    """
    # Throws if `_from` is not the current owner
    assert self.idToOwner[_tokenId] == _from

	# Update owner token index tracking
    self._removeTokenFromOwnerList(_from, _tokenId)

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


@internal
def _setTokenURI(_tokenId: uint256, _tokenURI: String[100]):
	"""
	@dev Set the URI for a token
		 Throws if the token ID does not exist
	"""
	assert self.idToOwner[_tokenId] != ZERO_ADDRESS

	self.idToURI[_tokenId] = _tokenURI

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


### MINT & BURN FUNCTIONS ###

@internal
def _mint(_to: address, _tokenURI: String[100]) -> bool:
	"""
	@dev Function to mint tokens
		 Throws if `_to` is zero address.
		 Throws if `_tokenId` is owned by someone.
	@param _to The address that will receive the minted tokens.
	@param _tokenURI The token URI
	@return A boolean that indicates if the operation was successful.
	"""
	# Throws if `_to` is zero address
	assert _to != ZERO_ADDRESS
	# Throws if '_tokenId' is equal to or greater than 'self.maxSupply'
	assert self.tokenId < self.maxSupply
	# loop through idToURI and throw if _tokenURI exists
	for i in range(150):
		assert _tokenURI != self.idToURI[i+1]
	# loop through idToOwner and throw if _addressCounter gets to 2 (max NFTs allowed per address)
	_addressCounter: uint256 = 0
	for i in range(150):
		if self.idToOwner[i+1] == _to:
			_addressCounter += 1
		assert _addressCounter <= 2
	# Add NFT. Throws if `_tokenId` is owned by someone
	self.tokenId += 1
	_tokenId: uint256 = self.tokenId
	self._addTokenTo(_to, _tokenId)
	current_index: uint256 = self._totalSupply() - self.burntCount
	self.indexToTokenId[current_index] = _tokenId
	self.tokenIdToIndex[_tokenId] = current_index
	self._setTokenURI(_tokenId, _tokenURI)
	log Transfer(ZERO_ADDRESS, _to, _tokenId)

	return True

@payable
@external
def mint(_to: address, _tokenURI: String[100]) -> bool:
	"""
	@dev Function to mint a token
	@return Boolean indicating if operation was successful
	"""
	# Throws if msg.value is not equal to mintPrice
	assert msg.value == self.mintPrice

	# Throws if `_to` is zero address
	assert _to != ZERO_ADDRESS
	self._mint(_to, _tokenURI)
	return True

@external
def withdraw():
    """
    @dev Function to withdraw funds
         Throws if `msg.sender` is not `self.admin`
    """
    send(self.beneficiary, self.balance)

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
    current_index: uint256 = self.tokenIdToIndex[_tokenId]
    last_index: uint256 = self._totalSupply() - self.burntCount

    last_index_token_id: uint256 = self.indexToTokenId[last_index]

    # Set last index to current index
    self.indexToTokenId[current_index] = last_index_token_id
    self.tokenIdToIndex[last_index_token_id] = current_index

    # Remove burnt token from mapping of token ID to index
    self.tokenIdToIndex[_tokenId] = 0

	# Increment coun of burnt tokens
    self.burntCount += 1

    log Transfer(owner, ZERO_ADDRESS, _tokenId)