/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// File: multi-token-standard/contracts/interfaces/IERC20.sol

pragma solidity ^0.6.7;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: multi-token-standard/contracts/interfaces/IERC165.sol

pragma solidity ^0.6.8;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// File: multi-token-standard/contracts/interfaces/IERC1155.sol

pragma solidity ^0.6.8;


interface IERC1155 {

  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /**
   * @dev MUST emit when the URI is updated for a token ID
   *   URIs are defined in RFC 3986
   *   The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema"
   */
  event URI(string _amount, uint256 indexed _id);


  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
    * @notice Transfers amount of an _id from the _from address to the _to address specified
    * @dev MUST emit TransferSingle event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @dev MUST emit TransferBatch event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if length of `_ids` is not the same as length of `_amounts`
    * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}

// File: multi-token-standard/contracts/interfaces/IERC1155TokenReceiver.sol

pragma solidity ^0.6.8;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

// File: multi-token-standard/contracts/utils/SafeMath.sol

pragma solidity ^0.6.8;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}

// File: multi-token-standard/contracts/utils/Address.sol

pragma solidity ^0.6.8;


/**
 * Utility library of inline functions on addresses
 */
library Address {

  // Default hash for EOA accounts returned by extcodehash
  bytes32 constant internal ACCOUNT_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly { codehash := extcodehash(_address) }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }
}

// File: multi-token-standard/contracts/utils/ERC165.sol

pragma solidity ^0.6.8;

abstract contract ERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) virtual public pure returns (bool) {
    return _interfaceID == this.supportsInterface.selector;
  }
}

// File: multi-token-standard/contracts/tokens/ERC1155/ERC1155.sol

pragma solidity ^0.6.8;







/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC1155, ERC165 {
  using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Objects balances
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping (address => mapping(address => bool)) internal operators;


  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public override
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public override
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }


  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    // Update balances
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas: _gasLimit}(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    external override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public override view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  /***********************************|
  |         Balance Functions         |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public override view returns (uint256)
  {
    return balances[_owner][_id];
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public override view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

// File: multi-token-standard/contracts/utils/LibBytes.sol

/*
  Copyright 2018 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  This is a truncated version of the original LibBytes.sol library from ZeroEx.
*/

pragma solidity ^0.6.8;


library LibBytes {
  using LibBytes for bytes;

  /***********************************|
  |        Pop Bytes Functions        |
  |__________________________________*/

  /**
   * @dev Pops the last byte off of a byte array by modifying its length.
   * @param b Byte array that will be modified.
   * @return result The byte that was popped off.
   */
  function popLastByte(bytes memory b)
    internal
    pure
    returns (bytes1 result)
  {
    require(
      b.length > 0,
      "LibBytes#popLastByte: GREATER_THAN_ZERO_LENGTH_REQUIRED"
    );

    // Store last byte.
    result = b[b.length - 1];

    assembly {
      // Decrement length of byte array.
      let newLen := sub(mload(b), 1)
      mstore(b, newLen)
    }
    return result;
  }


  /***********************************|
  |        Read Bytes Functions       |
  |__________________________________*/

  /**
   * @dev Reads a bytes32 value from a position in a byte array.
   * @param b Byte array containing a bytes32 value.
   * @param index Index in byte array of bytes32 value.
   * @return result bytes32 value from byte array.
   */
  function readBytes32(
    bytes memory b,
    uint256 index
  )
    internal
    pure
    returns (bytes32 result)
  {
    require(
      b.length >= index + 32,
      "LibBytes#readBytes32: GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED"
    );

    // Arrays are prefixed by a 256 bit length parameter
    index += 32;

    // Read the bytes32 from array memory
    assembly {
      result := mload(add(b, index))
    }
    return result;
  }
}

// File: multi-token-standard/contracts/interfaces/IERC1271Wallet.sol

pragma solidity ^0.6.8;


interface  IERC1271Wallet {

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided data
   * @dev MUST return the correct magic value if the signature provided is valid for the provided data
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
   *   > This function MAY modify Ethereum's state
   * @param _data       Arbitrary length data signed on the behalf of address(this)
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   *
   */
  function isValidSignature(
    bytes calldata _data,
    bytes calldata _signature)
    external
    view
    returns (bytes4 magicValue);

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided hash
   * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
   *   > This function MAY modify Ethereum's state
   * @param _hash       keccak256 hash that was signed
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes32 _hash,
    bytes calldata _signature)
    external
    view
    returns (bytes4 magicValue);
}

