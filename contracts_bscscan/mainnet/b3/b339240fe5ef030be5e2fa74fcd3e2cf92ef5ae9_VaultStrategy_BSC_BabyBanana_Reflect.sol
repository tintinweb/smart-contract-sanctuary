/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

// File: contracts/interfaces/IVaultStrategy.sol

interface IVaultStrategy
{
    //========================
    // CONSTANTS
    //========================
	
	function VERSION() external view returns (string memory);
    function BASE_VERSION() external view returns (string memory);

    //========================
    // ATTRIBUTES
    //========================

    function vault() external view returns (IVault);    

    //used tokens
    function depositToken() external view returns (IToken);
    function rewardToken() external view returns (IToken);
    function additionalRewardToken() external view returns (IToken);
    function lpToken0() external view returns (IToken);
    function lpToken1() external view returns (IToken); 

    //min swap amounts
    function minAdditionalRewardToReward() external view returns (uint256);
    function minRewardToDeposit() external view returns (uint256);
    function minDustToken0() external view returns (uint256);
    function minDustToken1() external view returns (uint256);

    //auto actions
    function autoConvertDust() external view returns (bool);
    function autoCompoundBeforeDeposit() external view returns (bool);
    function autoCompoundBeforeWithdraw() external view returns (bool);

    //pause
    function pauseDeposit() external view returns (bool);
    function pauseWithdraw() external view returns (bool);
    function pauseCompound() external view returns (bool);

    //========================
    // DEPOSIT / WITHDRAW / COMPOUND FUNCTIONS
    //========================  

    function deposit() external;
    function withdraw(address _user, uint256 _amount) external;
    function compound(address _user, bool _revertOnFail) external returns (bool compounded, uint256 rewardAmount, uint256 dustAmount);

    //========================
    // OVERRIDE FUNCTIONS
    //========================
    
    function beforeDeposit() external;
    function beforeWithdraw() external;

    //========================
    // POOL INFO FUNCTIONS
    //========================

    function balanceOf() external view returns (uint256);
    function balanceOfStrategy() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function balanceOfReward() external view returns (uint256);
    function balanceOfDust() external view returns (uint256, uint256);

    function poolCompoundReward() external view returns (uint256);
    function poolPending() external view returns (uint256);
    function poolDepositFee() external view returns (uint256);
    function poolWithdrawFee() external view returns (uint256);
    function poolAllocPoints() external view returns (uint256);
    function poolStartBlock() external view returns (uint256);
    function poolEndBlock() external view returns (uint256);
    function poolEndTime() external view returns (uint256);
    function poolHarvestLockUntil() external view returns (uint256);
    function poolHarvestLockDelay() external view returns (uint256);
    function isPoolFarmable() external view returns (bool);

    //========================
    // STRATEGY RETIRE FUNCTIONS
    //========================

    function retireStrategy() external;

    //========================
    // EMERGENCY FUNCTIONS
    //========================

    function panic() external;
    function pause(bool _pauseDeposit, bool _pauseWithdraw, bool _pauseCompound) external;
    function unpause(bool _unpauseDeposit, bool _unpauseWithdraw, bool _unpauseCompound) external;
}

// File: contracts/interfaces/IVault.sol

interface IVault
{
    //========================
    // CONSTANTS
    //========================

    function VERSION() external view returns (string memory);

    //========================
    // ATTRIBUTES
    //========================

    function strategy() external view returns (IVaultStrategy);

    function totalShares() external view returns (uint256);
    function lastCompound() external view returns (uint256);

    //========================
    // VAULT INFO FUNCTIONS
    //========================

    function depositToken() external view returns (IToken);
    function rewardToken() external view returns (IToken);
    function balance() external view returns (uint256);

    //========================
    // USER INFO FUNCTIONS
    //========================    

    function checkApproved(address _user) external view returns (bool);
    function balanceOf(address _user) external view returns (uint256);
    function userPending(address _user) external view returns (uint256);

    //========================
    // POOL INFO FUNCTIONS
    //========================

    function poolCompoundReward() external view returns (uint256);
    function poolPending() external view returns (uint256);
    function poolDepositFee() external view returns (uint256);
    function poolWithdrawFee() external view returns (uint256);
    function poolAllocPoints() external view returns (uint256);
    function poolStartBlock() external view returns (uint256);
    function poolEndBlock() external view returns (uint256);
    function poolEndTime() external view returns (uint256);
    function poolHarvestLockUntil() external view returns (uint256);
    function poolHarvestLockDelay() external view returns (uint256);
    function isPoolFarmable() external view returns (bool);

