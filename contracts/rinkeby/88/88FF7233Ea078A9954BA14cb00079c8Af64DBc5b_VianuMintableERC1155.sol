/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

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
    function isContract(address _account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution
        uint256 size;
        assembly {
            size := extcodesize(_account)
        }
        return size > 0;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: Sender is not the owner.");
        _;
    }

    /**
     * @notice Transfers the ownership of the contract to new address
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Ownable: Transferring ownership to the zero address.");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }

    /**
     * @notice Returns the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: Addition overflow.");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: Substraction overflow.");
        return a -b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a ==0 || b == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: Multiplication overflow.");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: Division by zero.");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: Modulo by zero.");
        return a % b;
    }
}

interface IERC165 {
    /** 
     * @notice Querfy if a contract implements an interface
     * @dev Interface identification is specified in ERC165.
     * @dev This function uses less than 30,000 gas
     * @param _interfaceId is the interface identified, as specified in ERC165
     */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceId The interface identifier, as specified in ERC-165
     * @return `true` if the contract implements `_interfaceId`
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[_interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `_interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
     function _registerInterface(bytes4 _interfaceId) internal virtual {
         require(_interfaceId != 0xffffffff, "ERC165: invalid interface id");
         _supportedInterfaces[_interfaceId] = true;
     }
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

interface IERC1155Metadata {

    event URI(string _uri, uint256 indexed _id);
    
    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     *      URIs are assumed to be deterministically generated based on tokenId
     *      TokenIds are assumed to be represented in their hex format in URIs
     * @return URI string
     */
    function uri(uint256 _id) external view returns (string memory);
}

/**
 * Recommended interface for public facing minting and burning functions.
 * These public methods should have restricted access.
 */
interface IERC1155MintBurn {
    /***************************************|
    |        External Minting Functions     |
    |______________________________________*/
    /**
     * @dev Mint _amount of tokens of a given id if not frozen and if max supply not exceeded
     * @param _to     The address to mint tokens to.
     * @param _id     Token id to mint
     * @param _amount The amount to be minted
     * @param _data   Byte array of data to pass to recipient if it's a contract
     */
    function mint(address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

    /**
     * @dev Mint tokens for each ids in _ids
     * @param _to      The address to mint tokens to.
     * @param _ids     Array of ids to mint
     * @param _amounts Array of amount of tokens to mint per id
     * @param _data    Byte array of data to pass to recipient if it's a contract
     */
    function mintBatch(address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

    /***************************************|
    |        External Burning Functions     |
    |______________________________________*/
    /**
     * @notice Burn _amount of tokens of a given token id
     * @param _from    The address to burn tokens from
     * @param _id      Token id to burn
     * @param _amount  The amount to be burned
     */
    function burn(address _from, uint256 _id, uint256 _amount) external;

    /**
     * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
     * @param _from     The address to burn tokens from
     * @param _ids      Array of token ids to burn
     * @param _amounts  Array of the amount to be burned
     */
    function burnBatch(address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
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
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns (bytes4);
    
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
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns (bytes4);
}

contract ERC1155 is IERC1155, ERC165 {

    using SafeMath for uint256;
    using Address for address;

    /***********************************|
    |             Variables             |
    |__________________________________*/

    // Mapping from account to its balances by tokenId
    mapping (address => mapping(uint256 => uint256)) internal _balances;
    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) internal _operators;
    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    // onReceive and onBatchReceive function signatures
    bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

    constructor () {
        _registerInterface(_INTERFACE_ID_ERC1155);
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
    function balanceOf(address _owner, uint256 _id) public override view returns (uint256) {
            return _balances[_owner][_id];
    }

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners The addresses of the token holders
     * @param _ids    ID of the Tokens
     * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] memory _owners, uint256[] memory _ids) public override view returns (uint256[] memory) {
        require(_owners.length == _ids.length, "ERC1155: Mismatch of _owners and _ids arrays for balanceOfBatch.");
        
        // Create a new variable to store the results for each owner-tokenId pair
        uint256[] memory batchBalances = new uint256[](_owners.length);

        // Iterate over each owner and tokenId
        for (uint256 i = 0; i < batchBalances.length; i++) {
            batchBalances[i] = _balances[_owners[i]][_ids[i]];
        }

        return batchBalances;
    }

    /***********************************|
    |         Operator Functions        |
    |__________________________________*/
    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external override {
        _operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Queries the approval status of an operator for a given owner
     * @param _owner     The owner of the Tokens
     * @param _operator  Address of authorized operator
     * @return isOperator True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool) {
        return _operators[_owner][_operator];
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
    function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) internal {
        // Update balances
        _balances[_from][_id] = _balances[_from][_id].sub(_amount);
        _balances[_to][_id] = _balances[_to][_id].add(_amount);

        // Emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    /**
     * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
     */
    function _callOnERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) internal {
        // Pass the data if the recipient is contract
        if (_to.isContract()) {
            bytes4 retVal = IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data);
            require(retVal == ERC1155_RECEIVED_VALUE, "ERC1155: Invalid onReceive message.");
        }
    }

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     */
    function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts) internal {
        require(_ids.length == _amounts.length, "ERC1155: Mismatch of _ids and _amounts arrays for _safeBatchTransferFrom.");

        // Number of transfers to execute
        uint256 nTransfers = _ids.length;

        // Executing all transfers
        for (uint256 i = 0; i < nTransfers; i++) {
            // Update balances
            _balances[_from][_ids[i]] = _balances[_from][_ids[i]].sub(_amounts[i]);
            _balances[_to][_ids[i]] = _balances[_to][_ids[i]].add(_amounts[i]);
        }

        // Emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    /**
     * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
     */
    function _callOnERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) internal {
        // Pass the data if the recipient is contract
        if (_to.isContract()) {
            bytes4 retVal = IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data);
            require(retVal == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155: Invalid onBatchReceive message.");
        }
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
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) public override {
        require(msg.sender == _from || isApprovedForAll(_from, msg.sender), "ERC1155 : msg.sender is not approved for safeTransferFrom.");
        require(_to != address(0), "ERC1155: Trying to trasnfer to the zero address for safeTransferFrom.");

        _safeTransferFrom(_from, _to, _id, _amount);
        _callOnERC1155Received(_from, _to, _id, _amount, _data);
    }

    /**
     * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
     * @param _from     Source addresses
     * @param _to       Target addresses
     * @param _ids      IDs of each token type
     * @param _amounts  Transfer amounts per token type
     * @param _data     Additional data with no specified format, sent in call to `_to`
     */
    function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) public override {
        require(msg.sender == _from || isApprovedForAll(_from, msg.sender), "ERC1155 : msg.sender is not approved for safeBatchTransferFrom.");
        require(_to != address(0), "ERC1155: Trying to trasnfer to the zero address for safeBatchTransferFrom.");

        _safeBatchTransferFrom(_from, _to, _ids, _amounts);
        _callOnERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
    }
}

/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata is IERC1155Metadata, ERC165 {

    /***********************************|
    |             Variables             |
    |__________________________________*/
    // URI's default URI prefix
    string internal baseMetadataURI;
    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 internal constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    constructor () {
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /***********************************|
    |     Metadata Public Function s    |
    |__________________________________*/
    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     *      URIs are assumed to be deterministically generated based on token ID
     * @return URI string
     */
    function uri(uint256 _id) public override view returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
    }

    /***********************************|
    |    Metadata Internal Functions    |
    |__________________________________*/
    /**
     * @notice Will emit default URI log event for corresponding token _id
     * @param _tokenIds Array of IDs of tokens to log default URI
     */
    function _logURIs(uint256[] memory _tokenIds) internal {
        string memory baseURI = baseMetadataURI;
        string memory tokenURI;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenURI = string(abi.encodePacked(baseURI, _uint2str(_tokenIds[i]), ".json"));
            emit URI(tokenURI, _tokenIds[i]);
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
        
        // Get the number of bytes
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;

        // Get each individual ASCII
        while (ii != 0) {
            bstr[k--] = bytes1(uint8(48 + ii % 10));
            ii /= 10;
        }

        return string(bstr);
    }
}

/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {

    using SafeMath for uint256;

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
    function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) internal {
        // Update balance
        _balances[_to][_id] = _balances[_to][_id].add(_amount);
        // Emit event
        emit TransferSingle(msg.sender, address(0), _to, _id, _amount);
        // Call onReceive method if the recipient is contract
        _callOnERC1155Received(address(0), _to, _id, _amount, _data);
    }

    /**
     * @notice Mint tokens for each ids in _ids
     * @param _to       The address to mint tokens to
     * @param _ids      Array of ids to mint
     * @param _amounts  Array of amount of tokens to mint per id
     * @param _data    Data to pass if receiver is contract
     */
    function _mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) internal {
        require(_ids.length == _amounts.length, "ERC1155MintBurn: Mismatched _ids and _amounts arrays for _mintBatch.");

        // Number of mints to execute
        uint256 nMints = _ids.length;

        // Executing all mints
        for (uint256 i = 0; i < nMints; i++) {
            _balances[_to][_ids[i]] = _balances[_to][_ids[i]].add(_amounts[i]);
        }

        // Emit event
        emit TransferBatch(msg.sender, address(0), _to, _ids, _amounts);
        // Call onBatchReceive method if the recipient is contract
        _callOnERC1155BatchReceived(address(0), _to, _ids, _amounts, _data);
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
    function _burn(address _from, uint256 _id, uint256 _amount) internal {
        // Update balance
        _balances[_from][_id] = _balances[_from][_id].sub(_amount);

        // Emit event
        emit TransferSingle(msg.sender, _from, address(0), _id, _amount);
    }

    /**
     * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
     * @param _from     The address to burn tokens from
     * @param _ids      Array of token ids to burn
     * @param _amounts  Array of the amount to be burned
     */
    function _burnBatch(address _from, uint256[] memory _ids, uint256[] memory _amounts) internal {
        require(_ids.length == _amounts.length, "ERC1155MintBurn: Mismatched _ids and _amounts arrays for _burnBatch.");

        // Number of burns to execute
        uint256 nBurns = _ids.length;

        // Executing all burns
        for(uint256 i = 0; i < nBurns; i++) {
            _balances[_from][_ids[i]] = _balances[_from][_ids[i]].sub(_amounts[i]);
        }

        //Emit event
        emit TransferBatch(msg.sender, _from, address(0), _ids, _amounts);
    }
}

contract VianuMintableERC1155 is ERC1155, ERC1155Metadata, ERC1155MintBurn, Ownable {
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    // Contract URI
    string private _uri;

    constructor (string memory _name, string memory _symbol, string memory uri_) {
        name = _name;
        symbol = _symbol;
        _uri = uri_;
    }

    function mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) external onlyOwner {
        _mint(_to, _id, _amount, _data);
    }

    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external {
        _mintBatch(_to, _ids, _amounts, _data);
    }

    function burn(address _from, uint256 _id, uint256 _amount) external {
        _burn(_from, _id, _amount);
    }

    function burnBatch(address _from, uint256[] memory _ids, uint256[] memory _amounts) external {
        _burnBatch(_from, _ids, _amounts);
    }
}