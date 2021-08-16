/**
 *Submitted for verification at polygonscan.com on 2021-08-16
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol



pragma solidity ^0.8.0;

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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol



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
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol



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
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: tetstst.sol

pragma solidity 0.8.6;


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        require (account != address(this));
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor ()  {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        require (account != address(this));
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}


/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC1155 {
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
    public override
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
        balances[_from][_id] = balances[_from][_id]-_amount; // Subtract amount
        balances[_to][_id] = balances[_to][_id]+_amount;     // Add amount

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
            bytes4 retval = IERC1155Receiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data);
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
            balances[_from][_ids[i]] = balances[_from][_ids[i]]-_amounts[i];
            balances[_to][_ids[i]] = balances[_to][_ids[i]]+_amounts[i];
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
            bytes4 retval = IERC1155Receiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data);
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
    public view virtual override returns (bool isOperator)
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
    public view override returns (uint256)
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
    public view override returns (uint256[] memory)
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

}

/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata {


    /***********************************|
    |    Utility Internal Functions     |
    |__________________________________*/

    /**
     * @notice Convert uint256 to string
     * @param _i Unsigned integer to convert to string
     */
function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

}






pragma experimental ABIEncoderV2;


contract PepemonStats is WhitelistAdminRole{
    
    struct BattleCardStats {
        uint16 element;
        uint16 hp;
        uint16 speed;
        uint16 intelligence;
        uint16 defense;
        uint16 attack;
        uint16 specialAttack;
        uint16 specialDefense;
        uint16 level;
        string name;
        string description;
        string ipfsAddr;
        string rarity;
    }

    struct SupportCardStats {
        bytes32 currentRoundChanges;
        bytes32 nextRoundChanges;
        uint256 specialCode;
        uint16 modifierNumberOfNextTurns;
        bool isOffense;
        bool isNormal;
        bool isStackable;
        string name;
        string description;
        string ipfsAddr;
        string rarity;
    }
    
    struct elementWR{
        uint16 weakness;
        uint16 resistance;
    }

    mapping(uint => BattleCardStats) public battleCardStats;
    mapping(uint => SupportCardStats) public supportCardStats;
    mapping (uint16 => string) public elementDecode;
    mapping (uint16 => elementWR) public weakResist;
    
    constructor(){
        elementDecode[1]="Fire";
        elementDecode[2]="Grass";
        elementDecode[3]="Water";
        elementDecode[4]="Lighting";
        elementDecode[5]="Wind";
        elementDecode[6]="Poison";
        elementDecode[7]="Ghost";
        elementDecode[8]="Fairy";
        elementDecode[9]="Earth";
        elementDecode[10]="Unknown";
        weakResist[1] = elementWR(3,2);
        weakResist[2] = elementWR(1,3);
        weakResist[3] = elementWR(4,1);
        weakResist[4] = elementWR(9,5);
        weakResist[5] = elementWR(6,9);
        weakResist[6] = elementWR(8,2);
        weakResist[7] = elementWR(8,6);
        weakResist[8] = elementWR(7,8);
        weakResist[9] = elementWR(2,7);
        weakResist[10] = elementWR(0,0);
    }
    
    function setBattleCardStats(uint id, BattleCardStats calldata x) public onlyWhitelistAdmin{
        battleCardStats[id] = x;
    }
    function setSupportCardStats(uint id, SupportCardStats calldata x) public onlyWhitelistAdmin{
        supportCardStats[id] = x;
    }
    function setWeakResist(uint16 element, elementWR calldata x) public onlyWhitelistAdmin{
        weakResist[element] = x;
    }
    function setElementDecode(uint16 element, string calldata x) public onlyWhitelistAdmin{
        elementDecode[element] = x;
    }
    
    //Pos 0-7 = hp, spd, int, def, atk, sp atk, sp def
    //Pos 8-13 = same but for opponent
    function deconvert(bytes32 num) public pure returns(int16[14] memory){
        int16[14] memory arr;
        for (uint i =0 ; i < 14; i++){
            arr[i] = int16(uint16(bytes2(num << 240))); 
            num = num >> 16;
        } 
        return arr;
    }
    function uint2str(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    function convert(int16[14] calldata arr) public pure returns (bytes32){
        bytes32 num;
        for (uint i = 0 ; i < 14; i++ ){
            num |= (bytes32(uint256(uint16(arr[i])))<<(16*i));
        }
        return num;
    }
    function getSupportType(SupportCardStats memory s) internal pure returns(string memory){
        string memory  x ="Defense ";
        string memory  y="(Special)";
        if (s.isOffense){
            x = "Offense ";
        }
        if (s.isNormal){
            y = "(Normal)";
        }
        return string(abi.encodePacked(x, y));
    }
    function _URIForSupport(uint id) internal view returns (string memory){
        SupportCardStats memory s = supportCardStats[id];
        return string(abi.encodePacked(
        "\"pool\": {\"name\": \"root\",\"points\": 1},\"external_url\": \"https://pepemon.world/\",\"image\": \"", 
        s.ipfsAddr, 
        "\",\"name\": \"",
        s.name, 
        "\",\"description\": \"",
        s.description,
        "\",\"attributes\": [{\"trait_type\": \"Set\",\"value\": \"Pepemon Support\"},{\"trait_type\": \"Rarity\",\"value\": \"",
        s.rarity, 
        "\"},{\"trait_type\": \"Type\",\"value\": \"", 
        getSupportType(s), 
        "\"}]}"));
    }


    function _URIForBattle(uint id) internal view returns (string memory){
        BattleCardStats memory b = battleCardStats[id];
        uint16 e = b.element;
        return string(abi.encodePacked("\"pool\": {\"name\": \"root\",\"points\": 1},\"external_url\": \"https://pepemon.world/\",\"image\": \"",
        b.ipfsAddr, 
        "\",\"name\": \"", 
        b.name, 
        "\",\"description\": \"", 
        b.description, 
        "\",\"attributes\":[{\"trait_type\":\"Set\",\"value\":\"Pepemon Battle\"},{\"trait_type\":\"Level\",\"value\":", 
        uint2str(b.level),
        "},{\"trait_type\":\"Element\",\"value\":\"", 
        elementDecode[e], 
         "\"},{\"trait_type\":\"Weakness\",\"value\":\""));
    }
    function _URIForBattle3(uint id) internal view returns (string memory){
        BattleCardStats memory b = battleCardStats[id];
        uint16 e = b.element;
        return string(abi.encodePacked(
            elementDecode[weakResist[e].weakness], 
            "\"},{\"trait_type\":\"Resistance\",\"value\":\"",
            elementDecode[weakResist[e].resistance], 
            "\"},{\"trait_type\":\"HP\",\"value\":", 
            uint2str(b.hp)));
    }
    function _URIForBattle2(uint id) internal view returns (string memory){
        BattleCardStats memory b = battleCardStats[id];
        return string(abi.encodePacked("},{\"trait_type\":\"Speed\",\"value\":"
        , uint2str(b.speed)
        , "},{\"trait_type\":\"Intelligence\",\"value\":"
        , uint2str(b.intelligence)
        , "},{\"trait_type\":\"Defense\",\"value\":"
        , uint2str(b.defense)));
    }
    function _URIForBattle4(uint id) internal view returns (string memory){
        BattleCardStats memory b = battleCardStats[id];
        return string(abi.encodePacked("},{\"trait_type\":\"Attack\",\"value\":",
        uint2str(b.attack),
        "},{\"trait_type\":\"Special Attack\",\"value\":", 
        uint2str(b.specialAttack), 
        "},{\"trait_type\":\"Special Defense\",\"value\":", 
        uint2str(b.specialDefense), 
        "}]}"));
    }
    
    function _getUri(uint id) internal view returns(string memory){
        if (battleCardStats[id].hp==0){
            return _URIForSupport(id);
        }else{
            return string(abi.encodePacked(_URIForBattle(id), _URIForBattle3(id), _URIForBattle2(id), _URIForBattle4(id)));
        }
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
        balances[_to][_id] = balances[_to][_id]+_amount;

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
            balances[_to][_ids[i]] = balances[_to][_ids[i]]+(_amounts[i]);
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
        balances[_from][_id] = balances[_from][_id]-(_amount);

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
            balances[_from][_ids[i]] = balances[_from][_ids[i]]-(_amounts[i]);
        }

        // Emit batch mint event
        emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
    }

}



