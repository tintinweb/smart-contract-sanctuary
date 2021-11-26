/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



pragma solidity ^0.8.0;

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]



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
interface IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]



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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]



pragma solidity ^0.8.0;





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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}


// File contracts/Interface/IMetaArt.sol


pragma solidity ^0.8.0;

interface IMetaArt {
    
    // creator
    function getTokenIdCreator(uint256 tokenId) external view returns (address payable);

    function getCreatorAssistant(address creator) external view returns (address payable);

    function getAssistantCreator(address assistant) external view returns (address payable);

    function getPaymentAddress(uint256 tokenId) external view returns (address payable paymentAddress);



    function setCreatorAssistant(address payable newCreatorAssistantAddress) external;

    function deleteCreatorAssistant(address payable deletingCreatorAssistant) external;

    // MetaData 
    function getCreatorUniqueIPFSHashAddress(string memory _path) external view returns (bool);

    // Mint
    function mint(string memory tokenIPFSPath) external returns (uint256 tokenId);

    function burn(uint256 tokenId) external;

    // Main

    function updateBaseURI(string memory baseURI_) external;

    function creatorRoleMigrateWithNFTs(
        uint256[] memory tokenIds,
        address originalAddress,
        address payable newCreator,
        bytes memory signature
    ) external;


    // ERC721
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

}


// File contracts/Market/RoleUpgradeable.sol


pragma solidity ^0.8.0;


abstract contract RoleUpgradeable is AccessControlUpgradeable {

    bytes32 constant private OPERATOR = "operator";

    function role_init(address admin) internal initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /** ========== external mutative functions ========== */

    function updateAdmin(address _newadmin) external {
        require(_newadmin != address(0), "new address must not be null");
        grantRole(DEFAULT_ADMIN_ROLE, _newadmin);
    }

    function updateOperator(address _newoperator) external {
        require(_newoperator != address(0), "new address must not be null");
        grantRole(OPERATOR, _newoperator);
    }

    function revokeAdmin(address revokingAdmin) external {
        revokeRole(DEFAULT_ADMIN_ROLE, revokingAdmin);
    }

    function revokeOperator(address revokingOperator) external {
        revokeRole(OPERATOR, revokingOperator);
    }

    /** ========== internal view functions ========== */

    function _getSeller(
        address nftContract, 
        uint256 tokenId
        ) internal view returns (address payable seller){

        return seller = payable(IMetaArt(nftContract).ownerOf(tokenId));
    } 


    /** ========== modifier ========== */

    modifier onlyMetaAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "only admin can call");
        _;
    }

    modifier onlyMetaOperator() {
        require(hasRole(OPERATOR, _msgSender()), "only operator can call");
        _;
    }


    uint256[100] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}


// File contracts/Market/SendValueWithFallbackWithdraw.sol


pragma solidity ^0.8.0;




abstract contract SendValueWithFallbackWithdraw is ContextUpgradeable, ReentrancyGuardUpgradeable{
    using AddressUpgradeable for address payable;
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private pendingWithdrawals;

    function pendingWithdrawal(address account) public view returns (uint256) {
        return pendingWithdrawals[account];
    }

    function withdrawfor(address payable account) public nonReentrant {
        uint256 amount = pendingWithdrawals[account];
        require(amount > 0, "no pending funds");
        pendingWithdrawals[account] = 0;
        account.sendValue(amount);

        emit withDrawal(account, amount);
    }

    function _sendValueWithFallbackWithdrawWithLowGasLimit(address payable account, uint256 amount) internal {
        _sendValueWithFallbackWithdraw(account, amount, 20000);
    }

    function _sendValueWithFallbackWithdrawWithMediumGasLimit(address payable account, uint256 amount) internal {
        _sendValueWithFallbackWithdraw(account, amount, 210000);
    }

    function _sendValueWithFallbackWithdraw(address payable account, uint256 amount, uint256 gaslimit) private {
        require(amount > 0, "no enough funds to send");

        (bool success, ) = account.call{value: amount, gas: gaslimit}("");

        if(!success) {
            pendingWithdrawals[account] = pendingWithdrawals[account].add(amount);
            
            emit withDrawPending(account, amount);
        }
    }

    event withDrawPending(address indexed account, uint256 amount);
    event withDrawal(address indexed account, uint256 amount);
}


