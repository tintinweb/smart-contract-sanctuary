// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/IAccessControl.sol";

/**
 * @dev This contract is fully forked from OpenZeppelin `AccessControl`.
 * The only difference is the removal of the ERC165 implementation as it's not
 * needed in Angle.
 *
 * Contract module that allows children to implement role-based access
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
abstract contract AccessControl is Context, IAccessControl {
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
    function grantRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) external override {
        require(account == _msgSender(), "71");

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
    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/// @title IAccessControl
/// @author Forked from OpenZeppelin
/// @notice Interface for `AccessControl` contracts
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IStakingRewards.sol";

/// @title IRewardsDistributor
/// @author Angle Core Team, inspired from Fei protocol
/// (https://github.com/fei-protocol/fei-protocol-core/blob/master/contracts/staking/IRewardsDistributor.sol)
/// @notice Rewards Distributor interface
interface IRewardsDistributor {
    // ========================= Public Parameter Getter ===========================

    function rewardToken() external view returns (IERC20);

    // ======================== External User Available Function ===================

    function drip(IStakingRewards stakingContract) external returns (uint256);

    // ========================= Governor Functions ================================

    function governorWithdrawRewardToken(uint256 amount, address governance) external;

    function governorRecover(
        address tokenAddress,
        address to,
        uint256 amount,
        IStakingRewards stakingContract
    ) external;

    function setUpdateFrequency(uint256 _frequency, IStakingRewards stakingContract) external;

    function setIncentiveAmount(uint256 _incentiveAmount, IStakingRewards stakingContract) external;

    function setAmountToDistribute(uint256 _amountToDistribute, IStakingRewards stakingContract) external;

    function setDuration(uint256 _duration, IStakingRewards stakingContract) external;

    function setStakingContract(
        address _stakingContract,
        uint256 _duration,
        uint256 _incentiveAmount,
        uint256 _dripFrequency,
        uint256 _amountToDistribute
    ) external;

    function setNewRewardsDistributor(address newRewardsDistributor) external;

    function removeStakingContract(IStakingRewards stakingContract) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IStakingRewardsFunctions
/// @author Angle Core Team
/// @notice Interface for the staking rewards contract that interact with the `RewardsDistributor` contract
interface IStakingRewardsFunctions {
    function notifyRewardAmount(uint256 reward) external;

    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 tokenAmount
    ) external;

    function setNewRewardsDistribution(address newRewardsDistribution) external;
}

/// @title IStakingRewards
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables
interface IStakingRewards is IStakingRewardsFunctions {
    function rewardToken() external view returns (IERC20);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./RewardsDistributorEvents.sol";

/// @notice Distribution parameters for a given contract
struct StakingParameters {
    // Amount of rewards distributed since the beginning
    uint256 distributedRewards;
    // Last time rewards were distributed to the staking contract
    uint256 lastDistributionTime;
    // Frequency with which rewards should be given to the underlying contract
    uint256 updateFrequency;
    // Number of tokens distributed for the person calling the update function
    uint256 incentiveAmount;
    // Time at which reward distribution started for this reward contract
    uint256 timeStarted;
    // Amount of time during which rewards will be distributed
    uint256 duration;
    // Amount of tokens to distribute to the concerned contract
    uint256 amountToDistribute;
}

/// @title RewardsDistributor
/// @author Angle Core Team (forked form FEI Protocol)
/// @notice Controls and handles the distribution of governance tokens to the different staking contracts of the protocol
/// @dev Inspired from FEI contract:
/// https://github.com/fei-protocol/fei-protocol-core/blob/master/contracts/staking/FeiRewardsDistributor.sol
contract RewardsDistributor is RewardsDistributorEvents, IRewardsDistributor, AccessControl {
    using SafeERC20 for IERC20;

    /// @notice Role for governors only
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    /// @notice Role for guardians and governors
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    // ============================ Reference to a contract ========================

    /// @notice Token used as a reward
    IERC20 public immutable override rewardToken;

    // ============================== Parameters ===================================

    /// @notice Maps a `StakingContract` to its distribution parameters
    mapping(IStakingRewards => StakingParameters) public stakingContractsMap;

    /// @notice List of all the staking contracts handled by the rewards distributor
    /// Used to be able to change the rewards distributor and propagate a new reference to the underlying
    /// staking contract
    IStakingRewards[] public stakingContractsList;

    // ============================ Constructor ====================================

    /// @notice Initializes the distributor contract with a first set of parameters
    /// @param governorList List of the governor addresses of the protocol
    /// @param guardian The guardian address, optional
    /// @param rewardTokenAddress The ERC20 token to distribute
    constructor(
        address[] memory governorList,
        address guardian,
        address rewardTokenAddress
    ) {
        require(rewardTokenAddress != address(0) && guardian != address(0), "0");
        require(governorList.length > 0, "47");
        rewardToken = IERC20(rewardTokenAddress);
        // Since this contract is independent from the rest of the protocol
        // When updating the governor list, governors should make sure to still update the roles
        // in this contract
        _setRoleAdmin(GOVERNOR_ROLE, GOVERNOR_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, GOVERNOR_ROLE);
        for (uint256 i = 0; i < governorList.length; i++) {
            require(governorList[i] != address(0), "0");
            _setupRole(GOVERNOR_ROLE, governorList[i]);
            _setupRole(GUARDIAN_ROLE, governorList[i]);
        }
        _setupRole(GUARDIAN_ROLE, guardian);
    }

    // ============================ External Functions =============================

    /// @notice Sends reward tokens to the staking contract
    /// @param stakingContract Reference to the staking contract
    /// @dev The way to pause this function is to set `updateFrequency` to infinity,
    /// or to completely delete the contract
    /// @dev A keeper calling this function could be frontran by a miner seeing the potential profit
    /// from calling this function
    /// @dev This function automatically computes the amount of reward tokens to send to the staking
    /// contract based on the time elapsed since the last drip, on the amount to distribute and on
    /// the duration of the distribution
    function drip(IStakingRewards stakingContract) external override returns (uint256) {
        StakingParameters storage stakingParams = stakingContractsMap[stakingContract];
        require(stakingParams.duration > 0, "80");
        require(_isDripAvailable(stakingParams), "81");

        uint256 dripAmount = _computeDripAmount(stakingParams);
        stakingParams.lastDistributionTime = block.timestamp;
        require(dripAmount != 0, "82");
        stakingParams.distributedRewards += dripAmount;
        emit Dripped(msg.sender, dripAmount, address(stakingContract));

        rewardToken.safeTransfer(address(stakingContract), dripAmount);
        IStakingRewards(stakingContract).notifyRewardAmount(dripAmount);
        _incentivize(stakingParams);

        return dripAmount;
    }

    // =========================== Governor Functions ==============================

    /// @notice Sends tokens back to governance treasury or another address
    /// @param amount Amount of tokens to send back to treasury
    /// @param to Address to send the tokens to
    /// @dev Only callable by governance and not by the guardian
    function governorWithdrawRewardToken(uint256 amount, address to) external override onlyRole(GOVERNOR_ROLE) {
        emit RewardTokenWithdrawn(amount);
        rewardToken.safeTransfer(to, amount);
    }

    /// @notice Function to withdraw ERC20 tokens that could accrue on a staking contract
    /// @param tokenAddress Address of the ERC20 to recover
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    /// @param stakingContract Reference to the staking contract
    /// @dev A use case would be to claim tokens if the staked tokens accumulate rewards or if tokens were
    /// mistakenly sent to staking contracts
    function governorRecover(
        address tokenAddress,
        address to,
        uint256 amount,
        IStakingRewards stakingContract
    ) external override onlyRole(GOVERNOR_ROLE) {
        stakingContract.recoverERC20(tokenAddress, to, amount);
    }

    /// @notice Sets a new rewards distributor contract and automatically makes this contract useless
    /// @param newRewardsDistributor Address of the new rewards distributor contract
    /// @dev This contract is not upgradeable, setting a new contract could allow for upgrades, which should be
    /// propagated across all staking contracts
    /// @dev This function transfers all the reward tokens to the new address
    /// @dev The new rewards distributor contract should be initialized correctly with all the staking contracts
    /// from the staking contract list
    function setNewRewardsDistributor(address newRewardsDistributor) external override onlyRole(GOVERNOR_ROLE) {
        // Checking the compatibility of the reward tokens. It is checked at the initialization of each staking contract
        // in the `setStakingContract` function that reward tokens are compatible with the `rewardsDistributor`. If
        // the `newRewardsDistributor` has a compatible rewards token, then all staking contracts will automatically be
        // compatible with it
        require(address(IRewardsDistributor(newRewardsDistributor).rewardToken()) == address(rewardToken), "83");
        require(newRewardsDistributor != address(this), "84");
        for (uint256 i = 0; i < stakingContractsList.length; i++) {
            stakingContractsList[i].setNewRewardsDistribution(newRewardsDistributor);
        }
        rewardToken.safeTransfer(newRewardsDistributor, rewardToken.balanceOf(address(this)));
        // The functions `setStakingContract` should then be called for each staking contract in the `newRewardsDistributor`
        emit NewRewardsDistributor(newRewardsDistributor);
    }

    /// @notice Deletes a staking contract from the staking contract map and removes it from the
    /// `stakingContractsList`
    /// @param stakingContract Contract to remove
    /// @dev Allows to clean some space and to avoid keeping in memory contracts which became useless
    /// @dev It is also a way governance has to completely stop rewards distribution from a contract
    function removeStakingContract(IStakingRewards stakingContract) external override onlyRole(GOVERNOR_ROLE) {
        uint256 indexMet;
        uint256 stakingContractsListLength = stakingContractsList.length;
        require(stakingContractsListLength >= 1, "80");
        for (uint256 i = 0; i < stakingContractsListLength - 1; i++) {
            if (stakingContractsList[i] == stakingContract) {
                indexMet = 1;
                stakingContractsList[i] = stakingContractsList[stakingContractsListLength - 1];
                break;
            }
        }
        require(indexMet == 1 || stakingContractsList[stakingContractsListLength - 1] == stakingContract, "80");

        stakingContractsList.pop();

        delete stakingContractsMap[stakingContract];
        emit DeletedStakingContract(address(stakingContract));
    }

    // =================== Guardian Functions (for parameters) =====================

    /// @notice Notifies and initializes a new staking contract
    /// @param _stakingContract Address of the staking contract
    /// @param _duration Time frame during which tokens will be distributed
    /// @param _incentiveAmount Incentive amount given to keepers calling the update function
    /// @param _updateFrequency Frequency when it is possible to call the update function and give tokens to the staking contract
    /// @param _amountToDistribute Amount of gov tokens to give to the staking contract across all drips
    /// @dev Called by governance to activate a contract
    /// @dev After setting a new staking contract, everything is as if the contract had already been set for `_updateFrequency`
    /// meaning that it is possible to `drip` the staking contract immediately after that
    function setStakingContract(
        address _stakingContract,
        uint256 _duration,
        uint256 _incentiveAmount,
        uint256 _updateFrequency,
        uint256 _amountToDistribute
    ) external override onlyRole(GOVERNOR_ROLE) {
        require(_duration > 0, "85");
        require(_duration >= _updateFrequency && block.timestamp >= _updateFrequency, "86");

        IStakingRewards stakingContract = IStakingRewards(_stakingContract);

        require(stakingContract.rewardToken() == rewardToken, "83");

        StakingParameters storage stakingParams = stakingContractsMap[stakingContract];

        stakingParams.updateFrequency = _updateFrequency;
        stakingParams.incentiveAmount = _incentiveAmount;
        stakingParams.lastDistributionTime = block.timestamp - _updateFrequency;
        // In order to allow a drip whenever a `stakingContract` is set, we consider that staking has already started
        // `_updateFrequency` ago
        stakingParams.timeStarted = block.timestamp - _updateFrequency;
        stakingParams.duration = _duration;
        stakingParams.amountToDistribute = _amountToDistribute;
        stakingContractsList.push(stakingContract);

        emit NewStakingContract(_stakingContract);
    }

    /// @notice Sets the update frequency
    /// @param _updateFrequency New update frequency
    /// @param stakingContract Reference to the staking contract
    function setUpdateFrequency(uint256 _updateFrequency, IStakingRewards stakingContract)
        external
        override
        onlyRole(GUARDIAN_ROLE)
    {
        StakingParameters storage stakingParams = stakingContractsMap[stakingContract];
        require(stakingParams.duration > 0, "80");
        require(stakingParams.duration >= _updateFrequency, "87");
        stakingParams.updateFrequency = _updateFrequency;
        emit FrequencyUpdated(_updateFrequency, address(stakingContract));
    }

    /// @notice Sets the incentive amount for calling drip
    /// @param _incentiveAmount New incentive amount
    /// @param stakingContract Reference to the staking contract
    function setIncentiveAmount(uint256 _incentiveAmount, IStakingRewards stakingContract)
        external
        override
        onlyRole(GUARDIAN_ROLE)
    {
        StakingParameters storage stakingParams = stakingContractsMap[stakingContract];
        require(stakingParams.duration > 0, "80");
        stakingParams.incentiveAmount = _incentiveAmount;
        emit IncentiveUpdated(_incentiveAmount, address(stakingContract));
    }

    /// @notice Sets the new amount to distribute to a staking contract
    /// @param _amountToDistribute New amount to distribute
    /// @param stakingContract Reference to the staking contract
    function setAmountToDistribute(uint256 _amountToDistribute, IStakingRewards stakingContract)
        external
        override
        onlyRole(GUARDIAN_ROLE)
    {
        StakingParameters storage stakingParams = stakingContractsMap[stakingContract];
        require(stakingParams.duration > 0, "80");
        require(stakingParams.distributedRewards < _amountToDistribute, "88");
        stakingParams.amountToDistribute = _amountToDistribute;
        emit AmountToDistributeUpdated(_amountToDistribute, address(stakingContract));
    }

    /// @notice Sets the new duration with which tokens will be distributed to the staking contract
    /// @param _duration New duration
    /// @param stakingContract Reference to the staking contract
    function setDuration(uint256 _duration, IStakingRewards stakingContract) external override onlyRole(GUARDIAN_ROLE) {
        StakingParameters storage stakingParams = stakingContractsMap[stakingContract];
        require(stakingParams.duration > 0, "80");
        require(_duration >= stakingParams.updateFrequency, "87");
        uint256 timeElapsed = _timeSinceStart(stakingParams);
        require(timeElapsed < stakingParams.duration && timeElapsed < _duration, "66");
        stakingParams.duration = _duration;
        emit DurationUpdated(_duration, address(stakingContract));
    }

    // =========================== Internal Functions ==============================

    /// @notice Gives the next time when `drip` could be called
    /// @param stakingParams Parameters of the concerned staking contract
    /// @return Block timestamp when `drip` will next be available
    function _nextDripAvailable(StakingParameters memory stakingParams) internal pure returns (uint256) {
        return stakingParams.lastDistributionTime + stakingParams.updateFrequency;
    }

    /// @notice Tells if `drip` can currently be called
    /// @param stakingParams Parameters of the concerned staking contract
    /// @return If the `updateFrequency` has passed since the last drip
    function _isDripAvailable(StakingParameters memory stakingParams) internal view returns (bool) {
        return block.timestamp >= _nextDripAvailable(stakingParams);
    }

    /// @notice Computes the amount of tokens to give at the current drip
    /// @param stakingParams Parameters of the concerned staking contract
    /// @dev Constant drip amount across time
    function _computeDripAmount(StakingParameters memory stakingParams) internal view returns (uint256) {
        if (stakingParams.distributedRewards >= stakingParams.amountToDistribute) {
            return 0;
        }
        uint256 dripAmount = (stakingParams.amountToDistribute *
            (block.timestamp - stakingParams.lastDistributionTime)) / stakingParams.duration;
        uint256 timeLeft = stakingParams.duration - _timeSinceStart(stakingParams);
        uint256 rewardsLeftToDistribute = stakingParams.amountToDistribute - stakingParams.distributedRewards;
        if (timeLeft < stakingParams.updateFrequency || rewardsLeftToDistribute < dripAmount || timeLeft == 0) {
            return rewardsLeftToDistribute;
        } else {
            return dripAmount;
        }
    }

    /// @notice Computes the time since distribution has started for the staking contract
    /// @param stakingParams Parameters of the concerned staking contract
    /// @return The time since distribution has started for the staking contract
    function _timeSinceStart(StakingParameters memory stakingParams) internal view returns (uint256) {
        uint256 _duration = stakingParams.duration;
        // `block.timestamp` is always greater than `timeStarted`
        uint256 timePassed = block.timestamp - stakingParams.timeStarted;
        return timePassed > _duration ? _duration : timePassed;
    }

    /// @notice Incentivizes the person calling the drip function
    /// @param stakingParams Parameters of the concerned staking contract
    function _incentivize(StakingParameters memory stakingParams) internal {
        rewardToken.safeTransfer(msg.sender, stakingParams.incentiveAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../external/AccessControl.sol";

import "../interfaces/IRewardsDistributor.sol";
import "../interfaces/IStakingRewards.sol";

/// @title RewardsDistributorEvents
/// @author Angle Core Team
/// @notice All the events used in `RewardsDistributor` contract
contract RewardsDistributorEvents {
    event Dripped(address indexed _caller, uint256 _amount, address _stakingContract);

    event RewardTokenWithdrawn(uint256 _amount);

    event FrequencyUpdated(uint256 _frequency, address indexed _stakingContract);

    event IncentiveUpdated(uint256 _incentiveAmount, address indexed _stakingContract);

    event AmountToDistributeUpdated(uint256 _amountToDistribute, address indexed _stakingContract);

    event DurationUpdated(uint256 _duration, address indexed _stakingContract);

    event NewStakingContract(address indexed _stakingContract);

    event DeletedStakingContract(address indexed stakingContract);

    event NewRewardsDistributor(address indexed newRewardsDistributor);
}