    //========================
    // DEPOSIT / WITHDRAW / COMPOUND FUNCTIONS
    //========================

    function depositAll(address _user) external;
    function deposit(address _user, uint256 _amount) external;
    function withdrawAll(address _user) external;
    function withdraw(address _user, uint256 _amount) external;
    function compound(address _user) external;
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

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

// File: @openzeppelin/contracts/utils/Strings.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/AccessControl.sol

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

// File: contracts/interfaces/IVaultChef.sol

interface IVaultChef is IAccessControl
{
    //========================
    // CONSTANTS
    //========================

    function VERSION() external view returns (string memory);
    function PERCENT_FACTOR() external view returns (uint256);

    //========================
    // ATTRIBUTES
    //========================

    function wrappedCoin() external view returns (IToken);

    function compoundRewardFee() external view returns (uint256);
    function nativeLiquidityFee() external view returns (uint256);
    function nativePoolFee() external view returns (uint256);
    function withdrawalFee() external view returns (uint256);

    function nativeLiquidityAddress() external view returns (address);
    function nativePoolAddress() external view returns (address);

    function compoundRewardNative() external view returns (bool);
    function allowUserCompound() external view returns (bool);    

    //========================
    // VAULT INFO FUNCTIONS
    //========================

    function vaultLength() external view returns (uint256);		
	function getVault(uint256 _vid) external view returns (IVault);
    function checkVaultApproved(uint _vid, address _user) external view returns (bool);

    //========================
    // DEPOSIT / WITHDRAW / COMPOUND FUNCTIONS
    //========================

    function compound(uint256 _vid) external;
    function deposit(uint256 _vid, uint256 _amount) external;
    function withdraw(uint256 _vid, uint256 _amount) external;	
	function emergencyWithdraw(uint256 _vid) external;
	
	//========================
    // MISC FUNCTIONS
    //========================
	
	function setReferrer(address _referrer) external;
    function getReferralInfo(address _user) external view returns (address, uint256);

    //========================
    // SECURITY FUNCTIONS
    //========================

    function requireAdmin(address _user) external view;
    function requireDeployer(address _user) external view;
    function requireCompounder(address _user) external view;
    function requireManager(address _user) external view;
    function requireSecurityAdmin(address _user) external view;
    function requireSecurityMod(address _user) external view;
    function requireAllowedContract(address _user) external view;    
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

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

// File: contracts/interfaces/IToken.sol

interface IToken is IERC20
{
	function decimals() external view returns (uint8);	
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
}

// File: contracts/interfaces/ITokenPair.sol

interface ITokenPair is IToken
{	
	function token0() external view returns (address);
	
	function token1() external view returns (address);
	
