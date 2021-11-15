// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
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
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

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
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
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
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
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
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
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
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
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
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";


contract RaffleAdminAccessControl is AccessControlEnumerable {
  bytes32 public constant RAFFLE_MANAGER_ROLE = keccak256("RAFFLE_MANAGER_ROLE");
  bytes32 public constant PRIZE_MANAGER_ROLE = keccak256("PRIZE_MANAGER_ROLE");

  address public managerOf;

  event RaffleManagerAdded(address indexed account, address managerOf);
  event RaffleManagerRemoved(address indexed account, address managerOf);
  event PrizeManagerAdded(address indexed account, address managerOf);
  event PrizeManagerRemoved(address indexed account, address managerOf);

  /**
  * @dev Constructor Add the given account both as the main Admin of the smart contract and a checkpoint admin
  * @param raffleOwner The account that will be added as raffleOwner
  */
  constructor (address raffleOwner, address _managerOf) {
    require(
      raffleOwner != address(0),
      "Raffle owner should be a valid address"
    );

    managerOf = _managerOf;

    _setupRole(DEFAULT_ADMIN_ROLE, raffleOwner);
    _setupRole(PRIZE_MANAGER_ROLE, raffleOwner);
    _setupRole(RAFFLE_MANAGER_ROLE, raffleOwner);
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "RaffleAdminAccessControl: Only admin role");
    _;
  }

  modifier onlyManager() {
    require(hasRole(RAFFLE_MANAGER_ROLE, msg.sender), "RaffleAdminAccessControl: Only manager role");
    _;
  }

   modifier onlyPrizeManager() {
    require(hasRole(PRIZE_MANAGER_ROLE, msg.sender), "RaffleAdminAccessControl: Only prize manager role");
    _;
  }

  /**
  * @dev Adds a new account to the manager role
  * @param account The account that will have the manager role
  */
  function addRaffleManager(address account) public onlyAdmin {
    grantRole(RAFFLE_MANAGER_ROLE, account);

    emit RaffleManagerAdded(account, managerOf);
  }

  /**
  * @dev Removes the sender from the list the manager role
  */
  function renounceRaffleManager() public {
    renounceRole(RAFFLE_MANAGER_ROLE, msg.sender);

    emit RaffleManagerRemoved(msg.sender, managerOf);
  }

  /**
  * @dev checks if the given account is a prizeManager
  * @param account The account that will be checked
  */
  function isRaffleManager(address account) public view returns (bool) {
    return hasRole(RAFFLE_MANAGER_ROLE, account);
  }

  /**
  * @dev Removes the given account from the manager role, if msg.sender is manager
  * @param manager The account that will have the manager role removed
  */
  function removeRaffleManager(address manager) public onlyAdmin {
    revokeRole(RAFFLE_MANAGER_ROLE, manager);

    emit RaffleManagerRemoved(manager, managerOf);
  }

  /**
    * @dev checks if the given account is a prizeManager
    * @param account The account that will be checked
    */
   function isPrizeManager(address account) public view returns (bool) {
     return hasRole(PRIZE_MANAGER_ROLE, account);
   }

   /**
    * @dev Adds a new account to the prizeManager role
    * @param account The account that will have the prizeManager role
    */
   function addPrizeManager(address account) public onlyAdmin virtual {
     grantRole(PRIZE_MANAGER_ROLE, account);

     emit PrizeManagerAdded(account, managerOf);
   }

   /**
    * @dev Removes the sender from the list the prizeManager role
    */
   function renouncePrizeManager() public {
     renounceRole(PRIZE_MANAGER_ROLE, msg.sender);

     emit PrizeManagerRemoved(msg.sender, managerOf);
   }

   /**
    * @dev Removes the given account from the prizeManager role, if msg.sender is admin
    * @param prizeManager The account that will have the prizeManager role removed
    */
   function removePrizeManager(address prizeManager) onlyAdmin public {
     revokeRole(PRIZE_MANAGER_ROLE, prizeManager);

     emit PrizeManagerRemoved(prizeManager, managerOf);
   }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILinkToken.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

	event RandomnessRequested(bytes32 requestId);

	/**
	 * @notice fulfillRandomness handles the VRF response. Your contract must
	 * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
	 * @notice principles to keep in mind when implementing your fulfillRandomness
	 * @notice method.
	 *
	 * @dev VRFConsumerBase expects its subcontracts to have a method with this
	 * @dev signature, and will call it once it has verified the proof
	 * @dev associated with the randomness. (It is triggered via a call to
	 * @dev rawFulfillRandomness, below.)
	 *
	 * @param requestId The Id initially returned by requestRandomness
	 * @param randomness the VRF output
	 */
	function fulfillRandomness(bytes32 requestId, uint256 randomness)
		internal virtual;

	/**
	 * @notice requestRandomness initiates a request for VRF output given _seed
	 *
	 * @dev The fulfillRandomness method receives the output, once it's provided
	 * @dev by the Oracle, and verified by the vrfCoordinator.
	 *
	 * @dev The _keyHash must already be registered with the VRFCoordinator, and
	 * @dev the _fee must exceed the fee specified during registration of the
	 * @dev _keyHash.
	 *
	 * @dev The _seed parameter is vestigial, and is kept only for API
	 * @dev compatibility with older versions. It can't *hurt* to mix in some of
	 * @dev your own randomness, here, but it's not necessary because the VRF
	 * @dev oracle will mix the hash of the block containing your request into the
	 * @dev VRF seed it ultimately uses.
	 *
	 * @param _keyHash ID of public key against which randomness is generated
	 * @param _fee The amount of LINK to send with the request
	 * @param _seed seed mixed into the input of the VRF.
	 *
	 * @return requestId unique ID for this request
	 *
	 * @dev The returned requestId can be used to distinguish responses to
	 * @dev concurrent requests. It is passed as the first argument to
	 * @dev fulfillRandomness.
	 */
	function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
		internal returns (bytes32 requestId)
	{
		LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
		// This is the seed passed to VRFCoordinator. The oracle will mix this with
		// the hash of the block containing this request to obtain the seed/input
		// which is finally passed to the VRF cryptographic machinery.
		uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
		// nonces[_keyHash] must stay in sync with
		// VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
		// successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
		// This provides protection against the user repeating their input seed,
		// which would result in a predictable/duplicate output, if multiple such
		// requests appeared in the same block.
		nonces[_keyHash] = nonces[_keyHash] + 1;
		bytes32 requestId = makeRequestId(_keyHash, vRFSeed);

		emit RandomnessRequested(requestId);

		return requestId;
	}

	ILinkToken immutable internal LINK;
	address immutable private vrfCoordinator;

	// Nonces for each VRF key from which randomness has been requested.
	//
	// Must stay in sync with VRFCoordinator[_keyHash][this]
	mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

	/**
	 * @param _vrfCoordinator address of VRFCoordinator contract
	 * @param _link address of LINK token contract
	 *
	 * @dev https://docs.chain.link/docs/link-token-contracts
	 */
	constructor(address _vrfCoordinator, address _link) {
		vrfCoordinator = _vrfCoordinator;
		LINK = ILinkToken(_link);
	}

	// rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
	// proof. rawFulfillRandomness then calls fulfillRandomness, after validating
	// the origin of the call
	function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
		require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
		fulfillRandomness(requestId, randomness);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

	/**
	 * @notice returns the seed which is actually input to the VRF coordinator
	 *
	 * @dev To prevent repetition of VRF output due to repetition of the
	 * @dev user-supplied seed, that seed is combined in a hash with the
	 * @dev user-specific nonce, and the address of the consuming contract. The
	 * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
	 * @dev the final seed, but the nonce does protect against repetition in
	 * @dev requests which are included in a single block.
	 *
	 * @param _userSeed VRF seed input provided by user
	 * @param _requester Address of the requesting contract
	 * @param _nonce User-specific nonce at the time of the request
	 */
	function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
		address _requester, uint256 _nonce)
		internal pure returns (uint256)
	{
		return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
	}

	/**
	 * @notice Returns the id for this request
	 * @param _keyHash The serviceAgreement ID to be used for this request
	 * @param _vRFInputSeed The seed to be passed directly to the VRF
	 * @return The id for this request
	 *
	 * @dev Note that _vRFInputSeed is not the seed passed by the consuming
	 * @dev contract, but the one generated by makeVRFInputSeed
	 */
	function makeRequestId(
		bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILinkToken {
	function allowance(address owner, address spender) external view returns (uint256 remaining);
	function approve(address spender, uint256 value) external returns (bool success);
	function balanceOf(address owner) external view returns (uint256 balance);
	function decimals() external view returns (uint8 decimalPlaces);
	function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
	function increaseApproval(address spender, uint256 subtractedValue) external;
	function name() external view returns (string memory tokenName);
	function symbol() external view returns (string memory tokenSymbol);
	function totalSupply() external view returns (uint256 totalTokensIssued);
	function transfer(address to, uint256 value) external returns (bool success);
	function transferAndCall(address to, uint256 value, bytes memory data) external returns (bool success);
	function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @title A provably fair NFT raffle
/// @author Valerio Leo @valerioHQ
interface IRaffle {
	enum PrizeType {
		ERC1155,
		ERC721
	}

	struct Prize {
		address tokenAddress;
		uint256 tokenId;
		bool claimed;
		PrizeType prizeType;
	}

	struct RaffleInfo {
		uint endDate;
		uint startDate;
		Prize[] prizes;
		address[] players;
		uint256 randomResult;
	}

	event RaffleStarted(uint256 raffleIndex, uint indexed startDate, uint indexed endDate);
	event EnteredGame(uint256 raffleIndex, address indexed player, uint256 playerIndexInRaffle);
	event PrizeAdded(uint256 raffleIndex, uint256 prizeIndex);
	event PrizeClaimed(uint256 raffleIndex, uint256 prizeIndex, address indexed winner);
	event WinnersDrafted(uint256 raffleIndex, uint256 randomNumber);

	/**
	 * @dev It allows to set a new raffle ticket.
	 * @param raffleTicketAddress The raffleTicketAddress. It must be ERC-1155 token.
	 */
	function setRaffleTicket(address raffleTicketAddress) external;

	/**
	 * @dev Initiate a new raffle. It should allow only when a raffle is not
	 * already running. Only the Owner can call this method.
	 * @param startDate The timestamp after when a raffle starts
	 * @param endDate The timestamp after when a raffle can be finalised
	 */
	function startRaffle(uint startDate, uint endDate) external returns (uint256);

	/**
	 * @dev This function helps to get a better picture of a given raffle. It also
	 * @dev helps in verifying offchain the fairness of the Raffle.
	 * @param raffleIndex The index of the Raffle to check.
	 */
	function getPlayersLength(uint256 raffleIndex) external view returns (uint256);

	/**
	 * @dev This function helps to get a better picture of a given raffle by
	 * @dev helping retrieving the number of Prizes
	 * @param raffleIndex The index of the Raffle to check.
	 */
	function getPrizesLength(uint256 raffleIndex) external view returns (uint256);

	/**
	 * @dev With this function the Owner can change the grace period
	 * @dev to withdraw unclamed Prices
	 * @param period The index of the Raffle to check.
	 */
	function changeWithdrawGracePeriod(uint256 period) external;

	/**
	 * @dev A handy getter for a Player of a given Raffle.
	 * @param raffleIndex the index of the Raffle where to get the Player
	 * @param playerIndex the index of the Player to get
	 */
	function getPlayerAtIndex(uint256 raffleIndex, uint256 playerIndex) external view returns (address);

	/**
	 * @dev A handy getter for the Prizes
	 * @param raffleIndex the index of the Raffle where to get the Player
	 * @param prizeIndex the index of the Prize to get
	 */
	function getPrizeAtIndex(uint256 raffleIndex, uint256 prizeIndex) external view returns (address, uint256);

	/**
	 * @dev This method disclosed the committed message and closes the current raffle.
	 * Only the Owner can call this method
	 * @param raffleIndex the index of the Raffle where to draft winners
	 * @param entropy The message in clear. It will be used as part of entropy from Chainlink
	 */
	function draftWinners(uint256 raffleIndex, uint256 entropy) external;

	/**
	 * @dev Allows a winner to withdraw his/her prize
	 * @param raffleIndex The index of the Raffle where to find the Price to withdraw
	 * @param prizeIndex The index of the Prize to withdraw
	 */
	function claimPrize(uint256 raffleIndex, uint prizeIndex) external;

		/**
	 * @dev It maps a given Prize with the address of the winner.
	 * @param raffleIndex The index of the Raffle where to find the Price winner
	 * @param prizeIndex The index of the prize to withdraw
	 */
	function getPrizeWinner(uint256 raffleIndex, uint256 prizeIndex) external view returns (address);

		/**
	 * @dev It maps a given Prize with the index of the winner.
	 * @param raffleIndex The index of the Raffle where to find the Price winner
	 * @param prizeIndex The index of the prize to withdraw
	 */
	function getPrizeWinnerIndex(uint256 raffleIndex, uint256 prizeIndex) external view returns (uint256);

	/**
	 * @dev Prevents locked NFT by allowing the Owner to withdraw an unclaimed
	 * @dev prize after a grace period has passed
	 * @param raffleIndex The index of the Raffle containing the Prize to withdraw
	 * @param prizeIndex The index of the prize to withdraw
	 */
	function unlockUnclaimedPrize(uint256 raffleIndex, uint prizeIndex) external;

	/**
	 * @dev Once a non-ticket NFT is received, it is considered as prize
	 * @dev play multiple tickets.
	 * @dev With this function, we add the received NFT as raffle Prize
	 * @param tokenAddress the address of the NFT received
	 * @param tokenId the id of the NFT received
	 */
	function addERC1155Prize(uint256 raffleIndex, address tokenAddress, uint256 tokenId) external;

	/**
	 * @dev Once a non-ticket NFT is received, it is considered as prize
	 * @dev play multiple tickets.
	 * @dev With this function, we add the received NFT as raffle Prize
	 * @param tokenAddress the address of the NFT received
	 * @param tokenId the id of the NFT received
	 */
	function addERC721Prize(uint256 raffleIndex, address tokenAddress, uint256 tokenId) external;

	/**
	 * @dev Anyone with a valid ticket can enter the raffle. One player can also
	 * @dev play multiple tickets.
	 * @param raffleIndex The index of the Raffle to enter
	 * @param ticketsAmount the number of tickets to play
	 */
	function enterGame(uint256 raffleIndex, uint256 ticketsAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "../AccessControl/RaffleAdminAccessControl.sol";
import "./IRaffle.sol";
import "../Chainlink/VRFConsumerBase.sol";

/// @title A provably fair NFT raffle
/// @author Valerio Leo @valerioHQ
contract Raffle is IRaffle, RaffleAdminAccessControl, IERC721Receiver, IERC1155Receiver, VRFConsumerBase {
	bytes32 internal keyHash;
	uint256 internal fee;

	mapping(bytes32 => uint256) public randomnessRequests;

	RaffleInfo[] public raffleInfo;

	ERC1155 public raffleTicket;

	uint256 public withdrawGracePeriod;

	constructor(
		address raffleTicketAddress,
		bytes32 _keyHash,
		address VRFCoordinator,
		address LINKToken,
		uint256 _fee
	)
		VRFConsumerBase(
			VRFCoordinator, // VRF Coordinator
			LINKToken  // LINK Token
		)
		RaffleAdminAccessControl(
			msg.sender,
			raffleTicketAddress
		)
		public
	{
		keyHash = _keyHash;
		fee = _fee;

		setRaffleTicket(raffleTicketAddress);
		changeWithdrawGracePeriod(60 * 60 * 24 * 7); // 1 week in seconds
	}

	modifier raffleExists(uint256 raffleIndex) {
		require(raffleInfo.length > raffleIndex, 'Raffle: Raffle does not exists');
		_;
	}

	modifier raffleIsRunning(uint256 raffleIndex) {
		require(
			raffleInfo[raffleIndex].startDate <= now() &&
			now() <= raffleInfo[raffleIndex].endDate, 'Raffle: Raffle not running'
		);
		_;
	}

	modifier raffleIsConcluded(uint256 raffleIndex) {
		require(now() >= raffleInfo[raffleIndex].endDate, 'Raffle: Raffle is not concluded yet');
		_;
	}

	modifier raffleIsNotConcluded(uint256 raffleIndex) {
		require(now() <= raffleInfo[raffleIndex].endDate, 'Raffle: Raffle is already concluded');
		_;
	}

	/**
	* @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
	* by `operator` from `from`, this function is called.
	*
	* It must return its Solidity selector to confirm the token transfer.
	* If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
	*
	* The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
	*/
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public virtual override returns (bytes4) {
		return this.onERC721Received.selector;
	}

	/**
	* @dev Handles the receipt of a multiple ERC1155 token types. This function
		is called at the end of a `safeBatchTransferFrom` after the balances have
		been updated. To accept the transfer(s), this must return
		`bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
		(i.e. 0xbc197c81, or its own function selector).
	* @param operator The address which initiated the batch transfer (i.e. msg.sender)
	* @param from The address which previously owned the token
	* @param ids An array containing ids of each token being transferred (order and length must match values array)
	* @param values An array containing amounts of each token being transferred (order and length must match ids array)
	* @param data Additional data with no specified format
	* @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
	*/
	function onERC1155BatchReceived(address operator, address from, uint256[] memory ids, uint256[] memory values, bytes calldata data) public virtual override returns (bytes4) {
		return this.onERC1155Received.selector;
	}

	/**
	 * @dev It allows to set a new raffle ticket.
	 * @param raffleTicketAddress The raffleTicketAddress. It must be ERC-1155 token.
	 */
	function setRaffleTicket(address raffleTicketAddress) public override onlyManager {
		require(raffleTicketAddress != address(0), 'Raffle: RaffleTicket address cannot be zero');

		raffleTicket = ERC1155(raffleTicketAddress);
	}

	/**
	*	@dev Handles the receipt of a single ERC1155 token type. This function is
		called at the end of a `safeTransferFrom` after the balance has been updated.
		To accept the transfer, this must return
		`bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
		(i.e. 0xf23a6e61, or its own function selector).
	*	@param operator The address which initiated the transfer (i.e. msg.sender)
	*	@param from The address which previously owned the token
	*	@param id The ID of the token being transferred
	*	@param value The amount of tokens being transferred
	*	@param data Additional data with no specified format
	*	@return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
	*/
	function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) public virtual override returns (bytes4) {
		return this.onERC1155Received.selector;
	}

	// ERC165 interface support
	function supportsInterface(bytes4 interfaceID) public pure override(IERC165, AccessControlEnumerable) returns (bool) {
			return  interfaceID == 0x01ffc9a7 ||    // ERC165
							interfaceID == 0x4e2312e0;      // ERC1155_ACCEPTED ^ ERC1155_BATCH_ACCEPTED;
	}

	/**
	* @dev Initiate a new raffle.
	* Only the Owner can call this method.
	* @param startDate The timestamp after when a raffle starts
	* @param endDate The timestamp after when a raffle can be finalised
	* @return (uint256) the index of the raffle
	*/
	function startRaffle(uint startDate, uint endDate) public override onlyManager returns (uint256) {
		require(startDate > now(), 'Raffle: Start date should be later than current block time');
		require(startDate < endDate, 'Raffle: End date should be later than start date');

		raffleInfo.push();
		uint256 newIndex = raffleInfo.length - 1;

		raffleInfo[newIndex].startDate = startDate;
		raffleInfo[newIndex].endDate = endDate;
		raffleInfo[newIndex].randomResult = 0;

		emit RaffleStarted(newIndex, startDate, endDate);

		return newIndex;
	}

	/**
	* @dev This function helps to get a better picture of a given raffle. It also
	* @dev helps in verifying offchain the fairness of the Raffle.
	* @param raffleIndex The index of the Raffle to check.
	* @return (uint256) the number of players in the raffle
	*/
	function getPlayersLength(uint256 raffleIndex) public override view  returns (uint256) {
		return raffleInfo[raffleIndex].players.length;
	}

	/**
	* @dev This function helps to get a better picture of a given raffle by
	* @dev helping retrieving the number of Prizes
	* @param raffleIndex The index of the Raffle to check.
	* @return (uint256) the number of prizes in the raffle
	*/
	function getPrizesLength(uint256 raffleIndex) public override view  returns (uint256) {
		return raffleInfo[raffleIndex].prizes.length;
	}

	/**
	* @dev With this function the Owner can change the grace period
	* @dev to withdraw unclamed Prices
	* @param period The length of the grace period in seconds
	*/
	function changeWithdrawGracePeriod(uint256 period) public onlyManager override {
		require(period >= 60 * 60 * 24 * 7, 'Withdraw grace period too short'); // 1 week in seconds

		withdrawGracePeriod = period;
	}

	/**
	* @dev A handy getter for a Player of a given Raffle.
	* @param raffleIndex the index of the Raffle where to get the Player
	* @param playerIndex the index of the Player to get
	* @return (address) the address of the player
	*/
	function getPlayerAtIndex(
		uint256 raffleIndex,
		uint256 playerIndex
	)
		public
		view
		override
		raffleExists(raffleIndex)
		returns (address)
	{
		require(playerIndex < raffleInfo[raffleIndex].players.length, 'Raffle: No Player at index');

		return raffleInfo[raffleIndex].players[playerIndex];
	}

	/**
	* @dev A handy getter for the Prizes
	* @param raffleIndex the index of the Raffle where to get the Player
	* @param prizeIndex the index of the Prize to get
	* @return (address, uint256) the prize address and the prize tokenId
	*/
	function getPrizeAtIndex(uint256 raffleIndex, uint256 prizeIndex) public override view returns (address, uint256) {
		return (
			raffleInfo[raffleIndex].prizes[prizeIndex].tokenAddress,
			raffleInfo[raffleIndex].prizes[prizeIndex].tokenId
		);
	}

	/**
	 * @dev This method disclosed the committed message and closes the current raffle.
	 * Only the Owner can call this method
	 * @param raffleIndex the index of the Raffle where to draft winners
	 * @param entropy The message in clear. It will be used as part of entropy from Chainlink
	 */
	function draftWinners(
		uint256 raffleIndex,
		uint256 entropy
	)
		public
		override
		onlyManager
		raffleExists(raffleIndex)
		raffleIsConcluded(raffleIndex)
	{
		require(raffleInfo[raffleIndex].randomResult == 0, 'Raffle: Randomness already requested');

		raffleInfo[raffleIndex].randomResult = 1; // 1 is our flag for 'pending'

		if(getPlayersLength(raffleIndex) > 0 && getPrizesLength(raffleIndex) > 0) {
			getRandomNumber(raffleIndex, entropy);
		}
		else {
			raffleInfo[raffleIndex].randomResult = 2; // 2 is our flag for 'concluded without Players or Prizes'

			emit WinnersDrafted(raffleIndex, 2);
		}
	}

	/**
	 * @dev Allows a winner to withdraw his/her prize
	 * @param raffleIndex The index of the Raffle where to find the Price to withdraw
	 * @param prizeIndex The index of the Prize to withdraw
	 */
	function claimPrize(
		uint256 raffleIndex,
		uint prizeIndex
	)
		public
		override
		raffleExists(raffleIndex)
		raffleIsConcluded(raffleIndex)
	{
		require(
			raffleInfo[raffleIndex].randomResult != 0 &&
			raffleInfo[raffleIndex].randomResult != 1,
			'Raffle: Random Number not drafted yet'
		);

		address prizeWinner = getPrizeWinner(raffleIndex, prizeIndex);
		require(msg.sender == prizeWinner, 'Raffle: You are not the winner of this Prize');

		_transferPrize(raffleIndex, prizeIndex, prizeWinner);
	}

	/**
	* @dev It maps a given Prize with the address of the winner.
	* @param raffleIndex The index of the Raffle where to find the Price winner
	* @param prizeIndex The index of the prize to withdraw
	* @return (uint256) The index of the winning account
	*/
	function getPrizeWinner(uint256 raffleIndex, uint256 prizeIndex) public override view  returns (address) {
		uint winnerIndex = getPrizeWinnerIndex(raffleIndex, prizeIndex);

		return raffleInfo[raffleIndex].players[winnerIndex];
	}

	/**
	* @dev It maps a given Prize with the index of the winner.
	* @param raffleIndex The index of the Raffle where to find the Price winner
	* @param prizeIndex The index of the prize to withdraw
	* @return (uint256) The index of the winning account
	*/
	function getPrizeWinnerIndex(
		uint256 raffleIndex,
		uint256 prizeIndex
	)
		public
		override
		view
		raffleIsConcluded(raffleIndex)
		returns (uint256)
	{
		require(getPlayersLength(raffleIndex) > 0, 'Raffle: Raffle concluded without Players');
		require(
			raffleInfo[raffleIndex].randomResult != 0 &&
			raffleInfo[raffleIndex].randomResult != 1,
			'Raffle: Randomness pending'
		);

		bytes32 randomNumber = keccak256(abi.encode(raffleInfo[raffleIndex].randomResult + prizeIndex));
		return uint(randomNumber) % getPlayersLength(raffleIndex);
	}

	/**
	 * @dev Prevents locked NFT by allowing the Owner to withdraw an unclaimed
	 * @dev prize after a grace period has passed
	 * @param raffleIndex The index of the Raffle containing the Prize to withdraw
	 * @param prizeIndex The index of the prize to withdraw
	 */
	function unlockUnclaimedPrize(
		uint256 raffleIndex,
		uint prizeIndex
	)
		public
		override
		onlyPrizeManager
		raffleIsConcluded(raffleIndex)
	{
		require(
			now() >= raffleInfo[raffleIndex].endDate + withdrawGracePeriod ||
			getPlayersLength(raffleIndex) == 0, // if there is no players, we can withdraw immediately
			'Raffle: Grace period not passed yet'
		);

		_transferPrize(raffleIndex, prizeIndex, msg.sender);
	}

	/**
	* @dev Once a non-ticket NFT is received, it is considered as prize
	* @dev play multiple tickets.
	* @notice MUST trigger PrizeAdded event
	* @dev With this function, we add the received NFT as raffle Prize
	* @param tokenAddress the address of the NFT received
	* @param tokenId the id of the NFT received
	* @param prizeType the type of prize to add. 0=ERC1155, 1=ERC721
	*/
	function _addPrize(
		uint256 raffleIndex,
		address tokenAddress,
		uint256 tokenId,
		PrizeType prizeType
	) internal {
		Prize memory prize;
		prize.tokenAddress = tokenAddress;
		prize.tokenId = tokenId;
		prize.prizeType = prizeType;

		raffleInfo[raffleIndex].prizes.push(prize);

		uint256 prizeIndex = raffleInfo[raffleIndex].prizes.length - 1;

		emit PrizeAdded(raffleIndex, prizeIndex);
	}

/**
	* @dev Once a non-ticket NFT is received, it is considered as prize
	* @dev play multiple tickets.
	* @notice MUST trigger PrizeAdded event
	* @dev With this function, we add the received ERC1155 NFT as raffle Prize
	* @param tokenAddress the address of the NFT received
	* @param tokenId the id of the NFT received
	*/
	function addERC1155Prize(
		uint256 raffleIndex,
		address tokenAddress,
		uint256 tokenId
	)
		public
		override
		onlyPrizeManager
		raffleExists(raffleIndex)
		raffleIsNotConcluded(raffleIndex)
	{ 
		ERC1155 prizeInstance = ERC1155(tokenAddress);

		prizeInstance.safeTransferFrom(msg.sender, address(this), tokenId, 1, '');

		_addPrize(raffleIndex, tokenAddress, tokenId, PrizeType.ERC1155);
	}

/**
	* @dev Once a non-ticket NFT is received, it is considered as prize
	* @dev play multiple tickets.
	* @notice MUST trigger PrizeAdded event
	* @dev With this function, we add the received ERC721 NFT as raffle Prize
	* @param tokenAddress the address of the NFT received
	* @param tokenId the id of the NFT received
	*/
	function addERC721Prize(
		uint256 raffleIndex,
		address tokenAddress,
		uint256 tokenId
	)
		public
		override
		onlyPrizeManager
		raffleExists(raffleIndex)
		raffleIsNotConcluded(raffleIndex)
	{ 
		ERC721 prizeInstance = ERC721(tokenAddress);

		prizeInstance.safeTransferFrom(msg.sender, address(this), tokenId);

		_addPrize(raffleIndex, tokenAddress, tokenId, PrizeType.ERC721);
	}

	/**
	* @dev Anyone with a valid ticket can enter the raffle. One player can also
	* @dev play multiple tickets.
	* @notice MUST trigger EnteredGame event
	* @param raffleIndex The index of the Raffle to enter
	* @param ticketsAmount the number of tickets to play
	*/
	function enterGame(
		uint256 raffleIndex,
		uint256 ticketsAmount
	)
		public
		override
		raffleExists(raffleIndex)
		raffleIsRunning(raffleIndex)
	{

		raffleTicket.safeTransferFrom(msg.sender, address(this), 0, ticketsAmount, '');

		for (uint i = 0; i < ticketsAmount; i++) {
			raffleInfo[raffleIndex].players.push(msg.sender);

			emit EnteredGame(raffleIndex, msg.sender, raffleInfo[raffleIndex].players.length - 1);
		}
	}

	/**
	* @dev It transfers the prize to a given address.
	* @notice MUST trigger WinnersDrafted event
	* @param raffleIndex The index of the Raffle to enter
	* @param prizeIndex The index of the prize to withdraw
	* @param winnerAddress The address of the winner
	*/
	function _transferPrize(uint256 raffleIndex, uint prizeIndex, address winnerAddress) internal {
		Prize storage prize = raffleInfo[raffleIndex].prizes[prizeIndex];

		if(prize.prizeType == PrizeType.ERC1155) {
			ERC1155 prizeInstance = ERC1155(prize.tokenAddress);

			prizeInstance.safeTransferFrom(address(this), winnerAddress, prize.tokenId, 1, '');
		} else {
			ERC721 prizeInstance = ERC721(prize.tokenAddress);

			prizeInstance.safeTransferFrom(address(this), winnerAddress, prize.tokenId);
		}

		raffleInfo[raffleIndex].prizes[prizeIndex].claimed = true;

		emit PrizeClaimed(raffleIndex, prizeIndex, winnerAddress);
	}

	/**
	* @dev Requests randomness from a user-provided seed
	* @param raffleIndex The index of the Raffle to to require randomness for
	* @param userProvidedSeed The seed provided by the Owner
	* @return requestId (bytes32) the request id
	*/
	function getRandomNumber(
		uint256 raffleIndex,
		uint256 userProvidedSeed
	)
		internal
		returns (bytes32 requestId)
	{
		require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");

		bytes32 requestId = requestRandomness(keyHash, fee, userProvidedSeed);
		randomnessRequests[requestId] = raffleIndex;
		raffleInfo[raffleIndex].randomResult = 1; // a flag for pending randomness

		return requestId;
	}

	/**
	* @dev Callback function used by VRF Coordinator
	* @notice MUST trigger WinnersDrafted event
	* @param requestId The id of the request being fulfilled
	* @param randomness The result of the randomness request
	*/
	function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
		uint256 raffleIndex = randomnessRequests[requestId];

		require(raffleInfo[raffleIndex].randomResult == 1, 'Raffle: Request already fulfilled');

		raffleInfo[raffleIndex].randomResult = randomness;

		emit WinnersDrafted(randomnessRequests[requestId], randomness);
	}

	/**
	 * @dev A simple time util
	 * @return (uint256) current block timestamp
	 */
	function now() internal view returns (uint256) {
		return block.timestamp;
	}
}

