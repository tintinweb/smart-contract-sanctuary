from vyper.interfaces import ERC721

implements: ERC721

interface ERC721Receiver:
  def onERC721Received(
    _operator: address,
    _from: address,
    _tokenId: uint256,
    _data: Bytes[1024]
  ) -> bytes32: view

event Transfer:
  sender: indexed(address)
  receiver: indexed(address)
  tokenId: indexed(uint256)

event Approval:
  owner: indexed(address)
  approved: indexed(address)
  tokenId: indexed(uint256)

event ApprovalForAll:
  owner: indexed(address)
  operator: indexed(address)
  approved: bool

idToOwner: HashMap[uint256, address]

idToApprovals: HashMap[uint256, address]

ownerToNFTokenCount: HashMap[address, uint256]

ownerToOperators: HashMap[address, HashMap[address, bool]]

_tokenURIs: HashMap[uint256, String[256]]

minter: address
baseURI: public(String[256])
tokenCounter: public(uint256)

supportedInterfaces: HashMap[bytes32, bool]

ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7
ERC721_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000080ac58cd


@external
def __init__():
    self.supportedInterfaces[ERC165_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_INTERFACE_ID] = True
    self.minter = msg.sender
    self.tokenCounter = 0


@view
@external
def supportsInterface(_interfaceID: bytes32) -> bool:
    return self.supportedInterfaces[_interfaceID]


@view
@external
def balanceOf(_owner: address) -> uint256:
    assert _owner != ZERO_ADDRESS
    return self.ownerToNFTokenCount[_owner]

@view
@external
def ownerOf(_tokenId: uint256) -> address:
    owner: address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    return owner

@view
@external
def getApproved(_tokenId: uint256) -> address:
    assert self.idToOwner[_tokenId] != ZERO_ADDRESS
    return self.idToApprovals[_tokenId]

@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    return (self.ownerToOperators[_owner])[_operator]


@view
@internal
def _isApprovedOrOwner(_spender: address, _tokenId: uint256) -> bool:
    owner: address = self.idToOwner[_tokenId]
    spenderIsOwner: bool = owner == _spender
    spenderIsApproved: bool = _spender == self.idToApprovals[_tokenId]
    spenderIsApprovedForAll: bool = (self.ownerToOperators[owner])[_spender]
    return (spenderIsOwner or spenderIsApproved) or spenderIsApprovedForAll


@internal
def _addTokenTo(_to: address, _tokenId: uint256):
    assert self.idToOwner[_tokenId] == ZERO_ADDRESS
    self.idToOwner[_tokenId] = _to
    self.ownerToNFTokenCount[_to] += 1


@internal
def _removeTokenFrom(_from: address, _tokenId: uint256):
    assert self.idToOwner[_tokenId] == _from
    self.idToOwner[_tokenId] = ZERO_ADDRESS
    self.ownerToNFTokenCount[_from] -= 1


@internal
def _clearApproval(_owner: address, _tokenId: uint256):
    assert self.idToOwner[_tokenId] == _owner
    if self.idToApprovals[_tokenId] != ZERO_ADDRESS:
        self.idToApprovals[_tokenId] = ZERO_ADDRESS


@internal
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
    assert self._isApprovedOrOwner(_sender, _tokenId)
    assert _to != ZERO_ADDRESS
    self._clearApproval(_from, _tokenId)
    self._removeTokenFrom(_from, _tokenId)
    self._addTokenTo(_to, _tokenId)
    log Transfer(_from, _to, _tokenId)

@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    self._transferFrom(_from, _to, _tokenId, msg.sender)

@external
def safeTransferFrom(
        _from: address,
        _to: address,
        _tokenId: uint256,
        _data: Bytes[1024]=b""
    ):
    self._transferFrom(_from, _to, _tokenId, msg.sender)
    if _to.is_contract: # check if `_to` is a contract address
        returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
        assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes32)


@external
def approve(_approved: address, _tokenId: uint256):
    owner: address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    assert _approved != owner
    senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
    senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[msg.sender]
    assert (senderIsOwner or senderIsApprovedForAll)
    self.idToApprovals[_tokenId] = _approved
    log Approval(owner, _approved, _tokenId)


@external
def setApprovalForAll(_operator: address, _approved: bool):
    assert _operator != msg.sender
    self.ownerToOperators[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)


@internal
def _mint(_to: address, _tokenId: uint256) -> bool:
    self._addTokenTo(_to, _tokenId)
    log Transfer(ZERO_ADDRESS, _to, _tokenId)
    return True


@external
def mint(_to: address, _tokenId: uint256) -> bool:
    assert msg.sender == self.minter
    assert _to != ZERO_ADDRESS
    return self._mint(_to, _tokenId)



@external
def burn(_tokenId: uint256):
    assert self._isApprovedOrOwner(msg.sender, _tokenId)
    owner: address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    self._clearApproval(owner, _tokenId)
    self._removeTokenFrom(owner, _tokenId)
    log Transfer(owner, ZERO_ADDRESS, _tokenId)


@external
def setBaseURI(_baseURI: String[256]) -> bool:
  self.baseURI = _baseURI
  return True

@internal
def _setTokenURI(tokenId: uint256, _tokenURI: String[256]):
  self._tokenURIs[tokenId] = _tokenURI

@external
def setTokenURI(tokenId: uint256, _tokenURI: String[256]):
  self._tokenURIs[tokenId] = _tokenURI

@external
def createCollectible(tokenURI: String[256]) -> uint256:
  assert msg.sender == self.minter
  newItemId: uint256 = self.tokenCounter
  self._mint(msg.sender, newItemId)
  self._setTokenURI(newItemId, tokenURI)
  self.tokenCounter = self.tokenCounter + 1
  return self.tokenCounter