	function getReserves() external view returns (uint112, uint112, uint32);	
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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



// File: contracts/core/access/VaultRoles.sol

abstract contract VaultRoles
{
    //========================
    // ATTRIBUTES
    //========================

    //roles
    bytes32 public constant ROLE_SUPER_ADMIN = keccak256("ROLE_SUPER_ADMIN"); //role management + admin
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN"); //highest security. required to change important settings (security risk)
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER"); //required to change settings to optimize behaviour (no security risk, but trust is required)
    bytes32 public constant ROLE_SECURITY_ADMIN = keccak256("ROLE_SECURITY_ADMIN"); //can pause and unpause (no security risk, but trust is required)
    bytes32 public constant ROLE_SECURITY_MOD = keccak256("ROLE_SECURITY_MOD"); //can pause but not unpause (no security risk, minimal trust required)
    bytes32 public constant ROLE_DEPLOYER = keccak256("ROLE_DEPLOYER"); //can deploy vaults, should be a trusted developer
    bytes32 public constant ROLE_COMPOUNDER = keccak256("ROLE_COMPOUNDER"); //compounders are always allowed to compound (no security risk)
}

// File: contracts/core/access/VaultAccessManager.sol

abstract contract VaultAccessManager is VaultRoles
{
    //========================
    // ATTRIBUTES
    //========================
    
    IVaultChef public immutable vaultChef;
    address public owner;

    //========================
    // CONSTRUCT
    //========================

    constructor(
        IVaultChef _vaultChef, 
        address _owner
    )
    {   
        vaultChef = _vaultChef;
        owner = _owner;
    }

    //========================
    // SECURITY FUNCTIONS
    //========================

    function isOwner() internal view returns (bool)
    {
        return (owner == msg.sender);
    }

    function requireOwner() internal view
    {
        require(
            isOwner(),
            "User is not Owner");
    }

    function requireAdmin() internal view
    {
        if (!isOwner())
        {
            vaultChef.requireAdmin(msg.sender);
        }
    }

    function requireManager() internal view
    {
        if (!isOwner())
        {
            vaultChef.requireManager(msg.sender);
        }
    }

    function requireDeployer() internal view
    {
        if (!isOwner())
        {
            vaultChef.requireDeployer(msg.sender);
        }
    }

    function requireSecurityAdmin() internal view
    {
        if (!isOwner())
        {
            vaultChef.requireSecurityAdmin(msg.sender);
        }
    }

    function requireSecurityMod() internal view
    {
        if (!isOwner())
        {
            vaultChef.requireSecurityMod(msg.sender);
        }
    }
}

// File: contracts/interfaces/IRouter.sol

interface IUniRouterV1
{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniRouterV2 is IUniRouterV1
{
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

// File: contracts/VaultStrategyV1.sol

abstract contract VaultStrategyV1 is IVaultStrategy, VaultAccessManager
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IToken;
    using SafeMath for uint256;

    //========================
    // CONSTANTS
    //========================
	
	string public constant override BASE_VERSION = "1.0.0";

    //========================
    // ATTRIBUTES
    //========================

    //base    
    IToken public immutable wrappedCoin;
    uint256 public immutable PERCENT_FACTOR;
    IVault public immutable override vault;

    //used tokens
    IToken public override depositToken;
    IToken public override rewardToken;
    IToken public override additionalRewardToken; //can be 0
    IToken public override lpToken0; //0 if no LP
    IToken public override lpToken1; //0 if no LP

    //min swap amounts
    uint256 public override minRewardToDeposit;
    uint256 public override minAdditionalRewardToReward;    
    uint256 public override minDustToken0;
    uint256 public override minDustToken1;

    //auto actions
    bool public override autoConvertDust;
    bool public override autoCompoundBeforeDeposit;
    bool public override autoCompoundBeforeWithdraw;

    //3rd party contracts
    address public router;
    address public masterChef;
    uint256 public poolID;

    //pause
    bool public override pauseDeposit;
    bool public override pauseWithdraw;
    bool public override pauseCompound;

    //general
    uint256 public lastHarvestBlock;
    uint256 public dustAmountSinceLastCompound;

    //========================
    // EVENTS FUNCTIONS
    //========================

    event Pause(address indexed _user, bool _deposit, bool _withdraw, bool _compound);
    event Unpause(address indexed _user, bool _deposit, bool _withdraw, bool _compound);
    event ConfigChanged(string indexed _key, uint256 _value);

    //========================
    // CREATE
    //========================

    constructor(
        IVaultChef _vaultChef,
        IVault _vault,
        address _masterChef,
        uint256 _poolID,
        address _router
    )
    VaultAccessManager(_vaultChef, address(_vault))
    {
        //base
        vault = _vault;
        wrappedCoin = _vaultChef.wrappedCoin();
        PERCENT_FACTOR = _vaultChef.PERCENT_FACTOR();

        //strategy
        masterChef = _masterChef;
        poolID = _poolID;
        router = _router;
    }

    function init(bool _isTokenPair) internal
    {
        if (_isTokenPair)
        {
            lpToken0 = IToken(ITokenPair(address(depositToken)).token0());
            lpToken1 = IToken(ITokenPair(address(depositToken)).token1());          
        }

        //give allowances
        giveAllowances(); 
    }

    //========================
    // CONFIG FUNCTIONS
    //========================

    function setMinDustAmount(uint256 _minDust0, uint256 _minDust1) external
    {
        //check
        requireManager();

        //set
        minDustToken0 = _minDust0;
        minDustToken1 = _minDust1;

        //events
        emit ConfigChanged("MinDustToken0", minDustToken0);
        emit ConfigChanged("MinDustToken1", minDustToken1);
    }

    function setMinRewardAmount(uint256 _minReward, uint256 _minAdditionalReward) external
    {
        //check
        requireManager();

        //set
        minRewardToDeposit = _minReward;
        minAdditionalRewardToReward = _minAdditionalReward;

        //events
        emit ConfigChanged("MinRewardToDeposit", minRewardToDeposit);
        emit ConfigChanged("MinAdditionalRewardToReward", minAdditionalRewardToReward);
    }

    function setAutoActions(bool _autoConvertDust, bool _autoCompoundBeforeDeposit, bool _autoCompoundBeforeWithdraw) external
    {
        //check
        requireManager();

        //set
        autoConvertDust = _autoConvertDust;
        autoCompoundBeforeDeposit = _autoCompoundBeforeDeposit;
        autoCompoundBeforeWithdraw = _autoCompoundBeforeWithdraw;

        //events
        emit ConfigChanged("AutoConvertDust", autoConvertDust ? 1 : 0);
        emit ConfigChanged("AutoCompoundBeforeDeposit", autoCompoundBeforeDeposit ? 1 : 0);
        emit ConfigChanged("AutoCompoundBeforeWithdraw", autoCompoundBeforeWithdraw ? 1 : 0);
    }

    //========================
    // POOL INFO FUNCTIONS
    //========================

    function balanceOf() public view override returns (uint256)
    {
        return balanceOfStrategy().add(balanceOfPool());
    }

    function balanceOfStrategy() public view override returns (uint256)
    {
        return depositToken.balanceOf(address(this));
    }

    function balanceOfPool() public view virtual override returns (uint256)
    {
        return 0;
    }

    function balanceOfReward() public view virtual override returns (uint256)
    {
        return rewardToken.balanceOf(address(this));
    }

    function balanceOfDust() public view virtual override returns (uint256, uint256)
    {
        return (lpToken0.balanceOf(address(this)), lpToken1.balanceOf(address(this)));
    }

    function poolCompoundReward() external view virtual override returns (uint256)
    {
        return poolPending().mul(vaultChef.compoundRewardFee()).div(PERCENT_FACTOR);
    }

    function poolPending() public view virtual override returns (uint256)
    {
        return 0;
    }

    function poolDepositFee() external view virtual override returns (uint256)
    {
        return 0;
    }

    function poolWithdrawFee() public view virtual override returns (uint256)
    {
        return 0;
    }

    function poolAllocPoints() public view virtual override returns (uint256)
    {
        return 1;
    }

    function poolStartBlock() public view virtual override returns (uint256)
    {
        return 0;
    }

    function poolEndBlock() public view virtual override returns (uint256)
    {
        return 0;
    }

    function poolEndTime() public view virtual override returns (uint256)
    {
        return 0;
    }

    function poolHarvestLockUntil() public view virtual override returns (uint256)
    {
        return 0;
    }

    function poolHarvestLockDelay() public view override returns (uint256)
    {   
        uint256 lockedUntil = poolHarvestLockUntil();
        if (lockedUntil <= block.timestamp)
        {
            return 0;
        }     

        return lockedUntil.sub(block.timestamp);
    }

    function isPoolFarmable() external view virtual override returns (bool)
    {
        uint256 endBlock = poolEndBlock();
        uint256 endTime = poolEndTime();
        if (poolAllocPoints() == 0
            || (endBlock > 0
                && block.number >= endBlock)
            || (endTime > 0
                && endTime >= block.timestamp))
        {
            return false;
        }
        
        return true;
    }

    //========================
    // OVERRIDE DEPOSIT / WITHDRAW / COMPOUND FUNCTIONS
    //========================

    function poolDeposit(uint256 _amount) internal virtual
    {
        _amount; //hide warning
    }

    function beforeDeposit() external virtual override
    {
        this; //hide warning
    }

    function poolWithdraw(uint256 _amount) internal virtual
    {
        _amount; //hide warning
    }    

    function beforeWithdraw() external virtual override
    {
        this; //hide warning
    }

    function emergencyWithdraw() internal virtual
    {
        poolWithdraw(balanceOfPool());
    } 

    //========================
    // DEPOSIT FUNCTIONS
    //========================    

    function deposit() public virtual override
    {
        //check
        requireOwner();
        require(!pauseDeposit, "Deposit paused!");

        //deposit
        uint256 currentBalance = balanceOfStrategy();
        if (currentBalance > 0)
        {
            poolDeposit(currentBalance);
        }
    }    

    //========================
    // WITHDRAW FUNCTIONS
    //======================== 

    function withdraw(address _user, uint256 _amount) external virtual override
    {
        //check
        requireOwner();
        require(!pauseWithdraw, "Withdraw paused!");

        //withdraw from pool
        uint256 poolWithdrawAmount = withdrawFromPool(_amount);

        //withdraw from strategy
        withdrawFromStrategy(_user, _amount, poolWithdrawAmount);
    }

    function withdrawFromPool(uint256 _amount) internal virtual returns (uint256 poolWithdrawAmount)
    {
        //withdraw from pool
        uint256 currentBalance = balanceOfStrategy();
        poolWithdrawAmount = 0;
        if (currentBalance < _amount)
        {
            poolWithdrawAmount = _amount.sub(currentBalance);
            uint256 poolWithdrawFeeAmount = 0;
            if (!pauseDeposit
                && !pauseCompound)
            {
                //withdrawal fee stays in pool and is shared by all users
                poolWithdrawFeeAmount = poolWithdrawAmount.mul(vaultChef.withdrawalFee()).div(PERCENT_FACTOR); 
            }
            poolWithdraw(poolWithdrawAmount.sub(poolWithdrawFeeAmount));
        }

        return poolWithdrawAmount;
    }

    function withdrawFromStrategy(address _user, uint256 _amount, uint256 _poolWithdrawAmount) internal virtual
    {
        //check amount
        uint256 withdrawAmount = balanceOfStrategy();
        if (withdrawAmount > _amount)
        {
            withdrawAmount = _amount;
        }

        //send to user
        uint256 withdrawalFeeAmount = 0;
        if (!pauseDeposit
            && !pauseCompound)
        {
            //withdrawal fee stays in strategy and is shared by all users
            //(only tax the strategy amount, as pool amount was already taxed)
            uint256 strategyWithdrawAmount = _amount.sub(_poolWithdrawAmount);
            withdrawalFeeAmount = strategyWithdrawAmount.mul(vaultChef.withdrawalFee()).div(PERCENT_FACTOR);            
        }
        depositToken.safeTransfer(_user, withdrawAmount.sub(withdrawalFeeAmount));
    }

    //========================
    // COMPOUND FUNCTIONS
    //======================== 
    
    function harvest() internal virtual
    {        
        if (block.number != lastHarvestBlock)
        {
            //harvest
            harvestPool();
            lastHarvestBlock = block.number;
        }
    }  

    function harvestPool() internal virtual
    {        
        poolWithdraw(0);
    }  

    function compound(address _user, bool _revertOnFail) public override returns (bool, uint256, uint256)
    {
        //check
        requireOwner();
        if (pauseCompound)
        {
            //no revert, if called before deposit/withdraw
            require(!_revertOnFail, "Compound paused!");
            return (false, 0, 0);
        }        
        if (poolHarvestLockDelay() != 0)
        {
            //no revert, if called before deposit/withdraw
            require(!_revertOnFail, "Harvest lock!");
            return (false, 0, 0);
        }

        //harvest
        harvest();

        //swap
        (bool compounded, uint256 rewardAmount, uint256 dustAmount) = rewardToDeposit(_user, _revertOnFail);

        //deposit
        uint256 currentBalance = balanceOfStrategy();
        if (currentBalance > 0)
        {
            poolDeposit(currentBalance);
        }

        //handle dust
        if (autoConvertDust)
        {
            dustToReward();
        }

        return (compounded, rewardAmount, dustAmount);
    }  

    //========================
    // SWAP FUNCTIONS
    //========================

    function convertDustToReward() external returns (uint256)
    {
        //check
        requireManager();

        //convert
        return dustToReward();
    }

    function dustToReward() internal returns (uint256)
    {
        uint256 balanceOfRewardBefore = balanceOfReward();

        //dust to reward
        if (isLPToken())
        {
            //get dust
            (uint256 token0Amount, uint256 token1Amount) = balanceOfDust();

            //converts token0 dust (if any) to reward token
            if (lpToken0 != rewardToken
                && token0Amount > 0
                && token0Amount >= minDustToken0)
            {
                swapTokens(token0Amount, lpToken0, rewardToken);
            }

            //converts token1 dust (if any) to reward token
            if (lpToken1 != rewardToken
                && token1Amount > 0
                && token1Amount >= minDustToken1)
            {
                swapTokens(token1Amount, lpToken1, rewardToken);
            }
        }

        //get created dust
        uint256 balanceOfRewardAfter = balanceOfReward();
        uint256 createdDust = balanceOfRewardAfter.sub(balanceOfRewardBefore);
        dustAmountSinceLastCompound = dustAmountSinceLastCompound.add(createdDust);
        return createdDust;
    }

    function additionalRewardToReward() internal
    {
        //check token
        if (additionalRewardToken == IToken(address(0))
            || additionalRewardToken == rewardToken
            || additionalRewardToken == depositToken)
        {
            return;
        }

        //check min threshold for swap
        uint256 additionalBalance = additionalRewardToken.balanceOf(address(this));
        if (additionalBalance < minAdditionalRewardToReward
            || additionalBalance == 0)
        {
            return;
        }

        //swap
        swapTokens(additionalBalance, additionalRewardToken, rewardToken);
    }

    function rewardToDeposit(address _compounder, bool _revertOnFail) internal returns (bool, uint256, uint256)
    {
        //additional reward
        additionalRewardToReward();

        //check min threshold for swap
        uint256 rewardBalance = balanceOfReward();
        if (rewardBalance < minRewardToDeposit
            || rewardBalance == 0)
        {            
            require(!_revertOnFail, "Insufficient reward for compound");
            return (false, 0, 0);
        }

        //collect fees
        chargeFees(_compounder, rewardBalance);

        //get values        
        uint256 dustAmount = dustAmountSinceLastCompound;
        uint256 rewardWithoutDust = balanceOfReward().sub(dustAmount);
        dustAmountSinceLastCompound = 0;

        //reward to deposit        
        if (isLPToken())
        {
            rewardToDepositLPToken();
        }
        else if (rewardToken != depositToken)
        {
            rewardToDepositToken();
        }

        return (true, rewardWithoutDust, dustAmount);
    }

    function rewardToDepositToken() internal virtual
    {
        swapTokens(balanceOfReward(), rewardToken, depositToken);
    }

    function rewardToDepositLPToken() internal virtual
    {
        uint256 halfReward = balanceOfReward().div(2);

        //swap reward to token 0
        if (lpToken0 != rewardToken)
        {
            swapTokens(halfReward, rewardToken, lpToken0);
        }

        //swap reward to token 1
        if (lpToken1 != rewardToken)
        {
            swapTokens(halfReward, rewardToken, lpToken1);
        }

        //add liquidity
        IUniRouterV2(router).addLiquidity(
            address(lpToken0),
            address(lpToken1),
            lpToken0.balanceOf(address(this)),
            lpToken1.balanceOf(address(this)),
            1,
            1,
            address(this),
            block.timestamp);
    }

    function swapTokens(uint256 _amount, IToken _from, IToken _to) internal
    {   
        //swap
        IUniRouterV2(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            makeSwapPath(_from, _to),
            address(this),
            block.timestamp);
    }

    function makeSwapPath(IToken _from, IToken _to) internal view returns (address[] memory)
	{
	    address[] memory path;
		if (_from == wrappedCoin
			|| _to == wrappedCoin)
		{
            //direct
			path = new address[](2);
			path[0] = address(_from);
			path[1] = address(_to);
		}
		else
		{
            //indirect over wrapped coin
			path = new address[](3);
			path[0] = address(_from);
			path[1] = address(wrappedCoin);
			path[2] = address(_to);
		}
		
		return path;
	}

    //========================
    // FEE FUNCTIONS
    //========================

    function getFees() internal view returns (uint256 nativeLiquidityFee, uint256 nativePoolFee, uint256 compoundFee, uint256 totalWrappedFee)
    {        
        //get data       
        compoundFee = vaultChef.compoundRewardFee();
        nativeLiquidityFee = vaultChef.nativeLiquidityFee();
        nativePoolFee = vaultChef.nativePoolFee();
        totalWrappedFee = nativeLiquidityFee.add(nativePoolFee);    

        //check pool fee
        if (vaultChef.nativePoolAddress() == address(0))
        {
            totalWrappedFee = totalWrappedFee.sub(nativePoolFee);
            nativePoolFee = 0;
        }
        
        //check compound reward fee        
        if (!vaultChef.compoundRewardNative())
        {
            totalWrappedFee = totalWrappedFee.add(compoundFee);
        }
    }

    function chargeFees(address _user, uint256 _rewardAmount) internal
    {
        if (_rewardAmount == 0)
        {
            return;
        }

        //get liquidity & pool fees and addresses
        (, uint256 nativePoolFee, uint256 compoundFee, uint256 totalWrappedFee) = getFees();

        //get fee amount
        uint256 wrappedBalanceBefore = wrappedCoin.balanceOf(address(this)); 
        uint256 feeAmount = _rewardAmount.mul(totalWrappedFee).div(PERCENT_FACTOR);
        if (wrappedCoin != rewardToken)
        {
            //swap to wrapped coin                    
            swapTokens(feeAmount, rewardToken, wrappedCoin);
            uint256 wrappedBalanceAfter = wrappedCoin.balanceOf(address(this)); 
            feeAmount = wrappedBalanceAfter.sub(wrappedBalanceBefore);
        }

        //send reward fee
        if (vaultChef.compoundRewardNative())
        {
            //send fee as native from reward amount
            sendFeeShare(_user, rewardToken, _rewardAmount, compoundFee, PERCENT_FACTOR);
        }
        else
        {
            //send fee as wrapped from wrapped fee amount
            sendFeeShare(_user, wrappedCoin, feeAmount, compoundFee, totalWrappedFee);
        }        

        //send pool fee
        if (nativePoolFee != 0)
        {
            sendFeeShare(vaultChef.nativePoolAddress(), wrappedCoin, feeAmount, nativePoolFee, totalWrappedFee);
        }

        //send liquidity fee (remaining fee amount, to prevent dust)
        uint256 wrappedBalanceCurrent = wrappedCoin.balanceOf(address(this)); 
        uint256 remainingFeeAmount = wrappedBalanceCurrent.sub(wrappedBalanceBefore);
        wrappedCoin.safeTransfer(vaultChef.nativeLiquidityAddress(), remainingFeeAmount);
    }

    function sendFeeShare(address _reciever, IToken _token, uint256 _fullAmount, uint256 _shares, uint256 _sharesTotal) internal
    {
        uint256 feeAmount = _fullAmount.mul(_shares).div(_sharesTotal);
        _token.safeTransfer(_reciever, feeAmount);
    }

    //========================
    // HELPER FUNCTIONS
    //========================

    function isLPToken() internal view returns (bool)
    {
        return (address(lpToken0) != address(0)
            && address(lpToken1) != address(0));
    }

    //========================
    // STRATEGY RETIRE FUNCTIONS
    //========================

    function retireStrategy() external override
    {
        //check
        requireOwner();

        //withdraw all & send to vault
        emergencyWithdraw();
        depositToken.transfer(address(vault), balanceOfStrategy());
    }

    //========================
    // EMERGENCY FUNCTIONS
    //========================

    function panic() external override
    {
        //check
        requireOwner();

        //pause, remove allowance & withdraw
        pause(true, true, true);
        emergencyWithdraw();
    }

    function pause(bool _pauseDeposit, bool _pauseWithdraw, bool _pauseCompound) public override
    {
        //check
        requireSecurityMod();

        //pause
        if (_pauseDeposit)
        {
            pauseDeposit = true;
        }
        if (_pauseWithdraw)
        {
            pauseWithdraw = true;
        }
        if (_pauseCompound)
        {
            pauseCompound = true;
        }

        //allowance
        if (pauseDeposit
            && pauseCompound)
        {
            removeAllowances();
        }

        //event        
        emit Pause(msg.sender, _pauseDeposit, _pauseWithdraw, _pauseCompound);
    }

    function unpause(bool _unpauseDeposit, bool _unpauseWithdraw, bool _unpauseCompound) public override
    {
        //check
        requireSecurityAdmin();

        //pause
        if (_unpauseDeposit)
        {
            pauseDeposit = false;
        }
        if (_unpauseWithdraw)
        {
            pauseWithdraw = false;
        }
        if (_unpauseCompound)
        {
            pauseCompound = false;
        }        

        //allowance
        if (!pauseDeposit
            || !pauseCompound)
        {
            giveAllowances();
        }

        //event
        emit Unpause(msg.sender, _unpauseDeposit, _unpauseWithdraw, _unpauseCompound);
    }

    //========================
    // ALLOWANCES FUNCTIONS
    //========================

    function giveAllowances() internal virtual
    {
        depositToken.safeApprove(masterChef, type(uint256).max);
        rewardToken.safeApprove(router, type(uint256).max);
        if (address(additionalRewardToken) != address(0))
        {
            additionalRewardToken.safeApprove(router, 0);
            additionalRewardToken.safeApprove(router, type(uint256).max);
        }
        if (isLPToken())
        {
            lpToken0.safeApprove(router, 0);
            lpToken0.safeApprove(router, type(uint256).max);
            
            lpToken1.safeApprove(router, 0);
            lpToken1.safeApprove(router, type(uint256).max);
        }
    }

    function removeAllowances() internal virtual
    {
        depositToken.safeApprove(masterChef, 0);
        rewardToken.safeApprove(router, 0);
        if (address(additionalRewardToken) != address(0))
        {
            additionalRewardToken.safeApprove(router, 0);
        }
        if (isLPToken())
        {
            lpToken0.safeApprove(router, 0);
            lpToken1.safeApprove(router, 0);
        }
    }
}

interface IDividendeDistributor_BSC_BabyBanana
{
    function claimDividend() external;

