//SourceUnit: iNCNInvestments_flat.sol

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




/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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




interface INiceCashNetwork {
    function users(address _user) external view returns(address payable,uint256, uint8, uint8, uint,uint,uint);
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
        return msg.data;
    }
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







/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}







interface iNCNInterface is IERC20 {
    function mint(address _to, uint256 _amount) external;
    function bulkMint(address[] memory _to, uint256[] memory _amount) external;
    function burn(address _from, uint256 _amount) external;
    function lock(address _from, uint256 _amount) external returns (uint256);
    function unlock(address _from, uint256 _lockIndex) external;
    function availableBalance(address _user) external view returns (uint256);
}


contract iNCNInvestments is AccessControl {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for iNCNInterface;

    iNCNInterface public incn;
    IERC20Metadata public usdt;
    address public network;

    Product[] public products;

    mapping(address => User) public users;

    enum DealStatus {
        Open,
        Pending,
        Closed
    }

    struct Product {
        uint256 price; //product price in USDT
        uint16 maxAmount; //% of allocation
        uint256 minAmount; //min amount of product available for sale (in USDT)
        uint64 term; //product term
        bool isTokenBurned; //a flag that determines either iNCN is burned or locked
        bool isActive;
        uint8 minPackNeeded; //min pack number required to buy the product
    }

    struct User {
        uint256 rewardAccrured;
        uint256 rewardPaid;
        Deal[] deals;
        mapping(uint256 => uint256) productLimitsUsed; //in USDT
    }

    struct Deal {
        uint32 productID; //ID of the product in products array
        DealStatus status;
        uint64 startTime; //deal operation time
        uint64 endTime; // startTime+Product.term essentially
        uint256 amountPaid; //amount paid by user in USDT
        uint256 price; //momentum price of the product in USDT (6 decimals) when it was bought by user
        uint256 priceRewardCollectedFor; //a price value of the product at the movement of last reward calculation for user (6 decimals)
        uint256 lockID;
    }

    event ProductAdded(uint256 indexed productID);
    event ProductUpdated(uint256 indexed productID);
    event Investment(
        address indexed user,
        uint256 indexed productID,
        uint256 indexed dealID,
        uint256 amountPaid
    );
    event DealProlongated(
        address indexed user,
        uint256 indexed productID,
        uint256 indexed dealID,
        uint64 endTime,
        uint256 price
    );
    event DealClosed(
        address indexed user,
        uint256 indexed productID,
        uint256 indexed dealID
    );
    event RewardClaimed(address indexed user, uint256 rewardPaid);

    constructor(
        address usdToken,
        address iNCNToken,
        address networkAddress
    ) {
        incn = iNCNInterface(iNCNToken);
        usdt = IERC20Metadata(usdToken);
        network = networkAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setProduct(
        uint256 productID,
        uint256 _price,
        uint256 _minAmount,
        uint16 _maxAmount,
        uint64 _term,
        bool _tokenBurned,
        bool _isActive,
        uint8 _minPackNeeded
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (products.length > productID) {
            products[productID].price = _price;
            products[productID].maxAmount = _maxAmount;
            products[productID].minAmount = _minAmount;
            products[productID].term = _term;
            products[productID].isTokenBurned = _tokenBurned;
            products[productID].isActive = _isActive;
            products[productID].minPackNeeded = _minPackNeeded;
            emit ProductUpdated(productID);
        } else {
            products.push(
                Product({
                    price: _price,
                    maxAmount: _maxAmount,
                    minAmount: _minAmount, //min amount of product available for sale (in USDT)
                    term: _term, //product term
                    isTokenBurned: _tokenBurned, //a flag that determines either iNCN is burned or locked
                    isActive: _isActive,
                    minPackNeeded: _minPackNeeded
                })
            );

            emit ProductAdded(products.length - 1);
        }
    }

    function updateProductPrice(uint256 productID, uint256 newPrice)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(products.length > productID, "Invalid productID");
        products[productID].price = newPrice;
        emit ProductUpdated(productID);
    }

    function activateProduct(uint256 productID)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(products.length > productID, "Invalid productID");
        require(
            products[productID].isActive == false,
            "Product is already activated"
        );
        products[productID].isActive = true;
        emit ProductUpdated(productID);
    }

    function deactivateProduct(uint256 productID)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(products.length > productID, "Invalid productID");
        require(
            products[productID].isActive == true,
            "Product is already deactivated"
        );
        products[productID].isActive = false;
        emit ProductUpdated(productID);
    }

    function withdrawUSDT(uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            usdt.balanceOf(address(this)) >= amount,
            "Not enough USDT balance on the contract"
        );
        usdt.safeTransfer(msg.sender, amount);
    }

    function closeDeal(address _user, uint256 _dealID)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(users[_user].deals.length > _dealID, "Deal doesn't exists");
        require(
            users[_user].deals[_dealID].status == DealStatus.Pending,
            "Status invalid"
        );
        users[_user].deals[_dealID].status = DealStatus.Closed;
        emit DealClosed(_user, users[_user].deals[_dealID].productID, _dealID);
    }

    function invest(uint256 _productID, uint256 _amountPaid) public {
        require(products.length > _productID, "Invalid productID");
        require(products[_productID].isActive, "Product inactive");
        require(
            products[_productID].minAmount <= _amountPaid,
            "Product amount is less then minimum required"
        );
        {
            (uint256 packageLimit, uint8 pack, address ref) = userPackageLimit(
                msg.sender
            );
            require(ref != address(0), "User is not registered in the network");
            require(
                products[_productID].minPackNeeded <= pack,
                "Upgrade your pack to use this product"
            );
            require(
                ((packageLimit * products[_productID].maxAmount) / 100) >=
                    _amountPaid +
                        users[msg.sender].productLimitsUsed[_productID],
                "Amount exceed package limit"
            );
        }

        //receive payment
        require(
            _amountPaid >= incn.availableBalance(msg.sender),
            "Not enough iNCN tokens available"
        );
        usdt.safeTransferFrom(msg.sender, address(this), _amountPaid);
        //burn or lock iNCN

        if (products[_productID].isTokenBurned) {
            incn.burn(msg.sender, _amountPaid);
            //fill in the deal
            users[msg.sender].deals.push(
                Deal({
                    productID: uint32(_productID), //ID of the product in products array
                    status: DealStatus.Pending,
                    startTime: uint64(block.timestamp), //deal operation time
                    endTime: uint64(
                        block.timestamp + products[_productID].term
                    ), // startTime+Product.term essentially
                    amountPaid: _amountPaid, //amount bought
                    price: products[_productID].price, //price bought
                    priceRewardCollectedFor: products[_productID].price, //a price
                    lockID: 0
                })
            );
        } else {
            uint256 _lockID = incn.lock(msg.sender, _amountPaid) + 1; //shifted lockID!!!

            users[msg.sender].deals.push(
                Deal({
                    productID: uint32(_productID), //ID of the product in products array
                    status: DealStatus.Open,
                    startTime: uint64(block.timestamp), //deal operation time
                    endTime: uint64(
                        block.timestamp + products[_productID].term
                    ), // startTime+Product.term essentially
                    amountPaid: _amountPaid, //amount bought
                    price: products[_productID].price, //price bought
                    priceRewardCollectedFor: products[_productID].price, //a price
                    lockID: _lockID
                })
            );
        }

        users[msg.sender].productLimitsUsed[_productID] += _amountPaid;

        emit Investment(
            msg.sender,
            _productID,
            users[msg.sender].deals.length - 1,
            _amountPaid
        );
    }

    function claimInitialState(uint256 dealID) public {
        require(users[msg.sender].deals.length > dealID, "Deal doesn't exists");
        require(
            users[msg.sender].deals[dealID].status == DealStatus.Open,
            "Status invalid"
        );
        require(
            users[msg.sender].deals[dealID].endTime < block.timestamp,
            "Deal has not expired yet"
        );
        require(
            users[msg.sender].deals[dealID].lockID > 0,
            "Deal has no iNCN tokens locked"
        );
        incn.unlock(msg.sender, users[msg.sender].deals[dealID].lockID - 1);
        usdt.safeTransfer(msg.sender, users[msg.sender].deals[dealID].amountPaid);
        users[msg.sender].productLimitsUsed[users[msg.sender].deals[dealID].productID] -= users[msg.sender].deals[dealID].amountPaid;
        users[msg.sender].deals[dealID].status = DealStatus.Closed;
        emit DealClosed(msg.sender, users[msg.sender].deals[dealID].productID, dealID);
    }

    function prolongate(uint256 dealID) public {
        require(users[msg.sender].deals.length > dealID, "Deal doesn't exists");
        require(
            users[msg.sender].deals[dealID].status == DealStatus.Open,
            "Status invalid"
        );
        require(
            products[users[msg.sender].deals[dealID].productID].isActive,
            "Product is not active"
        );
        require(
            !products[users[msg.sender].deals[dealID].productID].isTokenBurned,
            "Product deal can not be prolongated"
        );

        users[msg.sender].deals[dealID].endTime += products[
            users[msg.sender].deals[dealID].productID
        ].term;
        users[msg.sender].deals[dealID].price = products[
            users[msg.sender].deals[dealID].productID
        ].price;

        emit DealProlongated(
            msg.sender,
            users[msg.sender].deals[dealID].productID,
            dealID,
            users[msg.sender].deals[dealID].endTime,
            users[msg.sender].deals[dealID].price
        );
    }

    function claimReward() public {
        for (uint256 i = 0; i < users[msg.sender].deals.length; i++) {
            (uint256 currentPrice, uint256 reward) = accureRewardForDeal(
                msg.sender,
                i
            );
            if (reward > 0) {
                users[msg.sender].rewardAccrured += reward;
                users[msg.sender]
                    .deals[i]
                    .priceRewardCollectedFor = currentPrice;
            }
        }

        uint256 rewardToPay = users[msg.sender].rewardAccrured -
            users[msg.sender].rewardPaid;
        if (rewardToPay > 0) {
            users[msg.sender].rewardPaid = users[msg.sender].rewardAccrured;
            usdt.safeTransfer(msg.sender, rewardToPay);
        }
        emit RewardClaimed(msg.sender, rewardToPay);
    }

    function accureRewardForDeal(address _user, uint256 _dealID)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 prevPrice = users[_user].deals[_dealID].priceRewardCollectedFor;
        uint256 currentPrice = products[users[_user].deals[_dealID].productID]
            .price;
        uint256 reward = (currentPrice > prevPrice)
            ? (((currentPrice - prevPrice) *
                users[_user].deals[_dealID].amountPaid) /
                users[_user].deals[_dealID].price)
            : 0;
        return (currentPrice, reward);
    }

    function userPackageLimit(address user)
        public
        view
        returns (
            uint256,
            uint8,
            address
        )
    {
        (address ref, , uint8 pack, , , , ) = INiceCashNetwork(network).users(
            user
        );
        uint256 packageLimit = (2**(pack + 8) - 128) * (10**6);
        return (packageLimit, pack, ref);
    }

    function pendingRewardToClaim(address _user)
        internal
        view
        returns (uint256)
    {
        uint256 rewardAccuredInternal = users[_user].rewardAccrured;
        for (uint256 i = 0; i < users[_user].deals.length; i++) {
            uint256 prevPrice = users[_user].deals[i].priceRewardCollectedFor;
            uint256 currentPrice = products[users[_user].deals[i].productID]
                .price;
            uint256 reward = (currentPrice > prevPrice)
                ? (((currentPrice - prevPrice) *
                    users[_user].deals[i].amountPaid) /
                    users[_user].deals[i].price)
                : 0;
            rewardAccuredInternal += reward;
        }

        return rewardAccuredInternal - users[_user].rewardPaid;
    }
}