// File: multi-token-standard/contracts/utils/LibEIP712.sol

/**
 * Copyright 2018 ZeroEx Intl.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.6.8;


contract LibEIP712 {

  /***********************************|
  |             Constants             |
  |__________________________________*/

  // keccak256(
  //   "EIP712Domain(address verifyingContract)"
  // );
  bytes32 internal constant DOMAIN_SEPARATOR_TYPEHASH = 0x035aff83d86937d35b32e04f0ddc6ff469290eef2f1b692d8a815c89404d4749;

  // EIP-191 Header
  string constant internal EIP191_HEADER = "\x19\x01";

  /***********************************|
  |          Hashing Function         |
  |__________________________________*/

  /**
   * @dev Calculates EIP712 encoding for a hash struct in this EIP712 Domain.
   * @param hashStruct The EIP712 hash struct.
   * @return result EIP712 hash applied to this EIP712 Domain.
   */
  function hashEIP712Message(bytes32 hashStruct)
      internal
      view
      returns (bytes32 result)
  {
    return keccak256(
      abi.encodePacked(
        EIP191_HEADER,
        keccak256(
          abi.encode(
            DOMAIN_SEPARATOR_TYPEHASH,
            address(this)
          )
        ),
        hashStruct
    ));
  }
}

// File: multi-token-standard/contracts/utils/SignatureValidator.sol

pragma solidity ^0.6.8;




/**
 * @dev Contains logic for signature validation.
 * Signatures from wallet contracts assume ERC-1271 support (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1271.md)
 * Notes: Methods are strongly inspired by contracts in https://github.com/0xProject/0x-monorepo/blob/development/
 */
