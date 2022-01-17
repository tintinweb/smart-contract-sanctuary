# @version 0.3.1
"""
@title Voting Escrow
@author Curve Finance
@license MIT
@notice Votes have a weight depending on time, so that users are
        committed to the future of (whatever they are voting for)
@dev Vote weight decays linearly over time. Lock time cannot be
     more than `MAXTIME` (4 years).
"""

# Voting escrow to have time-weighted votes
# Votes have a weight depending on time, so that users are committed
# to the future of (whatever they are voting for).
# The weight in this implementation is linear, and lock cannot be more than maxtime:
# w ^
# 1 +        /
#   |      /
#   |    /
#   |  /
#   |/
# 0 +--------+------> time
#       maxtime (4 years?)

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
    def name(
            _name: String[64]
        ) -> String[64]: view

    def symbol(
            _symbol: String[32]
        ) -> String[32]: view

    def tokenURI(
            _tokenId: uint256
        ) -> String[2048]: view

# Interface for ERC721Enumerable

interface ERC721Enumerable:

    def totalSupply() -> uint256: view

    def tokenByIndex(
        _tokenId: uint256
    ) -> uint256: view

    def tokenOfOwnerByIndex(
        _owner: address,
        _tokenId: uint256
    ) -> uint256: view

struct Point:
    bias: int128
    slope: int128  # - dweight / dt
    ts: uint256
    blk: uint256  # block
# We cannot really do block numbers per se b/c slope is per time, not per block
# and per block could be fairly bad b/c Ethereum changes blocktimes.
# What we can do is to extrapolate ***At functions

struct LockedBalance:
    amount: int128
    end: uint256


interface ERC20:
    def decimals() -> uint256: view
    def name() -> String[64]: view
    def symbol() -> String[32]: view
    def transfer(to: address, amount: uint256) -> bool: nonpayable
    def transferFrom(spender: address, to: address, amount: uint256) -> bool: nonpayable

interface Tokenizer:
    def tokenURI(tokenId: uint256, balanceOf: uint256, locked_end: uint256, _value: uint256) -> String[2048]: view

DEPOSIT_FOR_TYPE: constant(int128) = 0
CREATE_LOCK_TYPE: constant(int128) = 1
INCREASE_LOCK_AMOUNT: constant(int128) = 2
INCREASE_UNLOCK_TIME: constant(int128) = 3
MERGE_TYPE: constant(int128) = 4

event Deposit:
    provider: indexed(address)
    tokenId: uint256
    value: uint256
    locktime: indexed(uint256)
    type: int128
    ts: uint256

event Withdraw:
    provider: indexed(address)
    tokenId: uint256
    value: uint256
    ts: uint256

event Supply:
    prevSupply: uint256
    supply: uint256

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

WEEK: constant(uint256) = 7 * 86400  # all future times are rounded by week
MAXTIME: constant(uint256) = 4 * 365 * 86400  # 4 years
MULTIPLIER: constant(uint256) = 10 ** 18

token: public(address)
supply: public(uint256)

locked: public(HashMap[uint256, LockedBalance])

epoch: public(uint256)
point_history: public(Point[100000000000000000000000000000])  # epoch -> unsigned point
user_point_history: public(HashMap[uint256, Point[1000000000]])  # user -> Point[user_epoch]
user_point_epoch: public(HashMap[uint256, uint256])
slope_changes: public(HashMap[uint256, int128])  # time -> signed slope change

name: public(String[64])
symbol: public(String[32])
version: public(String[32])
decimals: public(uint256)
tokenizer: address

MIN_VE: constant(uint256) = 2500 * 10**18

blockTransfers: HashMap[address, bool]

# @dev Current count of token
tokenId: uint256

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

# @dev Address of URI contract
tokenBaseURI: public(String[128])

# @dev Mapping of interface id to bool about whether or not it's supported
supportedInterfaces: HashMap[bytes32, bool]

# @dev ERC165 interface ID of ERC165
ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7

# @dev ERC165 interface ID of ERC721
ERC721_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000080ac58cd

# @dev ERC165 interface ID of ERC721Metadata
ERC721_METADATA_INTERFACE_ID: constant(bytes32) = 0x000000000000000000000000000000000000000000000000000000005b5e139f

# @dev ERC165 interface ID of ERC721Enumerable

