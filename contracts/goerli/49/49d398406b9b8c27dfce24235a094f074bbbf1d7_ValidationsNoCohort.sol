/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity =0.8.0;
// SPDX-License-Identifier: MIT

    
    
interface INodeOperations {

    function increasePOWRewards(address validator, uint256 amount) external ;
    function increaseStakeRewards(address validator) external;
    function increaseDelegatedStakeRewards(address validator) external;
    function returnNodeOperators() external view returns (address[] memory) ;
    function POWFee() external view returns (uint256);
    function returnDelegatorLink(address operator) external view returns (address);
    function isNodeOperator(address operator) external view returns (bool);
    function returnNodeOperatorsCount() external view returns (uint256);
    
    

}





/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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





// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
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


    
    
interface ICohortFactory {

    function returnCohorts(address enterprise) external view returns (address[] memory, uint256[] memory);
    function returnValidatorList(address enterprise, uint256 audit)external view returns(address[] memory);
    function cohortMap(address user, uint256 audit)external view returns(bool);
    function isValidatorInvited(address requestor, address validator, uint256 audit)external view returns(bool, bool);

}



    
interface IAuditToken {
       function mint(address to, uint256 amount) external returns (bool);
}










/**
 * @title Members
 * Allows on creation of Enterprise and Validator accounts and staking of funds by validators
 * Validators and enterprises have ability to withdraw their staking and earnings 
 * Contract also contains several update functions controlled by the Governance contracts
 */