contract SignatureValidator is LibEIP712 {
  using LibBytes for bytes;

  /***********************************|
  |             Variables             |
  |__________________________________*/

  // bytes4(keccak256("isValidSignature(bytes,bytes)"))
  bytes4 constant internal ERC1271_MAGICVALUE = 0x20c13b0b;

  // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
  bytes4 constant internal ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

  // Allowed signature types.
  enum SignatureType {
    Illegal,         // 0x00, default value
    EIP712,          // 0x01
    EthSign,         // 0x02
    WalletBytes,     // 0x03 To call isValidSignature(bytes, bytes) on wallet contract
    WalletBytes32,   // 0x04 To call isValidSignature(bytes32, bytes) on wallet contract
    NSignatureTypes  // 0x05, number of signature types. Always leave at end.
  }


  /***********************************|
  |        Signature Functions        |
  |__________________________________*/

  /**
   * @dev Verifies that a hash has been signed by the given signer.
   * @param _signerAddress  Address that should have signed the given hash.
   * @param _hash           Hash of the EIP-712 encoded data
   * @param _data           Full EIP-712 data structure that was hashed and signed
   * @param _sig            Proof that the hash has been signed by signer.
   *      For non wallet signatures, _sig is expected to be an array tightly encoded as
   *      (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType)
   * @return isValid True if the address recovered from the provided signature matches the input signer address.
   */
  function isValidSignature(
    address _signerAddress,
    bytes32 _hash,
    bytes memory _data,
    bytes memory _sig
  )
    public
    view
    returns (bool isValid)
  {
    require(
      _sig.length > 0,
      "SignatureValidator#isValidSignature: LENGTH_GREATER_THAN_0_REQUIRED"
    );

    require(
      _signerAddress != address(0x0),
      "SignatureValidator#isValidSignature: INVALID_SIGNER"
    );

    // Pop last byte off of signature byte array.
    uint8 signatureTypeRaw = uint8(_sig.popLastByte());

    // Ensure signature is supported
    require(
      signatureTypeRaw < uint8(SignatureType.NSignatureTypes),
      "SignatureValidator#isValidSignature: UNSUPPORTED_SIGNATURE"
    );

    // Extract signature type
    SignatureType signatureType = SignatureType(signatureTypeRaw);

    // Variables are not scoped in Solidity.
    uint8 v;
    bytes32 r;
    bytes32 s;
    address recovered;

    // Always illegal signature.
    // This is always an implicit option since a signer can create a
    // signature array with invalid type or length. We may as well make
    // it an explicit option. This aids testing and analysis. It is
    // also the initialization value for the enum type.
    if (signatureType == SignatureType.Illegal) {
      revert("SignatureValidator#isValidSignature: ILLEGAL_SIGNATURE");


    // Signature using EIP712
    } else if (signatureType == SignatureType.EIP712) {
      require(
        _sig.length == 97,
        "SignatureValidator#isValidSignature: LENGTH_97_REQUIRED"
      );
      r = _sig.readBytes32(0);
      s = _sig.readBytes32(32);
      v = uint8(_sig[64]);
      recovered = ecrecover(_hash, v, r, s);
      isValid = _signerAddress == recovered;
      return isValid;


    // Signed using web3.eth_sign() or Ethers wallet.signMessage()
    } else if (signatureType == SignatureType.EthSign) {
      require(
        _sig.length == 97,
        "SignatureValidator#isValidSignature: LENGTH_97_REQUIRED"
      );
      r = _sig.readBytes32(0);
      s = _sig.readBytes32(32);
      v = uint8(_sig[64]);
      recovered = ecrecover(
        keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),
        v,
        r,
        s
      );
      isValid = _signerAddress == recovered;
      return isValid;


    // Signature verified by wallet contract with data validation.
    } else if (signatureType == SignatureType.WalletBytes) {
      isValid = ERC1271_MAGICVALUE == IERC1271Wallet(_signerAddress).isValidSignature(_data, _sig);
      return isValid;


    // Signature verified by wallet contract without data validation.
    } else if (signatureType == SignatureType.WalletBytes32) {
      isValid = ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(_signerAddress).isValidSignature(_hash, _sig);
      return isValid;
    }

    // Anything else is illegal (We do not return false because
    // the signature may actually be valid, just not in a format
    // that we currently support. In this case returning false
    // may lead the caller to incorrectly believe that the
    // signature was invalid.)
    revert("SignatureValidator#isValidSignature: UNSUPPORTED_SIGNATURE");
  }
}

// File: multi-token-standard/contracts/tokens/ERC1155/ERC1155Meta.sol

pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;







/**
 * @dev ERC-1155 with native metatransaction methods. These additional functions allow users
 *      to presign function calls and allow third parties to execute these on their behalf
 */