/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address,
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Tradable is ERC1155, ERC1155MintBurn, ERC1155Metadata, Ownable, MinterRole, WhitelistAdminRole, PepemonStats {

    uint256 private _currentTokenID = 0;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    string public baseMetadataURI;
    
    constructor(
        string memory _name,
        string memory _symbol
    )  {
        name = _name;
        symbol = _symbol;
    }
    function _setBaseMetadataURI(string memory x) internal{
        baseMetadataURI = x;
    }
    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }
    
    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    function uri(uint256 _id) public view returns (string memory) {
        require(_exists(_id), "ERC1155Tradable#uri: NONEXISTENT_TOKEN");
        return _getUri(_id);
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Returns the max quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }


    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * @param _maxSupply max supply allowed
     * @param _initialSupply Optional amount to supply the first owner
     * @param _uri Optional URI for this token type
     * @param _data Optional data to pass if receiver is contract
     * @return tokenId The newly created token ID
     */
    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        string memory _uri,
        bytes memory _data
        
    ) internal  returns (uint256 tokenId) {
        require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }

        if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        return _id;
    }
    function createBattleCard(BattleCardStats calldata _stats,
        uint256 _maxSupply,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data) external onlyWhitelistAdmin returns(uint256 tokenId){
        uint _id = create(_maxSupply, _initialSupply, _uri, _data);
        setBattleCardStats(_id, _stats);
        return _id;
    }
    
    function createSupportCard(SupportCardStats calldata _stats,
        uint256 _maxSupply,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data) external onlyWhitelistAdmin returns(uint256 tokenId){
        uint _id = create(_maxSupply, _initialSupply, _uri, _data);
        setSupportCardStats(_id, _stats);
        return _id;
    }

    /**
     * @dev Mints some amount of tokens to an address
     * @param _to          Address of the future owner of the token
     * @param _id          Token ID to mint
     * @param _quantity    Amount of tokens to mint
     * @param _data        Data to pass if receiver is contract
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public onlyMinter {
        mintPepe(_to, _id, _quantity, _data);
    }
    function mintPepe(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) internal{
        uint256 tokenId = _id;
        uint256 newSupply = tokenSupply[tokenId]+_quantity;
        require(newSupply <= tokenMaxSupply[tokenId], "Max supply reached");
        _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id]+_quantity;
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
     * @dev calculates the next token ID based on value of _currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID+1;
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }
}




/**
 * @title Pepemon Factory
 * PEPEMON - gotta farm em all
 */
