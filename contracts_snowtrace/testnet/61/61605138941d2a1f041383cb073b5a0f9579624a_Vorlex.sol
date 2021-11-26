/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;



/**

$$\    $$\   $$$$$$\   $$$$$$$\   $$\        $$$$$$$$\  $$\   $$\ 
$$ |   $$ | $$  __$$\  $$  __$$\  $$ |       $$  _____| $$ |  $$ |
$$ |   $$ | $$ /  $$ | $$ |  $$ | $$ |       $$ |       \$$\ $$  |
\$$\  $$  | $$ |  $$ | $$$$$$$  | $$ |       $$$$$\      \$$$$  / 
 \$$\$$  /  $$ |  $$ | $$  __$$<  $$ |       $$  __|     $$  $$<  
  \$$$  /   $$ |  $$ | $$ |  $$ | $$ |       $$ |       $$  /\$$\ 
   \$  /     $$$$$$  | $$ |  $$ | $$$$$$$$\  $$$$$$$$\  $$ /  $$ |
    \_/      \______/  \__|  \__| \________| \________| \__|  \__|

 */
                                                                 


// https://vorlex.co Contract For Vorlex NFT Marketplace 
// Vorlex Contract written by Kaptain Ti 
// Vorlex Platform Owned by Franklin Ndekwe and Kaptain Ti(nee C.C. Thompson)

/**
 * @title Counters
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
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
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

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

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

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);
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
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

    }



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

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


/**

$$\    $$\   $$$$$$\   $$$$$$$\   $$\        $$$$$$$$\  $$\   $$\ 
$$ |   $$ | $$  __$$\  $$  __$$\  $$ |       $$  _____| $$ |  $$ |
$$ |   $$ | $$ /  $$ | $$ |  $$ | $$ |       $$ |       \$$\ $$  |
\$$\  $$  | $$ |  $$ | $$$$$$$  | $$ |       $$$$$\      \$$$$  / 
 \$$\$$  /  $$ |  $$ | $$  __$$<  $$ |       $$  __|     $$  $$<  
  \$$$  /   $$ |  $$ | $$ |  $$ | $$ |       $$ |       $$  /\$$\ 
   \$  /     $$$$$$  | $$ |  $$ | $$$$$$$$\  $$$$$$$$\  $$ /  $$ |
    \_/      \______/  \__|  \__| \________| \________| \__|  \__|

 */
                                                                 


// https://vorlex.co Contract For Vorlex Crypto Marketplace 
// Vorlex Contract written by Kaptain Ti 
// Vorlex Platform Owned by Franklin Ndekwe and Kaptain Ti(nee C.C. Thompson)