contract ERC1155Meta is ERC1155, SignatureValidator {
  using LibBytes for bytes;

  /***********************************|
  |       Variables and Structs       |
  |__________________________________*/

  /**
   * Gas Receipt
   *   feeTokenData : (bool, address, ?unit256)
   *     1st element should be the address of the token
   *     2nd argument (if ERC-1155) should be the ID of the token
   *     Last element should be a 0x0 if ERC-20 and 0x1 for ERC-1155
   */
  struct GasReceipt {
    uint256 gasFee;           // Fixed cost for the tx
    uint256 gasLimitCallback; // Maximum amount of gas the callback in transfer functions can use
    address feeRecipient;     // Address to send payment to
    bytes feeTokenData;       // Data for token to pay for gas
  }

  // Which token standard is used to pay gas fee
  enum FeeTokenType {
    ERC1155,    // 0x00, ERC-1155 token - DEFAULT
    ERC20,      // 0x01, ERC-20 token
    NTypes      // 0x02, number of signature types. Always leave at end.
  }

  // Signature nonce per address
  mapping (address => uint256) internal nonces;


  /***********************************|
  |               Events              |
  |__________________________________*/

  event NonceChange(address indexed signer, uint256 newNonce);


  /****************************************|
  |     Public Meta Transfer Functions     |
  |_______________________________________*/

  /**
   * @notice Allows anyone with a valid signature to transfer _amount amount of a token _id on the bahalf of _from
   * @param _from     Source address
   * @param _to       Target address
   * @param _id       ID of the token type
   * @param _amount   Transfered amount
   * @param _isGasFee Whether gas is reimbursed to executor or not
   * @param _data     Encodes a meta transfer indicator, signature, gas payment receipt and extra transfer data
   *   _data should be encoded as (
   *   (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType),
   *   (GasReceipt g, ?bytes transferData)
   * )
   *   i.e. high level encoding should be (bytes, bytes), where the latter bytes array is a nested bytes array
   */
  function metaSafeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bool _isGasFee,
    bytes memory _data)
    public
  {
    require(_to != address(0), "ERC1155Meta#metaSafeTransferFrom: INVALID_RECIPIENT");

    // Initializing
    bytes memory transferData;
    GasReceipt memory gasReceipt;

    // Verify signature and extract the signed data
    bytes memory signedData = _signatureValidation(
      _from,
      _data,
      abi.encode(
        META_TX_TYPEHASH,
        _from, // Address as uint256
        _to,   // Address as uint256
        _id,
        _amount,
        _isGasFee ? uint256(1) : uint256(0)  // Boolean as uint256
      )
    );

    // Transfer asset
    _safeTransferFrom(_from, _to, _id, _amount);

    // If Gas is being reimbursed
    if (_isGasFee) {
      (gasReceipt, transferData) = abi.decode(signedData, (GasReceipt, bytes));

      // We need to somewhat protect relayers against gas griefing attacks in recipient contract.
      // Hence we only pass the gasLimit to the recipient such that the relayer knows the griefing
      // limit. Nothing can prevent the receiver to revert the transaction as close to the gasLimit as
      // possible, but the relayer can now only accept meta-transaction gasLimit within a certain range.
      _callonERC1155Received(_from, _to, _id, _amount, gasReceipt.gasLimitCallback, transferData);

      // Transfer gas cost
      _transferGasFee(_from, gasReceipt);

    } else {
      _callonERC1155Received(_from, _to, _id, _amount, gasleft(), signedData);
    }
  }

  /**
   * @notice Allows anyone with a valid signature to transfer multiple types of tokens on the bahalf of _from
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _isGasFee Whether gas is reimbursed to executor or not
   * @param _data     Encodes a meta transfer indicator, signature, gas payment receipt and extra transfer data
   *   _data should be encoded as (
   *   (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType),
   *   (GasReceipt g, ?bytes transferData)
   * )
   *   i.e. high level encoding should be (bytes, bytes), where the latter bytes array is a nested bytes array
   */
  function metaSafeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bool _isGasFee,
    bytes memory _data)
    public
  {
    require(_to != address(0), "ERC1155Meta#metaSafeBatchTransferFrom: INVALID_RECIPIENT");

    // Initializing
    bytes memory transferData;
    GasReceipt memory gasReceipt;

    // Verify signature and extract the signed data
    bytes memory signedData = _signatureValidation(
      _from,
      _data,
      abi.encode(
        META_BATCH_TX_TYPEHASH,
        _from, // Address as uint256
        _to,   // Address as uint256
        keccak256(abi.encodePacked(_ids)),
        keccak256(abi.encodePacked(_amounts)),
        _isGasFee ? uint256(1) : uint256(0)  // Boolean as uint256
      )
    );

    // Transfer assets
    _safeBatchTransferFrom(_from, _to, _ids, _amounts);

    // If gas fee being reimbursed
    if (_isGasFee) {
      (gasReceipt, transferData) = abi.decode(signedData, (GasReceipt, bytes));

      // We need to somewhat protect relayers against gas griefing attacks in recipient contract.
      // Hence we only pass the gasLimit to the recipient such that the relayer knows the griefing
      // limit. Nothing can prevent the receiver to revert the transaction as close to the gasLimit as
      // possible, but the relayer can now only accept meta-transaction gasLimit within a certain range.
      _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasReceipt.gasLimitCallback, transferData);

      // Handle gas reimbursement
      _transferGasFee(_from, gasReceipt);

    } else {
      _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), signedData);
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Approve the passed address to spend on behalf of _from if valid signature is provided
   * @param _owner     Address that wants to set operator status  _spender
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   * @param _isGasFee  Whether gas will be reimbursed or not, with vlid signature
   * @param _data      Encodes signature and gas payment receipt
   *   _data should be encoded as (
   *     (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType),
   *     (GasReceipt g)
   *   )
   *   i.e. high level encoding should be (bytes, bytes), where the latter bytes array is a nested bytes array
   */
  function metaSetApprovalForAll(
    address _owner,
    address _operator,
    bool _approved,
    bool _isGasFee,
    bytes memory _data)
    public
  {
    // Verify signature and extract the signed data
    bytes memory signedData = _signatureValidation(
      _owner,
      _data,
      abi.encode(
        META_APPROVAL_TYPEHASH,
        _owner,                              // Address as uint256
        _operator,                           // Address as uint256
        _approved ? uint256(1) : uint256(0), // Boolean as uint256
        _isGasFee ? uint256(1) : uint256(0)  // Boolean as uint256
      )
    );

    // Update operator status
    operators[_owner][_operator] = _approved;

    // Emit event
    emit ApprovalForAll(_owner, _operator, _approved);

    // Handle gas reimbursement
    if (_isGasFee) {
      GasReceipt memory gasReceipt = abi.decode(signedData, (GasReceipt));
      _transferGasFee(_owner, gasReceipt);
    }
  }


  /****************************************|
  |      Signature Validation Functions     |
  |_______________________________________*/

  // keccak256(
  //   "metaSafeTransferFrom(address,address,uint256,uint256,bool,bytes)"
  // );
  bytes32 internal constant META_TX_TYPEHASH = 0xce0b514b3931bdbe4d5d44e4f035afe7113767b7db71949271f6a62d9c60f558;

  // keccak256(
  //   "metaSafeBatchTransferFrom(address,address,uint256[],uint256[],bool,bytes)"
  // );
  bytes32 internal constant META_BATCH_TX_TYPEHASH = 0xa3d4926e8cf8fe8e020cd29f514c256bc2eec62aa2337e415f1a33a4828af5a0;

  // keccak256(
  //   "metaSetApprovalForAll(address,address,bool,bool,bytes)"
  // );
  bytes32 internal constant META_APPROVAL_TYPEHASH = 0xf5d4c820494c8595de274c7ff619bead38aac4fbc3d143b5bf956aa4b84fa524;

  /**
   * @notice Verifies signatures for this contract
   * @param _signer     Address of signer
   * @param _sigData    Encodes signature, gas payment receipt and transfer data (if any)
   * @param _encMembers Encoded EIP-712 type members (except nonce and _data), all need to be 32 bytes size
   * @dev _data should be encoded as (
   *   (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType),
   *   (GasReceipt g, ?bytes transferData)
   * )
   *   i.e. high level encoding should be (bytes, bytes), where the latter bytes array is a nested bytes array
   * @dev A valid nonce is a nonce that is within 100 value from the current nonce
   */
  function _signatureValidation(
    address _signer,
    bytes memory _sigData,
    bytes memory _encMembers)
    internal returns (bytes memory signedData)
  {
    bytes memory sig;

    // Get signature and data to sign
    (sig, signedData) = abi.decode(_sigData, (bytes, bytes));

    // Get current nonce and nonce used for signature
    uint256 currentNonce = nonces[_signer];        // Lowest valid nonce for signer
    uint256 nonce = uint256(sig.readBytes32(65));  // Nonce passed in the signature object

    // Verify if nonce is valid
    require(
      (nonce >= currentNonce) && (nonce < (currentNonce + 100)),
      "ERC1155Meta#_signatureValidation: INVALID_NONCE"
    );

    // Take hash of bytes arrays
    bytes32 hash = hashEIP712Message(keccak256(abi.encodePacked(_encMembers, nonce, keccak256(signedData))));

    // Complete data to pass to signer verifier
    bytes memory fullData = abi.encodePacked(_encMembers, nonce, signedData);

    //Update signature nonce
    nonces[_signer] = nonce + 1;
    emit NonceChange(_signer, nonce + 1);

    // Verify if _from is the signer
    require(isValidSignature(_signer, hash, fullData, sig), "ERC1155Meta#_signatureValidation: INVALID_SIGNATURE");
    return signedData;
  }

  /**
   * @notice Returns the current nonce associated with a given address
   * @param _signer Address to query signature nonce for
   */
  function getNonce(address _signer)
    public view returns (uint256 nonce)
  {
    return nonces[_signer];
  }


  /***********************************|
  |    Gas Reimbursement Functions    |
  |__________________________________*/

  /**
   * @notice Will reimburse tx.origin or fee recipient for the gas spent execution a transaction
   *         Can reimbuse in any ERC-20 or ERC-1155 token
   * @param _from  Address from which the payment will be made from
   * @param _g     GasReceipt object that contains gas reimbursement information
   */
  function _transferGasFee(address _from, GasReceipt memory _g)
      internal
  {
    // Pop last byte to get token fee type
    uint8 feeTokenTypeRaw = uint8(_g.feeTokenData.popLastByte());

    // Ensure valid fee token type
    require(
      feeTokenTypeRaw < uint8(FeeTokenType.NTypes),
      "ERC1155Meta#_transferGasFee: UNSUPPORTED_TOKEN"
    );

    // Convert to FeeTokenType corresponding value
    FeeTokenType feeTokenType = FeeTokenType(feeTokenTypeRaw);

    // Declarations
    address tokenAddress;
    address feeRecipient;
    uint256 tokenID;
    uint256 fee = _g.gasFee;

    // If receiver is 0x0, then anyone can claim, otherwise, refund addresse provided
    feeRecipient = _g.feeRecipient == address(0) ? msg.sender : _g.feeRecipient;

    // Fee token is ERC1155
    if (feeTokenType == FeeTokenType.ERC1155) {
      (tokenAddress, tokenID) = abi.decode(_g.feeTokenData, (address, uint256));

      // Fee is paid from this ERC1155 contract
      if (tokenAddress == address(this)) {
        _safeTransferFrom(_from, feeRecipient, tokenID, fee);

        // No need to protect against griefing since recipient (if contract) is most likely owned by the relayer
        _callonERC1155Received(_from, feeRecipient, tokenID, gasleft(), fee, "");

      // Fee is paid from another ERC-1155 contract
      } else {
        IERC1155(tokenAddress).safeTransferFrom(_from, feeRecipient, tokenID, fee, "");
      }

    // Fee token is ERC20
    } else {
      tokenAddress = abi.decode(_g.feeTokenData, (address));
      require(
        IERC20(tokenAddress).transferFrom(_from, feeRecipient, fee),
        "ERC1155Meta#_transferGasFee: ERC20_TRANSFER_FAILED"
      );
    }
  }
}