ERC721_ENUMERABLE_INTERFACE_ID: constant(bytes32) = 0x00000000000000000000000000000000000000000000000000000000780e9d63

@external
def __init__(token_addr: address, _name: String[64], _symbol: String[32], _version: String[32], tokenizer: address):
    """
    @notice Contract constructor
    @param token_addr `ERC20CRV` token address
    @param _name Token name
    @param _symbol Token symbol
    @param _version Contract version - required for Aragon compatibility
    """
    self.token = token_addr
    self.point_history[0].blk = block.number
    self.point_history[0].ts = block.timestamp

    _decimals: uint256 = ERC20(token_addr).decimals()
    assert _decimals <= 255
    self.decimals = _decimals

    self.name = _name
    self.symbol = _symbol
    self.version = _version
    self.tokenizer = tokenizer

    self.supportedInterfaces[ERC165_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_ENUMERABLE_INTERFACE_ID] = True
    self.tokenId = 0

    log Transfer(ZERO_ADDRESS, msg.sender, 0)

@view
@external
def supportsInterface(_interfaceID: bytes32) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param _interfaceID Id of the interface
    """
    return self.supportedInterfaces[_interfaceID]

@external
@view
def get_last_user_slope(_tokenId: uint256) -> int128:
    """
    @notice Get the most recently recorded rate of voting power decrease for `_tokenId`
    @param _tokenId token of the NFT
    @return Value of the slope
    """
    uepoch: uint256 = self.user_point_epoch[_tokenId]
    return self.user_point_history[_tokenId][uepoch].slope

@external
@view
def user_point_history__ts(_tokenId: uint256, _idx: uint256) -> uint256:
    """
    @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
    @param _tokenId token of the NFT
    @param _idx User epoch number
    @return Epoch time of the checkpoint
    """
    return self.user_point_history[_tokenId][_idx].ts

@external
@view
def locked__end(_tokenId: uint256) -> uint256:
    """
    @notice Get timestamp when `_tokenId`'s lock finishes
    @param _tokenId User NFT
    @return Epoch time of the lock end
    """
    return self.locked[_tokenId].end


@view
@internal
def _balance(_owner: address) -> uint256:
    """
    @dev Returns the number of NFTs owned by `_owner`.
         Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    @param _owner Address for whom to query the balance.
    """
    return self.ownerToNFTokenCount[_owner]

@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @dev Returns the number of NFTs owned by `_owner`.
         Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    @param _owner Address for whom to query the balance.
    """
    return self._balance(_owner)

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
def tokenByIndex(_tokenId: uint256) -> uint256:
    """
    @dev  Get token by index
          Throws if '_tokenId' is larger than totalSupply()
    """
    assert _tokenId <= self.tokenId

    return self.tokenId

@view
@external
def tokenOfOwnerByIndex(_owner: address, _tokenIndex: uint256) -> uint256:
    """
    @dev  Get token by index
    """
    assert _tokenIndex <= self._balance(_owner)
    return self.ownerToNFTokenIdList[_owner][_tokenIndex]

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

@view
@external
def isApprovedOrOwner(_spender: address, _tokenId: uint256) -> bool:
    return self._isApprovedOrOwner(_spender, _tokenId)

@internal
def _addTokenToOwnerList(_to: address, _tokenId: uint256):
    """
    @dev Add a NFT to an index mapping to a given address
    @param to address of the receiver
    @param tokenId uint256 ID Of the token to be added
    """
    current_count: uint256 = self._balance(_to)

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
    current_count: uint256 = self._balance(_from)
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
    # Update owner token index tracking
    self._addTokenToOwnerList(_to, _tokenId)
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
    # Update owner token index tracking
    self._removeTokenFromOwnerList(_from, _tokenId)
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
    assert not self.blockTransfers[_to]
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
def toggleBlockTransfers(toggle: bool):
    self.blockTransfers[msg.sender] = toggle

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

@internal
def _mint(_to: address, _tokenId: uint256) -> bool:
    """
    @dev Function to mint tokens
         Throws if `_to` is zero address.
         Throws if `_tokenId` is owned by someone.
    @param _to The address that will receive the minted tokens.
    @param _tokenId The token id to mint.
    @return A boolean that indicates if the operation was successful.
    """
    # Throws if `_to` is zero address
    assert _to != ZERO_ADDRESS
    # Add NFT. Throws if `_tokenId` is owned by someone
    self._addTokenTo(_to, _tokenId)
    log Transfer(ZERO_ADDRESS, _to, _tokenId)
    return True