contract Members is  AccessControl {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

   

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant SETTER_ROLE =  keccak256("SETTER_ROLE");

    uint256 public amountTokensPerValidation =  100e18;    //New minted amount per validation

    uint256 public accessFee = 100e18;              // data subscriber fee for access to reports
    uint256 public enterpriseShareSubscriber = 40;  // share of enterprise income from data subscriber fee
    uint256 public validatorShareSubscriber = 40;   // share of validator income from data subscriber fee
    address public platformAddress;                 // address where all platform fees are deposited
    uint256 public platformShareValidation = 15;    // fee from validation
    uint256 public enterpriseMatch = 200;           // percentage to match against amountTokensPerValidation
    uint256 public minDepositDays = 60;             // number of days to considered for calculation of average spendings
    uint256 public requiredQuorum = 60;             // quorum required to consider validation valid
    

    
 
    /// @dev check if caller is a controller     
    modifier isController {
        require(hasRole(CONTROLLER_ROLE, msg.sender), "Members:IsController - Caller is not a controller");

        _;
    }

    /// @dev check if caller is a setter     
    modifier isSetter {
        require(hasRole(SETTER_ROLE, msg.sender), "Members:isSetter - Caller is not a setter");

        _;
    }

     // Audit types to be used. Two types added for future expansion 
    enum UserType {Enterprise, Validator, DataSubscriber}  



    mapping(address => mapping(UserType => string)) public user;
    mapping(address => mapping(UserType => bool)) public userMap;
    address[] public enterprises;
    address[] public validators;
    address[] public dataSubscribers;
    
    event UserAdded(address indexed user, string name, UserType indexed userType);
    event LogDepositReceived(address indexed from, uint amount);
    event LogSubscriptionCompleted(address subscriber, uint256 numberOfSubscriptions);
    event LogGovernanceUpdate(uint256 params, string indexed action);

    

    constructor(address _platformAddress ) {
        require(_platformAddress != address(0), "Members:constructor - Platform address can't be 0");
        platformAddress = _platformAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


     /**
     * @dev to be called by governance to update new amount for required quorum
     * @param _requiredQuorum new value of required quorum
     */
    function updateQuorum(uint256 _requiredQuorum) public isSetter() {
        require(_requiredQuorum != 0, "Members:updateQuorum - New quorum value can't be 0");
        requiredQuorum = _requiredQuorum;
        LogGovernanceUpdate(_requiredQuorum, "updateQuorum");
    }


    /**
    * @dev to be called by Governance contract to update new value for the validation platform fee
    * @param _newFee new value for data subscriber access fee
    */
    function updatePlatformShareValidation(uint256 _newFee) public isSetter() {

        require(_newFee != 0, "Members:updatePlatformShareValidation - New value for the platform fee can't be 0");
        platformShareValidation = _newFee;
        emit LogGovernanceUpdate(_newFee, "updatePlatformShareValidation");
    }

    /**
    * @dev to be called by Governance contract to update new value for data sub access fee
    * @param _accessFee new value for data subscriber access fee
    */
    function updateAccessFee(uint256 _accessFee) public isSetter() {

        require(_accessFee != 0, "Members:updateAccessFee - New value for the access fee can't be 0");
        accessFee = _accessFee;
        emit LogGovernanceUpdate(_accessFee, "updateAccessFee");
    }

     /**
    * @dev to be called by Governance contract to update new amount for validation rewards
    * @param _minDepositDays new value for minimum of days to calculate 
    */
    function updateMinDepositDays(uint256 _minDepositDays) public isSetter() {

        require(_minDepositDays != 0, "Members:updateMinDepositDays - New value for the min deposit days can't be 0");
        minDepositDays = _minDepositDays;
        emit LogGovernanceUpdate(_minDepositDays, "updateMinDepositDays");
    }

    /**
    * @dev to be called by Governance contract to update new amount for validation rewards
    * @param _amountTokensPerValidation new value of reward per validation
    */
    function updateTokensPerValidation(uint256 _amountTokensPerValidation) public isSetter() {

        require(_amountTokensPerValidation != 0, "Members:updateTokensPerValidation - New value for the reward can't be 0");
        amountTokensPerValidation = _amountTokensPerValidation;
        emit LogGovernanceUpdate(_amountTokensPerValidation, "updateRewards");

    }
    
    /**
    * @dev to be called by Governance contract
    * @param _enterpriseMatch new value of enterprise portion of enterprise value of validation cost
    */
    function updateEnterpriseMatch(uint256 _enterpriseMatch) public isSetter()  {

        require(_enterpriseMatch != 0, "Members:updateEnterpriseMatch - New value for the enterprise match can't be 0");
        enterpriseMatch = _enterpriseMatch;
        emit LogGovernanceUpdate(_enterpriseMatch, "updateEnterpriseMatch");

    }

    /**
    * @dev to be called by Governance contract to change enterprise and validators shares
    * of data subscription fees. 
    * @param _enterpriseShareSubscriber  - share of the enterprise
    * @param _validatorShareSubscriber - share of the subscribers
    */
    function updateDataSubscriberShares(uint256 _enterpriseShareSubscriber, uint256 _validatorShareSubscriber ) public isSetter()  {

        // platform share should be at least 10%
        require(_enterpriseShareSubscriber.add(validatorShareSubscriber) <=90, "Enterprise and Validator shares can't be larger than 90");
        enterpriseShareSubscriber = _enterpriseShareSubscriber;
        validatorShareSubscriber = _validatorShareSubscriber;
        emit LogGovernanceUpdate(enterpriseShareSubscriber, "updateDataSubscriberShares:Enterprise");
        emit LogGovernanceUpdate(validatorShareSubscriber, "updateDataSubscriberShares:Validator");
    }

   
    /** 
    * @dev add new platform user
    * @param newUser to add
    * @param name name of the user
    * @param userType  type of the user, enterprise, validator or data subscriber
    */
    function addUser(address newUser, string memory name, UserType userType) public isController() {

        require(!userMap[newUser][userType], "Members:addUser - This user already exist.");
        user[newUser][userType] = name;
        userMap[newUser][userType] = true;

        if (userType == UserType.DataSubscriber) 
            dataSubscribers.push(newUser);
            // dataSubscriberCount++;
        else if (userType == UserType.Validator)
            validators.push(newUser);
            // validatorCount++;
        else if (userType == UserType.Enterprise)
            enterprises.push(newUser);
            // enterpriseCount++;

        // userAddersses.push(newUser);
     
        emit UserAdded(newUser, name, userType);
    }

    function returnValidatorList() public view returns(address[] memory) {

        return validators;
    }

   

}


    
    
interface IValidations {

    enum ValidationStatus {Undefined, Yes, No}        


    function outstandingValidations(address enterprise) external view returns (uint256);
    function returnValidationUrl(bytes32 validationHash, address user) external  view returns(string memory url);
    function returnWinnerPoints(bytes32 validationHash, address user) external  view returns(uint256 plus, uint256 minus);
    function selectWinner(bytes32 validationHash, address[] memory winners) external view returns (address);
    function returnValidatorList(bytes32 validationHash) external view  returns (address[] memory);



     function collectValidationResults(bytes32 validationHash)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            string[] memory,
            bytes32[] memory
        );

    function returnValidationRecord(bytes32 validationHash) external  view
        returns( bool cohort,
                address requestor,
                uint256 validationTime,
                uint256 executionTime,
                string memory url,
                uint256 consensus,
                uint256 validationsCompleted,
                uint64 winnerConfirmations,
                bool paymentSent,
                address winner);

}