// File: multi-token-standard/contracts/tokens/ERC1155/ERC1155MintBurn.sol

pragma solidity ^0.6.8;



/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Add _amount
    balances[_to][_id] = balances[_to][_id].add(_amount);

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each ids in _ids
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nMint = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }


  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    //Substract _amount
    balances[_from][_id] = balances[_from][_id].sub(_amount);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    // Number of mints to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

// File: erc20-meta-token/contracts/wrapper/MetaERC20Wrapper.sol

pragma solidity ^0.6.8;
// pragma experimental ABIEncoderV2;








/**
 * @notice Allows users to wrap any amount of any ERC-20 token with a 1:1 ratio
 *   of corresponding ERC-1155 tokens with native metaTransaction methods. Each
 *   ERC-20 is assigned an ERC-1155 id for more efficient CALLDATA usage when
 *   doing transfers.
 */
contract MetaERC20Wrapper is ERC1155Meta, ERC1155MintBurn {

  // Variables
  uint256 internal nTokens = 1;                         // Number of ERC-20 tokens registered
  uint256 constant internal ETH_ID = 0x1;               // ID fo tokens representing Ether is 1
  address constant internal ETH_ADDRESS = address(0x1); // Address for tokens representing Ether is 0x00...01
  mapping (address => uint256) internal addressToID;    // Maps the ERC-20 addresses to their metaERC20 id
  mapping (uint256 => address) internal IDtoAddress;    // Maps the metaERC20 ids to their ERC-20 address


  /***********************************|
  |               Events              |
  |__________________________________*/

  event TokenRegistration(address token_address, uint256 token_id);

  /***********************************|
  |            Constructor            |
  |__________________________________*/

  // Register ETH as ID #1 and address 0x1
  constructor() public {
    addressToID[ETH_ADDRESS] = ETH_ID;
    IDtoAddress[ETH_ID] = ETH_ADDRESS;
  }

  /***********************************|
  |         Deposit Functions         |
  |__________________________________*/

  /**
   * Fallback function
   * @dev Deposit ETH in this contract to receive wrapped ETH
   * No parameters provided
   */
  receive () external payable {
    // Deposit ETH sent with transaction
    deposit(ETH_ADDRESS, msg.sender, msg.value);
  }

  /**
   * @dev Deposit ERC20 tokens or ETH in this contract to receive wrapped ERC20s
   * @param _token     The addess of the token to deposit in this contract
   * @param _recipient Address that will receive the ERC-1155 tokens
   * @param _value     The amount of token to deposit in this contract
   * Note: Users must first approve this contract addres on the contract of the ERC20 to be deposited
   */
  function deposit(address _token, address _recipient, uint256 _value)
    public payable
  {
    require(_recipient != address(0x0), "MetaERC20Wrapper#deposit: INVALID_RECIPIENT");

    // Internal ID of ERC-20 token deposited
    uint256 id;

    // Deposit ERC-20 tokens or ETH
    if (_token != ETH_ADDRESS) {

      // Check if transfer passes
      require(msg.value == 0, "MetaERC20Wrapper#deposit: NON_NULL_MSG_VALUE");
      IERC20(_token).transferFrom(msg.sender, address(this), _value);
      require(checkSuccess(), "MetaERC20Wrapper#deposit: TRANSFER_FAILED");

      // Load address token ID
      uint256 addressId = addressToID[_token];

      // Register ID if not already done
      if (addressId == 0) {
        nTokens += 1;             // Increment number of tokens registered
        id = nTokens;             // id of token is the current # of tokens
        IDtoAddress[id] = _token; // Map id to token address
        addressToID[_token] = id; // Register token

        // Emit registration event
        emit TokenRegistration(_token, id);

      } else {
        id = addressId;
      }

    } else {
      require(_value == msg.value, "MetaERC20Wrapper#deposit: INCORRECT_MSG_VALUE");
      id = ETH_ID;
    }

    // Mint meta tokens
    _mint(_recipient, id, _value, "");
  }


  /***********************************|
  |         Withdraw Functions        |
  |__________________________________*/

  /**
   * @dev Withdraw wrapped ERC20 tokens in this contract to receive the original ERC20s or ETH
   * @param _token The addess of the token to withdrww from this contract
   * @param _to The address where the withdrawn tokens will go to
   * @param _value The amount of tokens to withdraw
   */
  function withdraw(address _token, address payable _to, uint256 _value) public {
    uint256 tokenID = getTokenID(_token);
    _withdraw(msg.sender, _to, tokenID, _value);
  }

  /**
   * @dev Withdraw wrapped ERC20 tokens in this contract to receive the original ERC20s or ETH
   * @param _from    Address of users sending the Meta tokens
   * @param _to      The address where the withdrawn tokens will go to
   * @param _tokenID The token ID of the ERC-20 token to withdraw from this contract
   * @param _value   The amount of tokens to withdraw
   */
  function _withdraw(
    address _from,
    address payable _to,
    uint256 _tokenID,
    uint256 _value)
    internal
  {
    // Burn meta tokens
    _burn(_from, _tokenID, _value);

     // Withdraw ERC-20 tokens or ETH
    if (_tokenID != ETH_ID) {
      address token = IDtoAddress[_tokenID];
      IERC20(token).transfer(_to, _value);
      require(checkSuccess(), "MetaERC20Wrapper#withdraw: TRANSFER_FAILED");

    } else {
      require(_to != address(0), "MetaERC20Wrapper#withdraw: INVALID_RECIPIENT");
      (bool success, ) = _to.call{value: _value}("");
      require(success, "MetaERC20Wrapper#withdraw: TRANSFER_FAILED");
    }


  }
  /**
   * @notice Withdraw ERC-20 tokens when receiving their ERC-1155 counterpart
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _value     The amount of tokens being transferred
   * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address, address payable _from, uint256 _id, uint256 _value, bytes memory)
    public returns(bytes4)
  {
    // Only ERC-1155 from this contract are valid
    require(msg.sender == address(this), "MetaERC20Wrapper#onERC1155Received: INVALID_ERC1155_RECEIVED");
    getIdAddress(_id); // Checks if id is registered

    // Tokens are received, hence need to burn them here
    _withdraw(address(this), _from, _id, _value);

    return ERC1155_RECEIVED_VALUE;
  }

  /**
   * @notice Withdraw ERC-20 tokens when receiving their ERC-1155 counterpart
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _values    An array containing amounts of each token being transferred
   * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address, address payable _from, uint256[] memory _ids, uint256[] memory _values, bytes memory)
    public returns(bytes4)
  {
    // Only ERC-1155 from this contract are valid
    require(msg.sender == address(this), "MetaERC20Wrapper#onERC1155BatchReceived: INVALID_ERC1155_RECEIVED");

    // Withdraw all tokens
    for ( uint256 i = 0; i < _ids.length; i++) {
      // Checks if id is registered
      getIdAddress(_ids[i]);

      // Tokens are received, hence need to burn them here
      _withdraw(address(this), _from, _ids[i], _values[i]);
    }

    return ERC1155_BATCH_RECEIVED_VALUE;
  }

  /**
   * @notice Return the Meta-ERC20 token ID for the given ERC-20 token address
   * @param _token ERC-20 token address to get the corresponding Meta-ERC20 token ID
   * @return tokenID Meta-ERC20 token ID
   */
  function getTokenID(address _token) public view returns (uint256 tokenID) {
    tokenID = addressToID[_token];
    require(tokenID != 0, "MetaERC20Wrapper#getTokenID: UNREGISTERED_TOKEN");
    return tokenID;
  }

  /**
   * @notice Return the ERC-20 token address for the given Meta-ERC20 token ID
   * @param _id Meta-ERC20 token ID to get the corresponding ERC-20 token address
   * @return token ERC-20 token address
   */
  function getIdAddress(uint256 _id) public view returns (address token) {
    token = IDtoAddress[_id];
    require(token != address(0x0), "MetaERC20Wrapper#getIdAddress: UNREGISTERED_TOKEN");
    return token;
  }

  /**
   * @notice Returns number of tokens currently registered
   */
  function getNTokens() external view returns (uint256) {
    return nTokens;
  }



  /***********************************|
  |          Helper Functions         |
  |__________________________________*/

  /**
    * Checks the return value of the previous function up to 32 bytes. Returns true if the previous
    * function returned 0 bytes or 32 bytes that are not all-zero.
    * Code taken from: https://github.com/dydxprotocol/solo/blob/10baf8e4c3fb9db4d0919043d3e6fdd6ba834046/contracts/protocol/lib/Token.sol
    */
  function checkSuccess()
    private pure
    returns (bool)
  {
    uint256 returnValue = 0;

    /* solium-disable-next-line security/no-inline-assembly */
    assembly {
      // check number of bytes returned from last function call
      switch returndatasize()

        // no bytes returned: assume success
        case 0x0 {
          returnValue := 1
        }

        // 32 bytes returned: check if non-zero
        case 0x20 {
          // copy 32 bytes into scratch space
          returndatacopy(0x0, 0x0, 0x20)

          // load those bytes into returnValue
          returnValue := mload(0x0)
        }

        // not sure what was returned: dont mark as success
        default { }
      
    }

    return returnValue != 0;
  }

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more than 5,000 gas.
   * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
   */
  function supportsInterface(bytes4 interfaceID) public override pure returns (bool) {
    return  interfaceID == type(IERC165).interfaceId ||
      interfaceID == type(IERC1155).interfaceId || 
      interfaceID == type(IERC1155TokenReceiver).interfaceId;        
  }

}

// File: contracts/ArcadeumCoin.sol

pragma solidity ^0.6.8;
// pragma experimental ABIEncoderV2;


contract ArcadeumCoin is MetaERC20Wrapper {}