@internal
def _checkpoint(_tokenId: uint256, old_locked: LockedBalance, new_locked: LockedBalance):
    """
    @notice Record global and per-user data to checkpoint
    @param _tokenId NFT token ID. No user checkpoint if 0
    @param old_locked Pevious locked amount / end lock time for the user
    @param new_locked New locked amount / end lock time for the user
    """
    u_old: Point = empty(Point)
    u_new: Point = empty(Point)
    old_dslope: int128 = 0
    new_dslope: int128 = 0
    _epoch: uint256 = self.epoch

    if _tokenId != 0:
        # Calculate slopes and biases
        # Kept at zero when they have to
        if old_locked.end > block.timestamp and old_locked.amount > 0:
            u_old.slope = old_locked.amount / MAXTIME
            u_old.bias = u_old.slope * convert(old_locked.end - block.timestamp, int128)
        if new_locked.end > block.timestamp and new_locked.amount > 0:
            u_new.slope = new_locked.amount / MAXTIME
            u_new.bias = u_new.slope * convert(new_locked.end - block.timestamp, int128)

        # Read values of scheduled changes in the slope
        # old_locked.end can be in the past and in the future
        # new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
        old_dslope = self.slope_changes[old_locked.end]
        if new_locked.end != 0:
            if new_locked.end == old_locked.end:
                new_dslope = old_dslope
            else:
                new_dslope = self.slope_changes[new_locked.end]

    last_point: Point = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number})
    if _epoch > 0:
        last_point = self.point_history[_epoch]
    last_checkpoint: uint256 = last_point.ts
    # initial_last_point is used for extrapolation to calculate block number
    # (approximately, for *At methods) and save them
    # as we cannot figure that out exactly from inside the contract
    initial_last_point: Point = last_point
    block_slope: uint256 = 0  # dblock/dt
    if block.timestamp > last_point.ts:
        block_slope = MULTIPLIER * (block.number - last_point.blk) / (block.timestamp - last_point.ts)
    # If last point is already recorded in this block, slope=0
    # But that's ok b/c we know the block in such case

    # Go over weeks to fill history and calculate what the current point is
    t_i: uint256 = (last_checkpoint / WEEK) * WEEK
    for i in range(255):
        # Hopefully it won't happen that this won't get used in 5 years!
        # If it does, users will be able to withdraw but vote weight will be broken
        t_i += WEEK
        d_slope: int128 = 0
        if t_i > block.timestamp:
            t_i = block.timestamp
        else:
            d_slope = self.slope_changes[t_i]
        last_point.bias -= last_point.slope * convert(t_i - last_checkpoint, int128)
        last_point.slope += d_slope
        if last_point.bias < 0:  # This can happen
            last_point.bias = 0
        if last_point.slope < 0:  # This cannot happen - just in case
            last_point.slope = 0
        last_checkpoint = t_i
        last_point.ts = t_i
        last_point.blk = initial_last_point.blk + block_slope * (t_i - initial_last_point.ts) / MULTIPLIER
        _epoch += 1
        if t_i == block.timestamp:
            last_point.blk = block.number
            break
        else:
            self.point_history[_epoch] = last_point

    self.epoch = _epoch
    # Now point_history is filled until t=now

    if _tokenId != 0:
        # If last point was in this block, the slope change has been applied already
        # But in such case we have 0 slope(s)
        last_point.slope += (u_new.slope - u_old.slope)
        last_point.bias += (u_new.bias - u_old.bias)
        if last_point.slope < 0:
            last_point.slope = 0
        if last_point.bias < 0:
            last_point.bias = 0

    # Record the changed point into history
    self.point_history[_epoch] = last_point

    if _tokenId != 0:
        # Schedule the slope changes (slope is going down)
        # We subtract new_user_slope from [new_locked.end]
        # and add old_user_slope to [old_locked.end]
        if old_locked.end > block.timestamp:
            # old_dslope was <something> - u_old.slope, so we cancel that
            old_dslope += u_old.slope
            if new_locked.end == old_locked.end:
                old_dslope -= u_new.slope  # It was a new deposit, not extension
            self.slope_changes[old_locked.end] = old_dslope

        if new_locked.end > block.timestamp:
            if new_locked.end > old_locked.end:
                new_dslope -= u_new.slope  # old slope disappeared at this point
                self.slope_changes[new_locked.end] = new_dslope
            # else: we recorded it already in old_dslope

        # Now handle user history
        user_epoch: uint256 = self.user_point_epoch[_tokenId] + 1

        self.user_point_epoch[_tokenId] = user_epoch
        u_new.ts = block.timestamp
        u_new.blk = block.number
        self.user_point_history[_tokenId][user_epoch] = u_new


