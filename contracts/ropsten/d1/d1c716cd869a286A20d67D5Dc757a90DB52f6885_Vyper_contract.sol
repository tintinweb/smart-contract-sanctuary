# @version 0.3.0
"""
@title Bee NFT
@license MIT
@notice Contract for Bee NFTs
"""

from vyper.interfaces import ERC721

implements: ERC721

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
            _operator: address,
            _from: address,
            _token_id: uint256,
            _data: Bytes[1024]
        ) -> bytes32: view


interface Pollen:
    def settle(_owner: address) -> uint256: nonpayable


# @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
#      created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
#      number of NFTs may be created and assigned without emitting Transfer. At the time of any
#      transfer, the approved address for that NFT (if any) is reset to none.
# @param _from Sender of NFT (if address is zero address it indicates token creation).
# @param _to Receiver of NFT (if address is zero address it indicates token destruction).
# @param _token_id The NFT that got transferred.
event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _tokenId: indexed(uint256)

# @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
#      address indicates there is no approved address. When a Transfer event emits, this also
#      indicates that the approved address for that NFT (if any) is reset to none.
# @param _owner Owner of NFT.
# @param _approved Address that we are approving.
# @param _token_id NFT which we are approving.
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


pollen: public(address)

### OWNERSHIP VARIABLES ###

owner_of: HashMap[uint256, address]

balance_of: HashMap[address, uint256]

approved: HashMap[uint256, address]
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])

MAX_BEES: constant(uint256) = 10000
totalSupply: public(uint256)


### METADATA INFORMATION ###
official_site: public(String[64])
baseURI: public(String[64])


### MINT INFORMATION ###
minted: HashMap[address, uint256]

mint_price: public(uint256)
mint_limit: public(uint256)

mint_is_active: public(bool)  # initially is False

MAX_MINT: constant(uint256) = 15  # Max amount of tokens minted per tx


### PRESALE INFORMATION ###
presale_price: public(uint256)
presale_limit: public(uint256)

presale_signer: address

presale_is_active: public(bool)  # initially is False


PREMINT_AMOUNT: constant(uint256) = 10  # Amount of tokens minted to the team
admin: public(address)
future_admin: public(address)


supportsInterface: public(HashMap[bytes32, bool])
ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7
ERC721_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000080ac58cd
ERC721METADATA_INTERFACE_ID: constant(bytes32) = 0x000000000000000000000000000000000000000000000000000000005b5e139f


@external
def __init__():
    """
    @dev Contract constructor.
    """
    self.supportsInterface[ERC165_INTERFACE_ID] = True
    self.supportsInterface[ERC721_INTERFACE_ID] = True
    self.supportsInterface[ERC721METADATA_INTERFACE_ID] = True

    self.mint_price = 80 * 10 ** 15  # 0.08 ETH
    self.mint_limit = 10  # 10 bees per address

    self.presale_price = 59 * 10 ** 15  # 0.059 ETH
    self.presale_limit = 3  # 3 bees per address

    self.admin = msg.sender

    # Premint
    for i in range(PREMINT_AMOUNT):
        self.owner_of[i] = msg.sender
        log Transfer(ZERO_ADDRESS, msg.sender, i)

    self.balance_of[msg.sender] = PREMINT_AMOUNT
    self.totalSupply = PREMINT_AMOUNT


@external
@pure
def name() -> String[64]:
    """
    @notice A descriptive name for a collection of NFTs in this contract
    """
    return "Sloppy Bees"


@external
@pure
def symbol() -> String[32]:
    """
    @notice An abbreviated name for NFTs in this contract
    """
    return "BEE"


@internal
@pure
def _to_string(_num: uint256) -> String[5]:
    """
    @dev Vyper does not support 'to_string' fot integers.
         Assumed to receive _num < 10^5
    """
    num: uint256 = _num
    result: String[5] = "/////"  # Random symbols, so slice does not fail
    for i in range(5):
        digit: String[1] = slice("0123456789", num % 10, 1)
        result = slice(concat(digit, result), 0, 5)
        num /= 10
        if num == 0:
            result = slice(result, 0, 1 + i)
            break
    return result