/**
 * @title MemberHelpers
 * Additional function for Members
 */
contract MemberHelpers is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    address public auditToken; //AUDT token
    Members members; // Members contract
    IValidations public validations; // Validation interface
    mapping(address => uint256) public deposits; //track deposits per user
    uint256 public minContribution = 5e21;
    uint256 public maxContribution = 25e21;
    

    event LogDepositReceived(address indexed from, uint256 amount);
    event LogDepositRedeemed(address indexed from, uint256 amount);
    event LogIncreaseDeposit(address user, uint256 amount);
    event LogDecreaseDeposit(address user, uint256 amount);

    constructor(address _members, address _auditToken) {
        require(_members != address(0),"MemberHelpers:constructor - Member address can't be 0");
        require(_auditToken != address(0), "MemberHelpers:setCohort - Cohort address can't be 0");

        members = Members(_members);
        auditToken = _auditToken;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev check if caller is a controller
    modifier isController(string memory source) {
        string memory msgError = string(abi.encodePacked("MemberHelpers(isController - Modifier):", source, "- Caller is not a controller"));
        require(hasRole(CONTROLLER_ROLE, msg.sender),msgError);

        _;
    }


     /// @dev check if user is validator
    modifier isValidator(string memory source) {

        string memory msgError = string(abi.encodePacked("NodeOperations(Modifier):", source, "- You are not a validator"));
        require( members.userMap(msg.sender, Members.UserType(1)), msgError);

        _;
    }

    function returnDepositAmount(address user) public view returns (uint256) {
        return deposits[user];
    }

   

    function increaseDeposit(address user, uint256 amount) public isController("increaseDeposit") {
        deposits[user] = deposits[user].add(amount);
        emit LogIncreaseDeposit(user, amount);
    }

    function decreaseDeposit(address user, uint256 amount) public isController("decreaseDepoist") {
        deposits[user] = deposits[user].sub(amount);
        emit LogDecreaseDeposit(user, amount);
    }

    /**
     * @dev Function to accept contribution to staking
     * @param amount number of AUDT tokens sent to contract for staking
     */
    function stake(uint256 amount) public {
        require(amount > 0, "MemberHelpers:stake - Amount can't be 0");

        if (members.userMap(msg.sender, Members.UserType(1))) {
            require(
                amount + deposits[msg.sender] >= minContribution,
                "MemberHelpers:stake - Minimum contribution amount is 5000 AUDT tokens"
            );
            require(
                amount + deposits[msg.sender] <= maxContribution,
                "MemberHelpers:stake - Maximum contribution amount is 25000 AUDT tokens"
            );
        }
        require(
            members.userMap(msg.sender, Members.UserType(0)) ||
                members.userMap(msg.sender, Members.UserType(1)) ||
                members.userMap(msg.sender, Members.UserType(2)),
            "Staking:stake - User has been not registered as a validator or enterprise."
        );
        IERC20(auditToken).safeTransferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] = deposits[msg.sender].add(amount);
        emit LogDepositReceived(msg.sender, amount);
    }

    /**
     * @dev Function to redeem contribution.
     * @param amount number of tokens being redeemed
     */
    function redeem(uint256 amount) public {
        if (members.userMap(msg.sender, Members.UserType(0))) {
            uint256 outstandingVal = validations.outstandingValidations(msg.sender);

            if (outstandingVal > 0)
                // div(1e4) to adjust for four decimal points
                require(
                    deposits[msg.sender].sub(
                        members
                            .enterpriseMatch()
                            .mul(members.amountTokensPerValidation())
                            .mul(outstandingVal)
                            .div(1e4)
                    ) >= amount,
                    "MemberHelpers:redeem - Your deposit will be too low to fullfil your outstanding payments."
                );
        }

        deposits[msg.sender] = deposits[msg.sender].sub(amount);
        IERC20(auditToken).safeTransfer(msg.sender, amount);
        emit LogDepositRedeemed(msg.sender, amount);
    }

    /**
     * @dev to be called by administrator to set Validation address
     * @param _validations validation contract address
     */
    function setValidation(address _validations) public isController("setValidation") {
        require( _validations != address(0), "MemberHelpers:setValidation - Validation address can't be 0");
        validations = IValidations(_validations);
    }

}