@internal
def _deposit_for(_from: address, _tokenId: uint256, _value: uint256, unlock_time: uint256, locked_balance: LockedBalance, type: int128, merge: bool = False):
    """
    @notice Deposit and lock tokens for a user
    @param _tokenId NFT that holds lock
    @param _value Amount to deposit
    @param unlock_time New time when to unlock the tokens, or 0 if unchanged
    @param locked_balance Previous locked amount / timestamp
    """
    _locked: LockedBalance = locked_balance
    supply_before: uint256 = self.supply

    self.supply = supply_before + _value
    old_locked: LockedBalance = _locked
    # Adding to existing lock, or if a lock is expired - creating a new one
    _locked.amount += convert(_value, int128)
    if unlock_time != 0:
        _locked.end = unlock_time
    self.locked[_tokenId] = _locked

    # Possibilities:
    # Both old_locked.end could be current or expired (>/< block.timestamp)
    # value == 0 (extend lock) or value > 0 (add to lock or extend lock)
    # _locked.end > block.timestamp (always)
    self._checkpoint(_tokenId, old_locked, _locked)

    if _value != 0 and not merge:
        assert ERC20(self.token).transferFrom(_from, self, _value)

    log Deposit(_from, _tokenId, _value, _locked.end, type, block.timestamp)
    log Supply(supply_before, supply_before + _value)

@external
def merge(_from: uint256, _to: uint256):
    assert self._isApprovedOrOwner(msg.sender, _from)
    assert self._isApprovedOrOwner(msg.sender, _to)

    _locked0: LockedBalance = self.locked[_from]
    _locked1: LockedBalance = self.locked[_to]
    value0: uint256 = convert(_locked0.amount, uint256)
    end: uint256 = max(_locked0.end, _locked1.end)

    self._checkpoint(_from, _locked0, empty(LockedBalance))
    self._deposit_for(msg.sender, _to, value0, end, _locked1, MERGE_TYPE)


@external
def checkpoint():
    """
    @notice Record global data to checkpoint
    """
    self._checkpoint(0, empty(LockedBalance), empty(LockedBalance))


@external
@nonreentrant('lock')
def deposit_for(_tokenId: uint256, _value: uint256):
    """
    @notice Deposit `_value` tokens for `_tokenId` and add to the lock
    @dev Anyone (even a smart contract) can deposit for someone else, but
         cannot extend their locktime and deposit for a brand new user
    @param _tokenId lock NFT
    @param _value Amount to add to user's lock
    """
    _locked: LockedBalance = self.locked[_tokenId]

    assert _value > 0  # dev: need non-zero value
    assert _locked.amount > 0, "No existing lock found"
    assert _locked.end > block.timestamp, "Cannot add to expired lock. Withdraw"

    self._deposit_for(msg.sender, _tokenId, _value, 0, self.locked[_tokenId], DEPOSIT_FOR_TYPE)


@external
@nonreentrant('lock')
def create_lock(_value: uint256, _unlock_time: uint256) -> uint256:
    """
    @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
    @param _value Amount to deposit
    @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
    """
    unlock_time: uint256 = (_unlock_time / WEEK) * WEEK  # Locktime is rounded down to weeks

    assert _value > 0  # dev: need non-zero value
    assert unlock_time > block.timestamp, "Can only lock until time in the future"
    assert unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 4 years max"

    self.tokenId += 1
    _tokenId: uint256 = self.tokenId

    self._mint(msg.sender, _tokenId)

    _locked: LockedBalance = self.locked[_tokenId]

    self._deposit_for(msg.sender, _tokenId, _value, unlock_time, _locked, CREATE_LOCK_TYPE)
    return _tokenId