    function getUnpaidEarnings(address shareholder) external view returns (uint256);
}

interface INFT_BSC_BabyBanana
{
    function consume(uint256 tokenId, address sender) external;

    function stake(uint256 tokenId, address sender) external;

    function priceOf(uint256 tokenId) external view returns (uint256);

    function stakingRewardShareOf(uint256 tokenId, address account) external view returns (uint256);

    function featureValueOf(uint8 feature, address account) external view returns (uint256);

    function lotteryTicketsOf(address account) external view returns (uint256);

    function rewardTokenFor(address account) external view returns (address, address);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

contract VaultStrategy_BSC_BabyBanana_Reflect is VaultStrategyV1
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IToken;
    using SafeMath for uint256;

    //========================
    // CONSTANTS
    //========================

    string public constant override VERSION = "1.0.0";
    IToken public constant BABYBANANA_TOKEN = IToken(0xa3be3B30Fa5302daD5c9874cDB50E220eAadf092);
    IToken public constant REWARD_TOKEN = IToken(0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95);
    address public constant MASTERCHEF = 0x88F8AC6e8fF48291ce26dcAA514Fd482Cbf2823d;
    address public constant ROUTER = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;
    INFT_BSC_BabyBanana public constant NFT = INFT_BSC_BabyBanana(0x986462937DE0B064364631c9b72A15ac8cc76678);
    