contract PepemonFactory is ERC1155Tradable {
    string private _contractURI;

    constructor()  ERC1155Tradable("PepemonBattleFactory", "PEPEBATTLE") {
        _setBaseMetadataURI("https://pepemon.finance/api/cards/");
        _contractURI = "https://pepemon.finance/api/pepemon-erc1155";
    }

    function setBaseMetadataURI(string memory newURI) public onlyWhitelistAdmin {
        _setBaseMetadataURI(newURI);
    }

    function setContractURI(string memory newURI) public onlyWhitelistAdmin {
        _contractURI = newURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
	 * @dev Ends minting of token
	 * @param _id          Token ID for which minting will end
	 */
    function endMinting(uint256 _id) external onlyWhitelistAdmin {
        tokenMaxSupply[_id] = tokenSupply[_id];
    }

    function burn(address _account, uint256 _id, uint256 _amount) public onlyMinter {
        require(balanceOf(_account, _id) >= _amount, "Cannot burn more than addres has");
        _burn(_account, _id, _amount);
    }

    /**
    * Mint NFT and send those to the list of given addresses
    */
    function airdrop(uint256 _id, address[] memory _addresses) public onlyMinter {
        require(tokenMaxSupply[_id] - tokenSupply[_id] >= _addresses.length, "Cant mint above max supply");
        for (uint256 i = 0; i < _addresses.length; i++) {
            mint(_addresses[i], _id, 1, "");
        }
    }
    function batchMint(uint start, uint end, address to) external onlyMinter{
        for (uint i = start; i <= end; i++){
            mintPepe(to, i, 1, hex'');
        }
    }
}