@external
@nonreentrant('lock')
def increase_amount(_tokenId: uint256, _value: uint256):
    """
    @notice Deposit `_value` additional tokens for `_tokenId`
            without modifying the unlock time
    @param _value Amount of tokens to deposit and add to the lock
    """
    assert self._isApprovedOrOwner(msg.sender, _tokenId)

    _locked: LockedBalance = self.locked[_tokenId]

    assert _value > 0  # dev: need non-zero value
    assert _locked.amount > 0, "No existing lock found"
    assert _locked.end > block.timestamp, "Cannot add to expired lock. Withdraw"

    self._deposit_for(msg.sender, _tokenId, _value, 0, _locked, INCREASE_LOCK_AMOUNT)


@external
@nonreentrant('lock')
def increase_unlock_time(_tokenId: uint256, _unlock_time: uint256):
    """
    @notice Extend the unlock time for `_tokenId` to `_unlock_time`
    @param _unlock_time New epoch time for unlocking
    """
    assert self._isApprovedOrOwner(msg.sender, _tokenId)

    _locked: LockedBalance = self.locked[_tokenId]
    unlock_time: uint256 = (_unlock_time / WEEK) * WEEK  # Locktime is rounded down to weeks

    assert _locked.end > block.timestamp, "Lock expired"
    assert _locked.amount > 0, "Nothing is locked"
    assert unlock_time > _locked.end, "Can only increase lock duration"
    assert unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 4 years max"

    self._deposit_for(msg.sender, _tokenId, 0, unlock_time, _locked, INCREASE_UNLOCK_TIME)


@external
@nonreentrant('lock')
def withdraw(_tokenId: uint256):
    """
    @notice Withdraw all tokens for `_tokenId`
    @dev Only possible if the lock has expired
    """
    assert self._isApprovedOrOwner(msg.sender, _tokenId)

    _locked: LockedBalance = self.locked[_tokenId]
    assert block.timestamp >= _locked.end, "The lock didn't expire"
    value: uint256 = convert(_locked.amount, uint256)

    old_locked: LockedBalance = _locked
    _locked.end = 0
    _locked.amount = 0
    self.locked[_tokenId] = _locked
    supply_before: uint256 = self.supply
    self.supply = supply_before - value

    # old_locked can have either expired <= timestamp or zero end
    # _locked has only 0 end
    # Both can have >= 0 amount
    self._checkpoint(_tokenId, old_locked, _locked)

    assert ERC20(self.token).transfer(msg.sender, value)

    log Withdraw(msg.sender, _tokenId, value, block.timestamp)
    log Supply(supply_before, supply_before - value)


# The following ERC20/minime-compatible methods are not real balanceOf and supply!
# They measure the weights for the purpose of voting, so they don't represent
# real coins.

@internal
@view
def find_block_epoch(_block: uint256, max_epoch: uint256) -> uint256:
    """
    @notice Binary search to estimate timestamp for block number
    @param _block Block to find
    @param max_epoch Don't go beyond this epoch
    @return Approximate timestamp for block
    """
    # Binary search
    _min: uint256 = 0
    _max: uint256 = max_epoch
    for i in range(128):  # Will be always enough for 128-bit numbers
        if _min >= _max:
            break
        _mid: uint256 = (_min + _max + 1) / 2
        if self.point_history[_mid].blk <= _block:
            _min = _mid
        else:
            _max = _mid - 1
    return _min

@internal
@view
def _balanceOfNFT(_tokenId: uint256, _t: uint256 = block.timestamp) -> uint256:
    """
    @notice Get the current voting power for `_tokenId`
    @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    @param _tokenId NFT for lock
    @param _t Epoch time to return voting power at
    @return User voting power
    """
    _epoch: uint256 = self.user_point_epoch[_tokenId]
    if _epoch == 0:
        return 0
    else:
        last_point: Point = self.user_point_history[_tokenId][_epoch]
        last_point.bias -= last_point.slope * convert(_t - last_point.ts, int128)
        if last_point.bias < 0:
            last_point.bias = 0
        return convert(last_point.bias, uint256)


@view
@external
def tokenURI(_tokenId: uint256) -> String[2048]:
    """
    @dev Returns current token URI metadata
    @param _tokenId Token ID to fetch URI for.
    """
    _locked: LockedBalance = self.locked[_tokenId]
    return Tokenizer(self.tokenizer).tokenURI(_tokenId, self._balanceOfNFT(_tokenId), _locked.end, convert(_locked.amount, uint256))

