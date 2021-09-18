/**
 *Submitted for verification at polygonscan.com on 2021-09-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
//Written by Blockchainguy.net
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



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

  /**
   * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
   * @param  interfaceID The ERC-165 interface ID that is queried for support.s
   * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
   *      This function MUST NOT consume more than 5,000 gas.
   * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
   */
  function supportsInterface(bytes4 interfaceID) external view returns (bool);

}

interface IERC1155 {
  // Events

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

  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);

}

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
/**
 * Utility library of inline functions on addresses
 */
library Address {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { codehash := extcodehash(account) }
    return (codehash != 0x0 && codehash != accountHash);
  }

}

/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC165 {
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

  // Events
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event URI(string _uri, uint256 indexed _id);


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
    public
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount >= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, _data);
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
    public
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
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
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data);
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
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data);
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
    external
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }


  function isApprovedForAll(address _owner, address _operator)
    public virtual view returns (bool isOperator)
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
    public view returns (uint256)
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
    public view returns (uint256[] memory)
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

 
  bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

  bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

  function supportsInterface(bytes4 _interfaceID) external override view returns (bool) {
    if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
        _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
      return true;
    }
    return false;
  }

}

/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata {

  // URI's default URI prefix
  string internal baseMetadataURI;
  event URI(string _uri, uint256 indexed _id);


  /***********************************|
  |     Metadata Public Function s    |
  |__________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   *      Token IDs are assumed to be represented in their hex format in URIs
   * @return URI string
   */
  function uri(uint256 _id) public virtual view returns (string memory) {
    return string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
  }


  /***********************************|
  |    Metadata Internal Functions    |
  |__________________________________*/

  /**
   * @notice Will emit default URI log event for corresponding token _id
   * @param _tokenIDs Array of IDs of tokens to log default URI
   */
  function _logURIs(uint256[] memory _tokenIDs) internal {
    string memory baseURL = baseMetadataURI;
    string memory tokenURI;

    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      tokenURI = string(abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json"));
      emit URI(tokenURI, _tokenIDs[i]);
    }
  }

  /**
   * @notice Will emit a specific URI log event for corresponding token
   * @param _tokenIDs IDs of the token corresponding to the _uris logged
   * @param _URIs    The URIs of the specified _tokenIDs
   */
  function _logURIs(uint256[] memory _tokenIDs, string[] memory _URIs) internal {
    require(_tokenIDs.length == _URIs.length, "ERC1155Metadata#_logURIs: INVALID_ARRAYS_LENGTH");
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      emit URI(_URIs[i], _tokenIDs[i]);
    }
  }

  /**
   * @notice Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
    baseMetadataURI = _newBaseMetadataURI;
  }


  /***********************************|
  |    Utility Internal Functions     |
  |__________________________________*/

  /**
   * @notice Convert uint256 to string
   * @param _i Unsigned integer to convert to string
   */
  function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }

    uint256 j = _i;
    uint256 ii = _i;
    uint256 len;

    // Get number of bytes
    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;

    // Get each individual ASCII
    while (ii != 0) {
      bstr[k--] = byte(uint8(48 + ii % 10));
      ii /= 10;
    }

    // Convert to string
    return string(bstr);
  }

}

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
    _callonERC1155Received(address(0x0), _to, _id, _amount, _data);
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
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, _data);
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
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nBurn = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }

}

library Strings {
	// via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
	function strConcat(
		string memory _a,
		string memory _b,
		string memory _c,
		string memory _d,
		string memory _e
	) internal pure returns (string memory) {
		bytes memory _ba = bytes(_a);
		bytes memory _bb = bytes(_b);
		bytes memory _bc = bytes(_c);
		bytes memory _bd = bytes(_d);
		bytes memory _be = bytes(_e);
		string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
		bytes memory babcde = bytes(abcde);
		uint256 k = 0;
		for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
		for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
		for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
		for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
		for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
		return string(babcde);
	}

	function strConcat(
		string memory _a,
		string memory _b,
		string memory _c,
		string memory _d
	) internal pure returns (string memory) {
		return strConcat(_a, _b, _c, _d, "");
	}

	function strConcat(
		string memory _a,
		string memory _b,
		string memory _c
	) internal pure returns (string memory) {
		return strConcat(_a, _b, _c, "", "");
	}

	function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
		return strConcat(_a, _b, "", "", "");
	}

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len - 1;
		while (_i != 0) {
			bstr[k--] = bytes1(uint8(48 + (_i % 10)));
			_i /= 10;
		}
		return string(bstr);
	}
}


