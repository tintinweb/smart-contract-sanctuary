/**
 *Submitted for verification at polygonscan.com on 2021-07-19
*/

// File: contracts/IOwned.sol

pragma solidity >0.6.0;

/*
    Owned contract interface
*/
abstract contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() external virtual view returns (address);

    function transferOwnership(address _newOwner) public virtual;
    function acceptOwnership() public virtual;
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: contracts/IERC721BurnableStorage.sol

pragma solidity ^0.8.0;


interface IERC721Burnable is IERC721Metadata {
    /**
     * @dev issues `amount` tokens to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function mint(address to, uint256 tokenId) external;
     
    /**
     * @dev issues `amount` tokens to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function burn(uint256 tokenId) external;
}
// File: contracts/link.sol

pragma solidity >0.6.0;

abstract contract link {

  uint256 private constant receipt_flag = uint256(1) << 31;

  struct Message {
    uint256 id;         // the message id, different from the batch id
    bytes message;      // message as bytes, must deserialize
    uint256 block_num;
    bool received;  
  }

  struct InboundMessage {
    bytes message;
    uint256 block_num;
  }

  address owner;

  uint256 public available_message_id;
  uint64  public available_batch_id;
  uint64  public next_incoming_batch_id;

  uint256 public last_outgoing_batch_block_num;
  uint256 public last_incoming_batch_block_num;

  address[] owners;
  uint256 required_sigs;

  // mapping of bridge owners
  mapping (address => bool) public isOwner;

  // mapping/linked list of received messages
  mapping (uint256 => InboundMessage) public inbound; 

  // mapping/linked list of local messages
  mapping (uint64 => Message) public batches;
  mapping (uint256 => uint64) public outbound;

  mapping (bytes32 => mapping(address => bool)) public hasConfirmed;
  mapping (bytes32 => bool) public executedMsg;
  mapping (bytes32 => uint256) public numOfConfirmed;  

  constructor(address[] memory _owners, uint256 _required) {
    for (uint i = 0; i < _owners.length; i++) {
      require(!isOwner[_owners[i]] && _owners[i] != address(0));
      isOwner[_owners[i]] = true;
    }
    require(_required <= _owners.length);
    owners = _owners;
    required_sigs = _required;
  }

  /**
    * @dev confirms consensus of messages before execution
    *
    * @param theHash message
    */
  function confirmConsensus(bytes32 theHash) internal returns (bool) {
    require(isOwner[msg.sender], "sender not authorized");
    require(!(hasConfirmed[theHash][msg.sender]), "sender already confirmed");
    hasConfirmed[theHash][msg.sender] = true;
    numOfConfirmed[theHash] += 1;
    if (numOfConfirmed[theHash] >= required_sigs && !executedMsg[theHash]) {
      executedMsg[theHash] = true;
      return true;
    }
    return false;
  }

  /**
    * @dev confirms consensus of messages before execution
    *
    * @param id message
    */
  function modifyConsensus(
    uint256 id,
    address[] memory _owners,
    uint256 required
    ) public {
      bytes32 dataHash = keccak256(abi.encodePacked(id, _owners, required));
      if (!confirmConsensus(dataHash)) {
        return;
      }
      for (uint i = 0; i < owners.length; i++) {
        isOwner[owners[i]] = false;
      }
      for (uint i = 0; i < _owners.length; i++) {
        require(!isOwner[_owners[i]] && _owners[i] != address(0));
        isOwner[_owners[i]] = true;
      }
      require(required <= _owners.length);
      owners = _owners;
      required_sigs = required;
  }

  /**
    * @dev view function which returns Messages only if 12 blocks have passed
    *
    * @param batch_id the batch to retrieve
    */
  function getBatch(uint64 batch_id) public view returns (uint256 id, bytes memory message, uint256 block_num) {
    Message memory requestedMessage = batches[batch_id];
    if (requestedMessage.block_num > 0 && block.number > (requestedMessage.block_num + uint256(12))) {
      return (requestedMessage.id, requestedMessage.message, requestedMessage.block_num);
    }
    bytes memory emptyMessage;
    return (0, emptyMessage, 0);
  }

  /**
    * @dev handling the pushing of messages from other chains
    *
    * @param _message the message to push
    */
  function pushInboundMessage(uint256 id, bytes memory _message) external {
    bytes32 dataHash = keccak256(abi.encodePacked(id, _message));
    if (!confirmConsensus(dataHash)) {
      return;
    }
    InboundMessage memory message = InboundMessage(_message, block.number);  
    inbound[id] = message;  
    if(id < receipt_flag) {      
      onMessage(id, _message);      
    } else {
      uint256 orig_id = id - receipt_flag;
      require(orig_id > 0); //TODO
      //VERIFY BLOCK AGE
      batches[outbound[orig_id]].received = true;
      onReceipt(orig_id, _message);
    }
    last_incoming_batch_block_num = block.number;
  }