    //========================
    // ATTRIBUTES
    //========================

    address public nftAdmin;

    //========================
    // CREATE
    //========================

    constructor(
        IVaultChef _vaultChef,
        IVault _vault
    )
    VaultStrategyV1(
        _vaultChef,
        _vault,
        MASTERCHEF,
        0,
        ROUTER
    )
    {
        //init    
        depositToken = BABYBANANA_TOKEN;
        rewardToken = REWARD_TOKEN;   

        init(false);

        //nft
        nftAdmin = msg.sender;
    }    

    //========================
    // POOL INFO FUNCTIONS
    //========================

    function poolPending() public view override returns (uint256)
    {
        uint256 pendingBBNANA = IDividendeDistributor_BSC_BabyBanana(masterChef).getUnpaidEarnings(address(this));
        uint256 collectedReward = rewardToken.balanceOf(address(this));

        //convert pending to reward
        uint256 pendingToReward = 0;
        if (pendingBBNANA > 0)
        {
            uint256[] memory amountOut = IUniRouterV2(router).getAmountsOut(pendingBBNANA, makeSwapPath(BABYBANANA_TOKEN, rewardToken));
            pendingToReward = amountOut[amountOut.length -1];
        }
        
        return collectedReward.add(pendingToReward);
    }

    //========================
    // DEPOSIT / WITHDRAW / COMPOUND FUNCTIONS
    //========================

    function harvestPool() internal override
    { 
        IDividendeDistributor_BSC_BabyBanana(masterChef).claimDividend();  
        dustAmountSinceLastCompound = 0; //we have no real dust, so reset
    }

    //========================
    // NFT FUNCTIONS
    //========================

    function requireNFTAdmin(address _user) internal view
    {
        require(nftAdmin == _user, "User is not NFT Admin");
    }

    function transferNFTAdmin(address _newAdmin) external
    {
        //check
        requireNFTAdmin(msg.sender);

        //change
        nftAdmin = _newAdmin;
        emit ConfigChanged("ChangeNFTAdmin", uint256(uint160(_newAdmin)));
    }

    function transferNFT(uint256 _id, address _to, uint256 _amount) external
    {
        //check
        requireNFTAdmin(msg.sender);

        //transfer
        bytes memory data;// = [0x0];
        NFT.safeTransferFrom(address(this), _to, _id, _amount, data);
    }    
}