/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, 
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155, ERC1155MintBurn, ERC1155Metadata, Ownable {
	using Strings for string;

	uint256 private _currentTokenId = 0;
	mapping(uint256 => address) public creators;
	mapping(uint256 => uint256) public tokenCount;
	mapping(uint256 => uint256) public tokenMaxSupply;
	
	mapping(uint256 => uint256) public reserved_for_owner ;
    mapping(uint256 => uint256) public total_nft_claimed_by_owner;
     
    mapping(uint256 => uint256) public reserved_for_partner;
    mapping(uint256 => uint256) public total_nft_claimed_by_partner;
    
    uint256 public daily_nft_buy_limit = 500;
    mapping(uint256 => uint256) public nft_bought_today;
    uint256 public today_start_time = 0;
    uint256 private total_released_supply = 0;
    
    mapping(address => mapping(uint256 => uint256)) public user_daily_purchases; // user_daily_purchases[msg.sender][days_passed] = get uint of today's purchases
    uint256 public user_daily_purchase_limit = 10;
    
    uint256  public days_passed = 1;
    
   address public partner_wallet;
   
   address public usdt_address;
    
	// Contract name
	string public name;
	// Contract symbol
	string public symbol;

	constructor(
		string memory _name,
		string memory _symbol,
		address _usdt_address,
		address partner_Address
	) public {
		name = _name;
		symbol = _symbol;
		usdt_address = _usdt_address;
		partner_wallet = partner_Address;
		create(21000000,"",850000,150000);
	}
	function update_user_daily_purchase_limit(uint256 limit) external onlyOwner{
	    user_daily_purchase_limit = limit;
	}
	function update_partner_wallet(address partner_Address) external onlyOwner{
	    partner_wallet = partner_Address;
	}

	function uri(uint256 _id) public override view returns (string memory) {
	//	require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
		return Strings.strConcat(baseMetadataURI, Strings.uint2str(_id));
	}


	function get_token_count() public view returns (uint256) {
		return tokenCount[1];
	}

	/**
	 * @dev Returns the max quantity for a token ID
	 * @param _id uint256 ID of the token to query
	 * @return amount of token in existence
	 */
	function maxSupply(uint256 _id) public view returns (uint256) {
		return tokenMaxSupply[_id];
	}
	
	function get_total_released_supply() public view returns(uint256){
	    if( get_token_count().add(check_daily_limit_remaining(days_passed)) > tokenMaxSupply[1] ){
	        return tokenMaxSupply[1];
	    }
	    return get_token_count().add(check_daily_limit_remaining(days_passed));
	}
// 	function update_total_released_supply(uint256 supply) public onlyOwner{
// 	    return total_released_supply = supply;
// 	}

	/**
	 * @dev Will update the base URL of token's URI
	 * @param _newBaseMetadataURI New base URL of token's URI
	 */
	function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyOwner {
		_setBaseMetadataURI(_newBaseMetadataURI);
	}

    function update_daily_nft_limit(uint256 _id) internal {
        uint256 today_end_time = today_start_time + 24 hours;
        if(now > today_end_time){
            if(days_passed == 1){
                total_released_supply = total_released_supply.add(500);
            }
            if(days_passed == 2){
                daily_nft_buy_limit = check_daily_limit_remaining(_id).add(1000);
                total_released_supply = total_released_supply.add(1000);
            }else if(days_passed == 3){
                daily_nft_buy_limit = check_daily_limit_remaining(_id).add(3500);
                total_released_supply = total_released_supply.add(3500);
            }else if(days_passed == 4){
                daily_nft_buy_limit = check_daily_limit_remaining(_id).add(35000);
                total_released_supply = total_released_supply.add(35000);
            }else if(days_passed == 5){
                daily_nft_buy_limit = check_daily_limit_remaining(_id).add(60000);
                total_released_supply = total_released_supply.add(60000);
            }else if(days_passed == 6){
                daily_nft_buy_limit = check_daily_limit_remaining(_id).add(900000);
                total_released_supply = total_released_supply.add(900000);
            }else if(days_passed == 7 || days_passed == 8|| days_passed == 9|| days_passed == 10|| days_passed == 11 || days_passed == 12 || days_passed == 13|| days_passed == 14|| days_passed == 15){
                daily_nft_buy_limit = check_daily_limit_remaining(_id).add(1000000);
                total_released_supply = total_released_supply.add(1000000);
            }else if(days_passed == 16 || days_passed == 17|| days_passed == 18|| days_passed == 19|| days_passed == 20 || days_passed == 21 || days_passed == 22|| days_passed == 23|| days_passed == 24){
                daily_nft_buy_limit = check_daily_limit_remaining(_id).add(1000000);
                total_released_supply = total_released_supply.add(1000000);
            }else if(days_passed == 25){
                daily_nft_buy_limit = check_daily_limit_remaining(_id).add(1000000);
                total_released_supply = total_released_supply.add(1000000);
            }else if(days_passed > 25){
                daily_nft_buy_limit = 1000000;
                total_released_supply = total_released_supply.add(1000000);
            }
            
            today_start_time = today_end_time;
            days_passed++;
            nft_bought_today[ _id] = 1;
        }else{
            nft_bought_today[ _id] = nft_bought_today[ _id].add(1);
        }
    }
    
    function check_daily_limit_remaining(uint256 _id) public view returns(uint256){
        if(nft_bought_today[ _id] < daily_nft_buy_limit){
            return daily_nft_buy_limit.sub(nft_bought_today[ _id]);
        }
        return 0;
    }
    // function set_current_token_count(uint256 _id) public onlyOwner{
    //     tokenCount[1] = _id;
    // }
    // function set_days_passed(uint256 _id) public onlyOwner{
    //     days_passed = _id;
    // }
    function set_start_time(uint256 start) external onlyOwner{

            today_start_time = start;
        
    }
    //returns price for usdt with 6 decimals
    function getCurrentNftPrice() public view returns (uint256){
        uint256 temp_token_count = tokenCount[1];

if(temp_token_count <= 1500000){return 0;}   
    else if(temp_token_count >= 1500001 && temp_token_count < 2000001){return 1 * 10**6;}   
    else if(temp_token_count >= 2000001 && temp_token_count < 3000001){return 2 * 10**6;}   
    else if(temp_token_count >= 3000001 && temp_token_count < 4000001){return 3 * 10**6;}   
    else if(temp_token_count >= 4000001 && temp_token_count < 5000001){return 4 * 10**6;}   
    else if(temp_token_count >= 5000001 && temp_token_count < 6000001){return 5 * 10**6;}   
    else if(temp_token_count >= 6000001 && temp_token_count < 7000001){return 6 * 10**6;}   
    else if(temp_token_count >= 7000001 && temp_token_count < 8000001){return 7 * 10**6;}   
    else if(temp_token_count >= 8000001 && temp_token_count < 9000001){return 8 * 10**6;}   
    else if(temp_token_count >= 9000001 && temp_token_count < 10000001){return 9 * 10**6;}  
    else if(temp_token_count >= 10000001 && temp_token_count < 11000001){return 10 * 10**6;}
    else if(temp_token_count >= 11000001 && temp_token_count < 11200001){return 15 * 10**6;}
    else if(temp_token_count >= 11200001 && temp_token_count < 11400001){return 22 * 10**6;}
    else if(temp_token_count >= 11400001 && temp_token_count < 11600001){return 36 * 10**6;}
    else if(temp_token_count >= 11600001 && temp_token_count < 11800001){return 45 * 10**6;}
    else if(temp_token_count >= 11800001 && temp_token_count < 12000001){return 51 * 10**6;}
    else if(temp_token_count >= 12000001 && temp_token_count < 12200001){return 64 * 10**6;}
    else if(temp_token_count >= 12200001 && temp_token_count < 12400001){return 75 * 10**6;}
    else if(temp_token_count >= 12400001 && temp_token_count < 12600001){return 82 * 10**6;}
    else if(temp_token_count >= 12600001 && temp_token_count < 12800001){return 97 * 10**6;}
    else if(temp_token_count >= 12800001 && temp_token_count < 12900001){return 109 * 10**6;}
    else if(temp_token_count >= 12900001 && temp_token_count < 13000001){return 115 * 10**6;}
    else if(temp_token_count >= 13000001 && temp_token_count < 13100001){return 127 * 10**6;}
    else if(temp_token_count >= 13100001 && temp_token_count < 13200001){return 136 * 10**6;}
    else if(temp_token_count >= 13200001 && temp_token_count < 13300001){return 149 * 10**6;}
    else if(temp_token_count >= 13300001 && temp_token_count < 13400001){return 155 * 10**6;}
    else if(temp_token_count >= 13400001 && temp_token_count < 13500001){return 165 * 10**6;}
    else if(temp_token_count >= 13500001 && temp_token_count < 13600001){return 172 * 10**6;}
    else if(temp_token_count >= 13600001 && temp_token_count < 13700001){return 185 * 10**6;}
    else if(temp_token_count >= 13700001 && temp_token_count < 13800001){return 196 * 10**6;}
    else if(temp_token_count >= 13800001 && temp_token_count < 13900001){return 205 * 10**6;}
    else if(temp_token_count >= 13900001 && temp_token_count < 14000001){return 215 * 10**6;}
    else if(temp_token_count >= 14000001 && temp_token_count < 14100001){return 222 * 10**6;}
    else if(temp_token_count >= 14100001 && temp_token_count < 14200001){return 237 * 10**6;}
    else if(temp_token_count >= 14200001 && temp_token_count < 14300001){return 245 * 10**6;}
    else if(temp_token_count >= 14300001 && temp_token_count < 14400001){return 255 * 10**6;}
    else if(temp_token_count >= 14400001 && temp_token_count < 14500001){return 263 * 10**6;}
    else if(temp_token_count >= 14500001 && temp_token_count < 14600001){return 276 * 10**6;}
    else if(temp_token_count >= 14600001 && temp_token_count < 14700001){return 284 * 10**6;}
    else if(temp_token_count >= 14700001 && temp_token_count < 14800001){return 295 * 10**6;}
    else if(temp_token_count >= 14800001 && temp_token_count < 14900001){return 297 * 10**6;}
    else if(temp_token_count >= 14900001 && temp_token_count < 15000001){return 300 * 10**6;}
    else if(temp_token_count >= 15000001 && temp_token_count < 15075001){return 325 * 10**6;}
    else if(temp_token_count >= 15075001 && temp_token_count < 15150001){return 350 * 10**6;}
    else if(temp_token_count >= 15150001 && temp_token_count < 15225001){return 375 * 10**6;}
    else if(temp_token_count >= 15225001 && temp_token_count < 15300001){return 400 * 10**6;}
    else if(temp_token_count >= 15300001 && temp_token_count < 15375001){return 425 * 10**6;}
    else if(temp_token_count >= 15375001 && temp_token_count < 15450001){return 450 * 10**6;}
    else if(temp_token_count >= 15450001 && temp_token_count < 15525001){return 475 * 10**6;}
    else if(temp_token_count >= 15525001 && temp_token_count < 15600001){return 500 * 10**6;}
    else if(temp_token_count >= 15600001 && temp_token_count < 15675001){return 525 * 10**6;}
    else if(temp_token_count >= 15675001 && temp_token_count < 15750001){return 550 * 10**6;}
    else if(temp_token_count >= 15750001 && temp_token_count < 15825001){return 575 * 10**6;}
    else if(temp_token_count >= 15825001 && temp_token_count < 15900001){return 600 * 10**6;}
    else if(temp_token_count >= 15900001 && temp_token_count < 15975001){return 625 * 10**6;}
    else if(temp_token_count >= 15975001 && temp_token_count < 16050001){return 650 * 10**6;}
    else if(temp_token_count >= 16050001 && temp_token_count < 16125001){return 675 * 10**6;}
    else if(temp_token_count >= 16125001 && temp_token_count < 16200001){return 700 * 10**6;}
    else if(temp_token_count >= 16200001 && temp_token_count < 16275001){return 725 * 10**6;}
    else if(temp_token_count >= 16275001 && temp_token_count < 16350001){return 750 * 10**6;}
    else if(temp_token_count >= 16350001 && temp_token_count < 16425001){return 775 * 10**6;}
    else if(temp_token_count >= 16425001 && temp_token_count < 16500001){return 800 * 10**6;}
    else if(temp_token_count >= 16500001 && temp_token_count < 16575001){return 825 * 10**6;}
    else if(temp_token_count >= 16575001 && temp_token_count < 16650001){return 850 * 10**6;}
    else if(temp_token_count >= 16650001 && temp_token_count < 16725001){return 875 * 10**6;}
    else if(temp_token_count >= 16725001 && temp_token_count < 16800001){return 900 * 10**6;}
    else if(temp_token_count >= 16800001 && temp_token_count < 16875001){return 925 * 10**6;}
    else if(temp_token_count >= 16875001 && temp_token_count < 16950001){return 950 * 10**6;}
    else if(temp_token_count >= 16950001 && temp_token_count < 17025001){return 975 * 10**6;}
    else if(temp_token_count >= 17025001 && temp_token_count < 17100001){return 1000 * 10**6;}
    else if(temp_token_count >= 17100001 && temp_token_count < 17175001){return 1025 * 10**6;}
    else if(temp_token_count >= 17175001 && temp_token_count < 17250001){return 1050 * 10**6;}
    else if(temp_token_count >= 17250001 && temp_token_count < 17325001){return 1075 * 10**6;}
    else if(temp_token_count >= 17325001 && temp_token_count < 17400001){return 1100 * 10**6;}
    else if(temp_token_count >= 17400001 && temp_token_count < 17475001){return 1125 * 10**6;}
    else if(temp_token_count >= 17475001 && temp_token_count < 17550001){return 1150 * 10**6;}
    else if(temp_token_count >= 17550001 && temp_token_count < 17625001){return 1175 * 10**6;}
    else if(temp_token_count >= 17625001 && temp_token_count < 17700001){return 1200 * 10**6;}
    else if(temp_token_count >= 17700001 && temp_token_count < 17775001){return 1225 * 10**6;}
    else if(temp_token_count >= 17775001 && temp_token_count < 17850001){return 1250 * 10**6;}
    else if(temp_token_count >= 17850001 && temp_token_count < 17925001){return 1275 * 10**6;}
    else if(temp_token_count >= 17925001 && temp_token_count < 18000001){return 1300 * 10**6;}
    else if(temp_token_count >= 18000001 && temp_token_count < 18025001){return 153375 * 10**4;}
    else if(temp_token_count >= 18025001 && temp_token_count < 18050001){return 17675 * 10**5;}
    else if(temp_token_count >= 18050001 && temp_token_count < 18075001){return 200125 * 10**4;}
    else if(temp_token_count >= 18075001 && temp_token_count < 18100001){return 2235 * 10**6;}
    else if(temp_token_count >= 18100001 && temp_token_count < 18125001){return 246875 * 10**4;}
    else if(temp_token_count >= 18125001 && temp_token_count < 18150001){return 27025 * 10**5;}
    else if(temp_token_count >= 18150001 && temp_token_count < 18175001){return 293625 * 10**4;}
    else if(temp_token_count >= 18175001 && temp_token_count < 18200001){return 3170 * 10**6;}
    else if(temp_token_count >= 18200001 && temp_token_count < 18225001){return 340375 * 10**4;}
    else if(temp_token_count >= 18225001 && temp_token_count < 18250001){return 36375 * 10**5;}
    else if(temp_token_count >= 18250001 && temp_token_count < 18275001){return 387125 * 10**4;}
    else if(temp_token_count >= 18275001 && temp_token_count < 18300001){return 4105 * 10**6;}
    else if(temp_token_count >= 18300001 && temp_token_count < 18325001){return 433875 * 10**4;}
    else if(temp_token_count >= 18325001 && temp_token_count < 18350001){return 45725 * 10**5;}
    else if(temp_token_count >= 18350001 && temp_token_count < 18375001){return 480625 * 10**4;}
    else if(temp_token_count >= 18375001 && temp_token_count < 18400001){return 5040 * 10**6;}
    else if(temp_token_count >= 18400001 && temp_token_count < 18425001){return 527375 * 10**4;}
    else if(temp_token_count >= 18425001 && temp_token_count < 18450001){return 55075 * 10**5;}
    else if(temp_token_count >= 18450001 && temp_token_count < 18475001){return 574125 * 10**4;}
    else if(temp_token_count >= 18475001 && temp_token_count < 18500001){return 5975 * 10**6;}
    else if(temp_token_count >= 18500001 && temp_token_count < 18525001){return 620875 * 10**4;}
    else if(temp_token_count >= 18525001 && temp_token_count < 18550001){return 64425 * 10**5;}
    else if(temp_token_count >= 18550001 && temp_token_count < 18575001){return 667625 * 10**4;}
    else if(temp_token_count >= 18575001 && temp_token_count < 18600001){return 6910 * 10**6;}
    else if(temp_token_count >= 18600001 && temp_token_count < 18625001){return 714375 * 10**4;}
    else if(temp_token_count >= 18625001 && temp_token_count < 18650001){return 73775 * 10**5;}
    else if(temp_token_count >= 18650001 && temp_token_count < 18675001){return 761125 * 10**4;}
    else if(temp_token_count >= 18675001 && temp_token_count < 18700001){return 7845 * 10**6;}
    else if(temp_token_count >= 18700001 && temp_token_count < 18725001){return 807875 * 10**4;}
    else if(temp_token_count >= 18725001 && temp_token_count < 18750001){return 83125 * 10**5;}
    else if(temp_token_count >= 18750001 && temp_token_count < 18775001){return 854625 * 10**4;}
    else if(temp_token_count >= 18775001 && temp_token_count < 18800001){return 8780 * 10**6;}
    else if(temp_token_count >= 18800001 && temp_token_count < 18825001){return 901375 * 10**4;}
    else if(temp_token_count >= 18825001 && temp_token_count < 18850001){return 92475 * 10**5;}
    else if(temp_token_count >= 18850001 && temp_token_count < 18875001){return 948125 * 10**4;}
    else if(temp_token_count >= 18875001 && temp_token_count < 18900001){return 9715 * 10**6;}
    else if(temp_token_count >= 18900001 && temp_token_count < 18925001){return 994875 * 10**4;}
    else if(temp_token_count >= 18925001 && temp_token_count < 18950001){return 101825 * 10**5;}
    else if(temp_token_count >= 18950001 && temp_token_count < 18975001){return 1041625 * 10**4;}
    else if(temp_token_count >= 18975001 && temp_token_count < 19000001){return 10650 * 10**6;}
    else if(temp_token_count >= 19000001 && temp_token_count < 19025001){return 1088375 * 10**4;}
    else if(temp_token_count >= 19025001 && temp_token_count < 19050001){return 111175 * 10**5;}
    else if(temp_token_count >= 19050001 && temp_token_count < 19075001){return 1135125 * 10**4;}
    else if(temp_token_count >= 19075001 && temp_token_count < 19100001){return 11585 * 10**6;}
    else if(temp_token_count >= 19100001 && temp_token_count < 19125001){return 1181875 * 10**4;}
    else if(temp_token_count >= 19125001 && temp_token_count < 19150001){return 120525 * 10**5;}
    else if(temp_token_count >= 19150001 && temp_token_count < 19175001){return 1228625 * 10**4;}
    else if(temp_token_count >= 19175001 && temp_token_count < 19200001){return 12520 * 10**6;}
    else if(temp_token_count >= 19200001 && temp_token_count < 19225001){return 1275375 * 10**4;}
    else if(temp_token_count >= 19225001 && temp_token_count < 19250001){return 129875 * 10**5;}
    else if(temp_token_count >= 19250001 && temp_token_count < 19275001){return 1322125 * 10**4;}
    else if(temp_token_count >= 19275001 && temp_token_count < 19300001){return 13455 * 10**6;}
    else if(temp_token_count >= 19300001 && temp_token_count < 19325001){return 1368875 * 10**4;}
    else if(temp_token_count >= 19325001 && temp_token_count < 19350001){return 139225 * 10**5;}
    else if(temp_token_count >= 19350001 && temp_token_count < 19375001){return 1415625 * 10**4;}
    else if(temp_token_count >= 19375001 && temp_token_count < 19400001){return 14390 * 10**6;}
    else if(temp_token_count >= 19400001 && temp_token_count < 19425001){return 1462375 * 10**4;}
    else if(temp_token_count >= 19425001 && temp_token_count < 19450001){return 148575 * 10**5;}
    else if(temp_token_count >= 19450001 && temp_token_count < 19475001){return 1509125 * 10**4;}
    else if(temp_token_count >= 19475001 && temp_token_count < 19500001){return 15325 * 10**6;}
    else if(temp_token_count >= 19500001 && temp_token_count < 19525001){return 1555875 * 10**4;}
    else if(temp_token_count >= 19525001 && temp_token_count < 19550001){return 157925 * 10**5;}
    else if(temp_token_count >= 19550001 && temp_token_count < 19575001){return 1602625 * 10**4;}
    else if(temp_token_count >= 19575001 && temp_token_count < 19600001){return 16260 * 10**6;}
    else if(temp_token_count >= 19600001 && temp_token_count < 19625001){return 1649375 * 10**4;}
    else if(temp_token_count >= 19625001 && temp_token_count < 19650001){return 167275 * 10**5;}
    else if(temp_token_count >= 19650001 && temp_token_count < 19675001){return 1696125 * 10**2;}
    else if(temp_token_count >= 19675001 && temp_token_count < 19700001){return 17195 * 10**6;}
    else if(temp_token_count >= 19700001 && temp_token_count < 19725001){return 1742875 * 10**4;}
    else if(temp_token_count >= 19725001 && temp_token_count < 19750001){return 176625 * 10**5;}
    else if(temp_token_count >= 19750001 && temp_token_count < 19775001){return 1789625 * 10**4;}
    else if(temp_token_count >= 19775001 && temp_token_count < 19800001){return 18130 * 10**6;}
    else if(temp_token_count >= 19800001 && temp_token_count < 19825001){return 1836375 * 10**4;}
    else if(temp_token_count >= 19825001 && temp_token_count < 19850001){return 185975 * 10**5;}
    else if(temp_token_count >= 19850001 && temp_token_count < 19875001){return 1883125 * 10**4;}
    else if(temp_token_count >= 19875001 && temp_token_count < 19900001){return 19065 * 10**6;}
    else if(temp_token_count >= 19900001 && temp_token_count < 19925001){return 1929875 * 10**4;}
    else if(temp_token_count >= 19925001 && temp_token_count < 19950001){return 195325 * 10**5;}
    else if(temp_token_count >= 19950001 && temp_token_count < 19975001){return 1976625 * 10**4;}
    else if(temp_token_count >= 19975001 && temp_token_count < 20000001){return 20000 * 10**6;}
    else if(temp_token_count >= 20000001 && temp_token_count < 20028001){return 21237 * 10**6;}
    else if(temp_token_count >= 20028001 && temp_token_count < 20053001){return 22874 * 10**6;}
    else if(temp_token_count >= 20053001 && temp_token_count < 20078001){return 24911 * 10**6;}
    else if(temp_token_count >= 20078001 && temp_token_count < 20103001){return 27148 * 10**6;}
    else if(temp_token_count >= 20103001 && temp_token_count < 20128001){return 29785 * 10**6;}
    else if(temp_token_count >= 20128001 && temp_token_count < 20157001){return 32822 * 10**6;}
    else if(temp_token_count >= 20157001 && temp_token_count < 20181001){return 36259 * 10**6;}
    else if(temp_token_count >= 20181001 && temp_token_count < 20204001){return 40196 * 10**6;}
    else if(temp_token_count >= 20204001 && temp_token_count < 20227001){return 44433 * 10**6;}
    else if(temp_token_count >= 20227001 && temp_token_count < 20260001){return 49070 * 10**6;}
    else if(temp_token_count >= 20260001 && temp_token_count < 20282001){return 54107 * 10**6;}
    else if(temp_token_count >= 20282001 && temp_token_count < 20303001){return 59644 * 10**6;}
    else if(temp_token_count >= 20303001 && temp_token_count < 20334001){return 65781 * 10**6;}
    else if(temp_token_count >= 20334001 && temp_token_count < 20354001){return 72218 * 10**6;}
    else if(temp_token_count >= 20354001 && temp_token_count < 20374001){return 79455 * 10**6;}
    else if(temp_token_count >= 20374001 && temp_token_count < 20393001){return 87192 * 10**6;}
    else if(temp_token_count >= 20393001 && temp_token_count < 20412001){return 95329 * 10**6;}
    else if(temp_token_count >= 20412001 && temp_token_count < 20430001){return 103766 * 10**6;}
    else if(temp_token_count >= 20430001 && temp_token_count < 20448001){return 112703 * 10**6;}
    else if(temp_token_count >= 20448001 && temp_token_count < 20465001){return 122340 * 10**6;}
    else if(temp_token_count >= 20465001 && temp_token_count < 20482001){return 132577 * 10**6;}
    else if(temp_token_count >= 20482001 && temp_token_count < 20498001){return 143414 * 10**6;}
    else if(temp_token_count >= 20498001 && temp_token_count < 20514001){return 156251 * 10**6;}
    else if(temp_token_count >= 20514001 && temp_token_count < 20530001){return 170088 * 10**6;}
    else if(temp_token_count >= 20530001 && temp_token_count < 20546001){return 183525 * 10**6;}
    else if(temp_token_count >= 20546001 && temp_token_count < 20562001){return 197662 * 10**6;}
    else if(temp_token_count >= 20562001 && temp_token_count < 20578001){return 208499 * 10**6;}
    else if(temp_token_count >= 20578001 && temp_token_count < 20600001){return 225000 * 10**6;}
    else if(temp_token_count >= 20600001 && temp_token_count < 20625001){return 247500 * 10**6;}
    else if(temp_token_count >= 20625001 && temp_token_count < 20650001){return 270000 * 10**6;}
    else if(temp_token_count >= 20650001 && temp_token_count < 20675001){return 292500 * 10**6;}
    else if(temp_token_count >= 20675001 && temp_token_count < 20700001){return 315000 * 10**6;}
    else if(temp_token_count >= 20700001 && temp_token_count < 20725001){return 337500 * 10**6;}
    else if(temp_token_count >= 20725001 && temp_token_count < 20750001){return 360000 * 10**6;}
    else if(temp_token_count >= 20750001 && temp_token_count < 20775001){return 382500 * 10**6;}
    else if(temp_token_count >= 20775001 && temp_token_count < 20800001){return 405000 * 10**6;}
    else if(temp_token_count >= 20800001 && temp_token_count < 20825001){return 427500 * 10**6;}
    else if(temp_token_count >= 20825001 && temp_token_count < 20850001){return 500000 * 10**6;}
    else if(temp_token_count >= 20850001 && temp_token_count < 20868001){return 521739 * 10**6;}
    else if(temp_token_count >= 20868001 && temp_token_count < 20877523){return 543478 * 10**6;}
    else if(temp_token_count >= 20877523 && temp_token_count < 20885082){return 565217 * 10**6;}
    else if(temp_token_count >= 20885082 && temp_token_count < 20891626){return 586956 * 10**6;}
    else if(temp_token_count >= 20891626 && temp_token_count < 20898148){return 608695 * 10**6;}
    else if(temp_token_count >= 20898148 && temp_token_count < 20904670){return 630434 * 10**6;}
    else if(temp_token_count >= 20904670 && temp_token_count < 20911192){return 652173 * 10**6;}
    else if(temp_token_count >= 20911192 && temp_token_count < 20917714){return 673912 * 10**6;}
    else if(temp_token_count >= 20917714 && temp_token_count < 20924236){return 695651 * 10**6;}
    else if(temp_token_count >= 20924236 && temp_token_count < 20930758){return 717390 * 10**6;}
    else if(temp_token_count >= 20930758 && temp_token_count < 20937280){return 739129 * 10**6;}
    else if(temp_token_count >= 20937280 && temp_token_count < 20943802){return 760868 * 10**6;}
    else if(temp_token_count >= 20943802 && temp_token_count < 20950324){return 782607 * 10**6;}
    else if(temp_token_count >= 20950324 && temp_token_count < 20956846){return 804346 * 10**6;}
    else if(temp_token_count >= 20956846 && temp_token_count < 20963368){return 826085 * 10**6;}
    else if(temp_token_count >= 20963368 && temp_token_count < 20969890){return 847824 * 10**6;}
    else if(temp_token_count >= 20969890 && temp_token_count < 20976412){return 869563 * 10**6;}
    else if(temp_token_count >= 20976412 && temp_token_count < 20982934){return 891302 * 10**6;}
    else if(temp_token_count >= 20982934 && temp_token_count < 20989456){return 913041 * 10**6;}
    else if(temp_token_count >= 20989456 && temp_token_count < 20995956){return 934780 * 10**6;}
    else if(temp_token_count >= 20995956 && temp_token_count < 20999478){return 956519 * 10**6;}
    else if(temp_token_count >= 20999478 && temp_token_count < 21000000){return 978258 * 10**6;}
    else if(temp_token_count >= 21000000 ){return 1000000 * 10**6;}
    }    
    
    function update_usdt(address _usdt_address) public onlyOwner{
        usdt_address = _usdt_address;
    }
    
	function create(
		uint256 _maxSupply,
		string memory _uri,
		uint256 _reserved_for_owner,
		uint256 _reserved_for_partner
	) internal returns (uint256 tokenId) {
		//require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");
		uint256 _id = _getNextTokenID();
		_incrementTokenTypeId();
		creators[_id] = msg.sender;

		if (bytes(_uri).length > 0) {
			emit URI(_uri, _id);
		}
		tokenCount[_id] = 0; //setting initial supply
		tokenMaxSupply[_id] = _maxSupply;
		
    	reserved_for_owner[_id] = _reserved_for_owner;
        total_nft_claimed_by_owner[_id] = 0;
         
        reserved_for_partner[_id] = _reserved_for_partner;
        total_nft_claimed_by_partner[_id] = 0;
		return _id;
	}
	function get_token_max_supply()public view returns(uint256){
	    return tokenMaxSupply[1];
	}
    
	function mint() public {
	    uint256 _token_id = 1;
		require(tokenCount[_token_id] < tokenMaxSupply[_token_id], "Max supply reached");
		require(check_daily_limit_remaining(_token_id) > 0, "Contract's Daily Limit Reached");
		require(user_daily_purchases[msg.sender][days_passed] < user_daily_purchase_limit, "Users Daily Purchase Limit Reached");
		require(tokenCount[_token_id] >= 1000000, "Public minting will start after 1000000");
		require(today_start_time != 0, "Owner have not set a start time");

		if(getCurrentNftPrice() != 0){
		    require(IERC20(usdt_address).allowance(_msgSender(),address(this)) >= getCurrentNftPrice(), "Approve USDT First to Buy");
		    IERC20(usdt_address).transferFrom(_msgSender(), owner(), getCurrentNftPrice());
		}
		_mint(msg.sender, tokenCount[_token_id], 1, "");
		tokenCount[_token_id] = tokenCount[_token_id].add(1);
		update_daily_nft_limit(1);
		user_daily_purchases[msg.sender][days_passed] = user_daily_purchases[msg.sender][days_passed].add(1);

		
	}
	function burn(address _from, uint256 _id) external onlyOwner{
	    _burn(_from, _id,1);
	}
	
	function mint_to_owner(uint256 count) public onlyOwner {
	        uint256 _token_id = 1;
            require(total_nft_claimed_by_owner[_token_id] < reserved_for_owner[_token_id], "Owner Limit Reached");
            require(tokenCount[_token_id] + count < tokenMaxSupply[_token_id], "Total Supply Reacched");
            require(count <= 20, "Max 20 Allowed");
            
        for (uint256 i = 0; i < count; i++) {
            
		_mint(owner(), tokenCount[_token_id] + 1, 1, "");
		
		tokenCount[_token_id] = tokenCount[_token_id].add(1);
        total_nft_claimed_by_owner[_token_id] = total_nft_claimed_by_owner[_token_id].add(1);
        }
    }
    function mint_to_partner(uint256 count) public {
        uint256 _token_id = 1;
        require(msg.sender == partner_wallet, " Only Partnet Wallet can claim it");
       require(total_nft_claimed_by_partner[_token_id] < reserved_for_partner[_token_id], "Limit Reached");
       require(tokenCount[_token_id] + count < tokenMaxSupply[_token_id], "Total Supply Reacched");
       require(count <= 20, "Max 20 Allowed");    
        for (uint256 i = 0; i < count; i++) {
		
     
		_mint(partner_wallet, tokenCount[_token_id], 1, "");
		tokenCount[_token_id] = tokenCount[_token_id].add(1);
        total_nft_claimed_by_partner[_token_id] = total_nft_claimed_by_partner[_token_id].add(1);
        //_currentTokenId = _currentTokenId + 1;
         }
    }



	function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
		return ERC1155.isApprovedForAll(_owner, _operator);
	}

	/**
	 * @dev Returns whether the specified token exists by checking to see if it has a creator
	 * @param _id uint256 ID of the token to query the existence of
	 * @return bool whether the token exists
	 */
	function _exists(uint256 _id) internal view returns (bool) {
		return creators[_id] != address(0);
	}

	/**
	 * @dev calculates the next token ID based on value of _currentTokenId
	 * @return uint256 for the next token ID
	 */
	function _getNextTokenID() private view returns (uint256) {
		return _currentTokenId.add(1);
	}

	/**
	 * @dev increments the value of _currentTokenId
	 */
	function _incrementTokenTypeId() private {
		_currentTokenId++;
	}
}

/**
 * @title Bittycoin
 * Bittycoin - Collect limited edition NFTs from Bittycoin 
 */
contract Bittycoin is ERC1155Tradable {
    string contract_uri = "https://ipfs.infura.io/ipfs/QmfDTeggRmbFFWesHvqMDtAxJC1Fp2q1TFgM8faZ3kGfQS";
//https://ipfs.infura.io/ipfs/QmfDTeggRmbFFWesHvqMDtAxJC1Fp2q1TFgM8faZ3kGfQS
	constructor(address _usdt_address,address partner_Address) public ERC1155Tradable("Bittycoin NFT", "BT",_usdt_address, partner_Address) {
	}

	function contractURI() public view  returns (string memory) {
		//usdt_address = 0xc2132d05d31c914a87c6611c10748aeb04b58e8f		
		return contract_uri;
	}

}