contract Vorlex  is ERC1155, ERC1155Holder,  AccessControl  {
    
    bytes32 ADMIN_ROLE = bytes32("ADMIN_ROLE");
    bytes32 MINTER_ROLE = bytes32("MINTER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter private _vorlex_count;

    /**
        * @dev Throws if called by any account other than admin.
    */
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
        _;
    }

    enum sale_status { 
        OPEN_BUY, CANC_BUY,
        OPEN_ESCROW_BUY, CANC_ESCROW_BUY, CLOSED_ESCROW_BUY, 
        OPEN_BID, ACTIVE_BID, CANC_BID, CLOSED_BID 
    }

    struct Vorlexy {
        string ipfs;
        address custodian;
        uint256 amount;
        string vorlex_data;
    }

    struct Sale {
        sale_status status; 
        uint256 vorlex_id;
        uint256 amount;
        uint256 purchased_amount;
        uint256 settled_amount;
        uint256 worth; // Cost per Token for Buy and Total Cost for Bid
        uint256 bid_span; // Length of Bid Auction :: 1 hour for Buy Sales
        uint256 expiry; // For Bids
        address seller;
        address highest_bidder;
    }

    event InFunded(string indexed metadata);
    event OutFunded(uint256 indexed amount, address indexed receiver, 
            string indexed metadata);
    event Minted(uint256 indexed vorlex_id, string ipfs, 
            address indexed custodian, uint256 amount, string vorlex_data);
    event CustodianChanged(uint256 indexed vorlex_id, address indexed new_custodian);
    event SaleSetup(bytes32 indexed sale_id, uint256 indexed vorlex, uint256 indexed amount, 
            uint256 worth, uint256 bid_span, sale_status status);
    event Purchased(bytes32 indexed sale_id, uint256 indexed amount, 
                    address indexed buyer, bool on_chain, string metatdata);
    event Bidded(bytes32 indexed sale_id, uint256 indexed bid_amount);
    event SaleCancelled(bytes32 indexed sale_id, bool indexed by_seller);
    event SaleClosed(bytes32 indexed sale_id, uint256 indexed settle_amount);
    event Burnt(string metadata);
    event Swapped(string metadata);
    event BatchMoved(string metadata);

    uint256 public MIN_SALE = 15000000000000000;

	mapping(string => uint256) private _minted_vorlexes;
    mapping(uint256 => Vorlexy) public vorlexes;
    mapping(bytes32  => Sale) public sales;

    constructor() ERC1155("https://vorlex.co/uri/{id}.json") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, address(this));
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /**
        * @dev Add ETH to the contract
        * @dev Used to handle MINT FEES
        * @param metadata More Information on the Funds, Usually MINT FEES, DONATIONS or FUEL
    */
    function inFundContract(string memory metadata) external payable {
         emit InFunded(metadata);
    }

    /**
        * @dev Transfer ETH from contract :: Only by ADMIN
        * @param amount Amount of ETH to be transferred
        * @param receiver Recepient of ETH
        * @param metadata More Information on the Funds, Usually WITHDRAWAL or REFUNDS
    */

    function outFundContract(
        uint256 amount, address receiver, string memory metadata
    ) external payable onlyAdmin {
        emit OutFunded(amount, receiver, metadata);
        payable(receiver).transfer(amount); // Withdraw ETH from the Vorlex Contract
    }

    /**
        * @dev Set Minimum Price for Token for Sales 
    */

    function setMinSale(uint256 new_min_sale) 
    external virtual onlyAdmin {
        MIN_SALE = new_min_sale;
    }

    /**
        * @dev Mints a single Vorlex NFT :: Only by MINTER
        * @dev If Vorlex already exists, additional tokens are minted, no data is altered;
        * @param ipfs IPFS hash of Vorlex
        * @param custodian Vorlex Custodian :: Physical owner and custodian of vorlex who receives royalties for transaction
        * @param amount Amount of tokens to be minted for the Vorlex NFT
        * @param vorlex_data JSON Information of Vorlex
    */
	function mint(
        string memory ipfs, address custodian, 
        uint256 amount, string memory vorlex_data 
    ) external {
        require(hasRole(MINTER_ROLE, msg.sender), "NOT_MINTER");
        uint256 new_vorlex = _minted_vorlexes[ipfs];
         if(new_vorlex == 0){
            _vorlex_count.increment();
            new_vorlex = _vorlex_count.current();
            _minted_vorlexes[ipfs] = new_vorlex;
            vorlexes[new_vorlex] = Vorlexy(ipfs, custodian, amount, vorlex_data);
        }
        _mint(custodian, new_vorlex, amount, "");
        emit Minted(new_vorlex, ipfs, custodian, amount, vorlex_data);
    } 

    /**
        * @dev Set a New Custodian for a Vorlex if Former Custodian is defunct :: Only by ADMIN
        * @param vorlex_id Vorlex id
        * @param new_custodian Wallet Address of New Custodian
     */
    function setCustodian
    (uint256 vorlex_id, address new_custodian) 
    external onlyAdmin {
        require(vorlexes[vorlex_id].custodian != address(0), "VORLEX_DOESNT_EXIST");
        vorlexes[vorlex_id].custodian = new_custodian;
        emit CustodianChanged(vorlex_id, new_custodian);
    }

    /**
        * @dev Get Total Number of Minted Vorlexes
     */
    function totalSupply() external view returns (uint256) {
        return _vorlex_count.current();
    }

    /**
        * @dev Create a Sale or Auction :: Only by Owner of Vorlex
        * @dev Tokens are transferred to contract when called
        * @param sale_id keccak256 hash of {vorlex_id, sale_not_auc, amount, seller, timestamp}
        * @param buy_not_bid True for BuySale Setup, False for BidSale Setup
        * @param is_escrow Indicates if it is an Escrow sale or not. Escrow sales are finalized by admin. All Bidding Auctions are Escrowed
        * @param vorlex_id Vorlex id
        * @param amount Amount of tokens to setup for Sale or Auction
        * @param worth For Sale => cost per tokem :: For Auction => cost for all tokens
        * @param bid_span Length of Auction :: For Sale => 1hr and doesn't count :: For Auction => 1 hour min & 72 hour max after first bid
        
     */
    function createSale(
        bytes32 sale_id, bool buy_not_bid, bool is_escrow, 
        uint256 vorlex_id, uint256 amount, uint256 worth, uint256 bid_span
    ) external {
        require(sales[sale_id].vorlex_id == 0, "DUPLICATE_SALE" );
        require(bid_span >= 1 hours && bid_span <= 3 days, "INVALID_BID_SPAN"); // * Check if the Bid Span is Valid
        require((buy_not_bid ? worth : worth/amount) >= MIN_SALE, "LOW_COST_PER_TOKEN");
        sale_status new_status = buy_not_bid && !is_escrow ? sale_status.OPEN_BUY : 
                                 buy_not_bid && is_escrow ? sale_status.OPEN_ESCROW_BUY : 
                                 sale_status.OPEN_BID;
        sales[sale_id] = Sale(new_status, vorlex_id, amount, 0,0, worth, bid_span, 0, msg.sender, address(0));
        safeTransferFrom(msg.sender, address(this), vorlex_id, amount, "");
        emit SaleSetup(sale_id, vorlex_id, amount, worth, bid_span, new_status);
    } 

    /**
        * @dev Purchase tokens that are on sale :: Will not call if Auction
        * @dev Tpkens are tramsferred to buyer 
        * @dev Custodian => Paid 10% :: Seller => Paid 80%
        * @param sale_id Auction ID of Sale
        * @param amount Amount of tokens to buy
        * @param buyer Address of token buyer
        * @param on_chain False if token was purchased with cash or other crypto on vorlex.co
        * @param metadata Off-chain purchase information
     */
    function purchaseToken(
        bytes32 sale_id, uint256 amount,address buyer, 
        bool on_chain, string memory metadata
    ) external payable {
        require (sales[sale_id].status == sale_status.OPEN_BUY || 
                 sales[sale_id].status == sale_status.OPEN_ESCROW_BUY, 
                 "NOT_OPEN_BUY_SALE");
        require(sales[sale_id].amount >= amount, "LOW_TOKENS_AVAILABLE");
        if(on_chain){   
            require(msg.value/amount == sales[sale_id].worth, "INVALID_TOKEN_PRICE");
        }
        else {
            require(hasRole(ADMIN_ROLE, msg.sender), "NOT_ADMIN");
        }
        this.safeTransferFrom( address(this), buyer, sales[sale_id].vorlex_id, amount, "");
        sales[sale_id].purchased_amount += amount;
        sales[sale_id].amount -= amount;
        emit Purchased(sale_id, amount, buyer, on_chain, metadata);
        if(sales[sale_id].status == sale_status.OPEN_BUY){     // Transfer Payment and Token if not Escrow
            uint256 _payment = msg.value;
            payable(vorlexes[sales[sale_id].vorlex_id].custodian).transfer(_payment /10);   // Pay Royalty to Custodian
            payable(sales[sale_id].seller).transfer(_payment * 4/5);       // Pay Seller 80% of Purchase
        }
    }

    /**
        * @dev Place a bid on Auction :: Will not call if for sale or Auction expired
        * @dev First bid sets expiry to time_of_bid + bid_span
        * @dev Bid should be at least 1% increment to highest bid
        * @param sale_id Auction ID
     */
    function placeBid(bytes32 sale_id) external payable {
        require (sales[sale_id].status == sale_status.OPEN_BID || 
                 sales[sale_id].status == sale_status.ACTIVE_BID, 
                 "NOT_VALID_BID_SALE");
        require ((msg.value - sales[sale_id].worth) >= (sales[sale_id].worth /100), "LOW_BID_INCREMENT" );
        require(sales[sale_id].expiry > block.timestamp || sales[sale_id].expiry == 0, "EXPIRED" );
        sales[sale_id].highest_bidder = msg.sender;
        sales[sale_id].worth = msg.value;
        emit Bidded(sale_id, msg.value);
        if(sales[sale_id].expiry == 0) {
            sales[sale_id].expiry = block.timestamp + sales[sale_id].bid_span;
            sales[sale_id].status = sale_status.ACTIVE_BID;
        }
        else {
            payable(sales[sale_id].highest_bidder).transfer(sales[sale_id].worth);
        }
    }

    /**
        * @dev Cancel a Sale/Unbidded Auction 
        * @dev Tokens are transferred back to seller
        * @param sale_id Auction or Sale ID
     */
    function cancelSale(bytes32 sale_id) external {
        require(msg.sender == sales[sale_id].seller || 
                hasRole(ADMIN_ROLE, msg.sender), 
                "NOT_SELLER_OR_ADMIN");
        require(sales[sale_id].status == sale_status.OPEN_BUY || 
                sales[sale_id].status == sale_status.OPEN_ESCROW_BUY || 
                sales[sale_id].status == sale_status.OPEN_BID , 
                "NOT_OPEN_SALE");
        if(msg.sender == sales[sale_id].seller){
            this.safeTransferFrom( address(this),  msg.sender,  sales[sale_id].vorlex_id, sales[sale_id].amount, "");
        }
        sales[sale_id].status = sales[sale_id].status == sale_status.OPEN_BUY ? sale_status.CANC_BUY :
                                sales[sale_id].status == sale_status.OPEN_BID ? sale_status.CANC_BID :
                                sale_status.CANC_ESCROW_BUY ;
        emit SaleCancelled(sale_id, msg.sender == sales[sale_id].seller);
    }

    /**
        * @dev Finalize Escrow :: Only by ADMIN
        * @param sale_id Auction ID of ESCROW PURCHASE or 
        * @param settle_amount Amount to Settle for ESCROW
    */
    function closeSale(bytes32 sale_id, uint256 settle_amount) external payable onlyAdmin {
        require(sales[sale_id].status == sale_status.OPEN_ESCROW_BUY ||
                sales[sale_id].status == sale_status.CANC_ESCROW_BUY ||
                sales[sale_id].status == sale_status.ACTIVE_BID , 
                "INVALID_CLOSE");
                
        emit SaleClosed(sale_id, settle_amount);
        if(sales[sale_id].status == sale_status.ACTIVE_BID){
            require(sales[sale_id].expiry < block.timestamp , "BIDDING_IS_OPEN" );
            safeTransferFrom( 
                address(this),  sales[sale_id].highest_bidder,  
                sales[sale_id].vorlex_id, sales[sale_id].amount, "");
            sales[sale_id].status = sale_status.CLOSED_BID;
            payable(vorlexes[sales[sale_id].vorlex_id].custodian).transfer(sales[sale_id].worth/10); // Custodian Royalty
            payable(sales[sale_id].seller).transfer(sales[sale_id].worth * 4/5);// Owner's Payout
        } else {
            require(sales[sale_id].purchased_amount - sales[sale_id].settled_amount >= 
                settle_amount , "INVALID SETTLE_AMOUNT" );
            uint256 payout = sales[sale_id].worth * settle_amount;
            sales[sale_id].settled_amount += settle_amount;
            payable(vorlexes[sales[sale_id].vorlex_id].custodian).transfer(payout/10); // Custodian Royalty
            payable(sales[sale_id].seller).transfer(payout * 4/5);// Owner's Payout
        }
    }

    /**
        * @dev Batch Move for SWAP, TRANSFER & BURN OPERATIONS
        * @dev Transfer is impossible between Vorlexers and Vorlexers cannot burn their tokens.
        * @param is_swap If operation is a Swap Operation
        * @param metadata More information about the Transfer Ops
    */

    function batchMove(
        uint256[] memory vorlex_ids, uint256[] memory amounts, address from, address to, 
        bool is_swap, string memory metadata 
    ) external {
        safeBatchTransferFrom(from, to, vorlex_ids, amounts, "");
        if(to == address(0)){ // If operation is a burn operation
            for (uint256 i = 0; i < amounts.length; i++) {
                vorlexes[vorlex_ids[i]].amount -= amounts[i];
            }
            emit Burnt(metadata);
        }
        if(is_swap){
            emit Swapped(metadata);
        }
        emit BatchMoved(metadata);
    }

    /**
        * @dev Vorlexes can only be transferred to this Contract/Admin or From this Contract/Admin by NON-ADMIN
        * @dev ADMIN can initiate any transfers
     */
    function _beforeTokenTransfer(
        address operator,address from,address to,
        uint256[] memory ids,uint256[] memory amounts, bytes memory data
    )
        internal virtual override(ERC1155)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        require (hasRole(ADMIN_ROLE, from) || hasRole(ADMIN_ROLE, to) || hasRole(ADMIN_ROLE, operator), "INVALID_TOKEN_TRANSFER");

    }

    function supportsInterface(bytes4 interfaceId) 
    public view virtual override(AccessControl, ERC1155, ERC1155Receiver) 
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}