  /**
    * @dev handling the pushing of local messages
    *
    * @param _message the message to push
    */
  function pushMessage(bytes memory _message) internal {
    Message memory message = Message(available_message_id, _message, block.number, false);
    batches[available_batch_id] = message;
    outbound[available_message_id] = available_batch_id;
    available_message_id++;
    available_batch_id++;
  }

  /**
    * @dev handling the pushing of local receipts
    *
    * @param _message message
    */
  function pushReceipt(uint256 id, bytes memory _message) internal {
    uint256 receipt_id = id + receipt_flag;
    Message memory message = Message(receipt_id, _message, block.number, true);
    batches[available_batch_id] = message;
    outbound[receipt_id] = available_batch_id;
    available_batch_id++;
  }

  function readMessage(bytes memory data, uint256 offset, uint256 length) internal pure returns (uint256 o) {
      require(data.length >= offset + length, "Reading bytes out of bounds");
      assembly {
          o := mload(add(data, add(32, offset)))
          let lb := sub(32, length)
          if lb { o := div(o, exp(2, mul(lb, 8))) }
      }
  }

  /**
    * @dev on message hook, unique implementation per consumer
    *
    * @param id uint256
    * @param _message message
    */
  function onMessage(uint256 id, bytes memory _message) internal virtual;

  /**
    * @dev on receipt hook, unique implementation per consumer
    *
    * @param id uint256
    * @param _message message
    */
  function onReceipt(uint256 id, bytes memory _message) internal virtual;
}
  
library Endian {
  /* https://ethereum.stackexchange.com/questions/83626/how-to-reverse-byte-order-in-uint256-or-bytes32 */
  function reverse64(uint64 input) internal pure returns (uint64 v) {
      v = input;

      // swap bytes
      v = ((v & 0xFF00FF00FF00FF00) >> 8) |
          ((v & 0x00FF00FF00FF00FF) << 8);

      // swap 2-byte long pairs
      v = ((v & 0xFFFF0000FFFF0000) >> 16) |
          ((v & 0x0000FFFF0000FFFF) << 16);

      // swap 4-byte long pairs
      v = (v >> 32) | (v << 32);
  }
}

// File: contracts/atomictokenpeg.sol

pragma solidity ^0.8.0;




contract atomictokenpeg is link {
  event Refund(uint256 id, address recipient, uint256 tokenId, bytes reason);
  event Failure(bytes reason);
  event Receipt(address recipient, uint256 tokenId, bytes reason);
  
  constructor(
    address[] memory _owners,
    uint8 _required
  ) link(_owners, _required)
  {}

  /**
    * @dev accepts ownership of smart token
    */
  function acceptTokenOwnership(address tokenAddress) public {
    IOwned ownableToken = IOwned(tokenAddress);
    ownableToken.acceptOwnership();
  }

  /**
    * @dev allows msg.sender to send tokens to another chain
    *
    * @param tokenId message
    * @param recipient message
    */
  function sendToken(uint256 tokenId, uint64 recipient, address tokenContract) public {
    bytes memory message = abi.encodePacked(bool(true), Endian.reverse64(recipient), uint64(tokenId), msg.sender, tokenContract);
    IERC721Burnable(tokenContract).burn(tokenId);
    pushMessage(message);
  }

  /**
    * @dev allows msg.sender to send tokens to another chain
    *
    * @param recipient message
    */
  function mintTokens(uint256 tokenId, address recipient, uint256 id, address tokenAddress, bytes memory message) internal {
    bytes memory receipt = message;
    try IERC721Burnable(tokenAddress).mint(recipient, tokenId) {
      // return success true
      receipt[0] = 0x01;
    } catch(bytes memory failureMessage) {
      // return success false
      receipt[0] = 0x00;
      emit Failure(failureMessage);
    }
    pushReceipt(id, receipt);
  }

  /**
    * @dev on message hook, unique implementation per consumer
    *
    * @param _message message
    */
  function onMessage(uint256 id, bytes memory _message) internal override {
    //byte 0, status
    //byte 1-8, eos account
    //byte 9-17, asset_id
    //byte 17-37 address
    //byte 37-45 token index
    uint256 tokenId = readMessage(_message, 9, 8);
    address recipient = address(uint160(readMessage(_message, 17, 20)));
    address tokenAddress = address(uint160(readMessage(_message, 37, 20)));
    mintTokens(tokenId, recipient, id, tokenAddress, _message);
  }

  /**
    * @dev on receipt hook, unique implementation per consumer
    *
    * @param _message message
    */
  function onReceipt(uint256 id, bytes memory _message) internal override {
    // messages sent do not receive receipts
    // incoming message failure logged on eosio
  }
}