/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    // /**
    //  * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
    //  * `recipient`, forwarding all available gas and reverting on errors.
    //  *
    //  * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
    //  * of certain opcodes, possibly making contracts go over the 2300 gas limit
    //  * imposed by `transfer`, making them unable to receive funds via
    //  * `transfer`. {sendValue} removes this limitation.
    //  *
    //  * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
    //  *
    //  * IMPORTANT: because control is transferred to `recipient`, care must be
    //  * taken to not create reentrancy vulnerabilities. Consider using
    //  * {ReentrancyGuard} or the
    //  * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
    //  */
    // function sendValue(address payable recipient, uint256 amount) internal {
    //     require(address(this).balance >= amount, "Address: insufficient balance");

    //     // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    //     (bool success, ) = recipient.call{ value: amount }("");
    //     require(success, "Address: unable to send value, recipient may have reverted");
    // }

    // /**
    //  * @dev Performs a Solidity function call using a low level `call`. A
    //  * plain`call` is an unsafe replacement for a function call: use this
    //  * function instead.
    //  *
    //  * If `target` reverts with a revert reason, it is bubbled up by this
    //  * function (like regular Solidity function calls).
    //  *
    //  * Returns the raw returned data. To convert to the expected return value,
    //  * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
    //  *
    //  * Requirements:
    //  *
    //  * - `target` must be a contract.
    //  * - calling `target` with `data` must not revert.
    //  *
    //  * _Available since v3.1._
    //  */
    // function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    //   return functionCall(target, data, "Address: low-level call failed");
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
    //  * `errorMessage` as a fallback revert reason when `target` reverts.
    //  *
    //  * _Available since v3.1._
    //  */
    // function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    //     return functionCallWithValue(target, data, 0, errorMessage);
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
    //  * but also transferring `value` wei to `target`.
    //  *
    //  * Requirements:
    //  *
    //  * - the calling contract must have an ETH balance of at least `value`.
    //  * - the called Solidity function must be `payable`.
    //  *
    //  * _Available since v3.1._
    //  */
    // function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    //     return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
    //  * with `errorMessage` as a fallback revert reason when `target` reverts.
    //  *
    //  * _Available since v3.1._
    //  */
    // function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     require(isContract(target), "Address: call to non-contract");

    //     // solhint-disable-next-line avoid-low-level-calls
    //     (bool success, bytes memory returndata) = target.call{ value: value }(data);
    //     return _verifyCallResult(success, returndata, errorMessage);
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
    //  * but performing a static call.
    //  *
    //  * _Available since v3.3._
    //  */
    // function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    //     return functionStaticCall(target, data, "Address: low-level static call failed");
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
    //  * but performing a static call.
    //  *
    //  * _Available since v3.3._
    //  */
    // function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
    //     require(isContract(target), "Address: static call to non-contract");

    //     // solhint-disable-next-line avoid-low-level-calls
    //     (bool success, bytes memory returndata) = target.staticcall(data);
    //     return _verifyCallResult(success, returndata, errorMessage);
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
    //  * but performing a delegate call.
    //  *
    //  * _Available since v3.4._
    //  */
    // function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    //     return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    // }

    // /**
    //  * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
    //  * but performing a delegate call.
    //  *
    //  * _Available since v3.4._
    //  */
    // function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    //     require(isContract(target), "Address: delegate call to non-contract");

    //     // solhint-disable-next-line avoid-low-level-calls
    //     (bool success, bytes memory returndata) = target.delegatecall(data);
    //     return _verifyCallResult(success, returndata, errorMessage);
    // }

    // function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
    //     if (success) {
    //         return returndata;
    //     } else {
    //         // Look for revert reason and bubble it up if present
    //         if (returndata.length > 0) {
    //             // The easiest way to bubble the revert reason is using memory via assembly

    //             // solhint-disable-next-line no-inline-assembly
    //             assembly {
    //                 let returndata_size := mload(returndata)
    //                 revert(add(32, returndata), returndata_size)
    //             }
    //         } else {
    //             revert(errorMessage);
    //         }
    //     }
    // }
}

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

/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

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

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}


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

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}


