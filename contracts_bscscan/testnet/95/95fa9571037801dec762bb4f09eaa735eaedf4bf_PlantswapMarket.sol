/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

// SPDX-License-Identifier: MIT
/* LastEdit: 15August2021 22:15
**
** Plantswap.finance - Plantswap Market
** Version:         1.0.0
**
** Detail: This contract is used to place collectibles or token for sales.
**         You can also append other collectibles or tokens to the first listing to create a set of item and or token.
**         Also possible to place open offer for a token or collectible.
**         You can also create auctions for collectibles or tokens.
*/
pragma solidity 0.8.0;


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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

/**
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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

interface BEP20 {
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface PlantswapProfile {
    function increaseUserPoints(address _userAddress, uint256 _numberPoints, uint256 _campaignId) external;
    function increaseTeamPoints(uint256 _teamId, uint256 _numberPoints, uint256 _campaignId) external;
    function getUserProfile(address _userAddress) external view returns (uint256, uint256, uint256, address, uint256, uint256, bool);
}

contract PlantswapMarket is AccessControl, ERC721Holder {
    using Address for address;
    using Counters for Counters.Counter;
    // Plant Token Contract address
    BEP20 public plantToken;
    // Plantswap Profile Contract address (Upgradable)
    PlantswapProfile public plantswapProfile;
    // Fees -> Plantswap Development Foundation address
    address public feesAddress = 0xcab64A8d400FD7d9F563292E6135285FD9E54980;
    bool private profileActive;
    // TOKEN_ROLE is granted to all BEP20 approved token to use in the market
    bytes32 public constant TOKEN_ROLE = keccak256("TOKEN_ROLE");
    // NFT_ROLE is granted to all ERC721 address to use in the market
    bytes32 public constant NFT_ROLE = keccak256("NFT_ROLE");
    // ADDRESSMANAGER_ROLE is granted to Address Manager to Add token and Nft Address
    bytes32 public constant ADDRESSMANAGER_ROLE = keccak256("ADDRESSMANAGER_ROLE");
    // Stats
    uint256 public numberActiveItems;
    uint256 public numberActiveNfts;
    uint256 public numberActiveSalesItems;
    uint256 public numberUnclaimedSaleItems;
    uint256 public numberSales;
    uint256 public numberSoldItems;
    // Minimum number of Plant Token the user need to have to be able to do this action
    uint256 public numberPlantToUpdate;
    uint256 public numberPlantToSell;
    uint256 public numberPlantToBuy;
    uint256 public numberPlantToExtra;
    uint256 public numberPlantToOffer;
    // Cost (in Plant Token) for different actions
    uint256 public costPlantToUpdate;
    uint256 public costPlantToSell;
    uint256 public costPlantToBuy;
    uint256 public costPlantToExtra;
    uint256 public costPlantToOffer;
    // Points for different actions
    uint256 public numberPointToSell;
    uint256 public numberPointToBuy;
    uint256 public numberPointToExtra;
    uint256 public numberPointToOffer;

    // True if this listings and items
    mapping(uint256 => bool) public listingsById;
    mapping(uint256 => bool) public itemsById;
    // Basic structures mapping
    mapping(uint256 => Listing) private listings;
    mapping(uint256 => Item) private items;
    mapping(uint256 => mapping(uint256 => uint256)) private extras;
    mapping(uint256 => mapping(uint256 => uint256)) private offers;
    // True if the user has done this
    mapping(address => bool) public hasSellSomething;
    mapping(address => bool) public hasBuySomething;
    // Map user data
    mapping(address => uint256) public countListingBySeller;
    mapping(address => mapping(uint256 => uint256)) public listingsIdBySellerAddress;
    // Map item data
    mapping(address => uint256) public itemsIdByAddress;
    mapping(uint256 => uint256) public itemsByListingId;
    mapping(address => mapping(uint256 => uint256)) public itemsIdByAddressAndTokenId;
    // Map extras and offers data
    mapping(uint256 => uint256) public countExtraToListingsId;
    mapping(uint256 => uint256) public countOfferToListingsId;
    // Generate itemsId and listingsId
    Counters.Counter private _countListings;
    Counters.Counter private _countItems;
    // Events
    event ActivateTransaction(uint256 indexed listingId);
    event CancelTransaction(uint256 indexed listingId);
    event FreezeTransaction(uint256 indexed listingId);
    event CancelLikeTransaction(uint256 indexed listingId, address indexed liker);
    event ClaimedTransaction(uint256 indexed listingId, address indexed claimer);
    event LikeTransaction(uint256 indexed listingId, address indexed liker);
    event MakeTransaction(uint256 indexed listingId, address indexed closer);
    event AddTransaction(uint256 indexed listingId, address indexed seller, address buyTokenAddress, uint256 buyTokenId, uint256 buyCount, address indexed sellTokenAddress, uint256 sellTokenId, uint256 sellCount);
    event UpdateTransaction(uint256 indexed listingId, address indexed seller, address buyTokenAddress, uint256 buyTokenId, uint256 buyCount, address indexed sellTokenAddress, uint256 sellTokenId, uint256 sellCount);
    
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not the main admin");
        _;
    }
    modifier onlyAddressManager() {
        require(hasRole(ADDRESSMANAGER_ROLE, _msgSender()), "Not a address manager");
        _;
    }

    struct Listing {
        address seller;
        uint8 sellType;
        uint256 sellTypeValue;
        uint256 blocknumber;
        bool buyNftElseToken;
        address buyTokenAddress;
        uint256 buyTokenId;
        uint256 buyCount;
        bool sellNftElseToken;
        address sellTokenAddress;
        uint256 sellTokenId;
        uint256 sellCount;
        bool isSold;
        bool isActive;
        bool isCanceled;
    }
    struct Item {
        bool nft;
        address itemAddress;
        uint256 tokenId;
        uint256 countActive;
        uint256 countSold;
        uint256 countUnclaim;
    }

    constructor(
        BEP20 _plantToken,
        PlantswapProfile _plantswapProfile,
        bool _profileActive
    ) {
        plantToken = _plantToken;
        plantswapProfile = _plantswapProfile;
        profileActive = _profileActive;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addTransaction(
        uint8 _sellType,
        uint256 _sellTypeValue,
        bool _buyNftElseToken, 
        address _buyTokenAddress, 
        uint _buyTokenId, 
        uint256 _buyCount, 
        bool _sellNftElseToken, 
        address _sellTokenAddress, 
        uint _sellTokenId, 
        uint256 _sellCount, 
        bool _isActive) external {

        /* Sell type: 
            0 = normal sell of token and or nfts, 
            1 = auction, 
            2 = add extras buy (Only with a type 0), 
            3 = add extras sell (Only with a type 0), 
            5 = place buy offer (auction bid), 
            6 = place sell offer (open to offer), 
            7 = place buy offer for any token id with token id larger than or tokenId and smaller than buyCount
        */
        require(_sellType == 0 || _sellType == 1 || _sellType == 2 || _sellType == 3 || _sellType == 5 || _sellType == 6 || _sellType == 7, "Invalid sellType");
        // If token, no tokenId is allowed
        if(!_buyNftElseToken) {
            require(hasRole(TOKEN_ROLE, _buyTokenAddress), "Token buy address invalid");
            require(_buyTokenId == 0, "Invalid buy tokenId, keep at 0");
        }
        else {
            require(hasRole(NFT_ROLE, _buyTokenAddress), "NFT buy address invalid");
        }
        if(!_sellNftElseToken) {
            require(hasRole(TOKEN_ROLE, _sellTokenAddress), "Token sell address invalid");
            require(_sellTokenId == 0, "Invalid sell tokenId, keep at 0");
        }
        else {
            require(hasRole(NFT_ROLE, _sellTokenAddress), "NFT sell address invalid");
        }
        if(!_buyNftElseToken && !_sellNftElseToken) {
            require(_buyTokenAddress != _sellTokenAddress, "Token A == Token B");
        }
        if(_sellType < 7) {
            // If NFT, not more than 1 token is allowed
            if(_buyNftElseToken) {
                require(_buyCount == 1, "Invalid buy count, keep at 1");
            }
            if(_sellNftElseToken) {
                require(_sellCount == 1, "Invalid sell count, keep at 1");
            }
            if(_sellType == 1) {
            // If Auction, need a block number limit
            require(_sellTypeValue > block.number, "Invalid auction block count");
            }
        }
        else {
            // If NFT, not verify that _buyCount is bigger than buyTokenId For Type 7, this is the tokenId range open for buy/sell
            require(_buyNftElseToken && _buyCount >= _buyTokenId, "Invalid sell/buy count for NFT");
            // Check that the nft Address is valid
            require(hasRole(NFT_ROLE, _buyTokenAddress), "NFT buy address invalid");
        }
        // If extras or offer, need a listingId
        if(_sellType == 2 || _sellType == 3 || _sellType == 5) {
            require(listingsById[_sellTypeValue], "Invalid referenced listing");
            require(listings[_sellTypeValue].isActive, "Reference listing not active");
            require(!listings[_sellTypeValue].isSold, "Reference listing sold already");
            require(!listings[_sellTypeValue].isCanceled, "Reference listing canceled");
        }
        uint256 sellerTeamId = _isUserActiveGiveTeamId(_msgSender());
        if(_sellType == 0 || _sellType == 1) {
            _checkPlantHoldingAndPayTxCost(numberPlantToSell, costPlantToSell);
        }
        if(_sellType == 2 || _sellType == 3) {
            // No extras on extras
            require(listings[_sellTypeValue].sellType != 2 && listings[_sellTypeValue].sellType != 3 && listings[_sellTypeValue].sellType != 7, "No inception");
            // If extras user need to be the seller
            require(listings[_sellTypeValue].seller == _msgSender(), "You are not the seller");
            _checkPlantHoldingAndPayTxCost(numberPlantToExtra, costPlantToExtra);
        }
        if(_sellType == 5 || _sellType == 6 || _sellType == 7) {
            _placeOffer(listings[_sellTypeValue], _sellTypeValue, _buyTokenAddress, _buyTokenId, _buyCount, _sellTokenAddress, _sellTokenId, _sellCount);
        }
        if(_sellType == 2 || _sellType == 5) {
            _moveTokenOrNft(
                _msgSender(), 
                false, 
                _buyNftElseToken, 
                _buyTokenAddress, 
                _buyTokenId, 
                _buyCount);
            _itemCreateOrAppend(_buyTokenAddress, _buyNftElseToken, _buyTokenId);
            _listingCreation(_sellType, _sellTypeValue, 
                _buyNftElseToken, _buyTokenAddress, _buyTokenId, _buyCount,
                _sellNftElseToken, _sellTokenAddress, _sellTokenId, _sellCount, _isActive);
            itemsByListingId[_countListings.current()] = (uint256) (_countItems.current());
        }
        if(_sellType == 0 || _sellType == 1 || _sellType == 3 || _sellType == 6 || _sellType == 7) {
            _moveTokenOrNft(
                _msgSender(), 
                false, 
                _sellNftElseToken, 
                _sellTokenAddress, 
                _sellTokenId, 
                _sellCount);
            _itemCreateOrAppend(_sellTokenAddress, _sellNftElseToken, _sellTokenId);
            _listingCreation(_sellType, _sellTypeValue, 
                _buyNftElseToken, _buyTokenAddress, _buyTokenId, _buyCount,
                _sellNftElseToken, _sellTokenAddress, _sellTokenId, _sellCount, _isActive);
            itemsByListingId[_countListings.current()] = (uint256) (_countItems.current());
        }
        if(_sellType == 0 || _sellType == 1) {
            _increasePoints(_msgSender(), sellerTeamId, numberPointToSell, (10000000 + _countListings.current()));
            hasSellSomething[_msgSender()] = (bool) (true);
        }
        else if(_sellType == 2 || _sellType == 3) {
            _increasePoints(_msgSender(), sellerTeamId, numberPointToExtra, (10000000 + _countListings.current()));
        }
        else {
            _increasePoints(_msgSender(), sellerTeamId, numberPointToOffer, (10000000 + _countListings.current()));
        }
        emit AddTransaction(_countListings.current(), _msgSender(), _buyTokenAddress, _buyTokenId, _buyCount, _sellTokenAddress, _sellTokenId, _sellCount);
    }

    function modifyTransaction(uint256 _listingId, uint256 _copyListingId, uint8 _newSellType) external {
        require(!listings[_listingId].isSold, "Listing is sold");
        require(listings[_listingId].seller == _msgSender(), "Not the seller");
        require(listings[_listingId].sellType == 5 || listings[_listingId].sellType == 6 || listings[_listingId].sellType == 7, "Listing not a open offer");
        if(listings[_listingId].sellType == 5) {
            // Check for buy offer on auction
            if(listings[listings[_listingId].sellTypeValue].sellType == 1) {
                // Check that user has not the best offer (can't cancel best offer)
                require(offers[_listingId][countOfferToListingsId[_listingId]] >= _listingId, "Can't cancel best offer");
            }
        }
        if(listings[_listingId].sellType == 5) {
            require(_newSellType == 0 || _newSellType == 5, "Invalid new sell type");
            listings[_listingId].sellType = _newSellType;
            // + Allog type 5 to match and close a type 0 or 7
            // + Allog type 5 to transform bid to different listings (if follow requirement)
            listings[_listingId].sellNftElseToken = listings[_copyListingId].sellNftElseToken;
            listings[_listingId].sellTokenAddress = listings[_copyListingId].sellTokenAddress;
            listings[_listingId].sellTokenId = listings[_copyListingId].sellTokenId;
            listings[_listingId].sellCount = listings[_copyListingId].sellCount;
        }
        if(listings[_listingId].sellType == 6 || listings[_listingId].sellType == 7) {
            require(_newSellType == 0 || _newSellType == 1, "Invalid new sell type");
            listings[_listingId].sellType = _newSellType;
            listings[_listingId].buyNftElseToken = listings[_copyListingId].buyNftElseToken;
            listings[_listingId].buyTokenAddress = listings[_copyListingId].buyTokenAddress;
            listings[_listingId].buyTokenId = listings[_copyListingId].buyTokenId;
            listings[_listingId].buyCount = listings[_copyListingId].buyCount;
        }
    }
    function cancelTransaction(uint256 _listingId) external {
        require(listings[_listingId].isActive, "Listing not active");
        require(listings[_listingId].seller == _msgSender(), "Not the seller");

        if(listings[_listingId].sellType == 2 || listings[_listingId].sellType == 3) {
            // Check first that the listing is not sold
            require(!listings[listings[_listingId].sellTypeValue].isSold, "Reference listing sold");
        }
        // Check for buy offer
        if(listings[_listingId].sellType == 5) {
            // Check for buy offer on auction
            if(listings[listings[_listingId].sellTypeValue].sellType == 1) {
                // Check that user has not the best offer (can't cancel best offer)
                require(offers[_listingId][countOfferToListingsId[_listingId]] >= _listingId, "Can't cancel best offer");
            }
        }
        _checkPlantHoldingAndPayTxCost(numberPlantToUpdate, costPlantToUpdate);
        listings[_listingId].isActive = (bool) (false);
        listings[_listingId].isCanceled = (bool) (true);

        if(listings[_listingId].sellType == 0 || listings[_listingId].sellType == 1 || listings[_listingId].sellType == 6 || listings[_listingId].sellType == 7) {
            // Give back the item to the user
            _moveTokenOrNft(
                _msgSender(), 
                true, 
                listings[_listingId].sellNftElseToken, 
                listings[_listingId].sellTokenAddress, 
                listings[_listingId].sellTokenId, 
                listings[_listingId].sellCount);
            // Check for extras
            if(countExtraToListingsId[_listingId] > 0) {
                // Check extra is active
                for(uint256 i = 0; i < countExtraToListingsId[_listingId]; i++) {
                    // Cancel extras buy
                    if(listings[extras[_listingId][i]].isActive && listings[extras[_listingId][i]].sellType == 2) {
                        // Give back the result of the transaction to seller
                        _moveTokenOrNft(
                            _msgSender(), 
                            true, 
                            listings[extras[_listingId][i]].buyNftElseToken, 
                            listings[extras[_listingId][i]].buyTokenAddress, 
                            listings[extras[_listingId][i]].buyTokenId, 
                            listings[extras[_listingId][i]].buyCount);
                        listings[extras[_listingId][i]].isActive = (bool) (false);
                        numberActiveSalesItems -= (uint256) (1);
                        items[itemsIdByAddress[listings[extras[_listingId][i]].sellTokenAddress]].countActive -= (uint256) (1);
                    }
                    // Cancel extras sell and return to seller
                    if(listings[extras[_listingId][i]].isActive && listings[extras[_listingId][i]].sellType == 3) {
                        // Give back the result of the transaction to seller
                        _moveTokenOrNft(
                            _msgSender(), 
                            true, 
                            listings[extras[_listingId][i]].sellNftElseToken, 
                            listings[extras[_listingId][i]].sellTokenAddress, 
                            listings[extras[_listingId][i]].sellTokenId, 
                            listings[extras[_listingId][i]].sellCount);
                        listings[extras[_listingId][i]].isActive = (bool) (false);
                        numberActiveSalesItems -= (uint256) (1);
                        items[itemsIdByAddress[listings[extras[_listingId][i]].sellTokenAddress]].countActive -= (uint256) (1);
                    }
                }
            }
        }
        if(listings[_listingId].sellType == 5) {
            // Give back the item to the user
            _moveTokenOrNft(
                _msgSender(), 
                true, 
                listings[_listingId].buyNftElseToken, 
                listings[_listingId].buyTokenAddress, 
                listings[_listingId].buyTokenId, 
                listings[_listingId].buyCount);
            // Check for extras
            if(countExtraToListingsId[_listingId] > 0) {
                // Check extra is active
                for(uint256 i = 0; i < countExtraToListingsId[_listingId]; i++) {
                    // Cancel extras sell and return to seller
                    if(listings[extras[_listingId][i]].isActive && listings[extras[_listingId][i]].sellType == 2) {
                        // Give back the result of the transaction to seller
                        _moveTokenOrNft(
                            _msgSender(), 
                            true, 
                            listings[extras[_listingId][i]].buyNftElseToken, 
                            listings[extras[_listingId][i]].buyTokenAddress, 
                            listings[extras[_listingId][i]].buyTokenId, 
                            listings[extras[_listingId][i]].buyCount);
                        listings[extras[_listingId][i]].isActive = (bool) (false);
                        numberActiveSalesItems -= (uint256) (1);
                        items[itemsIdByAddress[listings[extras[_listingId][i]].sellTokenAddress]].countActive -= (uint256) (1);
                    }
                    // Cancel extras buy
                    if(listings[extras[_listingId][i]].isActive && listings[extras[_listingId][i]].sellType == 3) {
                        _moveTokenOrNft(
                            _msgSender(), 
                            true, 
                            listings[extras[_listingId][i]].sellNftElseToken, 
                            listings[extras[_listingId][i]].sellTokenAddress, 
                            listings[extras[_listingId][i]].sellTokenId, 
                            listings[extras[_listingId][i]].sellCount);
                        listings[extras[_listingId][i]].isActive = (bool) (false);
                        numberActiveSalesItems -= (uint256) (1);
                        items[itemsIdByAddress[listings[extras[_listingId][i]].sellTokenAddress]].countActive -= (uint256) (1);
                    }
                }
            }
        }
        numberActiveSalesItems -= (uint256) (1);
        items[itemsIdByAddress[listings[_listingId].sellTokenAddress]].countActive -= (uint256) (1);
        emit CancelTransaction(_listingId);
    }

    function claimTransaction(uint256 _listingId) external {
        require(listingsById[_listingId], "ListingId not Valid");
        require(listings[_listingId].isSold, "Listing is not sold");
        require(listings[_listingId].seller == _msgSender(), "Not the seller");
        
        if(listings[_listingId].sellType == 1) {
            require(listings[_listingId].sellTypeValue < block.number, "Auction is still pending");
        }
        if(listings[_listingId].sellType <= 1) {
            _moveTokenOrNft(
                _msgSender(), 
                false, 
                listings[_listingId].buyNftElseToken, 
                listings[_listingId].buyTokenAddress, 
                listings[_listingId].buyTokenId, 
                listings[_listingId].buyCount);
            numberUnclaimedSaleItems -= (uint256) (1);
            items[itemsIdByAddress[listings[_listingId].buyTokenAddress]].countUnclaim -= (uint256) (1);
            // Check for extras
            if(countExtraToListingsId[_listingId] > 0) {
                // Check extra is active
                for(uint256 i = 0; i < countExtraToListingsId[_listingId]; i++) {
                    if(listings[extras[_listingId][i]].isActive && listings[extras[_listingId][i]].sellType == 2) {
                        // Give back the result of the transaction to seller
                        _moveTokenOrNft(
                            _msgSender(), 
                            false, 
                            listings[extras[_listingId][i]].buyNftElseToken, 
                            listings[extras[_listingId][i]].buyTokenAddress, 
                            listings[extras[_listingId][i]].buyTokenId, 
                            listings[extras[_listingId][i]].buyCount);
                        numberUnclaimedSaleItems -= (uint256) (1);
                        items[itemsIdByAddress[listings[extras[_listingId][i]].buyTokenAddress]].countUnclaim -= (uint256) (1);
                    }
                    if(listings[extras[_listingId][i]].isActive && listings[extras[_listingId][i]].sellType == 2) {
                        // Give back the result of the transaction to seller
                        _moveTokenOrNft(
                            _msgSender(), 
                            false, 
                            listings[extras[_listingId][i]].buyNftElseToken, 
                            listings[extras[_listingId][i]].buyTokenAddress, 
                            listings[extras[_listingId][i]].buyTokenId, 
                            listings[extras[_listingId][i]].buyCount);
                        numberUnclaimedSaleItems -= (uint256) (1);
                        items[itemsIdByAddress[listings[extras[_listingId][i]].buyTokenAddress]].countUnclaim -= (uint256) (1);
                    }
                }
            }
        }
        // + Deal with 5/6/7 types of listing
        emit ClaimedTransaction(_listingId, _msgSender());
    }

    function closeTransaction(uint256 _listingId, uint256 _extraValue) external {
        require(listingsById[_listingId], "ListingId not Valid");
        require(listings[_listingId].isActive, "Listing not active");
        require(listings[_listingId].sellType != 2 && listings[_listingId].sellType != 3, "Refer to main listing");
        _checkPlantHoldingAndPayTxCost(numberPlantToBuy, costPlantToBuy);
        
        uint256 buyTokenId = listings[_listingId].buyTokenId;
        uint256 buyCount = listings[_listingId].buyCount;
        
        if(listings[_listingId].sellType == 1 || listings[_listingId].sellType == 7) {
            require(listings[_listingId].seller == _msgSender(), "Not the seller");
            if(listings[_listingId].sellType == 1) {
                require(countOfferToListingsId[_listingId] > 0, "No offer on listing");
                // Match best offer
                buyCount = listings[offers[_listingId][countOfferToListingsId[_listingId]]].buyCount;
            }
            else {
                buyTokenId = _extraValue;
            }
        }

        if(listings[_listingId].sellType == 0 || listings[_listingId].sellType == 1 || listings[_listingId].sellType == 7) {
            // Check we have allowance to transfer the item
            _moveTokenOrNft(
                _msgSender(), 
                false, 
                listings[_listingId].buyNftElseToken, 
                listings[_listingId].buyTokenAddress, 
                buyTokenId, 
                buyCount);
            items[itemsIdByAddress[listings[_listingId].sellTokenAddress]].countUnclaim += (uint256) (1);
            _moveTokenOrNft(
                _msgSender(), 
                true, 
                listings[_listingId].sellNftElseToken, 
                listings[_listingId].sellTokenAddress, 
                listings[_listingId].sellTokenId, 
                listings[_listingId].sellCount);
            // Check for extras
            if(countExtraToListingsId[_listingId] > 0) {
                // Check extra is active
                for(uint256 i = 0; i < countExtraToListingsId[_listingId]; i++) {
                    if(listings[extras[_listingId][i]].isActive && listings[extras[_listingId][i]].sellType == 2) {
                        _moveTokenOrNft(
                            _msgSender(), 
                            false, 
                            listings[extras[_listingId][i]].sellNftElseToken, 
                            listings[extras[_listingId][i]].sellTokenAddress, 
                            listings[extras[_listingId][i]].sellTokenId, 
                            listings[extras[_listingId][i]].sellCount);
                        items[itemsIdByAddress[listings[_listingId].sellTokenAddress]].countUnclaim += (uint256) (1);
                        _moveTokenOrNft(
                            _msgSender(), 
                            true, 
                            listings[extras[_listingId][i]].buyNftElseToken, 
                            listings[extras[_listingId][i]].buyTokenAddress, 
                            listings[extras[_listingId][i]].buyTokenId, 
                            listings[extras[_listingId][i]].buyCount);
                        numberActiveSalesItems -= (uint256) (1);
                        numberUnclaimedSaleItems += (uint256) (1);
                        items[itemsIdByAddress[listings[extras[_listingId][i]].buyTokenAddress]].countActive -= (uint256) (1);
                        items[itemsIdByAddress[listings[extras[_listingId][i]].buyTokenAddress]].countSold += (uint256) (1);
                    }
                    if(listings[extras[_listingId][i]].isActive && listings[extras[_listingId][i]].sellType == 3) {
                        _moveTokenOrNft(
                            _msgSender(), 
                            false, 
                            listings[extras[_listingId][i]].buyNftElseToken, 
                            listings[extras[_listingId][i]].buyTokenAddress, 
                            listings[extras[_listingId][i]].buyTokenId, 
                            listings[extras[_listingId][i]].buyCount);
                        items[itemsIdByAddress[listings[_listingId].buyTokenAddress]].countUnclaim += (uint256) (1);
                        _moveTokenOrNft(
                            _msgSender(), 
                            true, 
                            listings[extras[_listingId][i]].sellNftElseToken, 
                            listings[extras[_listingId][i]].sellTokenAddress, 
                            listings[extras[_listingId][i]].sellTokenId, 
                            listings[extras[_listingId][i]].sellCount);
                        numberActiveSalesItems -= (uint256) (1);
                        numberUnclaimedSaleItems += (uint256) (1);
                        items[itemsIdByAddress[listings[extras[_listingId][i]].buyTokenAddress]].countActive -= (uint256) (1);
                        items[itemsIdByAddress[listings[extras[_listingId][i]].buyTokenAddress]].countSold += (uint256) (1);
                    }
                }
            }
        }
        if(listings[_listingId].sellType == 5 || listings[_listingId].sellType == 6) {
            // + Check it's a open offer and not a auction (Auction get closed by the main listing)
            // Check for buy offer on auction

            // + Check if the offer is still active
            // + Check that user is the seller of the listing
            // + Check that the offer is not already sold
        }
        numberSales += (uint256) (1);
        numberActiveSalesItems -= (uint256) (1);
        numberUnclaimedSaleItems += (uint256) (1);
        // Update countLike on the Item
        items[itemsIdByAddress[listings[_listingId].sellTokenAddress]].countActive -= (uint256) (1);
        items[itemsIdByAddress[listings[_listingId].sellTokenAddress]].countSold += (uint256) (1);
        // Update listing
        listings[_listingId].isActive = (bool) (false);
        listings[_listingId].isSold = (bool) (true);

        _increasePoints(_msgSender(), _isUserActiveGiveTeamId(_msgSender()), numberPointToBuy, (30000000 + _listingId));
        emit MakeTransaction(_listingId, _msgSender());
    }
    function freezeTransaction(uint256 _listingId) external {
        require(listings[_listingId].isActive, "Listing not active");
        require(listings[_listingId].seller == _msgSender(), "Not seller of this listing");
        // + Allow moderator to pause listing
        require(plantToken.balanceOf(_msgSender()) >= numberPlantToUpdate, "Not holding enough tokens");
        require(itemsIdByAddress[listings[_listingId].sellTokenAddress] > 0, "Sell Token not valid item address");

        if(listings[_listingId].sellType == 0 || listings[_listingId].sellType == 1 || listings[_listingId].sellType == 3 || listings[_listingId].sellType == 6 || listings[_listingId].sellType == 7) {
            numberActiveSalesItems -= (uint256) (1);
            // Update countActive on the Item
            items[itemsIdByAddress[listings[_listingId].sellTokenAddress]].countActive -= (uint256) (1);
        }
        if(listings[_listingId].sellType != 0 && listings[_listingId].sellType != 1) {
            require(!listings[listings[_listingId].sellTypeValue].isSold, "Original Listing is sold");
        }
        listings[_listingId].isActive = (bool) (false);
        emit FreezeTransaction(_listingId);
    }
    function activateTransaction(uint256 _listingId) external {
        require(!listings[_listingId].isActive, "Listing is active");
        require(listings[_listingId].seller == _msgSender(), "Not seller of this listing");
        // + Allow moderator to reactivate listing
        require(plantToken.balanceOf(_msgSender()) >= numberPlantToUpdate, "Not holding enough tokens");
        require(itemsIdByAddress[listings[_listingId].sellTokenAddress] > 0, "Sell Token not valid item address");

        if(listings[_listingId].sellType == 0 || listings[_listingId].sellType == 1 || listings[_listingId].sellType == 3 || listings[_listingId].sellType == 6 || listings[_listingId].sellType == 7) {
            numberActiveSalesItems += (uint256) (1);
            // Update countActive on the Item
            items[itemsIdByAddress[listings[_listingId].sellTokenAddress]].countActive += (uint256) (1);
        }
        if(listings[_listingId].sellType == 2 && listings[_listingId].sellType == 5) {
            require(!listings[listings[_listingId].sellTypeValue].isSold, "Original Listing sold");
        }
        listings[_listingId].isActive = (bool) (true);
        emit ActivateTransaction(_listingId);
    }

    // onlyAddressManager
    function updateAddressManager(bool _isNft, address _address) external onlyAddressManager {
        if(_isNft) {
            require(IERC721(_address).supportsInterface(0x80ac58cd), "Not ERC721");
            grantRole(NFT_ROLE, _address);
        } else {
            grantRole(TOKEN_ROLE, _address);
        }
    }
    // onlyOwner
    function updatePlantswapProfile(PlantswapProfile _plantswapProfile) external onlyOwner {
        plantswapProfile = _plantswapProfile;
    }
    function updateProfileRequirement(bool _profileActive) external onlyOwner {
        profileActive = _profileActive;
    }
    function updateFeesAddress(address _feesAddress) external onlyOwner {
        feesAddress = _feesAddress;
    }
    function updatePlantMinimumHold(
        uint256 _numberPlantToUpdate, 
        uint256 _numberPlantToSell, 
        uint256 _numberPlantToBuy, 
        uint256 _numberPlantToExtra, 
        uint256 _numberPlantToOffer) external onlyOwner {
        numberPlantToUpdate = (uint256) (_numberPlantToUpdate);
        numberPlantToSell = (uint256) (_numberPlantToSell);
        numberPlantToBuy = (uint256) (_numberPlantToBuy);
        numberPlantToExtra = (uint256) (_numberPlantToExtra);
        numberPlantToOffer = (uint256) (_numberPlantToOffer);
    }
    function updatePlantCost(
        uint256 _costPlantToUpdate,
        uint256 _costPlantToSell,
        uint256 _costPlantToBuy,
        uint256 _costPlantToExtra,
        uint256 _costPlantToOffer) external onlyOwner {
        costPlantToUpdate = (uint256) (_costPlantToUpdate);
        costPlantToSell = (uint256) (_costPlantToSell);
        costPlantToBuy = (uint256) (_costPlantToBuy);
        costPlantToExtra = (uint256) (_costPlantToExtra);
        costPlantToOffer = (uint256) (_costPlantToOffer);
    }
    function updatePointsReward(
        uint256 _numberPointToSell,
        uint256 _numberPointToBuy, 
        uint256 _numberPointToExtra, 
        uint256 _numberPointToOffer) external onlyOwner {
        numberPointToSell = (uint256) (_numberPointToSell);
        numberPointToBuy = (uint256) (_numberPointToBuy);
        numberPointToExtra = (uint256) (_numberPointToExtra);
        numberPointToOffer = (uint256) (_numberPointToOffer);
    }

    // Get market data
    function getLastListingId() external view returns (uint256) {
        return _countListings.current();
    }

    function getNumberActiveItems() external view returns (uint256) {
        return numberActiveItems;
    }

    function getNumberActiveSalesItems() external view returns (uint256) {
        return numberActiveSalesItems;
    }

    function getNumberUnclaimedSaleItems() external view returns (uint256) {
        return numberUnclaimedSaleItems;
    }

    function getNumberSales() external view returns (uint256) {
        return numberSales;
    }

    // Get minimum token to hold for action
    function getNumberPlantToUpdate() external view returns (uint256) {
        return numberPlantToUpdate;
    }

    function getNumberPlantToSell() external view returns (uint256) {
        return numberPlantToSell;
    }

    function getNumberPlantToBuy() external view returns (uint256) {
        return numberPlantToBuy;
    }

    function getNumberPlantToExtra() external view returns (uint256) {
        return numberPlantToExtra;
    }

    function getNumberPlantToOffer() external view returns (uint256) {
        return numberPlantToOffer;
    }

    // Get Cost of action
    function getCostPlantToUpdate() external view returns (uint256) {
        return costPlantToUpdate;
    }

    function getCostPlantToSell() external view returns (uint256) {
        return costPlantToSell;
    }

    function getCostPlantToBuy() external view returns (uint256) {
        return costPlantToBuy;
    }

    function getCostPlantToExtra() external view returns (uint256) {
        return costPlantToExtra;
    }

    function getCostPlantToOffer() external view returns (uint256) {
        return costPlantToOffer;
    }

    // Get points reward
    function getNumberPointToSell() external view returns (uint256) {
        return numberPointToSell;
    }

    function getNumberPointToBuy() external view returns (uint256) {
        return numberPointToBuy;
    }

    function getNumberPointToExtra() external view returns (uint256) {
        return numberPointToExtra;
    }

    function getNumberPointToOffer() external view returns (uint256) {
        return numberPointToOffer;
    }

    // Get Listings
    function getListingMeta(uint256 _listingId) external view returns (address, uint256, uint256, uint256, bool, bool) {
        return (
            listings[_listingId].seller, 
            listings[_listingId].sellType, 
            listings[_listingId].sellTypeValue, 
            listings[_listingId].blocknumber, 
            listings[_listingId].isSold, 
            listings[_listingId].isActive
        );
    }

    function getListingBuyData(uint256 _listingId) external view returns (bool, address, uint256, uint256) {
        return (
            listings[_listingId].buyNftElseToken,
            listings[_listingId].buyTokenAddress, 
            listings[_listingId].buyTokenId, 
            listings[_listingId].buyCount
        );
    }

    function getListingSellData(uint256 _listingId) external view returns (bool, address, uint256, uint256) {
        return (
            listings[_listingId].sellNftElseToken,
            listings[_listingId].sellTokenAddress, 
            listings[_listingId].sellTokenId, 
            listings[_listingId].sellCount
        );
    }

    function getListingStats(uint256 _listingId) external view returns (uint256, uint256, bool, bool) {
        return (
            countExtraToListingsId[_listingId],
            countOfferToListingsId[_listingId],
            listings[_listingId].isActive,
            listings[_listingId].isCanceled
        );
    }

    // Get Items
    function getItem(uint256 _itemId) external view returns (bool, address, uint256, uint256, uint256, uint256) {
        return (
            items[_itemId].nft,
            items[_itemId].itemAddress,
            items[_itemId].tokenId,
            items[_itemId].countActive,
            items[_itemId].countSold,
            items[_itemId].countUnclaim
        );
    }

    // Get basic eta on listing
    function isListingSold(uint256 _listingId) external view returns (bool) {
        return (listings[_listingId].isSold);
    }

    function isListingActive(uint256 _listingId) external view returns (bool) {
        return (listings[_listingId].isActive);
    }

    function isListingCancel(uint256 _listingId) external view returns (bool) {
        return (listings[_listingId].isCanceled);
    }

    // Internal functions
    function _placeOffer(
        Listing memory _refListing, 
        uint256 _sellTypeValue, 
        address _buyTokenAddress, 
        uint _buyTokenId, 
        uint256 _buyCount, 
        address _sellTokenAddress, 
        uint _sellTokenId, 
        uint256 _sellCount) internal {
        // No offer on offer
        require(_refListing.sellType != 5 && _refListing.sellType != 6 && _refListing.sellType != 7, "No inception on offers");
        // User can't bid on his own listing
        require(_refListing.seller != _msgSender(), "buyer == seller");
        // Verify if the referenced listing is a auction
        if(_refListing.sellType == 1) {
            // Confirm block number is larger than current block.number
            require(_refListing.blocknumber > block.number, "Auction finish");
            // Verify that offer is for same token address and type than listing
            require(_refListing.buyTokenAddress == _buyTokenAddress, "Offer the same buy token address");
            if(_refListing.buyNftElseToken) {
                require(_refListing.buyTokenId == _buyTokenId, "Offer the same buy tokenId");
            }
            require(_refListing.sellTokenAddress == _sellTokenAddress, "Offer the same sell token address");
            if(_refListing.sellNftElseToken) {
                require(_refListing.sellTokenId == _sellTokenId, "Offer the same sell tokenId");
            }
            // Verify is previous offer
            if(countOfferToListingsId[_sellTypeValue] > 0) {
                // Verify that offer is best than best offer
                if(!listings[countOfferToListingsId[_sellTypeValue]].buyNftElseToken) {
                    require(listings[countOfferToListingsId[_sellTypeValue]].buyCount <= _buyCount, "Offer better than buy offer");
                }
                if(!listings[countOfferToListingsId[_sellTypeValue]].sellNftElseToken) {
                    require(listings[countOfferToListingsId[_sellTypeValue]].sellCount <= _sellCount, "Offer better than buy offer");
                }
            }
            else {
                // Verify that offer is higher or equal than minimum offer
                if(!_refListing.buyNftElseToken) {
                    require(_refListing.buyCount <= _buyCount, "Offer better than minimum requirement");
                }
                if(!_refListing.sellNftElseToken) {
                    require(_refListing.sellCount <= _sellCount, "Offer better than minimum requirement");
                }
            }
            _checkPlantHoldingAndPayTxCost(numberPlantToOffer, costPlantToOffer);
        }
    }
    function _moveTokenOrNft(address _address, bool _isSend, bool _isNft, address _tokenAddress, uint256 _tokenId, uint256 _count) internal {
        if(_isNft) {
            if(_isSend) {
                // Transfer Nft to _to
                IERC721(_address).safeTransferFrom(_address, address(this), _tokenId);
            }
            else {
                // Check that this token is own by the user
                require(_address == IERC721(_address).ownerOf(_tokenId), "Error nft allowance");
                // Transfer NFT to this contract
                IERC721(_address).safeTransferFrom(_address, address(this), _tokenId);
            }
        }
        else {
            if(_isSend) {
                // Transfer token to _to
                BEP20(_tokenAddress).transferFrom(_address, address(this), _count);
            }
            else {
                // Check that the user has give allowance to the market
                require(_count <= BEP20(_tokenAddress).allowance(_address, address(this)), "Error token allowance");
                // Transfer token to this contract
                BEP20(_tokenAddress).transferFrom(_address, address(this), _count);
            }
        }
    }
    
    function _isUserActiveGiveTeamId(address _user) internal view returns (uint256) {
        // Get user profile status
        uint256 teamId;
        if(profileActive) {
            bool isUserActive;
            ( , , teamId, , , , isUserActive) = plantswapProfile.getUserProfile(_user);
            // Check user is active
            require(isUserActive, "Profile require");
        }
        return (uint256) (teamId);
    }

    function _increasePoints(address _to, uint256 _teamId, uint256 _points, uint256 _campaignId) internal {
        if(_points > 0 && profileActive) {
            plantswapProfile.increaseUserPoints(_to, _points, _campaignId);
            plantswapProfile.increaseTeamPoints(_teamId, _points, _campaignId);
        }
    }

    function _payTxCost(uint256 _txCost) internal {
        if(_txCost > 0) {
            // Transfer PLANT tokens to this contract
            plantToken.transferFrom(_msgSender(), feesAddress, _txCost);
        }
    }

    function _checkPlantHoldingAndPayTxCost(uint256 _numberPlantToHold, uint256 _txCost) internal {
        if(_numberPlantToHold > 0) {
            require(plantToken.balanceOf(_msgSender()) >= _numberPlantToHold, "Token balance < minimum holding");
        }
        if(_txCost > 0) {
            require(plantToken.balanceOf(_msgSender()) >= _txCost, "Token balance < fees");
            _payTxCost(_txCost);
        }
    }

    function _itemCreateOrAppend(address _itemAddress, bool _isNft, uint256 _tokenId) internal {
        if(itemsIdByAddress[_itemAddress] > 0) {
            // Update the item
            items[itemsIdByAddress[_itemAddress]].countActive += (uint256) (1);    
        }
        else {
            // Create the item
            _countItems.increment();
            uint256 newItemId = (uint256) (_countItems.current()); 
            items[newItemId] = Item({
                nft: (bool) (_isNft),
                itemAddress: (address) (_itemAddress),
                tokenId: (uint256) (_tokenId),
                countActive: (uint256) (1),
                countSold: (uint256) (0), 
                countUnclaim: (uint256) (0)});
            itemsById[newItemId]  = (bool) (true);
            numberActiveItems += (uint256) (1);
            itemsIdByAddress[_itemAddress] = (uint256) (newItemId);
            itemsIdByAddressAndTokenId[_itemAddress][_tokenId] = (uint256) (newItemId);
        }
    }

    function _listingCreation(
        uint8 _sellType, 
        uint256 _sellTypeValue, 
        bool _buyNftElseToken, 
        address _buyTokenAddress, 
        uint256 _buyTokenId, 
        uint256 _buyCount, 
        bool _sellNftElseToken, 
        address _sellTokenAddress, 
        uint256 _sellTokenId, 
        uint256 _sellCount, 
        bool _isActive) internal {

        // increment listingId
        _countListings.increment();
        uint256 newListingId = _countListings.current(); 
        // Create listing
        listings[newListingId] = Listing({
            seller: (address) (_msgSender()),
            sellType: (uint8) (_sellType),
            sellTypeValue: (uint256) (_sellTypeValue),
            blocknumber: (uint256) (block.number),
            buyNftElseToken: (bool) (_buyNftElseToken),
            buyTokenAddress: (address) (_buyTokenAddress),
            buyTokenId: (uint256) (_buyTokenId),
            buyCount: (uint256) (_buyCount),
            sellNftElseToken: (bool) (_sellNftElseToken),
            sellTokenAddress: (address) (_sellTokenAddress),
            sellTokenId: (uint256) (_sellTokenId),
            sellCount: (uint256) (_sellCount),
            isSold: (bool) (false),
            isActive: (bool) (_isActive),
            isCanceled: (bool) (false) });
        listingsById[newListingId]  = (bool) (true);
        numberActiveSalesItems += (uint256) (1);

        // Increment the number of listings the user has
        countListingBySeller[_msgSender()] += (uint256) (1);
        // Log the listing id with the user
        listingsIdBySellerAddress[_msgSender()][countListingBySeller[_msgSender()]] = (uint256) (newListingId);

        // If this is a extra or buy offer
        if(_sellType == 2 || _sellType == 3) {
            // Link the listing together
            extras[_sellTypeValue][countExtraToListingsId[_sellTypeValue]] = (uint256) (newListingId);
            countExtraToListingsId[_sellTypeValue] += (uint256) (1);
        }
        if(_sellType == 5) {
            // Link the listing together
            offers[_sellTypeValue][countOfferToListingsId[_sellTypeValue]] = (uint256) (newListingId);
            countOfferToListingsId[_sellTypeValue] += (uint256) (1);
        }
    }
}