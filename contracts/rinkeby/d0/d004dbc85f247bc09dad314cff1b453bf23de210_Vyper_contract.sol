# Modified from: https://github.com/ethereum/vyper/blob/master/examples/tokens/ERC721.vy

contract ERC721Receiver:
    def onERC721Received(
        _operator: address,
        _from: address,
        _tokenId: uint256,
        _data: bytes[1024]
    ) -> bytes32: modifying

contract URI:
    def tokenURI(_tokenId: uint256) -> string[128]: constant

contract Socks:
    def totalSupply() -> uint256: constant

Transfer: event({_from: indexed(address), _to: indexed(address), _tokenId: indexed(uint256)})
Approval: event({_owner: indexed(address), _approved: indexed(address), _tokenId: indexed(uint256)})
ApprovalForAll: event({_owner: indexed(address), _operator: indexed(address), _approved: bool})

name: public(string[32])
symbol: public(string[32])
totalSupply: public(uint256)

minter: public(address)
socks: public(Socks)
newURI: public(address)

ownerOf: public(map(uint256, address))                     # map(tokenId, owner)
balanceOf: public(map(address, uint256))                   # map(owner, balance)
getApproved: public(map(uint256, address))                 # map(tokenId, approvedSpender)
isApprovedForAll: public(map(address, map(address, bool))) # map(owner, map(operator, bool))
supportsInterface: public(map(bytes32, bool))              # map(interfaceId, bool)
ownerIndexToTokenId: map(address, map(uint256, uint256))   # map(owner, map(index, tokenId))
tokenIdToIndex: map(uint256, uint256)                      # map(tokenId, index)

ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7
ERC721_ENUMERABLE_INTERFACE_ID: constant(bytes32) = 0x00000000000000000000000000000000000000000000000000000000780e9d63
ERC721_METADATA_INTERFACE_ID: constant(bytes32) = 0x000000000000000000000000000000000000000000000000000000005b5e139f
ERC721_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000080ac58cd


@public
def __init__(_socks: address):
    self.name = 'Rooksocks'
    self.symbol = 'ROCKS'
    self.minter = msg.sender
    self.socks = Socks(_socks)
    self.supportsInterface[ERC165_INTERFACE_ID] = True
    self.supportsInterface[ERC721_ENUMERABLE_INTERFACE_ID] = True
    self.supportsInterface[ERC721_METADATA_INTERFACE_ID] = True
    self.supportsInterface[ERC721_INTERFACE_ID] = True


@public
@constant
def tokenURI(_tokenId: uint256) -> string[128]:
    if (self.newURI == ZERO_ADDRESS):
        return 'https://cloudflare-ipfs.com/ipfs/QmNZEeAN1zk6hLoHHREVkZ7PoPYaoH7n6LR6w9QAcEc29h'
    else:
        return URI(self.newURI).tokenURI(_tokenId)


# Token index is same as ID and can't change
@public
@constant
def tokenByIndex(_index: uint256) -> uint256:
    assert _index < self.totalSupply
    return _index

@public
@constant
def tokenOfOwnerByIndex(_owner: address, _index: uint256) -> uint256:
    assert _index < self.balanceOf[_owner]
    return self.ownerIndexToTokenId[_owner][_index]

@private
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
    _owner: address = self.ownerOf[_tokenId]
    # Check requirements
    assert _owner == _from and _to != ZERO_ADDRESS
    _senderIsOwner: bool = _sender == _owner
    _senderIsApproved: bool = _sender == self.getApproved[_tokenId]
    _senderIsApprovedForAll: bool = self.isApprovedForAll[_owner][_sender]
    assert _senderIsOwner or _senderIsApproved or _senderIsApprovedForAll
    # Update ownerIndexToTokenId for _from
    _highestIndexFrom: uint256 = self.balanceOf[_from] - 1   # get highest index of _from
    _tokenIdIndexFrom: uint256 = self.tokenIdToIndex[_tokenId] # get index of _from where _tokenId is
    if _highestIndexFrom == _tokenIdIndexFrom:               # _tokenId is the last token in _from's list
        self.ownerIndexToTokenId[_from][_highestIndexFrom] = 0
    else:
        self.ownerIndexToTokenId[_from][_tokenIdIndexFrom] = self.ownerIndexToTokenId[_from][_highestIndexFrom]
        self.ownerIndexToTokenId[_from][_highestIndexFrom] = 0
    # Update ownerIndexToTokenId for _to
    _newHighestIndexTo: uint256 = self.balanceOf[_to]
    self.ownerIndexToTokenId[_to][_newHighestIndexTo] = _tokenId
    # Update tokenIdToIndex
    self.tokenIdToIndex[_tokenId] = _newHighestIndexTo
    # update ownerOf and balanceOf
    self.ownerOf[_tokenId] = _to
    self.balanceOf[_from] -= 1
    self.balanceOf[_to] += 1
    # Clear approval.
    if self.getApproved[_tokenId] != ZERO_ADDRESS:
        self.getApproved[_tokenId] = ZERO_ADDRESS
    log.Transfer(_from, _to, _tokenId)


@public
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    self._transferFrom(_from, _to, _tokenId, msg.sender)


@public
def safeTransferFrom(_from: address, _to: address, _tokenId: uint256, _data: bytes[1024]=""):
    self._transferFrom(_from, _to, _tokenId, msg.sender)
    if _to.is_contract:
        returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert returnValue == method_id('onERC721Received(address,address,uint256,bytes)', bytes32)


@public
def approve(_approved: address, _tokenId: uint256):
    owner: address = self.ownerOf[_tokenId]
    # Check requirements
    senderIsOwner: bool = msg.sender == owner
    senderIsApprovedForAll: bool = (self.isApprovedForAll[owner])[msg.sender]
    assert senderIsOwner or senderIsApprovedForAll
    # Set the approval
    self.getApproved[_tokenId] = _approved
    log.Approval(owner, _approved, _tokenId)


@public
def setApprovalForAll(_operator: address, _approved: bool):
    assert _operator != msg.sender
    self.isApprovedForAll[msg.sender][_operator] = _approved
    log.ApprovalForAll(msg.sender, _operator, _approved)


@public
def mint(_to: address) -> bool:
    assert msg.sender == self.minter and _to != ZERO_ADDRESS
    _tokenId: uint256 = self.totalSupply
    _toBal: uint256 = self.balanceOf[_to]
    # can only mint if a sock has been burned
    _socksSupply: uint256 = self.socks.totalSupply()
    _socksBurned: uint256 = 500 * 10**18 - _socksSupply
    assert _tokenId * 10**18 < _socksBurned
    # update mappings
    self.ownerOf[_tokenId] = _to
    self.balanceOf[_to] += 1
    self.ownerIndexToTokenId[_to][_toBal] = _tokenId
    self.tokenIdToIndex[_tokenId] = _toBal
    self.totalSupply += 1
    log.Transfer(ZERO_ADDRESS, _to, _tokenId)
    return True


@public
def changeMinter(_minter: address):
    assert msg.sender == self.minter
    self.minter = _minter

@public
def changeURI(_newURI: address):
    assert msg.sender == self.minter
    self.newURI = _newURI