@external
@view
def balanceOfNFT(_tokenId: uint256, _t: uint256 = block.timestamp) -> uint256:
    return self._balanceOfNFT(_tokenId, _t)

@internal
@view
def _balanceOfAtNFT(_tokenId: uint256, _block: uint256) -> uint256:
    """
    @notice Measure voting power of `_tokenId` at block height `_block`
    @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    @param _tokenId User's wallet NFT
    @param _block Block to calculate the voting power at
    @return Voting power
    """
    # Copying and pasting totalSupply code because Vyper cannot pass by
    # reference yet
    assert _block <= block.number

    # Binary search
    _min: uint256 = 0
    _max: uint256 = self.user_point_epoch[_tokenId]
    for i in range(128):  # Will be always enough for 128-bit numbers
        if _min >= _max:
            break
        _mid: uint256 = (_min + _max + 1) / 2
        if self.user_point_history[_tokenId][_mid].blk <= _block:
            _min = _mid
        else:
            _max = _mid - 1

    upoint: Point = self.user_point_history[_tokenId][_min]

    max_epoch: uint256 = self.epoch
    _epoch: uint256 = self.find_block_epoch(_block, max_epoch)
    point_0: Point = self.point_history[_epoch]
    d_block: uint256 = 0
    d_t: uint256 = 0
    if _epoch < max_epoch:
        point_1: Point = self.point_history[_epoch + 1]
        d_block = point_1.blk - point_0.blk
        d_t = point_1.ts - point_0.ts
    else:
        d_block = block.number - point_0.blk
        d_t = block.timestamp - point_0.ts
    block_time: uint256 = point_0.ts
    if d_block != 0:
        block_time += d_t * (_block - point_0.blk) / d_block

    upoint.bias -= upoint.slope * convert(block_time - upoint.ts, int128)
    if upoint.bias >= 0:
        return convert(upoint.bias, uint256)
    else:
        return 0

@external
@view
def balanceOfAtNFT(_tokenId: uint256, _block: uint256) -> uint256:
    return self._balanceOfAtNFT(_tokenId, _block)

@internal
@view
def supply_at(point: Point, t: uint256) -> uint256:
    """
    @notice Calculate total voting power at some point in the past
    @param point The point (bias/slope) to start search from
    @param t Time to calculate the total voting power at
    @return Total voting power at that time
    """
    last_point: Point = point
    t_i: uint256 = (last_point.ts / WEEK) * WEEK
    for i in range(255):
        t_i += WEEK
        d_slope: int128 = 0
        if t_i > t:
            t_i = t
        else:
            d_slope = self.slope_changes[t_i]
        last_point.bias -= last_point.slope * convert(t_i - last_point.ts, int128)
        if t_i == t:
            break
        last_point.slope += d_slope
        last_point.ts = t_i

    if last_point.bias < 0:
        last_point.bias = 0
    return convert(last_point.bias, uint256)


@external
@view
def totalSupply(t: uint256 = block.timestamp) -> uint256:
    """
    @notice Calculate total voting power
    @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    @return Total voting power
    """
    _epoch: uint256 = self.epoch
    last_point: Point = self.point_history[_epoch]
    return self.supply_at(last_point, t)


@external
@view
def totalSupplyAt(_block: uint256) -> uint256:
    """
    @notice Calculate total voting power at some point in the past
    @param _block Block to calculate the total voting power at
    @return Total voting power at `_block`
    """
    assert _block <= block.number
    _epoch: uint256 = self.epoch
    target_epoch: uint256 = self.find_block_epoch(_block, _epoch)

    point: Point = self.point_history[target_epoch]
    dt: uint256 = 0
    if target_epoch < _epoch:
        point_next: Point = self.point_history[target_epoch + 1]
        if point.blk != point_next.blk:
            dt = (_block - point.blk) * (point_next.ts - point.ts) / (point_next.blk - point.blk)
    else:
        if point.blk != block.number:
            dt = (_block - point.blk) * (block.timestamp - point.ts) / (block.number - point.blk)
    # Now dt contains info on how far are we beyond point

    return self.supply_at(point, point.ts + dt)