// File contracts/Market/MarketFeeUpgradeable.sol


pragma solidity ^0.8.0;


abstract contract MarketFeeUpgradeable is 
    RoleUpgradeable, 
    SendValueWithFallbackWithdraw{
    
    uint256 internal constant BASIS_SHARE = 100;
    uint256 private _primaryBasisShare;
    uint256 private _secondBasisShare;
    uint256 private _secondCreatorBasisShare;

    mapping(address => mapping(uint256 => bool)) private firstSaleCompleted;

    address payable private metaTreasury;

    
    // contract init function
    function metafee_init(
        address payable metaTreasury_
    ) internal initializer {
        metaTreasury = metaTreasury_;
    }

    /** ========== external view functions ========== */

    function getFeeConfig() external view returns (
        uint256 __basisShare,
        uint256 __primaryBasisShare,
        uint256 __secondBasisShare,
        uint256 __secondCreatorBasisShare
    ) {
        return (
            __basisShare = BASIS_SHARE,
            __primaryBasisShare = _primaryBasisShare,
            __secondBasisShare = _secondBasisShare,
            __secondCreatorBasisShare = _secondCreatorBasisShare
        );
    }

    function getFees(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external view returns (
        uint256 metaFee,
        uint256 creatorSecondaryFee,
        uint256 ownerFee
    ) {
        (metaFee, , creatorSecondaryFee, , ownerFee) = _getFees (
            nftContract, tokenId, _getSeller(nftContract, tokenId), price
        );
    }



    /** ========== internal mutative functions ========== */

    function _distributeFee (
        address nftContract,
        uint256 tokenId,
        address payable seller,
        uint256 price
    ) internal returns (
            uint256 metaFee,
            uint256 royalties,
            uint256 ownerFee
        ){
        address payable royaltiesRecipientAddress;
        address payable tokenOwner;

        (metaFee, 
        royaltiesRecipientAddress, 
        royalties, 
        tokenOwner, 
        ownerFee) = _getFees(
            nftContract, 
            tokenId, 
            seller, 
            price);

        // whenever the fees are distributed, make 'firstSaleCompleted' is true.
        // if there is a second-sale happening, the state will not be changed.
        firstSaleCompleted[nftContract][tokenId] = true;

        if(royalties > 0) {
            _sendValueWithFallbackWithdrawWithMediumGasLimit(royaltiesRecipientAddress, royalties);
        }

        _sendValueWithFallbackWithdrawWithLowGasLimit(metaTreasury, metaFee);
        _sendValueWithFallbackWithdrawWithMediumGasLimit(tokenOwner, ownerFee);

        emit auctionFeeDistributed(metaFee, royaltiesRecipientAddress, royalties, tokenOwner, ownerFee);
    }

    // the marketfee update function is only able to be called by admin.
    function _updateMarketFee(
        uint256 primaryBasisShare_,
        uint256 secondBasisShare_,
        uint256 secondCreatorBasisShare_
    ) internal {
        require(metaTreasury == _msgSender(), "only treasury address have the right to modify fee setting");
        require(primaryBasisShare_ < BASIS_SHARE, "fess >= 100%");
        require((secondBasisShare_ + secondCreatorBasisShare_) < BASIS_SHARE, "fess >= 100%");

        _primaryBasisShare = primaryBasisShare_;
        _secondBasisShare = secondBasisShare_;
        _secondCreatorBasisShare = secondCreatorBasisShare_;

        emit marketFeeupdated(
            primaryBasisShare_,
            secondBasisShare_,
            secondCreatorBasisShare_
        );
    }

    /** ========== private view functions ========== */

    function _getFees(
        address nftContract,
        uint256 tokenId,
        address payable seller,
        uint256 price
    ) private view returns (
        uint256 metaFee,
        address payable royaltiesRecipientAddress,
        uint256 royalties,
        address payable tokenOwner,
        uint256 owenrFee
    ) {
        // In generallyl, the payment address is creator, but if there is an assistant address,
        // the assistant address will help complete the operation and receive creator revenue or royalties
        address payable _paymentAddress = IMetaArt(nftContract).getPaymentAddress(tokenId);

        uint256 metaFeeShare;

        // 1. If there is a first-sale happening that 'creator/assistant' is owner of the NFT. 
        // And the owner('tokenOwner') will receive all revenue(only sale revenue) excluding platform fee.
        // 2. If there is a second-sale happening that creator is different from owner.
        // creator will have a certain of revenue called royalties by calculating with '__secondCreatorBasisShare'.
        // platform fee will be adjusted by '__secondBasisShare' and the rest of revenue will be sent to owner(seller).
        if(_getIsPrimary(nftContract, tokenId, seller)) {
            metaFeeShare = _primaryBasisShare;
            tokenOwner = _paymentAddress;
        } else {
            metaFeeShare = _secondBasisShare;
            
            if(_paymentAddress != seller) {
                royaltiesRecipientAddress = _paymentAddress;
                royalties = price * (_secondCreatorBasisShare / BASIS_SHARE);
                tokenOwner = seller;
            }
            
        }

        metaFee = price * (metaFeeShare / BASIS_SHARE);
        // If it is first-sale, there is no royalty.
        owenrFee = price - metaFee - royalties;
    }

    // cause assistant have the authority to mint NFT for creator that the first owner of NFT is different.
    // therefore judging first-sale needs two conditions that 'firstSaleCompleted[nftContract][tokenId]' is false,
    // and seller is creator/assistant.
    function _getIsPrimary(address nftContract, uint256 tokenId, address seller) private view returns (bool) {
        address creator = IMetaArt(nftContract).getTokenIdCreator(tokenId);
        address assistant = IMetaArt(nftContract).getCreatorAssistant(creator);
        bool ifFirstSaleRole = creator == seller || assistant == seller;
        return !firstSaleCompleted[nftContract][tokenId] && ifFirstSaleRole;
    }


    /** ========== event ========== */

    event marketFeeupdated (
        uint256 indexed primaryBasisShare,
        uint256 indexed secondBasisShare,
        uint256 indexed secondCreatorBasisShare
    );

    event auctionFeeDistributed(
        uint256 indexed metaFee,
        address indexed royaltiesRecipientAddress,
        uint256 royalties,
        address indexed tokenOwner,
        uint256 owenrFee
    );


    uint256[100] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/cryptography/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}


// File @openzeppelin/contracts-upgradeable/utils/cryptography/[email protected]



pragma solidity ^0.8.0;



/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271Upgradeable.isValidSignature.selector);
    }
}


