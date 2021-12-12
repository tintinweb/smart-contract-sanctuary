/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

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
  function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

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
  event TransferSingle(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256 _id,
    uint256 _amount
  );

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(
    address indexed _operator,
    address indexed _from,
    address indexed _to,
    uint256[] _ids,
    uint256[] _amounts
  );

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

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
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external;

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
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
    external
    view
    returns (uint256[] memory);

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
  function isApprovedForAll(address _owner, address _operator)
    external
    view
    returns (bool isOperator);
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
  function onERC1155Received(
    address _operator,
    address _from,
    uint256 _id,
    uint256 _amount,
    bytes calldata _data
  ) external returns (bytes4);

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
  function onERC1155BatchReceived(
    address _operator,
    address _from,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) external returns (bytes4);
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
  address private _owner;

  string private constant ERR = "Ownable";

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _transferOwnership(msg.sender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == msg.sender, ERR);
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), ERR);
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata {
  // URI's default URI prefix
  string private baseMetadataURI;

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
  function uri(uint256 _id) public view returns (string memory) {
    bytes memory bytesURI = bytes(baseMetadataURI);
    if (bytesURI.length == 0 || bytesURI[bytesURI.length - 1] == '/')
      return string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
    else return baseMetadataURI;
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

    // Get each individual ASCII
    while (ii != 0) {
      bstr[--len] = bytes1(uint8(48 + ii % 10));
      ii /= 10;
    }

    // Convert to string
    return string(bstr);
  }
}

abstract contract ReentrancyGuard {
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being non-zero value makes deployment a bit more expensive,
  // but in exchange the refund on every call to nonReentrant will be lower in
  // amount. Since refunds are capped to a percentage of the total
  // transaction's gas, it is best to keep them low in cases like this one, to
  // increase the likelihood of the full refund coming into effect.
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  string private constant ERR = "Reentrancy";

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, ERR);

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

// OpenSea Registry Proxy
contract ProxyRegistry {
  mapping(address => address) public proxies;
}