pragma experimental ABIEncoderV2;










/**
 * @title DepositModifiers
 * Collection of function which alter deposit values
 */

contract DepositModifiers is  AccessControl {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;



    address public auditToken;                  
    Members members;
    MemberHelpers public memberHelpers;
    ICohortFactory public cohortFactory;
    INodeOperations public nodeOperations;

    mapping(address => DataSubscriberTypes[]) public dataSubscriberCohorts;

    struct DataSubscriberTypes{
        address cohort;
        uint256 audits;
    }

    mapping(address => mapping(address => mapping(uint256 => bool))) public dataSubscriberCohortMap;
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");


    event LogDataSubscriberPaid(address indexed from, uint256 accessFee,  uint256 indexed audits, address enterprise, uint256 enterpriseShare);
    event LogSubscriptionCompleted(address subscriber, uint256 numberOfSubscriptions);
    event LogDataSubscriberValidatorPaid(address  from, address indexed validator, uint256 amount);
    event LogFeesReceived(address indexed validator, uint256 tokens, bytes32 validationHash);
    event LogRewardsDeposited(uint256 tokens, uint256 enterpriseAmount, address indexed enterprise, bytes32 validationHash);
    event LogNonCohortPaymentReceived(address indexed validator, uint256 tokens, bytes32 validationHash);
    event LogNonCohortValidationPaid(address indexed requestor, address winner, bytes32 validationHash, uint256 amount);



    constructor(address  _members, address _auditToken, address _memberHelpers, address _cohortFactory, address _nodeOperations ) {
        require(_members != address(0), "DepositModifier:constructor - Member address can't be 0");
        members = Members(_members);
        auditToken = _auditToken;
        memberHelpers = MemberHelpers(_memberHelpers);
        cohortFactory = ICohortFactory(_cohortFactory);
        nodeOperations = INodeOperations(_nodeOperations);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev check if caller is a controller
    modifier isController(string memory source) {
        string memory msgError = string(abi.encodePacked("DepositModifier - (isController-Modifier):", source, "- Caller is not a controller"));
        require(hasRole(CONTROLLER_ROLE, msg.sender),msgError);

        _;
    }


    /**
    * @dev called when data subscriber initiates subscription 
    * @param enterpriseAddress - address of the enterprise
    * @param audits - type of audits this cohort is part of
    */
    function dataSubscriberPayment(address enterpriseAddress, uint256 audits) public  {

        require(enterpriseAddress != address(0), "DepositModifier:dataSubscriberPayment - Enterprise address can't be 0");
        require(audits >=0 && audits <=5, "DepositModifier:dataSubscriberPayment - Audit type is not in the required range");
        require(!dataSubscriberCohortMap[msg.sender][enterpriseAddress][audits], "DepositModifier:dataSubscriberPayment - You are already subscribed");
        require(members.userMap(msg.sender, Members.UserType(2)), "DepositModifier:dataSubscriberPayment - You have to register as data subscriber");

        uint256 accessFee = members.accessFee();

        require(memberHelpers.returnDepositAmount(msg.sender) >= accessFee, "DepositModifier:dataSubscriberPayment - You don't have enough AUDT to complet this tranasction.");
        IERC20(auditToken).safeTransferFrom(msg.sender, address(this), accessFee);
        uint platformShare = 100 - members.enterpriseShareSubscriber() -members.validatorShareSubscriber();
        IERC20(auditToken).safeTransfer(members.platformAddress(), accessFee.mul(platformShare).div(100));

        if (members.userMap(msg.sender, Members.UserType(2)) || members.userMap(msg.sender, Members.UserType(0))){
            memberHelpers.decreaseDeposit(msg.sender, accessFee);
        }

        uint256 enterpriseShare = accessFee.mul(members.enterpriseShareSubscriber()).div(100);
        memberHelpers.increaseDeposit(enterpriseAddress, enterpriseShare);

        allocateValidatorDataSubscriberFee(enterpriseAddress, audits, accessFee.mul(members.validatorShareSubscriber()).div(100));
        dataSubscriberCohortMap[msg.sender][enterpriseAddress][audits] = true;

        emit LogDataSubscriberPaid(msg.sender, accessFee, audits, enterpriseAddress, enterpriseShare);
    }

    /**
    * @dev To calculate validator share of data subscriber fee and allocate it to validator deposits
    * @param enterprise - address of cohort holding list of validators
    * @param audits - audit type
    * @param amount - total amount of tokens available for allocation
    */
    function allocateValidatorDataSubscriberFee(address enterprise, uint256 audits, uint256 amount) internal  {

        address[] memory cohortValidators = cohortFactory.returnValidatorList(enterprise, audits);
        uint256 totalDeposits;

        for (uint i=0; i < cohortValidators.length; i++){
            totalDeposits = totalDeposits.add(memberHelpers.returnDepositAmount(cohortValidators[i]));
        }

        for (uint i=0; i < cohortValidators.length; i++){
            uint256 oneValidatorPercentage = (memberHelpers.returnDepositAmount(cohortValidators[i]).mul(10e18)).div(totalDeposits);
            uint256 oneValidatorAmount = amount.mul(oneValidatorPercentage).div(10e18);
            memberHelpers.increaseDeposit(cohortValidators[i], oneValidatorAmount);
            emit LogDataSubscriberValidatorPaid(msg.sender, cohortValidators[i], oneValidatorAmount);
        }
    }


    /**
    * @dev To automate subscription for multiple cohorts for data subscriber 
    * @param enterprise - array of enterprise addresses
    * @param audits - array of audit types for each cohort
    */
    function dataSubscriberPaymentMultiple(address[] memory enterprise, uint256[] memory audits) public {

        uint256 length = enterprise.length;
        require(length <= 256, "DepositModifiers:dataSubscriberPaymentMultiple - List too long");
        for (uint256 i = 0; i < length; i++) {
            dataSubscriberPayment(enterprise[i], audits[i]);
        }

        emit LogSubscriptionCompleted(msg.sender, length);
    }

    /**
    * @dev To process payment for cohort validation
    * @param winner - winner of POW
    * @param _requestor - requesting party
    * @param validationHash -  hash identifying validation
    */
    function processPayment(address winner, address _requestor, bytes32 validationHash) public isController("processPayment") {

        uint256 enterprisePortion =  members.amountTokensPerValidation().mul(members.enterpriseMatch()).div(100);
        uint256 platformFee = members.amountTokensPerValidation().mul(members.platformShareValidation()).div(100);
        uint256 winnerFee = members.amountTokensPerValidation().add(enterprisePortion).sub(platformFee);

        memberHelpers.decreaseDeposit(_requestor, enterprisePortion);
        IAuditToken(auditToken).mint(address(this), members.amountTokensPerValidation());
        memberHelpers.increaseDeposit(members.platformAddress(), platformFee);

        memberHelpers.increaseDeposit(winner, winnerFee);
        emit LogFeesReceived(winner, winnerFee, validationHash);
        emit LogRewardsDeposited(winnerFee, enterprisePortion, _requestor, validationHash);
    }


     /**
    * @dev To process payment for no cohort validation
    * @param _winner - winner of the POW
    * @param _requestor - requesting party
    * @param validationHash -  hash identifying validation
    */
    function processNonChortPayment(address _winner, address _requestor, bytes32 validationHash) public isController("processNonChortPayment") {

        uint256 POWFee = nodeOperations.POWFee();
        memberHelpers.decreaseDeposit(_requestor, POWFee);
        nodeOperations.increasePOWRewards(_winner, POWFee);
        emit LogNonCohortValidationPaid(_requestor, _winner, validationHash, POWFee);
    }

    /**
    * @dev To return all cohorts to which data subscriber is subscribed to 
    * @param subscriber - address of the subscriber
    * @return the structure with cohort address and their types for subscriber
    */
    function returnCohortsForDataSubscriber(address subscriber) public view returns(DataSubscriberTypes[] memory){
            return (dataSubscriberCohorts[subscriber]);
    }

}


    
    
interface IValidatinosHelpers {

    function isHashAndTimeCorrect( bytes32 documentHash, uint256 _validationTime) external view returns (bool);
    function returnWinnerStruct(bytes32 validationHash, address contractAddress)external view returns (string memory valUrl, address winner);
    function selectWinner(bytes32 validationHash, address[] memory winners) external view returns (address);
    function determineWinners(bytes32 validationHash) external view returns (address[] memory, uint256);
    function calculateVoteQuorum(bytes32 validationHash, address validationContract) external  view returns (uint256);

}





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

    uint256 private _status;

    constructor() {
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
}













/**
 * @title Validations
 * Allows on validation with and without cohort requested by data subscribers. 
 */
abstract contract Validations is  ReentrancyGuard{
    using SafeMath for uint256;
    Members public members;
    MemberHelpers public memberHelpers;
    DepositModifiers public depositModifiers;
    ICohortFactory public cohortFactory;
    INodeOperations public nodeOperations;
    IValidatinosHelpers public validationHelpers;
    mapping(address => uint256) public outstandingValidations;

    // Audit types to be used. Three types added for future expansion
    enum AuditTypes {Unknown, Financial, System, NFT, Type4, Type5, Type6}

    AuditTypes public audits;

    // Validation can be approved or disapproved. Initial status is undefined.
    enum ValidationStatus {Undefined, Yes, No}        

    struct Validation {
   bool cohort;
        address requestor;
        uint256 validationTime;
        uint256 executionTime;
        string url;
        uint256 consensus;
        uint256 validationsCompleted;
        AuditTypes auditType;
        mapping(address => ValidationStatus) validatorChoice;
        mapping(address => uint256) validatorTime;
        mapping(address => string) validationUrl;
        mapping(address => uint256) winnerVotesPlus;
        mapping(address => uint256) winnerVotesMinus;
        mapping(address => bytes32) validationHash;
        uint64 winnerConfirmations;
        bool paymentSent;
        address winner;
    }

    mapping(bytes32 => Validation) public validations; // track each validation

    event ValidationInitialized(address indexed user, bytes32 validationHash, uint256 initTime, bytes32 documentHash, string url, AuditTypes indexed auditType);
    event ValidatorValidated(address indexed validator, bytes32 indexed documentHash, uint256 validationTime, ValidationStatus decision, string valUrl);
    event RequestExecuted(uint256 indexed audits, address indexed requestor, bytes32 validationHash, bytes32 documentHash, uint256 consensus, uint256 quorum,  uint256 timeExecuted, string url, address[] winners);
    event PaymentProcessed(bytes32 validationHash, address winner, uint256 pointsPlus, uint256 pointsMinus);
    event WinnerVoted(address validator, address winner, bool isValid);


    constructor(address _members, address _memberHelpers, address _cohortFactory, address _depositModifiers, address _nodeOperations, address _validationHelpers) {

        members = Members(_members);
        memberHelpers = MemberHelpers(_memberHelpers);
        cohortFactory = ICohortFactory(_cohortFactory);
        depositModifiers = DepositModifiers(_depositModifiers);
        nodeOperations = INodeOperations(_nodeOperations);
        validationHelpers = IValidatinosHelpers(_validationHelpers);
        // _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    }

   /**
   * @dev verify if requesting party has sufficient funds
   * @param requestor a user whos funds are checked
   * @return true or false 
   */
   function checkIfRequestorHasFunds(address requestor) public virtual view returns (bool) {
      
    }
 
   
    /**
     * @dev to be called by Enterprise to initiate new validation
     * @param documentHash - hash of unique identifier of validated transaction
     * @param url - locatoin of the file on IPFS or other decentralized file storage
     * @param auditType - type of auditing 
     */
    function initializeValidation(bytes32 documentHash, string memory url, AuditTypes auditType, bool isCohort) internal virtual {
        require(documentHash.length > 0, "Validation:initializeValidation - Document hash value can't be 0");

        uint256 validationTime = block.timestamp;
        bytes32 validationHash = keccak256(abi.encodePacked(documentHash, validationTime));

        outstandingValidations[msg.sender]++;
        Validation storage newValidation = validations[validationHash];

        newValidation.url = url; 
        newValidation.validationTime = validationTime;
        newValidation.requestor = msg.sender;
        newValidation.auditType = auditType;
        newValidation.cohort = isCohort;

        emit ValidationInitialized(msg.sender, validationHash, validationTime, documentHash, url, auditType);
    }


    function voteWinner(address[] memory winners, bool[] memory vote,  bytes32 validationHash) public {

        Validation storage validation = validations[validationHash];

        for (uint8 i=0; i< winners.length; i++){
            if (vote[i])
                validation.winnerVotesPlus[winners[i]] =  validation.winnerVotesPlus[winners[i]].add(1);
            else
                validation.winnerVotesMinus[winners[i]] =  validation.winnerVotesMinus[winners[i]].add(1);

            emit WinnerVoted(msg.sender, winners[i], vote[i]);
        }

        validation.winnerConfirmations++;
        uint256 operatorCount = returnValidatorCount();
        uint256 currentQuorum = validation.winnerConfirmations * 100 / operatorCount;
        
        if (currentQuorum >= members.requiredQuorum() && !validation.paymentSent){
            address winner = validationHelpers.selectWinner(validationHash, winners);
            validation.winner = winner;
            validation.paymentSent = true;
            processPayments(validationHash, winner);
        }
    }


    function returnValidatorList(bytes32 validationHash) public view virtual returns (address[] memory);

    function returnValidatorCount() public view virtual returns(uint256);
    
    

    /**
     * @dev Review the validation results
     * @param validationHash - consist of hash of hashed document and timestamp
     * @return array  of validators
     * @return array of stakes of each validatoralidation.requestor
     * @return array of validation choices for each validator
     */
    function collectValidationResults(bytes32 validationHash)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            string[] memory,
            bytes32[] memory
        )
    {
        uint256 j=0;
        Validation storage validation = validations[validationHash];

        address[] memory validatorsList = returnValidatorList(validationHash);
        address[] memory validatorListActive = new address[](validation.validationsCompleted);
        uint256[] memory stake = new uint256[](validation.validationsCompleted);
        uint256[] memory validatorsValues = new uint256[](validation.validationsCompleted);
        uint256[] memory validationTime = new uint256[] (validation.validationsCompleted);
        string[] memory validationUrl = new string[] (validation.validationsCompleted);
        bytes32[] memory reportHash = new bytes32[]  (validation.validationsCompleted);



        for (uint256 i = 0; i < validatorsList.length; i++) {
            if(validation.validatorChoice[validatorsList[i]] != ValidationStatus.Undefined) {
                stake[j] = memberHelpers.returnDepositAmount(validatorsList[i]);
                validatorsValues[j] = uint256(validation.validatorChoice[validatorsList[i]]);
                validationTime[j] = validation.validatorTime[validatorsList[i]];
                validationUrl[j] = validation.validationUrl[validatorsList[i]];
                validatorListActive[j] = validatorsList[i];
                reportHash[j] = validation.validationHash[validatorsList[i]];
                j++;
            }
        }
        return (validatorListActive, stake, validatorsValues, validationTime, validationUrl, reportHash);
    }

    /**
     * @dev validators can check if specific document has been already validated by them
     * @param validationHash - consist of hash of hashed document and timestamp
     * @return validation choices used by validator
     */
    function isValidated(bytes32 validationHash) public view returns (ValidationStatus){
        return validations[validationHash].validatorChoice[msg.sender];
    }
   
    function processPayments(bytes32 validationHash, address winner) internal virtual {
    }


    /**
     * @dev to mark validation as executed. This happens when participation level reached "requiredQuorum"
     * @param validationHash - consist of hash of hashed document and timestamp
     * @param documentHash hash of the document
     */
    function executeValidation(bytes32 validationHash, bytes32 documentHash, uint256 quorum) internal nonReentrant {
       
        Validation storage validation = validations[validationHash];
        validation.executionTime = block.timestamp;

        (address[] memory winners, uint256 consensus) = validationHelpers.determineWinners(validationHash);
        validation.consensus = consensus;
        
        emit RequestExecuted( uint256(validation.auditType), validation.requestor, validationHash, documentHash, consensus, quorum, block.timestamp, validation.url, winners);
        
    }


    /**
     * @dev called by validator to approve or disapprove this validation
     * @param documentHash - hash of validated document
     * @param validationTime - this is the time when validation has been initialized
     * @param decision - one of the ValidationStatus choices cast by validator
     */
        function validate(bytes32 documentHash, uint256 validationTime, ValidationStatus decision, string memory valUrl, bytes32 reportHash) public virtual {

        bytes32 validationHash = keccak256(abi.encodePacked(documentHash, validationTime));
        Validation storage validation = validations[validationHash];
        require(members.userMap(msg.sender, Members.UserType(1)), "Validation:validate - Validator is not authorized.");
        require(validation.validationTime == validationTime, "Validation:validate - the validation params don't match.");
        require(validation.validatorChoice[msg.sender] ==ValidationStatus.Undefined, "Validation:validate - This document has been validated already.");
        require(nodeOperations.returnDelegatorLink(msg.sender) == address(0x0), "Validations:validate - you can't validated because you have delegated your stake");
        require(nodeOperations.isNodeOperator(msg.sender), "Validations:validate - you are not a node operator");
        validation.validatorChoice[msg.sender] = decision;
        validation.validatorTime[msg.sender] = block.timestamp;
        validation.validationUrl[msg.sender] = valUrl;
        validation.validationHash[msg.sender] = reportHash;

        validation.validationsCompleted ++;

        nodeOperations.increaseStakeRewards(msg.sender);
        nodeOperations.increaseDelegatedStakeRewards(msg.sender);

        emit ValidatorValidated(msg.sender, documentHash, validationTime, decision, valUrl);

        uint256 quorum = validationHelpers.calculateVoteQuorum(validationHash, address(this));

        if (quorum >= members.requiredQuorum() && validation.executionTime == 0) {
            executeValidation(validationHash, documentHash, quorum);
        }
    }



    function returnValidationRecord(bytes32 validationHash) public  view
    returns( bool cohort,
            address requestor,
            uint256 validationTime,
            uint256 executionTime,
            string memory url,
            uint256 consensus,
            uint256 validationsCompleted,
            uint64 winnerConfirmations,
            bool paymentSent,
            address winner) {



        Validation storage validation = validations[validationHash];

        cohort = validation.cohort;
        requestor = validation.requestor;
        validationTime = validation.validationTime;
        executionTime = validation.executionTime;
        url = validation.url;
        consensus = validation.consensus;
        validationsCompleted = validation.validationsCompleted;
        winnerConfirmations = validation.winnerConfirmations;
        paymentSent = validation.paymentSent;
        winner = validation.winner;

    }


   function returnValidationUrl(bytes32 validationHash, address user) public  view returns(string memory url) {

        Validation storage validation = validations[validationHash];
        url = validation.validationUrl[user];

    }

     function returnWinnerPoints(bytes32 validationHash, address user) public  view returns(uint256 plus, uint256 minus) {

        Validation storage validation = validations[validationHash];
        plus = validation.winnerVotesPlus[user];
        minus = validation.winnerVotesMinus[user];

    }
   
}








contract ValidationsNoCohort is Validations {
    using SafeMath for uint256;

    constructor(address _members, address _memberHelpers, address _cohortFactory, address _depositModifiers, address _nodeOperations, address _validationHelpers) 
        Validations(_members, _memberHelpers, _cohortFactory, _depositModifiers, _nodeOperations, _validationHelpers){

    }

    /**
    * @dev to be called by data subscriber to initiate new validation
    * @param documentHash - hash of unique identifier of validated transaction
    * @param url - locatoin of the file on IPFS or   function returnValidatorList(bytes32 validationHash) public view override  returns (address[] memory){
    * @param auditType - type of auditing 
    */
    function initializeValidationNoCohort(bytes32 documentHash, string memory url, AuditTypes auditType) public {

        require(checkIfRequestorHasFunds(msg.sender), "ValidationsNoCohort:initializeValidationNoCohort - Not sufficient funds. Deposit additional funds.");
        require(members.userMap(msg.sender, Members.UserType(2)), "ValidationsNoCohort:initializeValidationNoCohort - You have to register as data subscriber");
        super.initializeValidation(documentHash, url, auditType, false);
        
    }

   /**
   * @dev verify if requesting party has sufficient funds
   * @param requestor a user whos funds are checked
   * @return true or false 
   */
      function checkIfRequestorHasFunds(address requestor) public override view returns (bool) {
       if (outstandingValidations[requestor] > 0 )
          return ( memberHelpers.deposits(requestor) > nodeOperations.POWFee().mul(outstandingValidations[requestor]));
       else 
          return true;
    }


    function processPayments(bytes32 validationHash, address winner) internal override { 

        Validation storage validation = validations[validationHash];
        outstandingValidations[validation.requestor] = outstandingValidations[validation.requestor].sub(1);
        depositModifiers.processNonChortPayment(winner, validation.requestor, validationHash);
        emit PaymentProcessed(validationHash, winner, validation.winnerVotesPlus[winner], validation.winnerVotesMinus[winner]);
    }

    function validate(bytes32 documentHash, uint256 validationTime, ValidationStatus decision, string memory valUrl, bytes32 reportHash) public override {
        super.validate(documentHash, validationTime, decision, valUrl, reportHash);
    }

    function returnValidatorCount() public view override returns (uint256){
        return nodeOperations.returnNodeOperatorsCount();
    }

    function returnValidatorList(bytes32 validationHash) public view override  returns (address[] memory){

        address[] memory validatorsList = nodeOperations.returnNodeOperators();
        return validatorsList;
    }


}