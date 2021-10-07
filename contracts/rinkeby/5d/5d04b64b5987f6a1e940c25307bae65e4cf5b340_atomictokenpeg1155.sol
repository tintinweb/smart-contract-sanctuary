/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol



pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol



pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol



pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: contracts/IOwned.sol


pragma solidity ^0.8.0;

/*
    Owned contract interface
*/
abstract contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() external virtual view returns (address);

    function transferOwnership(address _newOwner) public virtual;
    function acceptOwnership() public virtual;
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol



pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: contracts/IERC1155Tradable.sol


pragma solidity ^0.8.0;


interface IERC1155Tradable is IERC1155MetadataURI {
    /**
     * burn
     */
    function burn(
        address account,
        uint256 id,
        uint256 value) external;
        
    /**
     * safeTransferFrom
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data) external override;
        
    /**
     * create
     */
    function create(
        address _initialOwner,
        uint256 _id,
        uint256 _initialSupply,
        string memory _uri,
        bytes memory _data) external returns (uint256);
        
    /**
     * uri
     */
    function uri(uint256) external override view returns (string memory);
}
// File: contracts/bitManipulation.sol

pragma solidity >0.6.0;

library bitManipulation {
  // https://gist.github.com/ageyev/779797061490f5be64fb02e978feb6ac
  function slice(
      bytes memory _bytes,
      uint256 _start,
      uint256 _length
  )
      internal
      pure
      returns (bytes memory)
  {
      require(_length + 31 >= _length, "slice_overflow");
      require(_bytes.length >= _start + _length, "slice_outOfBounds");

      bytes memory tempBytes;

      assembly {
          switch iszero(_length)
          case 0 {
              // Get a location of some free memory and store it in tempBytes as
              // Solidity does for memory variables.
              tempBytes := mload(0x40)

              // The first word of the slice result is potentially a partial
              // word read from the original array. To read it, we calculate
              // the length of that partial word and start copying that many
              // bytes into the array. The first word we copy will start with
              // data we don't care about, but the last `lengthmod` bytes will
              // land at the beginning of the contents of the new array. When
              // we're done copying, we overwrite the full first word with
              // the actual length of the slice.
              let lengthmod := and(_length, 31)

              // The multiplication in the next line is necessary
              // because when slicing multiples of 32 bytes (lengthmod == 0)
              // the following copy loop was copying the origin's length
              // and then ending prematurely not copying everything it should.
              let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
              let end := add(mc, _length)

              for {
                  // The multiplication in the next line has the same exact purpose
                  // as the one above.
                  let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
              } lt(mc, end) {
                  mc := add(mc, 0x20)
                  cc := add(cc, 0x20)
              } {
                  mstore(mc, mload(cc))
              }

              mstore(tempBytes, _length)

              //update free-memory pointer
              //allocating the array padded to 32 bytes like the compiler does now
              mstore(0x40, and(add(mc, 31), not(31)))
          }
          //if we want a zero-length slice let's just return a zero-length array
          default {
              tempBytes := mload(0x40)
              //zero out the 32 bytes slice we are about to return
              //we need to do it because Solidity does not garbage collect
              mstore(tempBytes, 0)

              mstore(0x40, add(tempBytes, 0x20))
          }
      }

      return tempBytes;
  }

  // https://ethereum.stackexchange.com/questions/29295/how-to-convert-a-bytes-to-string-in-solidity
  function bytesToString(bytes memory byteCode) public pure returns(string memory stringData)
  {
      uint256 blank = 0; //blank 32 byte value
      uint256 length = byteCode.length;

      uint cycles = byteCode.length / 0x20;
      uint requiredAlloc = length;

      if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
      {
          cycles++;
          requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
      }

      stringData = new string(requiredAlloc);

      //copy data in 32 byte blocks
      assembly {
          let cycle := 0

          for
          {
              let mc := add(stringData, 0x20) //pointer into bytes we're writing to
              let cc := add(byteCode, 0x20)   //pointer to where we're reading from
          } lt(cycle, cycles) {
              mc := add(mc, 0x20)
              cc := add(cc, 0x20)
              cycle := add(cycle, 0x01)
          } {
              mstore(mc, mload(cc))
          }
      }

      //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
      if (length % 0x20 > 0)
      {
          uint offsetStart = 0x20 + length;
          assembly
          {
              let mc := add(stringData, offsetStart)
              mstore(mc, mload(add(blank, 0x20)))
              //now shrink the memory back so the returned object is the correct size
              mstore(stringData, length)
          }
      }
  }

    // https://ethereum.stackexchange.com/questions/9142/how-to-convert-a-string-to-bytes32
    function string_tobytes(string memory s) public pure returns (bytes memory){
        return bytes(s);
    }
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

// File: contracts/atomictokenpeg1155.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;






contract atomictokenpeg1155 is link, ERC1155Holder {
  event Refund(uint256 id, address recipient, uint256 tokenId, bytes reason);
  event Failure(bytes reason);
  event Receipt(address recipient, uint256 tokenId, bytes reason);
  event debug(bytes uriBytes);
  event debuga(bytes uriBytes1);

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
    bytes memory message = abi.encodePacked(
      bool(true), 
      Endian.reverse64(recipient), 
      uint64(tokenId), msg.sender, 
      tokenContract,
      // add LEB128 encoding length prefix
      uint8(bytes(IERC1155Tradable(tokenContract).uri(tokenId)).length),
      bitManipulation.string_tobytes(IERC1155Tradable(tokenContract).uri(tokenId))
    );
    emit debuga(message);
    IERC1155Tradable(tokenContract).burn(msg.sender, tokenId, 1);
    pushMessage(message);
  }

  /**
    * @dev allows msg.sender to send tokens to another chain
    *
    * @param recipient message
    */
  function transferTokens(uint256 tokenId, address recipient, uint256 id, address tokenAddress, string memory uri, bytes memory message) internal {
    bytes memory receipt = message;
    bytes memory data = "0x00";
    try IERC1155Tradable(tokenAddress).create(address(this), tokenId, 1, uri, data) returns (uint256) {
      // return success true
      receipt[0] = 0x01;
    } catch(bytes memory failureMessage) {
      // return success false
      receipt[0] = 0x00;
      emit Failure(failureMessage);
      pushReceipt(id, receipt);
      return;
    }
    try IERC1155Tradable(tokenAddress).safeTransferFrom(address(this), recipient, tokenId, 1, data) {
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
    uint256 tokenId = readMessage(_message, 9, 8);
    address recipient = address(uint160(readMessage(_message, 17, 20)));
    address tokenAddress = address(uint160(readMessage(_message, 37, 20)));
    // skip LEB128 encoding length prefix
    string memory uri = bitManipulation.bytesToString(bitManipulation.slice(_message, 58, _message.length - 58));
    emit debug(_message);
    transferTokens(tokenId, recipient, id, tokenAddress, uri, _message);
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