/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    // function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
    //     require(to != address(0), "ERC1155: mint to the zero address");
    //     require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    //     address operator = _msgSender();

    //     _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    //     for (uint i = 0; i < ids.length; i++) {
    //         _balances[ids[i]][to] += amounts[i];
    //     }

    //     emit TransferBatch(operator, address(0), to, ids, amounts);

    //     _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    // }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        _balances[id][account] = accountBalance - amount;

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    // function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
    //     require(account != address(0), "ERC1155: burn from the zero address");
    //     require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    //     address operator = _msgSender();

    //     _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

    //     for (uint i = 0; i < ids.length; i++) {
    //         uint256 id = ids[i];
    //         uint256 amount = amounts[i];

    //         uint256 accountBalance = _balances[id][account];
    //         require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
    //         _balances[id][account] = accountBalance - amount;
    //     }

    //     emit TransferBatch(operator, account, address(0), ids, amounts);
    // }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}



// https://vorlex.co Contract For Vorlex Crypto Marketplace 
// Vorlex Contract written by Kaptain Ti (C.C. Thompson)
// Vorlex Platform Owned by Kaptain Ti(C.C. Thompson and Franklin Ndekwe)

contract Vorlex  is ERC1155, ERC1155Holder,  AccessControl  {

    bytes32 MINTER_ROLE = bytes32("MINTER_ROLE");
    bytes32 SWAPPER_ROLE = bytes32("SWAPPER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter private _vorlex_count;

    /**
        * @dev Throws if called by any account other than admin.
    */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ADM");
        _;
    }

      struct Vorlexy {
        bytes32 v_ipfs;
        address anc;
        bytes32 data;
    }

     struct Auction {
        uint256 sale_or_auc; // One-time Sale or Auction
        uint256 v_id;
        uint256 amount;
        uint256 worth; // Cost per Token for Sale and Total Cost for Bid
        uint256 bid_span; // Length of Bid Auction
        uint256 expiry;
        address seller;
        address highest_bidder;
    }

    struct Swap {
        address swapper;
        address swappee;
        uint256 creation_block;
    }

    event Funded();
    event Withdrawn(uint256 indexed amount);
    event Minted(uint256 indexed v_id, uint256 indexed amount );
    event AncestorChanged(uint256 indexed v_id, address indexed new_ancestor);
    event AuctionSetup(bytes32 indexed auc_id);
    event Sold(bytes32 indexed sale_id, uint256 indexed amount);
    event Bidded(bytes32 indexed auc_id );
    event AuctionCancelled(bytes32 indexed auc_id);
    event AuctionWon(bytes32 indexed auc_id, address indexed winner, uint256 indexed worth);
    event SwapStarted(bytes32 swap_id);
    event SwapResponded( bytes32 indexed swap_id);
    event SwapConfirmed( bytes32 indexed swap_id);

	mapping(bytes32 => uint256) _minted_vs;
    mapping(uint256 => Vorlexy) public vorlexes;
    mapping(bytes32  => Auction) public aucs;
    mapping(bytes32 => Swap) public swaps;
    
    constructor(
    ) ERC1155("https://vorlex.co/uri/{id}.json") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(SWAPPER_ROLE, msg.sender);
    }


    /**
        * @dev Add ETH to the contract
    */
    function fundContract() external payable {
         emit Funded();
    }

    /**
        * @dev Withdraw ETH from contract :: Only by ADMIN
    */
    function withdrawEthFromContract(uint256 amount) public payable onlyAdmin {
        payable(msg.sender).transfer(amount); // Withdraw ETH from the Vorlex Contract
        emit Withdrawn(amount);
    }

    /**
        * @dev Mints a single Vorlex NFT :: Only by MINTER
        * @dev If Vorlex already exists, additional tokens are minted, no data is altered;
        * @param v_ipfs IPFS hash converted to bytes32 using bs58 encoder
        * @param anc Vorlex ancestor :: First owner of vorlex who receives royalties for transaction
        * @param amount Amount of tokens to be minted for the Vorlex NFT
        * @param data String to bytes32 using web3 asciiToHex :: Contains Vorlex Type + & + Vorlex Expiry when decoded
    */
	function mint( bytes32 v_ipfs, address anc, uint256 amount, bytes32 data) public virtual {
        require(hasRole(MINTER_ROLE, msg.sender), "MINR");
        uint256 new_vorlex = _minted_vs[v_ipfs];
         if(new_vorlex == 0){
            _vorlex_count.increment();
            new_vorlex = _vorlex_count.current();
            _minted_vs[v_ipfs] = new_vorlex;
            vorlexes[new_vorlex] = Vorlexy(v_ipfs, anc, data);
        }
        _mint(anc, new_vorlex, amount, "");
        emit Minted( new_vorlex, amount);
    } 

    /**
        * @dev Set a New Ancestor for a Vorlex if Former Ancestor is defunct :: Only by ADMIN
        * @param v_id Vorlex id
        * @param new_anc Wallet Address of New Ancestor
     */
    function setAnc( uint256 v_id, address new_anc) public virtual onlyAdmin {
        require(vorlexes[v_id].anc != address(0), "NILTOK");
        vorlexes[v_id].anc = new_anc;
        AncestorChanged(v_id, new_anc);
    }

    /**
        * @dev Get Total Number of Minted Vorlexes
     */
    function totalSupply() public view returns (uint256) {
        return _vorlex_count.current();
    }

    /**
        * @dev Burn Tokens from a Vorlex NFT :: Only by ADMIN
        * @param owner Owner of the Vorlex to Burn
        * @param v_id Vorlex id 
        * @param amount Amount of tokens to burn
    */
    function burn(address owner, uint256 v_id, uint256 amount) public virtual onlyAdmin {
        _burn(owner, v_id, amount);
    }

    /**
        * @dev Create a Sale or Auction :: Only by Owner of Vorlex
        * @dev Tokens are transferred to contract when called
        * @param auc_id keccak256 hash of {vorlex_id, sale_not_auc, amount, seller, timestamp}
        * @param sale_or_auc True for Sale Setup, False for Auction Setup
        * @param v_id Vorlex id
        * @param amount Amount of tokens to setup for Sale or Auction
        * @param worth For Sale => cost per tokem :: For Auction => cost for all tokens
        * @param bid_span Length of Auction :: For Sale => 0 :: For Auction => 1 hour min & 72 hour max after first bid
        
     */
    function createAuction(bytes32 auc_id, bool sale_or_auc, uint256 v_id, uint256 amount, uint256 worth, uint256 bid_span) public virtual {
        require(aucs[auc_id].v_id == 0, "DUPL" );
        require(bid_span >= 1 hours && bid_span <= 3 days && worth > 0);
        aucs[auc_id] = Auction(sale_or_auc ? 1 : 2, v_id, amount, worth, bid_span,0,  msg.sender, address(0));
        safeTransferFrom( msg.sender,  address(this),  v_id, amount, "");
        emit AuctionSetup(auc_id);
    } 

    /**
        * @dev Purchase tokens that are on sale :: Will not call if Auction
        * @dev Tpkens are tramsferred to buyer 
        * @dev Ancestor => Paid 10% :: Seller => Paid 80%
        * @param auc_id Auction ID of Sale
        * @param amount Amount of tokens to buy
     */
    function purchaseToken( bytes32 auc_id, uint256 amount) public payable {
        require (aucs[auc_id].sale_or_auc == 1, "FORBID");
        require(aucs[auc_id].amount >= amount, "LOWTOK");
        require(msg.value/amount == aucs[auc_id].worth, "LOWBAL");
        aucs[auc_id].amount -= amount;
        uint256 _payment = msg.value;
        payable(vorlexes[aucs[auc_id].v_id].anc).transfer(_payment /10); // anc Royalty
        payable(aucs[auc_id].seller).transfer(_payment * 4/5); // Owner's Payout
        this.safeTransferFrom( address(this), msg.sender, aucs[auc_id].v_id, amount, "");
        emit Sold(auc_id, amount );
    }

    /**
        * @dev Place a bid on Auction :: Will not call if for sale or Auction expired
        * @dev First bid sets expiry to time_of_bid + bid_span
        * @dev Bid should be at least 1% increment to highest bid
        * @param auc_id Auction ID
     */
    function placeBid(bytes32 auc_id) public payable {
        require (aucs[auc_id].sale_or_auc == 2, "FORSALE");
        require ((msg.value - aucs[auc_id].worth) >= (aucs[auc_id].worth /100), "LOWBAL" );
        require(aucs[auc_id].expiry > block.timestamp || aucs[auc_id].expiry == 0, "EXPIRED" );
        if(aucs[auc_id].highest_bidder != address(0)) {
        payable(aucs[auc_id].highest_bidder).transfer(aucs[auc_id].worth);
        }
        else {
        aucs[auc_id].expiry = block.timestamp + aucs[auc_id].bid_span;
        }
        aucs[auc_id].highest_bidder = msg.sender;
        aucs[auc_id].worth = msg.value;
        emit Bidded(auc_id);
    }

    /**
        * @dev IF => Cancel a Sale/Unbidded Auction :: ELSE => Close a winning Auction after expiry
        * @dev IF => Tokens are transferred back to seller :: ELSE => Tokens are transferred to HIGHEST BIDDER
        * @dev ELSE => Ancestor gets 10% of the highest bid as royalty :: Seller gets 80% of the highest bid
        * @param auc_id Auction or Sale ID
     */
    function finalizeAuction(bytes32 auc_id ) public payable {
        require(msg.sender == aucs[auc_id].seller, "NOWN");
        if(aucs[auc_id].highest_bidder == address(0)) {
            this.safeTransferFrom( address(this),  msg.sender,  aucs[auc_id].v_id, aucs[auc_id].amount, "");
            emit AuctionCancelled(auc_id);
        }
        else {
            require(aucs[auc_id].expiry < block.timestamp , "NOEXP" );
            this.safeTransferFrom( address(this),  aucs[auc_id].highest_bidder,  aucs[auc_id].v_id, aucs[auc_id].amount, "");
            payable(vorlexes[aucs[auc_id].v_id].anc).transfer(aucs[auc_id].worth/10); // anc Royalty
            payable(aucs[auc_id].seller).transfer(aucs[auc_id].worth * 4/5);// Owner's Payout
            emit AuctionWon(auc_id, aucs[auc_id].highest_bidder, aucs[auc_id].worth);
        }
        delete aucs[auc_id];
    }

    /**
        * DO NOT CALL OUTSIDE THE VORLEX PLATFORM {{ vorlex.co }}
        * @dev Creates a Swap Table :: Swap can only be between two Vorlexers
        * @dev Swapper's Vorlexes are transferred to the Contract on Call
        * @dev Swapper pays calculated Swap fees from Vorlex.co platform 
        * @dev Swapper may lose tokens if called outside the Vorlex platform or swap fees are altered
        * @param swap_id keccak256 hash of {swapper, swappee, timestamp}
        * @param v_ids Array of Swapper's Vorlex IDs
        * @param amounts Array of Amounts of Corresponding Swapper's Vorlex IDs
        * @param swappee Address of Swappee (The other Vorlexer on the Swap Table)
     */
    function swapInit(bytes32 swap_id, uint256[] memory v_ids, uint256[] memory amounts, address swappee) public virtual payable {
        require(swaps[swap_id].creation_block == 0, "DUPL");
        safeBatchTransferFrom(msg.sender, address(this), v_ids, amounts, "");
        swaps[swap_id]= Swap(msg.sender, swappee, block.number);
        emit SwapStarted(swap_id);
    }

    /**
        * DO NOT CALL OUTSIDE THE VORLEX PLATFORM {{ vorlex.co }}
        * @dev Swappee responds to the Swap Table :: Caller must be Swappee
        * @dev Swappee's Vorlexes are transferred to the Contract on Call
        * @dev Swappee pays calculated Swap fees from Vorlex.co platform 
        * @dev Swappee may lose tokens if called outside the Vorlex platform or swap fees are altered
        * @param swap_id Swap ID
        * @param v_ids Array of Swappee's Vorlex IDs
        * @param amounts Array of Amounts of Corresponding Swappee's Vorlex IDs
     */
    function swapRespond(bytes32 swap_id, uint256[] memory v_ids, uint256[] memory amounts) public virtual payable {
        require(msg.sender == swaps[swap_id].swappee, "NOMATCH");
        safeBatchTransferFrom(msg.sender, address(this), v_ids, amounts, "");
        emit SwapResponded(swap_id);
    }

    /**
        * @dev Swap Confirm :: Only by Admin :: After Swap has been Verified on Vorlex Platform
        * @dev Swapper's tokens are transferred to Swappee && Swappee's tokens are transferred to Swapper
        * @dev Swap Table is deleted after confirmation
     */
    function swapConfirm(bytes32 swap_id, uint256[] memory swapper_vids, uint256[] memory swapper_amounts, uint256[] memory swappee_vids, uint256[] memory swappee_amounts) public virtual {
        require(hasRole(SWAPPER_ROLE, msg.sender), "SWAPR");
        this.safeBatchTransferFrom( address(this), swaps[swap_id].swapper, swappee_vids, swappee_amounts, "");
        this.safeBatchTransferFrom( address(this), swaps[swap_id].swappee, swapper_vids, swapper_amounts, "");
        emit SwapConfirmed(swap_id);
        delete swaps[swap_id];
    }

    /**
        * @dev Vorlexes can only be transferred to this Contract or From this Contract :: Vorlexes cannot be transferred between two Vorlexers
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual override(ERC1155)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        require (from == address(this) || to == address(this) || from == address(0) || to == address(0) , "INVALID TRX");

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}