// File contracts/MigrationSignature.sol


pragma solidity ^0.8.0;



abstract contract MigrationSignature {  


    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function _toEthSignedMessageHash(bytes memory message) internal pure returns (bytes32) {
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(message.length) , message));
    }


    function _requireAuthorizedMigration(
        address originalAddress,
        address newAddress,
        bytes memory signature
    ) internal view {
        require(newAddress != address(0), "Invalid new address");
        bytes32 hash = 
        _toEthSignedMessageHash(
            abi.encodePacked("I authorize Foundation to migrate to", toAsciiString(newAddress))
        );

        require(SignatureCheckerUpgradeable.isValidSignatureNow(originalAddress, hash, signature), "signature is incorrect");
    }
}


// File contracts/Market/AuctionUpgradeable.sol


pragma solidity ^0.8.0;


abstract contract AuctionUpgradeable is 
    MarketFeeUpgradeable,
    MigrationSignature
    {
    
    uint256 public nextAuctionId;

    struct ReserveAuction {
        address nftContract;
        uint256 tokenId;
        address payable seller;
        uint256 duration;
        uint256 extensionDuration;
        uint256 endTime;
        address payable bidder;
        uint256 currentPrice;
    }

    mapping (address => mapping(uint256 => uint256)) private tokenToAuctionId;
    mapping (uint256 => ReserveAuction) private reserveAuctions;

    uint256 private _minIncreasePercent;
    uint256 private _duration;
    uint256 private _extensionDuration;

    uint256 private constant MAX_DURATION = 1000 days;


    function auction_init() internal initializer {
        nextAuctionId = 1;
        _duration = 24 hours;
        _extensionDuration = 15 minutes;
        _minIncreasePercent = 10;  // 10% of BASIS_SHARES
    }


    /** ========== public view functions ========== */

    function getAuctionInformation(uint256 auctionId) public view returns (ReserveAuction memory) {
        return reserveAuctions[auctionId];
    }

    function getTokenToAuctionID(address nftContract, uint256 tokenId) public view returns (uint256) {
        return tokenToAuctionId[nftContract][tokenId];
    }

    function getAuctionConfiguration() public view returns (
        uint256 duration_,
        uint256 extensionDuration_,
        uint256 minIncreasePercent_
    ) {
        duration_ = _duration;
        extensionDuration_ = _extensionDuration;
        minIncreasePercent_ = _minIncreasePercent;
    }
    
    /** ========== external mutative functions ========== */


    // 1. only NFT owner have the rights to create auction entry despite the primary-sale or second-sale
    // 2. when auction is created, it will not countdown until first bid.
    // 3. cause seller(owner) of NFT is not linked to NFT creator or second-saler directly,
    // therefore seller have the authority to migrate the auction to another user who will be new seller.
    // but of course the creator(or assistant if there is one) will have a certain of the royalties after NFT sold.
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 reservePrice
    ) external nonReentrant {

        require(reservePrice > 0, "the reserve price must not be 0");
        require(tokenToAuctionId[nftContract][tokenId] == 0, "sorry, the auction of the NFT has been in progress");
        require(IMetaArt(nftContract).ownerOf(tokenId) == _msgSender(), "sorry, you could not sell NFT which you do not have");

        uint256 auctionId = _getNextAuctionId();
        tokenToAuctionId[nftContract][tokenId] = auctionId;

        reserveAuctions[auctionId] = ReserveAuction( {
            nftContract: nftContract,
            tokenId: tokenId,
            seller: payable(_msgSender()),
            duration: _duration,
            extensionDuration: _extensionDuration,
            endTime: 0,  // endTime is only known once the first bid
            bidder: payable(address(0)), // bidder will be recorded once the placebid() calling
            currentPrice: reservePrice
        });
        
        // once the auction of the NFT has been created, the NFT will be transferred from caller address
        IMetaArt(nftContract).transferFrom(_msgSender(), address(this), tokenId);

        emit auctionCreated(
            nftContract,
            tokenId,
            auctionId,
            _msgSender(),
            _duration,
            _extensionDuration,
            reservePrice
        );
    }

    // the seller of the auction have the authority to update reserve price before first bid.
    function updateAuction(uint256 auctionId, uint256 reservePrice) external {
        ReserveAuction storage reserveAuction = reserveAuctions[auctionId];
        require(reservePrice > 0, "the reserve price must not be 0");
        require(reserveAuction.seller == _msgSender(), "the auction is not yours");
        require(reserveAuction.endTime == 0, "the auction has been in progress");

        reserveAuction.currentPrice = reservePrice;

        emit auctionUpdated(auctionId, reservePrice);
    }

    // the seller of the auction have the authority to cancel the auction before first bid.
    function cancelAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction memory reserveAuction = reserveAuctions[auctionId];
        require(reserveAuction.seller == _msgSender(), "the auction is not yours");
        require(reserveAuction.endTime == 0, "the auction has been in progress");

        delete reserveAuctions[auctionId];
        delete tokenToAuctionId[reserveAuction.nftContract][reserveAuction.tokenId];

        IMetaArt(reserveAuction.nftContract).transferFrom(address(this), reserveAuction.seller, reserveAuction.tokenId);

        emit auctionCancelled(auctionId);
    }

    // user who like the selling NFT could place bid.
    // 1. If it is first bid of the selling NFT, that will trigger countdown of the auction
    // and the default duration is 24 hour which is referring to foundation setting.
    // placed price must higher than reserve price which seller set.
    // 2. If it is second bid of the selling NFT, there are following setting.
    //   1. The same address is not allowed to bid twice.
    //   2. Placed price must higher than _getMinBidAmount().
    //   3. The auction duration is not over.
    //   4. As soon as new bidder is accepted, the privous bid fee will be refund to original bidder.
    // P.S. There is extension duration which allow user place a bid after auction duration is over.
    //      During the extension duration, new bid will update the auction end time until there is no one bid.
    function placeBid(uint256 auctionId) external payable nonReentrant {
        ReserveAuction storage reserveAuction = reserveAuctions[auctionId];
        require(reserveAuction.currentPrice > 0, "auction is invalid");

        if(reserveAuction.endTime == 0 && reserveAuction.bidder == address(0)) {
            require(msg.value >= reserveAuction.currentPrice, "bid must be at least the reserve price");

            reserveAuction.currentPrice = msg.value;
            reserveAuction.bidder = payable(_msgSender());
            reserveAuction.endTime = block.timestamp + reserveAuction.duration;
        } else {
            require(reserveAuction.endTime > block.timestamp, "sorry, the auction is over");
            require(reserveAuction.bidder != address(0) && reserveAuction.bidder != _msgSender(), "the bidder is not allowed bid twice");
            require(msg.value > _getMinBidAmount(reserveAuction.currentPrice), "bid amount is too low");

            uint256 originalPrice= reserveAuction.currentPrice;
            address payable originalBidder = reserveAuction.bidder;
            
            reserveAuction.currentPrice = msg.value;
            reserveAuction.bidder = payable(_msgSender());

            // If there is no one bid in extensionDuration after endTime, the last bidder will get the NFT
            if(reserveAuction.endTime - block.timestamp < reserveAuction.extensionDuration) {
                reserveAuction.endTime = block.timestamp + reserveAuction.extensionDuration;
            }

            _sendValueWithFallbackWithdrawWithLowGasLimit(originalBidder, originalPrice);
        }

        emit auctionBidPlaced(auctionId, _msgSender(), msg.value, reserveAuction.endTime);
    }

    // Anyone has the authority to finalize the closing auction.
    function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction storage reserveAuction = reserveAuctions[auctionId];

        require(reserveAuction.endTime > 0 && reserveAuction.bidder != address(0), "the auction is still waitting to bid");
        require(reserveAuction.endTime - block.timestamp > reserveAuction.extensionDuration, "the auction is still in the last extension duration"); 

        delete reserveAuctions[auctionId];
        delete tokenToAuctionId[reserveAuction.nftContract][reserveAuction.tokenId];

        IMetaArt(reserveAuction.nftContract).transferFrom(address(this), reserveAuction.bidder, reserveAuction.tokenId);

        (uint256 metaFee, 
        uint256 royalties, 
        uint256 ownerFee) = _distributeFee(
            reserveAuction.nftContract, 
            reserveAuction.tokenId, 
            reserveAuction.seller, 
            reserveAuction.currentPrice);

        emit auctionFinalized(auctionId, reserveAuction.seller, reserveAuction.bidder, metaFee, royalties, ownerFee);
    }

    // even though the auction has started, admin can still cancel reserve auction but need reasonable reason.
    function _adminCancelReserceAuction(uint256 auctionId, string memory reason) internal  {
        ReserveAuction memory reserveAuction = reserveAuctions[auctionId];
        require(bytes(reason).length > 0, "cancellation reason is necessary");
        require(reserveAuction.currentPrice > 0, "the auction not found");
        
        delete reserveAuctions[auctionId];
        delete tokenToAuctionId[reserveAuction.nftContract][reserveAuction.tokenId];

        IMetaArt(reserveAuction.nftContract).transferFrom(address(this), reserveAuction.seller, reserveAuction.tokenId);

        if(reserveAuction.bidder != address(0)) {
            _sendValueWithFallbackWithdrawWithLowGasLimit(reserveAuction.bidder, reserveAuction.currentPrice);
        }

        emit auctionCancelledbyAdmin(auctionId, reason);
    }


    // Auction migration will transfer the revenue of NFT selling as well.
    function auctionMigration(
        uint256[] calldata auctionIds,
        address originalAddress,
        address payable newAddress,
        bytes calldata signature) external {
            // original address must sign the migration operation through meta site.
            _requireAuthorizedMigration(originalAddress, newAddress, signature);

            for(uint256  i = 0; i < auctionIds.length; i++) {
                uint256 auctionId = auctionIds[i];
                ReserveAuction storage reserveAuction = reserveAuctions[auctionId];

                require(reserveAuction.seller == originalAddress, "The migrating auction is not created by original address");
                reserveAuction.seller = newAddress;
                
                emit reserveAuctionMigrated(auctionId, originalAddress, newAddress);
            }
            
    }

    /** ========== internal mutative functions ========== */
    function _getNextAuctionId() internal returns (uint256) {
        return nextAuctionId++;
    }

    function _updateAuctionConfig(
        uint256 minIncreasePercent_,
        uint256 duration_,
        uint256 extensionDuration_
    ) internal {
        require(duration_ < MAX_DURATION, "new value must be lower than 'MAX_DURATION'");
        require(duration_ > extensionDuration_, "auction duration must higher than extension duration");

        _minIncreasePercent = minIncreasePercent_;
        _duration = duration_;
        _extensionDuration = extensionDuration_;

        emit auctionConfigUpdated(minIncreasePercent_, duration_, extensionDuration_);
    }

    /** ========== internal view functions ========== */

    function _getMinBidAmount(uint256 currentPrice) internal view returns (uint256) {
        uint256 minIncreament = currentPrice * (_minIncreasePercent / BASIS_SHARE);
        
        return minIncreament + currentPrice;
    }

    /** ========== event ========== */
    event auctionCreated(
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 indexed auctionId,
        address seller,
        uint256 duration,
        uint256 extensionDuration,
        uint256 reservePrice
    );

    event auctionUpdated(
        uint256 indexed auctionId, 
        uint256 reservePrice
    );

    event auctionCancelled(uint256 indexed auctionId);

    event auctionBidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 price,
        uint256 endTime
    );

    event auctionFinalized(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed bidder,
        uint256 metafee,
        uint256 creatorfee,
        uint256 ownerfee
    );

    event auctionCancelledbyAdmin(
        uint256 indexed auctionId, 
        string reason
    );

    event reserveAuctionMigrated(
        uint256 indexed auctionId, 
        address indexed originalAddress, 
        address newAddress
    );

    event auctionConfigUpdated(
        uint256 indexed minIncreasePercent_,
        uint256 indexed duration_,
        uint256 indexed extensionDuration_
    );


    uint256[100] private __gap;
}


// File contracts/Market/Market.sol


pragma solidity ^0.8.0;


contract MTT is 
    Initializable,
    RoleUpgradeable, 
    SendValueWithFallbackWithdraw,
    MarketFeeUpgradeable, 
    AuctionUpgradeable
    {


    function market_init(        
        address payable metaTreasury_,
        address admin
        ) external initializer {
        auction_init();
        metafee_init(metaTreasury_);
        role_init(admin);
    }

    function adminUpdateConfig(
        uint256 primaryBasisShare_,
        uint256 secondBasisShare_,
        uint256 secondCreatorBasisShare_,
        uint256 minIncreasePercent_,
        uint256 duration_,
        uint256 extensionDuration_
    ) external onlyMetaAdmin {
        _updateMarketFee(primaryBasisShare_, secondBasisShare_, secondCreatorBasisShare_);
        _updateAuctionConfig(minIncreasePercent_, duration_, extensionDuration_);
    }


    function adminCancelReserveAuction(uint256 auctionId, string memory reason) external onlyMetaAdmin {
        _adminCancelReserceAuction(auctionId, reason);
    }


    uint256[100] private __gap;
}