/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155Base is IERC1155, IERC165, ERC1155Metadata, Ownable, ReentrancyGuard {
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  address constant internal NULL_ADDR = address(0);

  string private constant ERR = "ERC1155Base";

  // Contract name
  string public name;

  // Contract symbol
  string public symbol;

  // ProxyRegistry
  address private immutable _proxyRegistry;

  // initializer
  address private immutable _initializer;

  // Objects balances
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping (address => mapping(address => bool)) internal operators;

    // Max mints per transaction
  uint256 private _maxTxMint;

  // The CAP of mintable tokenIds
  uint256 private _cap;

  // ETH price of one tokenIds
  uint256 private _tokenPrice;

  // TokenId counter, 1 minted in ctor
  uint256 private _currentTokenId;

  // MintAllowed
  uint256 mintAllowed;

  // Fired when funds are distributed
  event Distributed(address indexed receiver, uint256 amount);

  /***********************************|
  |             Initialization        |
  |__________________________________*/

  constructor(address initializer_, address proxyRegistry) {
    _proxyRegistry = proxyRegistry;
    _initializer = initializer_;
  }

  function initialize(
    address owner_,
    string memory name_,
    string memory symbol_
   ) external
  {
    require(msg.sender == _initializer, ERR);

    _transferOwnership(owner_);
    name = name_;
    symbol = symbol_;

    // Mint our first token
    balances[owner_][0] = 1;
    emit TransferSingle(msg.sender, NULL_ADDR, owner(), 0, 1);
  }

  /**
   * @dev Clone Initialization.
   */
  function initialize(
    address owner_,
    string memory name_,
    string memory symbol_,
    uint256 cap_,
    uint256 maxPerTx_,
    uint256 price_) external
  {
    require(msg.sender == _initializer, ERR);

    _transferOwnership(owner_);

    name = name_;
    symbol = symbol_;
    _cap = cap_;
    _maxTxMint = maxPerTx_;
    _tokenPrice = price_;
    // Mint our first token
    balances[owner_][0] = 1;
    _currentTokenId = 1;
    mintAllowed = 1;
    emit TransferSingle(msg.sender, NULL_ADDR, owner_, 0, 1);
  }

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
    external override
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), ERR);
    require(_to != address(0), ERR);
 
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
    external override
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), ERR);
    require(_to != address(0), ERR);

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
  }

  function unsafeBatchMint(address[] calldata _tos, uint256[] calldata _counts, uint256[] calldata _ids) external onlyOwner {
    uint256 idOffset = 0;
    for (uint256 i = 0; i < _tos.length; ++i) {
      uint256 idOffsetEnd = idOffset + _counts[i];
      require (idOffsetEnd <= _ids.length, ERR);
      {
        uint256 curE = _ids[idOffset] >> 8;
        uint256 mask = 0;
        for (; idOffset < idOffsetEnd; ++idOffset) {
          // Update storage balance of previous bin
          uint256 elem = _ids[idOffset] >> 8;
          uint256 id = uint256(1) << (_ids[idOffset] & 0xFF);
          if (elem != curE) {
            balances[_tos[i]][curE] |= mask;
            curE = elem;
            mask = 0;
          }
          mask |= id;
        }
        balances[_tos[i]][curE] |= mask;
        emit TransferSingle(msg.sender, NULL_ADDR, _tos[i], _ids[idOffset], 1);
      }

      uint256[] memory amounts = new uint256[](_counts[i]);
      for (uint pos = 0; pos < _counts[i]; ++pos)
        amounts[pos] = 1;
      _callonERC1155BatchReceived(address(0), _tos[i], _ids[idOffsetEnd - _counts[i]:idOffsetEnd], amounts, '');
    }
  }

  function unsafeBatchMessage(address[] calldata _tos, uint256[] calldata _counts, uint256[] calldata _ids) external onlyOwner {
    uint256 idOffset = 0;
    for (uint256 i = 0; i < _tos.length; ++i) {
      uint256 idOffsetEnd = idOffset + _counts[i];
      require (idOffsetEnd <= _ids.length, ERR);
      for (; idOffset < idOffsetEnd; ++idOffset) {
        emit TransferSingle(msg.sender, NULL_ADDR, _tos[i], _ids[idOffset], 1);
      }
    }
  }

  /**
   * @dev mint
   */
  function mint(address to, uint256 numMint) external payable nonReentrant {
    uint256 tid = _currentTokenId;
    uint256 tidEnd = _currentTokenId + numMint;

    require(mintAllowed != 0 &&
      numMint > 0 &&
      numMint <= _maxTxMint &&
      tidEnd <= _cap &&
      msg.value >= numMint * _tokenPrice, ERR
    );
    
    {
      uint256 mask = 0;
      uint256 curE = tid >> 8;
      for (; tid < tidEnd; ++tid) {
        // Update storage balance of previous bin
        uint256 elem = tid >> 8;
        uint256 id = uint256(1) << (tid & 0xFF);
        if (elem != curE) {
          balances[to][curE] |= mask;
          curE = elem;
          mask = 0;
        }
        mask |= id;
        emit TransferSingle(msg.sender, NULL_ADDR, to, tid, 1);
      }
      balances[to][curE] |= mask;
      _currentTokenId += numMint;
    }

    {
      uint256 dust = msg.value - (numMint * _tokenPrice);
      if (dust > 0) payable(msg.sender).transfer(dust);
    }

    { 
      uint256[] memory ids = new uint256[](numMint);
      uint256[] memory amounts = new uint256[](numMint);
      for (uint256 i = 0; i < numMint; ++i) {
        ids[i] = tid - numMint--;
        amounts[i] = 1;
      }
      _callonERC1155BatchReceived(address(0), to, ids, amounts, '');
    }
  }

  /**
   * @dev Distribute rewards
   */
  function distribute(
    address[] calldata accounts,
    uint256[] calldata refunds,
    uint256[] calldata percents
  ) external onlyOwner {
    require(
      (refunds.length == 0 || refunds.length == accounts.length) &&
        (percents.length == 0 || percents.length == accounts.length),
      ERR
    );

    uint256 availableAmount = address(this).balance;
    uint256[] memory amounts = new uint256[](accounts.length);

    for (uint256 i = 0; i < refunds.length; ++i) {
      require(refunds[i] <= availableAmount, ERR);
      amounts[i] = refunds[i];
      availableAmount -= refunds[i];
    }

    uint256 amountToShare = availableAmount;
    for (uint256 i = 0; i < percents.length; ++i) {
      uint256 amount = (amountToShare * percents[i]) / 100;
      amounts[i] += (amount <= availableAmount) ? amount : availableAmount;
      availableAmount -= amount;
    }

    for (uint256 i = 0; i < accounts.length; ++i) {
      if (amounts[i] > 0) {
        payable(accounts[i]).transfer(amounts[i]);
        emit Distributed(accounts[i], amounts[i]);
      }
    }
  }

  function setBaseMetadataURI(string memory _newBaseMetadataURI) external onlyOwner {
    _setBaseMetadataURI(_newBaseMetadataURI);
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
    require(_amount == 1, ERR);

    // Update balances
    _transferOwner(_from, _to, _id);

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
      require(retval == ERC1155_RECEIVED_VALUE, ERR);
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
    uint256 len = _ids.length;

    require(len == _amounts.length, ERR);

    // Executing all transfers
    for (uint256 i = 0; i < len; ++i) {
      require(_amounts[i] == 1, ERR);
      // Update storage balance of previous bin
      _transferOwner(_from, _to, _ids[i]);
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
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, ERR);
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
   * @return isOperator if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public view override returns (bool isOperator)
  {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistry);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

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
    public view override returns (uint256)
  {
    return _isOwner(_owner, _id) ? 1 : 0;
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public view override returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, ERR);

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = _isOwner(_owners[i], _ids[i]) ? 1 : 0;
    }

    return batchBalances;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * INTERFACE_SIGNATURE_ERC165 = bytes4(keccak256("supportsInterface(bytes4)"));
   */
  bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

  /**
   * INTERFACE_SIGNATURE_ERC1155 =
   * bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
   * bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
   * bytes4(keccak256("balanceOf(address,uint256)")) ^
   * bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
   * bytes4(keccak256("setApprovalForAll(address,bool)")) ^
   * bytes4(keccak256("isApprovedForAll(address,address)"));
   */
  bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) external pure override returns (bool) {
    if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
        _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
      return true;
    }
    return false;
  }

  /***********************************|
  |         balance Functions         |
  |__________________________________*/

  function _isOwner(address _from, uint256 _id) internal view returns (bool) {
    return (balances[_from][_id >> 8] & (uint256(1) << (_id & 0xFF))) != 0;
  }

  function _transferOwner(address _from, address _to, uint256 _id) internal {
    uint256 elem = _id >> 8;
    uint256 id = uint256(1) << (_id & 0xFF);

    if (_from != NULL_ADDR) {
      require((balances[_from][elem] & id) != 0, ERR);
      balances[_from][elem] &=~id;
    }
    
    if (_to != NULL_ADDR) {
      balances[_to][elem] |= id;
    }
  }
}