@external
@view
def tokenURI(_token_id: uint256) -> String[69]:
    """
    @dev Throws if `_token_id` is not a valid NFT
    @param _token_id A distinct Uniform Resource Identifier (URI) for a given asset.
    @return URI of the token
    """
    assert self.owner_of[_token_id] != ZERO_ADDRESS  # dev: invalid token_id
    id: String[5] = self._to_string(_token_id)
    return concat(self.baseURI, id)


@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @dev Returns the number of NFTs owned by `_owner`.
         Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    @param _owner Address for whom to query the balance.
    """
    assert _owner != ZERO_ADDRESS
    return self.balance_of[_owner]


@view
@external
def ownerOf(_tokenId: uint256) -> address:
    """
    @dev Returns the address of the owner of the NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId The identifier for an NFT.
    """
    owner: address = self.owner_of[_tokenId]
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
    assert self.owner_of[_tokenId] != ZERO_ADDRESS
    return self.approved[_tokenId]


### TRANSFER FUNCTION HELPERS ###


@internal
@view
def _isApprovedOrOwner(_spender: address, _token_id: uint256) -> bool:
    """
    @dev Returns whether the given spender can transfer a given token ID
    @param spender address of the spender to query
    @param tokenId uint256 ID of the token to be transferred
    @return bool whether the msg.sender is approved for the given token ID,
        is an operator of the owner, or is the owner of the token
    """
    owner: address = self.owner_of[_token_id]

    spender_is_owner: bool = owner == _spender
    spender_is_approved: bool = _spender == self.approved[_token_id]
    spender_is_approved_for_all: bool = (self.isApprovedForAll[owner])[_spender]

    return (spender_is_owner or spender_is_approved) or spender_is_approved_for_all


@internal
def _add_token_to(_to: address, _token_id: uint256):
    """
    @dev Add a NFT to a given address.
         Throws if `_token_id` is owned by someone
    """
    assert self.owner_of[_token_id] == ZERO_ADDRESS
    Pollen(self.pollen).settle(_to)
    self.owner_of[_token_id] = _to
    self.balance_of[_to] += 1


@internal
def _remove_token_from(_from: address, _token_id: uint256):
    """
    @dev Remove a NFT from a given address
         Throws if `_from` is not the current owner.
    """
    assert self.owner_of[_token_id] == _from
    Pollen(self.pollen).settle(_from)
    self.owner_of[_token_id] = ZERO_ADDRESS
    self.balance_of[_from] -= 1


@internal
def _clear_approval(_owner: address, _token_id: uint256):
    """
    @dev Clear an approval of a given address
         Throws if `_owner` is not the current owner.
    """
    assert self.owner_of[_token_id] == _owner
    if self.approved[_token_id] != ZERO_ADDRESS:
        self.approved[_token_id] = ZERO_ADDRESS


@internal
def _transfer_from(_from: address, _to: address, _token_id: uint256, _sender: address):
    """
    @dev Execute transfer of a NFT.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT. (NOTE: `msg.sender` not allowed in private function so pass `_sender`.)
         Throws if `_to` is the zero address.
         Throws if `_from` is not the current owner.
         Throws if `_token_id` is not a valid NFT.
    """
    assert self._isApprovedOrOwner(_sender, _token_id)
    assert _to != ZERO_ADDRESS

    self._clear_approval(_from, _token_id)
    self._remove_token_from(_from, _token_id)
    self._add_token_to(_to, _token_id)

    log Transfer(_from, _to, _token_id)


@internal
def _check_on_erc721_received(_from: address, _to: address, _token_id: uint256, _data: Bytes[1024]):
    if _to.is_contract:
        returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(_from, _to, _token_id, _data)
        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert returnValue == convert(method_id("onERC721Received(address,address,uint256,bytes)"), bytes32)


### TRANSFER FUNCTIONS ###


@external
def transferFrom(_from: address, _to: address, _token_id: uint256):
    """
    @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `_from` is not the current owner.
         Throws if `_to` is the zero address.
         Throws if `_token_id` is not a valid NFT.
    @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
            they maybe be permanently lost.
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _token_id The NFT to transfer.
    """
    self._transfer_from(_from, _to, _token_id, msg.sender)


@external
def safeTransferFrom(
        _from: address,
        _to: address,
        _token_id: uint256,
        _data: Bytes[1024]=b""
    ):
    """
    @dev Transfers the ownership of an NFT from one address to another address.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the
         approved address for this NFT.
         Throws if `_from` is not the current owner.
         Throws if `_to` is the zero address.
         Throws if `_token_id` is not a valid NFT.
         If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
         the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
         NOTE: bytes4 is represented by bytes32 with padding
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _token_id The NFT to transfer.
    @param _data Additional data with no specified format, sent in call to `_to`.
    """
    self._transfer_from(_from, _to, _token_id, msg.sender)
    self._check_on_erc721_received(_from, _to, _token_id, _data)


@external
def approve(_approved: address, _token_id: uint256):
    """
    @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
         Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
         Throws if `_token_id` is not a valid NFT. (NOTE: This is not written the EIP)
         Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    @param _approved Address to be approved for the given NFT ID.
    @param _token_id ID of the token to be approved.
    """
    owner: address = self.owner_of[_token_id]

    assert owner != ZERO_ADDRESS
    assert _approved != owner

    sender_is_owner: bool = self.owner_of[_token_id] == msg.sender
    sender_is_approved_for_all: bool = (self.isApprovedForAll[owner])[msg.sender]
    assert (sender_is_owner or sender_is_approved_for_all)

    self.approved[_token_id] = _approved
    log Approval(owner, _approved, _token_id)


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
    assert _operator != msg.sender

    self.isApprovedForAll[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)


### MINT & BURN FUNCTIONS ###


@internal
def _safe_mint(_number_of_bees: uint256, _to: address):
    Pollen(self.pollen).settle(_to)
    token_id: uint256 = self.totalSupply

    for i in range(MAX_MINT):
        if i == _number_of_bees:
            break
        self.owner_of[token_id] = _to
        self._check_on_erc721_received(ZERO_ADDRESS, _to, token_id, b"")
        log Transfer(ZERO_ADDRESS, _to, token_id)
        token_id += 1

    self.balance_of[_to] += _number_of_bees
    self.totalSupply += _number_of_bees


@external
@payable
@nonreentrant("mint")
def mint(_number_of_bees: uint256 = 1, _to: address = msg.sender) -> bool:
    """
    @dev Function to mint tokens
         Throws if `_to` is zero address.
         Throws if `_to` is contract and it does not implement `onERC721Received`
    @param _number_of_bees Number of Bees to mint.
    @param _to The address that will receive the minted tokens.
    @return A boolean that indicates if the operation was successful.
    """
    assert self.mint_is_active  # dev: mint is not active
    assert _to != ZERO_ADDRESS

    assert _number_of_bees <= MAX_MINT  # dev: too many bees
    assert self.minted[msg.sender] / MAX_BEES + _number_of_bees <= self.mint_limit  # dev: too many tokens for you
    assert self.totalSupply + _number_of_bees <= MAX_BEES  # dev: all bees are minted

    assert msg.value == _number_of_bees * self.mint_price  # dev: incorrect ETH amount

    self._safe_mint(_number_of_bees, _to)
    self.minted[msg.sender] += _number_of_bees * MAX_BEES
    return True


@internal
@view
def _signature_is_valid(_from: address, _signature: Bytes[65]) -> bool:
    """
    @dev Check that signature is `_from` signed my signer
    """
    hash: bytes32 = keccak256(convert(_from, bytes32))

    r: uint256 = extract32(_signature, 0, output_type=uint256)
    s: uint256 = extract32(_signature, 32, output_type=uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)

    assert v == 27 or v == 28

    signer: address = ecrecover(hash, v, r, s)
    return self.presale_signer == signer


@external
@payable
@nonreentrant("mint")
def presale(_number_of_bees: uint256, _signature: Bytes[65], _to: address = msg.sender) -> bool:
    """
    @dev Function to mint tokens on presale
         Throws if `_to` is zero address.
         Throws if `_to` is contract and it does not implement `onERC721Received`
    @param _number_of_bees Number of Bees to mint.
    @param _signature Signature made bh the team to whitelist presale.
    @param _to The address that will receive the minted tokens.
    @return A boolean that indicates if the operation was successful.
    """
    assert self.presale_is_active  # dev: presale did not start or already ended
    assert _to != ZERO_ADDRESS

    assert self._signature_is_valid(msg.sender, _signature)  # dev: you are not allowed for presale

    assert self.minted[msg.sender] + _number_of_bees <= self.presale_limit  # dev: too many tokens for you
    assert msg.value == _number_of_bees * self.presale_price  # dev: incorrect ETH amount

    self._safe_mint(_number_of_bees, _to)
    self.minted[msg.sender] += _number_of_bees
    return True


@external
def burn(_token_id: uint256):
    """
    @dev Burns a specific ERC721 token.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `_token_id` is not a valid NFT.
    @param _token_id uint256 id of the ERC721 token to be burned.
    """
    assert self._isApprovedOrOwner(msg.sender, _token_id)
    owner: address = self.owner_of[_token_id]
    assert owner != ZERO_ADDRESS

    Pollen(self.pollen).settle(msg.sender)
    self._clear_approval(owner, _token_id)
    self._remove_token_from(owner, _token_id)
    log Transfer(owner, ZERO_ADDRESS, _token_id)


### ADMIN FUNCTIONS ###


@external
def set_base_uri(_base_uri: String[64]):
    """
    @notice set base URI for tokens
    """
    assert msg.sender == self.admin  # dev: admin only
    self.baseURI = _base_uri


@external
def set_pollen(_pollen: address):
    """
    @notice set pollen token to farm
    """
    assert msg.sender == self.admin  # dev: admin only
    # Settlement for premint
    Pollen(_pollen).settle(msg.sender)
    self.pollen = _pollen


@external
def set_official_site(_site: String[64]):
    """
    @notice set official site of the NFT
    """
    assert msg.sender == self.admin  # dev: admin only
    self.official_site = _site


@external
def set_presale_signer(_signer: address):
    """
    @notice set signer of whitelist signatures for presale
    """
    assert msg.sender == self.admin  # dev: admin only
    self.presale_signer = _signer


@external
def start_presale():
    """
    @notice allow presale
    """
    assert msg.sender == self.admin  # dev: admin only
    assert not self.mint_is_active  # dev: mint is active
    assert self.presale_signer != ZERO_ADDRESS  # dev: presale signer is not set
    assert self.pollen != ZERO_ADDRESS  # dev: pollen is not set

    self.presale_is_active = True


@external
def stop_presale():
    """
    @notice disable presale
    """
    assert msg.sender == self.admin  # dev: admin only
    self.presale_is_active = False


@external
def start_mint():
    """
    @notice allow minting
    """
    assert msg.sender == self.admin  # dev: admin only
    assert not self.presale_is_active  # dev: presale is active
    assert self.pollen != ZERO_ADDRESS  # dev: pollen is not set
    self.mint_is_active = True


@external
def stop_mint():
    """
    @notice disable minting
    """
    assert msg.sender == self.admin  # dev: admin only
    self.mint_is_active = False


@external
def set_new_presale(_price: uint256, _limit: uint256):
    """
    @notice Set new prices for minting new tokens
    @param _price Price for minting each token
    @param _limit Amount of tokens one address can mint
    """
    assert msg.sender == self.admin  # dev: admin only
    assert _limit <= MAX_BEES  # dev: too big limit

    self.presale_price = _price
    self.presale_limit = _limit


@external
def set_new_mint(_price: uint256, _limit: uint256):
    """
    @notice Set new prices for minting new tokens
    @param _price Price for minting each token
    @param _limit Amount of tokens one address can mint
    """
    assert msg.sender == self.admin  # dev: admin only
    assert _limit <= MAX_BEES  # dev: too big limit

    self.mint_price = _price
    self.mint_limit = _limit


@external
def withdraw(_to: address = msg.sender):
    """
    @notice send received ether
    """
    assert msg.sender == self.admin  # dev: admin only
    send(_to, self.balance)


@external
def commit_new_admin(_new_admin: address):
    """
    @notice transfer admin rights to another address
    """
    assert msg.sender == self.admin  # dev: admin only
    self.future_admin = _new_admin


@external
def apply_new_admin():
    """
    @dev should be called from the new admin
    """
    assert msg.sender == self.future_admin  # dev: new admin only
    self.admin = self.future_admin