// SPDX-License-Identifier:MIT
// solhint-disable no-inline-assembly
pragma solidity ^0.6.2;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // we copy the msg.data , except the last 20 bytes (and update the total length)
            assembly {
                let ptr := mload(0x40)
                // copy only size-20 bytes
                let size := sub(calldatasize(),20)
                // structure RLP data as <offset> <length> <bytes>
                mstore(ptr, 0x20)
                mstore(add(ptr,32), size)
                calldatacopy(add(ptr,64), 0, size)
                return(ptr, add(size,64))
            }
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.6.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";
import "../Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
 *     require(hasRole(MY_ROLE, _msgSender()));
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
 */
abstract contract AccessControlUpgradeSafe is Initializable, ContextUpgradeSafe {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {


    }

    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
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
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableUpgradeSafe is Initializable, ContextUpgradeSafe {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */

    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {


        _paused = false;

    }


    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    uint256[49] private __gap;
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

// solhint-disable
// Imported from https://github.com/UMAprotocol/protocol/blob/4d1c8cc47a4df5e79f978cb05647a7432e111a3d/packages/core/contracts/common/implementation/FixedPoint.sol
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SignedSafeMath.sol";


/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_SCALING_FACTOR = 10**18;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    struct Unsigned {
        uint256 rawValue;
    }

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5**18`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    struct Signed {
        int256 rawValue;
    }

    function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5**18`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
pragma solidity 0.6.12;

import "./IERC20withDec.sol";

interface ICUSDCContract is IERC20withDec {
  /*** User Interface ***/

  function mint(uint256 mintAmount) external returns (uint256);

  function redeem(uint256 redeemTokens) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);

  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

  function liquidateBorrow(
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral
  ) external returns (uint256);

  function getAccountSnapshot(address account)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  function balanceOfUnderlying(address owner) external returns (uint256);

  function exchangeRateCurrent() external returns (uint256);

  /*** Admin Functions ***/

  function _addReserves(uint256 addAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

abstract contract ICreditDesk {
  uint256 public totalWritedowns;
  uint256 public totalLoansOutstanding;

  function setUnderwriterGovernanceLimit(address underwriterAddress, uint256 limit) external virtual;

  function createCreditLine(
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr
  ) public virtual returns (address);

  function drawdown(address creditLineAddress, uint256 amount) external virtual;

  function pay(address creditLineAddress, uint256 amount) external virtual;

  function assessCreditLine(address creditLineAddress) external virtual;

  function applyPayment(address creditLineAddress, uint256 amount) external virtual;

  function getNextPaymentAmount(address creditLineAddress, uint256 asOfBLock) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

/*
Only addition is the `decimals` function, which we need, and which both our Fidu and USDC use, along with most ERC20's.
*/

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20withDec is IERC20 {
  /**
   * @dev Returns the number of decimals used for the token
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20withDec.sol";

interface IFidu is IERC20withDec {
  function mintTo(address to, uint256 amount) external;

  function burnFrom(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

abstract contract IPool {
  uint256 public sharePrice;

  function deposit(uint256 amount) external virtual;

  function withdraw(uint256 usdcAmount) external virtual;

  function withdrawInFidu(uint256 fiduAmount) external virtual;

  function collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) public virtual;

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual returns (bool);

  function drawdown(address to, uint256 amount) public virtual returns (bool);

  function sweepToCompound() public virtual;

  function sweepFromCompound() public virtual;

  function distributeLosses(address creditlineAddress, int256 writedownDelta) external virtual;

  function assets() public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./CreditLine.sol";
import "../../external/FixedPoint.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @title The Accountant
 * @notice Library for handling key financial calculations, such as interest and principal accrual.
 * @author Goldfinch
 */

library Accountant {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Signed;
  using FixedPoint for FixedPoint.Unsigned;
  using FixedPoint for int256;
  using FixedPoint for uint256;

  // Scaling factor used by FixedPoint.sol. We need this to convert the fixed point raw values back to unscaled
  uint256 public constant FP_SCALING_FACTOR = 10**18;
  uint256 public constant INTEREST_DECIMALS = 1e8;
  uint256 public constant BLOCKS_PER_DAY = 5760;
  uint256 public constant BLOCKS_PER_YEAR = (BLOCKS_PER_DAY * 365);

  struct PaymentAllocation {
    uint256 interestPayment;
    uint256 principalPayment;
    uint256 additionalBalancePayment;
  }

  function calculateInterestAndPrincipalAccrued(
    CreditLine cl,
    uint256 blockNumber,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    uint256 balance = cl.balance(); // gas optimization
    uint256 interestAccrued = calculateInterestAccrued(cl, balance, blockNumber, lateFeeGracePeriod);
    uint256 principalAccrued = calculatePrincipalAccrued(cl, balance, blockNumber);
    return (interestAccrued, principalAccrued);
  }

  function calculatePrincipalAccrued(
    CreditLine cl,
    uint256 balance,
    uint256 blockNumber
  ) public view returns (uint256) {
    if (blockNumber >= cl.termEndBlock()) {
      return balance;
    } else {
      return 0;
    }
  }

  function calculateWritedownFor(
    CreditLine cl,
    uint256 blockNumber,
    uint256 gracePeriodInDays,
    uint256 maxDaysLate
  ) public view returns (uint256, uint256) {
    FixedPoint.Unsigned memory amountOwedPerDay = calculateAmountOwedForOneDay(cl);
    if (amountOwedPerDay.isEqual(0)) {
      return (0, 0);
    }
    FixedPoint.Unsigned memory fpGracePeriod = FixedPoint.fromUnscaledUint(gracePeriodInDays);
    FixedPoint.Unsigned memory daysLate;

    // Excel math: =min(1,max(0,periods_late_in_days-graceperiod_in_days)/MAX_ALLOWED_DAYS_LATE) grace_period = 30,
    // Before the term end block, we use the interestOwed to calculate the periods late. However, after the loan term
    // has ended, since the interest is a much smaller fraction of the principal, we cannot reliably use interest to
    // calculate the periods later.
    uint256 totalOwed = cl.interestOwed().add(cl.principalOwed());
    daysLate = FixedPoint.fromUnscaledUint(totalOwed).div(amountOwedPerDay);
    if (blockNumber > cl.termEndBlock()) {
      uint256 blocksLate = blockNumber.sub(cl.termEndBlock());
      daysLate = daysLate.add(FixedPoint.fromUnscaledUint(blocksLate).div(BLOCKS_PER_DAY));
    }

    FixedPoint.Unsigned memory maxLate = FixedPoint.fromUnscaledUint(maxDaysLate);
    FixedPoint.Unsigned memory writedownPercent;
    if (daysLate.isLessThanOrEqual(fpGracePeriod)) {
      // Within the grace period, we don't have to write down, so assume 0%
      writedownPercent = FixedPoint.fromUnscaledUint(0);
    } else {
      writedownPercent = FixedPoint.min(FixedPoint.fromUnscaledUint(1), (daysLate.sub(fpGracePeriod)).div(maxLate));
    }

    FixedPoint.Unsigned memory writedownAmount = writedownPercent.mul(cl.balance()).div(FP_SCALING_FACTOR);
    // This will return a number between 0-100 representing the write down percent with no decimals
    uint256 unscaledWritedownPercent = writedownPercent.mul(100).div(FP_SCALING_FACTOR).rawValue;
    return (unscaledWritedownPercent, writedownAmount.rawValue);
  }

  function calculateAmountOwedForOneDay(CreditLine cl) public view returns (FixedPoint.Unsigned memory) {
    // Determine theoretical interestOwed for one full day
    uint256 totalInterestPerYear = cl.balance().mul(cl.interestApr()).div(INTEREST_DECIMALS);
    FixedPoint.Unsigned memory interestOwed = FixedPoint.fromUnscaledUint(totalInterestPerYear).div(365);

    return interestOwed;
  }

  function calculateInterestAccrued(
    CreditLine cl,
    uint256 balance,
    uint256 blockNumber,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256) {
    // We use Math.min here to prevent integer overflow (ie. go negative) when calculating
    // numBlocksElapsed. Typically this shouldn't be possible, because
    // the interestAccruedAsOfBlock couldn't be *after* the current blockNumber. However, when assessing
    // we allow this function to be called with a past block number, which raises the possibility
    // of overflow.
    // This use of min should not generate incorrect interest calculations, since
    // this functions purpose is just to normalize balances, and  will be called any time
    // a balance affecting action takes place (eg. drawdown, repayment, assessment)
    uint256 interestAccruedAsOfBlock = Math.min(blockNumber, cl.interestAccruedAsOfBlock());
    uint256 numBlocksElapsed = blockNumber.sub(interestAccruedAsOfBlock);
    uint256 totalInterestPerYear = balance.mul(cl.interestApr()).div(INTEREST_DECIMALS);
    uint256 interestOwed = totalInterestPerYear.mul(numBlocksElapsed).div(BLOCKS_PER_YEAR);

    if (lateFeeApplicable(cl, blockNumber, lateFeeGracePeriodInDays)) {
      uint256 lateFeeInterestPerYear = balance.mul(cl.lateFeeApr()).div(INTEREST_DECIMALS);
      uint256 additionalLateFeeInterest = lateFeeInterestPerYear.mul(numBlocksElapsed).div(BLOCKS_PER_YEAR);
      interestOwed = interestOwed.add(additionalLateFeeInterest);
    }

    return interestOwed;
  }

  function lateFeeApplicable(
    CreditLine cl,
    uint256 blockNumber,
    uint256 gracePeriodInDays
  ) public view returns (bool) {
    uint256 blocksLate = blockNumber.sub(cl.lastFullPaymentBlock());
    return cl.lateFeeApr() > 0 && blocksLate > gracePeriodInDays.mul(BLOCKS_PER_DAY);
  }

  function allocatePayment(
    uint256 paymentAmount,
    uint256 balance,
    uint256 interestOwed,
    uint256 principalOwed
  ) public pure returns (PaymentAllocation memory) {
    uint256 paymentRemaining = paymentAmount;
    uint256 interestPayment = Math.min(interestOwed, paymentRemaining);
    paymentRemaining = paymentRemaining.sub(interestPayment);

    uint256 principalPayment = Math.min(principalOwed, paymentRemaining);
    paymentRemaining = paymentRemaining.sub(principalPayment);

    uint256 balanceRemaining = balance.sub(principalPayment);
    uint256 additionalBalancePayment = Math.min(paymentRemaining, balanceRemaining);

    return
      PaymentAllocation({
        interestPayment: interestPayment,
        principalPayment: principalPayment,
        additionalBalancePayment: additionalBalancePayment
      });
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "./PauserPausable.sol";

/**
 * @title BaseUpgradeablePausable contract
 * @notice This is our Base contract that most other contracts inherit from. It includes many standard
 *  useful abilities like ugpradeability, pausability, access control, and re-entrancy guards.
 * @author Goldfinch
 */

contract BaseUpgradeablePausable is
  Initializable,
  AccessControlUpgradeSafe,
  PauserPausable,
  ReentrancyGuardUpgradeSafe
{
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  using SafeMath for uint256;
  // Pre-reserving a few slots in the base contract in case we need to add things in the future.
  // This does not actually take up gas cost or storage cost, but it does reserve the storage slots.
  // See OpenZeppelin's use of this pattern here:
  // https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/GSN/Context.sol#L37
  uint256[50] private __gap1;
  uint256[50] private __gap2;
  uint256[50] private __gap3;
  uint256[50] private __gap4;

  // solhint-disable-next-line func-name-mixedcase
  function __BaseUpgradeablePausable__init(address owner) public initializer {
    require(owner != address(0), "Owner cannot be the zero address");
    __AccessControl_init_unchained();
    __Pausable_init_unchained();
    __ReentrancyGuard_init_unchained();

    _setupRole(OWNER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);

    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  function isAdmin() public view returns (bool) {
    return hasRole(OWNER_ROLE, _msgSender());
  }

  modifier onlyAdmin() {
    require(isAdmin(), "Must have admin role to perform this action");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./GoldfinchConfig.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/IFidu.sol";
import "../../interfaces/ICreditDesk.sol";
import "../../interfaces/IERC20withDec.sol";
import "../../interfaces/ICUSDCContract.sol";

/**
 * @title ConfigHelper
 * @notice A convenience library for getting easy access to other contracts and constants within the
 *  protocol, through the use of the GoldfinchConfig contract
 * @author Goldfinch
 */

library ConfigHelper {
  function getPool(GoldfinchConfig config) internal view returns (IPool) {
    return IPool(poolAddress(config));
  }

  function getUSDC(GoldfinchConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(usdcAddress(config));
  }

  function getCreditDesk(GoldfinchConfig config) internal view returns (ICreditDesk) {
    return ICreditDesk(creditDeskAddress(config));
  }

  function getFidu(GoldfinchConfig config) internal view returns (IFidu) {
    return IFidu(fiduAddress(config));
  }

  function getCUSDCContract(GoldfinchConfig config) internal view returns (ICUSDCContract) {
    return ICUSDCContract(cusdcContractAddress(config));
  }

  function oneInchAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.OneInch));
  }

  function trustedForwarderAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TrustedForwarder));
  }

  function configAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.GoldfinchConfig));
  }

  function poolAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Pool));
  }

  function creditDeskAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CreditDesk));
  }

  function fiduAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.Fidu));
  }

  function cusdcContractAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.CUSDCContract));
  }

  function usdcAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.USDC));
  }

  function reserveAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.TreasuryReserve));
  }

  function protocolAdminAddress(GoldfinchConfig config) internal view returns (address) {
    return config.getAddress(uint256(ConfigOptions.Addresses.ProtocolAdmin));
  }

  function getReserveDenominator(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.ReserveDenominator));
  }

  function getWithdrawFeeDenominator(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.WithdrawFeeDenominator));
  }

  function getLatenessGracePeriodInDays(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.LatenessGracePeriodInDays));
  }

  function getLatenessMaxDays(GoldfinchConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(ConfigOptions.Numbers.LatenessMaxDays));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @title ConfigOptions
 * @notice A central place for enumerating the configurable options of our GoldfinchConfig contract
 * @author Goldfinch
 */

library ConfigOptions {
  // NEVER EVER CHANGE THE ORDER OF THESE!
  // You can rename or append. But NEVER change the order.
  enum Numbers {
    TransactionLimit,
    TotalFundsLimit,
    MaxUnderwriterLimit,
    ReserveDenominator,
    WithdrawFeeDenominator,
    LatenessGracePeriodInDays,
    LatenessMaxDays
  }
  enum Addresses {
    Pool,
    CreditLineImplementation,
    CreditLineFactory,
    CreditDesk,
    Fidu,
    USDC,
    TreasuryReserve,
    ProtocolAdmin,
    OneInch,
    TrustedForwarder,
    CUSDCContract,
    GoldfinchConfig
  }

  function getNumberName(uint256 number) public pure returns (string memory) {
    Numbers numberName = Numbers(number);
    if (Numbers.TransactionLimit == numberName) {
      return "TransactionLimit";
    }
    if (Numbers.TotalFundsLimit == numberName) {
      return "TotalFundsLimit";
    }
    if (Numbers.MaxUnderwriterLimit == numberName) {
      return "MaxUnderwriterLimit";
    }
    if (Numbers.ReserveDenominator == numberName) {
      return "ReserveDenominator";
    }
    if (Numbers.WithdrawFeeDenominator == numberName) {
      return "WithdrawFeeDenominator";
    }
    if (Numbers.LatenessGracePeriodInDays == numberName) {
      return "LatenessGracePeriodInDays";
    }
    if (Numbers.LatenessMaxDays == numberName) {
      return "LatenessMaxDays";
    }
    revert("Unknown value passed to getNumberName");
  }

  function getAddressName(uint256 addressKey) public pure returns (string memory) {
    Addresses addressName = Addresses(addressKey);
    if (Addresses.Pool == addressName) {
      return "Pool";
    }
    if (Addresses.CreditLineImplementation == addressName) {
      return "CreditLineImplementation";
    }
    if (Addresses.CreditLineFactory == addressName) {
      return "CreditLineFactory";
    }
    if (Addresses.CreditDesk == addressName) {
      return "CreditDesk";
    }
    if (Addresses.Fidu == addressName) {
      return "Fidu";
    }
    if (Addresses.USDC == addressName) {
      return "USDC";
    }
    if (Addresses.TreasuryReserve == addressName) {
      return "TreasuryReserve";
    }
    if (Addresses.ProtocolAdmin == addressName) {
      return "ProtocolAdmin";
    }
    if (Addresses.OneInch == addressName) {
      return "OneInch";
    }
    if (Addresses.TrustedForwarder == addressName) {
      return "TrustedForwarder";
    }
    if (Addresses.CUSDCContract == addressName) {
      return "CUSDCContract";
    }
    revert("Unknown value passed to getAddressName");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseUpgradeablePausable.sol";
import "./ConfigHelper.sol";
import "./Accountant.sol";
import "./CreditLine.sol";
import "./CreditLineFactory.sol";

/**
 * @title Goldfinch's CreditDesk contract
 * @notice Main entry point for borrowers and underwriters.
 *  Handles key logic for creating CreditLine's, borrowing money, repayment, etc.
 * @author Goldfinch
 */

contract CreditDesk is BaseUpgradeablePausable, ICreditDesk {
  // Approximate number of blocks per day
  uint256 public constant BLOCKS_PER_DAY = 5760;
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  struct Underwriter {
    uint256 governanceLimit;
    address[] creditLines;
  }

  struct Borrower {
    address[] creditLines;
  }

  event PaymentApplied(
    address indexed payer,
    address indexed creditLine,
    uint256 interestAmount,
    uint256 principalAmount,
    uint256 remainingAmount
  );
  event PaymentCollected(address indexed payer, address indexed creditLine, uint256 paymentAmount);
  event DrawdownMade(address indexed borrower, address indexed creditLine, uint256 drawdownAmount);
  event CreditLineCreated(address indexed borrower, address indexed creditLine);
  event GovernanceUpdatedUnderwriterLimit(address indexed underwriter, uint256 newLimit);

  mapping(address => Underwriter) public underwriters;
  mapping(address => Borrower) private borrowers;
  mapping(address => address) private creditLines;

  /**
   * @notice Run only once, on initialization
   * @param owner The address of who should have the "OWNER_ROLE" of this contract
   * @param _config The address of the GoldfinchConfig contract
   */
  function initialize(address owner, GoldfinchConfig _config) public initializer {
    __BaseUpgradeablePausable__init(owner);
    config = _config;
  }

  /**
   * @notice Sets a particular underwriter's limit of how much credit the DAO will allow them to "create"
   * @param underwriterAddress The address of the underwriter for whom the limit shall change
   * @param limit What the new limit will be set to
   * Requirements:
   *
   * - the caller must have the `OWNER_ROLE`.
   */
  function setUnderwriterGovernanceLimit(address underwriterAddress, uint256 limit)
    external
    override
    onlyAdmin
    whenNotPaused
  {
    require(withinMaxUnderwriterLimit(limit), "This limit is greater than the max allowed by the protocol");
    underwriters[underwriterAddress].governanceLimit = limit;
    emit GovernanceUpdatedUnderwriterLimit(underwriterAddress, limit);
  }

  /**
   * @notice Allows an underwriter to create a new CreditLine for a single borrower
   * @param _borrower The borrower for whom the CreditLine will be created
   * @param _limit The maximum amount a borrower can drawdown from this CreditLine
   * @param _interestApr The interest amount, on an annualized basis (APR, so non-compounding), expressed as an integer.
   *  We assume 8 digits of precision. For example, to submit 15.34%, you would pass up 15340000,
   *  and 5.34% would be 5340000
   * @param _paymentPeriodInDays How many days in each payment period.
   *  ie. the frequency with which they need to make payments.
   * @param _termInDays Number of days in the credit term. It is used to set the `termEndBlock` upon first drawdown.
   *  ie. The credit line should be fully paid off {_termIndays} days after the first drawdown.
   * @param _lateFeeApr The additional interest you will pay if you are late. For example, if this is 3%, and your
   *  normal rate is 15%, then you will pay 18% while you are late.
   *
   * Requirements:
   *
   * - the caller must be an underwriter with enough limit (see `setUnderwriterGovernanceLimit`)
   */
  function createCreditLine(
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr
  ) public override whenNotPaused returns (address) {
    Underwriter storage underwriter = underwriters[msg.sender];
    Borrower storage borrower = borrowers[_borrower];
    require(underwriterCanCreateThisCreditLine(_limit, underwriter), "The underwriter cannot create this credit line");

    address clAddress = getCreditLineFactory().createCreditLine();
    CreditLine cl = CreditLine(clAddress);
    cl.initialize(
      address(this),
      _borrower,
      msg.sender,
      _limit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr
    );

    underwriter.creditLines.push(clAddress);
    borrower.creditLines.push(clAddress);
    creditLines[clAddress] = clAddress;
    emit CreditLineCreated(_borrower, clAddress);

    cl.grantRole(keccak256("OWNER_ROLE"), config.protocolAdminAddress());
    cl.authorizePool(address(config));
    return clAddress;
  }

  /**
   * @notice Allows a borrower to drawdown on their creditline.
   *  `amount` USDC is sent to the borrower, and the credit line accounting is updated.
   * @param creditLineAddress The creditline from which they would like to drawdown
   * @param amount The amount, in USDC atomic units, that a borrower wishes to drawdown
   *
   * Requirements:
   *
   * - the caller must be the borrower on the creditLine
   */
  function drawdown(address creditLineAddress, uint256 amount)
    external
    override
    whenNotPaused
    onlyValidCreditLine(creditLineAddress)
  {
    CreditLine cl = CreditLine(creditLineAddress);
    Borrower storage borrower = borrowers[msg.sender];
    require(borrower.creditLines.length > 0, "No credit lines exist for this borrower");
    require(amount > 0, "Must drawdown more than zero");
    require(cl.borrower() == msg.sender, "You are not the borrower of this credit line");
    require(withinTransactionLimit(amount), "Amount is over the per-transaction limit");
    uint256 unappliedBalance = getUSDCBalance(creditLineAddress);
    require(
      withinCreditLimit(amount, unappliedBalance, cl),
      "The borrower does not have enough credit limit for this drawdown"
    );

    uint256 balance = cl.balance();

    if (balance == 0) {
      cl.setInterestAccruedAsOfBlock(blockNumber());
      cl.setLastFullPaymentBlock(blockNumber());
    }

    IPool pool = config.getPool();

    // If there is any balance on the creditline that has not been applied yet, then use that first before
    // drawing down from the pool. This is to support cases where the borrower partially pays back the
    // principal before the due date, but then decides to drawdown again
    uint256 amountToTransferFromCL;
    if (unappliedBalance > 0) {
      if (amount > unappliedBalance) {
        amountToTransferFromCL = unappliedBalance;
        amount = amount.sub(unappliedBalance);
      } else {
        amountToTransferFromCL = amount;
        amount = 0;
      }
      bool success = pool.transferFrom(creditLineAddress, msg.sender, amountToTransferFromCL);
      require(success, "Failed to drawdown");
    }

    (uint256 interestOwed, uint256 principalOwed) = updateAndGetInterestAndPrincipalOwedAsOf(cl, blockNumber());
    balance = balance.add(amount);

    updateCreditLineAccounting(cl, balance, interestOwed, principalOwed);

    // Must put this after we update the credit line accounting, so we're using the latest
    // interestOwed
    require(!isLate(cl), "Cannot drawdown when payments are past due");
    emit DrawdownMade(msg.sender, address(cl), amount.add(amountToTransferFromCL));

    if (amount > 0) {
      bool success = pool.drawdown(msg.sender, amount);
      require(success, "Failed to drawdown");
    }
  }

  /**
   * @notice Allows a borrower to repay their loan. Payment is *collected* immediately (by sending it to
   *  the individual CreditLine), but it is not *applied* unless it is after the nextDueBlock, or until we assess
   *  the credit line (ie. payment period end).
   *  Any amounts over the minimum payment will be applied to outstanding principal (reducing the effective
   *  interest rate). If there is still any left over, it will remain in the USDC Balance
   *  of the CreditLine, which is held distinct from the Pool amounts, and can not be withdrawn by LP's.
   * @param creditLineAddress The credit line to be paid back
   * @param amount The amount, in USDC atomic units, that a borrower wishes to pay
   */
  function pay(address creditLineAddress, uint256 amount)
    external
    override
    whenNotPaused
    onlyValidCreditLine(creditLineAddress)
  {
    require(amount > 0, "Must pay more than zero");
    CreditLine cl = CreditLine(creditLineAddress);

    collectPayment(cl, amount);
    assessCreditLine(creditLineAddress);
  }

  /**
   * @notice Assesses a particular creditLine. This will apply payments, which will update accounting and
   *  distribute gains or losses back to the pool accordingly. This function is idempotent, and anyone
   *  is allowed to call it.
   * @param creditLineAddress The creditline that should be assessed.
   */
  function assessCreditLine(address creditLineAddress)
    public
    override
    whenNotPaused
    onlyValidCreditLine(creditLineAddress)
  {
    CreditLine cl = CreditLine(creditLineAddress);
    // Do not assess until a full period has elapsed or past due
    require(cl.balance() > 0, "Must have balance to assess credit line");

    // Don't assess credit lines early!
    if (blockNumber() < cl.nextDueBlock() && !isLate(cl)) {
      return;
    }

    uint256 blockToAssess = calculateNextDueBlock(cl);
    cl.setNextDueBlock(blockToAssess);

    // We always want to assess for the most recently *past* nextDueBlock.
    // So if the recalculation above sets the nextDueBlock into the future,
    // then ensure we pass in the one just before this.
    if (blockToAssess > blockNumber()) {
      uint256 blocksPerPeriod = cl.paymentPeriodInDays().mul(BLOCKS_PER_DAY);
      blockToAssess = blockToAssess.sub(blocksPerPeriod);
    }
    _applyPayment(cl, getUSDCBalance(address(cl)), blockToAssess);
  }

  function applyPayment(address creditLineAddress, uint256 amount)
    external
    override
    whenNotPaused
    onlyValidCreditLine(creditLineAddress)
  {
    CreditLine cl = CreditLine(creditLineAddress);
    require(cl.borrower() == msg.sender, "You do not belong to this credit line");
    _applyPayment(cl, amount, blockNumber());
  }

  function migrateCreditLine(
    CreditLine clToMigrate,
    address borrower,
    uint256 limit,
    uint256 interestApr,
    uint256 paymentPeriodInDays,
    uint256 termInDays,
    uint256 lateFeeApr
  ) public {
    require(clToMigrate.underwriter() == msg.sender, "Caller must be the underwriter");
    require(clToMigrate.limit() > 0, "Can't migrate empty credit line");
    address newClAddress = createCreditLine(borrower, limit, interestApr, paymentPeriodInDays, termInDays, lateFeeApr);

    CreditLine newCl = CreditLine(newClAddress);

    // Set accounting state vars.
    newCl.setBalance(clToMigrate.balance());
    newCl.setInterestOwed(clToMigrate.interestOwed());
    newCl.setPrincipalOwed(clToMigrate.principalOwed());
    newCl.setTermEndBlock(clToMigrate.termEndBlock());
    newCl.setNextDueBlock(clToMigrate.nextDueBlock());
    newCl.setInterestAccruedAsOfBlock(clToMigrate.interestAccruedAsOfBlock());
    newCl.setWritedownAmount(clToMigrate.writedownAmount());
    newCl.setLastFullPaymentBlock(clToMigrate.lastFullPaymentBlock());

    // Close out the original credit line
    clToMigrate.setLimit(0);
    clToMigrate.setBalance(0);
    bool success = config.getPool().transferFrom(
      address(clToMigrate),
      address(newCl),
      config.getUSDC().balanceOf(address(clToMigrate))
    );
    require(success, "Failed to transfer funds");
  }

  // Public View Functions (Getters)

  /**
   * @notice Simple getter for the creditlines of a given underwriter
   * @param underwriterAddress The underwriter address you would like to see the credit lines of.
   */
  function getUnderwriterCreditLines(address underwriterAddress) public view returns (address[] memory) {
    return underwriters[underwriterAddress].creditLines;
  }

  /**
   * @notice Simple getter for the creditlines of a given borrower
   * @param borrowerAddress The borrower address you would like to see the credit lines of.
   */
  function getBorrowerCreditLines(address borrowerAddress) public view returns (address[] memory) {
    return borrowers[borrowerAddress].creditLines;
  }

  /**
   * @notice This function is only meant to be used by frontends. It returns the total
   * payment due for a given creditLine as of the provided blocknumber. Returns 0 if no
   * payment is due (e.g. asOfBLock is before the nextDueBlock)
   * @param creditLineAddress The creditLine to calculate the payment for
   * @param asOfBLock The block to use for the payment calculation, if it is set to 0, uses the current block number
   */
  function getNextPaymentAmount(address creditLineAddress, uint256 asOfBLock)
    external
    view
    override
    onlyValidCreditLine(creditLineAddress)
    returns (uint256)
  {
    if (asOfBLock == 0) {
      asOfBLock = blockNumber();
    }
    CreditLine cl = CreditLine(creditLineAddress);

    if (asOfBLock < cl.nextDueBlock() && !isLate(cl)) {
      return 0;
    }

    (uint256 interestAccrued, uint256 principalAccrued) = Accountant.calculateInterestAndPrincipalAccrued(
      cl,
      asOfBLock,
      config.getLatenessGracePeriodInDays()
    );
    return cl.interestOwed().add(interestAccrued).add(cl.principalOwed().add(principalAccrued));
  }

  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
  }

  /*
   * Internal Functions
   */

  /**
   * @notice Collects `amount` of payment for a given credit line. This sends money from the payer to the credit line.
   *  Note that payment is not *applied* when calling this function. Only collected (ie. held) for later application.
   * @param cl The CreditLine the payment will be collected for.
   * @param amount The amount, in USDC atomic units, to be collected
   */
  function collectPayment(CreditLine cl, uint256 amount) internal {
    require(withinTransactionLimit(amount), "Amount is over the per-transaction limit");

    emit PaymentCollected(msg.sender, address(cl), amount);

    bool success = config.getPool().transferFrom(msg.sender, address(cl), amount);
    require(success, "Failed to collect payment");
  }

  /**
   * @notice Applies `amount` of payment for a given credit line. This moves already collected money into the Pool.
   *  It also updates all the accounting variables. Note that interest is always paid back first, then principal.
   *  Any extra after paying the minimum will go towards existing principal (reducing the
   *  effective interest rate). Any extra after the full loan has been paid off will remain in the
   *  USDC Balance of the creditLine, where it will be automatically used for the next drawdown.
   * @param cl The CreditLine the payment will be collected for.
   * @param amount The amount, in USDC atomic units, to be applied
   * @param blockNumber The blockNumber on which accrual calculations should be based. This allows us
   *  to be precise when we assess a Credit Line
   */
  function _applyPayment(
    CreditLine cl,
    uint256 amount,
    uint256 blockNumber
  ) internal {
    (uint256 paymentRemaining, uint256 interestPayment, uint256 principalPayment) = handlePayment(
      cl,
      amount,
      blockNumber
    );

    IPool pool = config.getPool();
    updateWritedownAmounts(cl, pool);

    if (interestPayment > 0 || principalPayment > 0) {
      emit PaymentApplied(cl.borrower(), address(cl), interestPayment, principalPayment, paymentRemaining);
      pool.collectInterestAndPrincipal(address(cl), interestPayment, principalPayment);
    }
  }

  function handlePayment(
    CreditLine cl,
    uint256 paymentAmount,
    uint256 asOfBlock
  )
    internal
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    (uint256 interestOwed, uint256 principalOwed) = updateAndGetInterestAndPrincipalOwedAsOf(cl, asOfBlock);
    Accountant.PaymentAllocation memory pa = Accountant.allocatePayment(
      paymentAmount,
      cl.balance(),
      interestOwed,
      principalOwed
    );

    uint256 newBalance = cl.balance().sub(pa.principalPayment);
    // Apply any additional payment towards the balance
    newBalance = newBalance.sub(pa.additionalBalancePayment);

    uint256 totalPrincipalPayment = cl.balance().sub(newBalance);
    uint256 paymentRemaining = paymentAmount.sub(pa.interestPayment).sub(totalPrincipalPayment);

    updateCreditLineAccounting(
      cl,
      newBalance,
      interestOwed.sub(pa.interestPayment),
      principalOwed.sub(pa.principalPayment)
    );

    assert(paymentRemaining.add(pa.interestPayment).add(totalPrincipalPayment) == paymentAmount);

    return (paymentRemaining, pa.interestPayment, totalPrincipalPayment);
  }

  function updateWritedownAmounts(CreditLine cl, IPool pool) internal {
    (uint256 writedownPercent, uint256 writedownAmount) = Accountant.calculateWritedownFor(
      cl,
      blockNumber(),
      config.getLatenessGracePeriodInDays(),
      config.getLatenessMaxDays()
    );

    if (writedownPercent == 0 && cl.writedownAmount() == 0) {
      return;
    }
    int256 writedownDelta = int256(cl.writedownAmount()) - int256(writedownAmount);
    cl.setWritedownAmount(writedownAmount);
    if (writedownDelta > 0) {
      // If writedownDelta is positive, that means we got money back. So subtract from totalWritedowns.
      totalWritedowns = totalWritedowns.sub(uint256(writedownDelta));
    } else {
      totalWritedowns = totalWritedowns.add(uint256(writedownDelta * -1));
    }
    pool.distributeLosses(address(cl), writedownDelta);
  }

  function isLate(CreditLine cl) internal view returns (bool) {
    uint256 blocksElapsedSinceFullPayment = blockNumber().sub(cl.lastFullPaymentBlock());
    return blocksElapsedSinceFullPayment > cl.paymentPeriodInDays().mul(BLOCKS_PER_DAY);
  }

  function getCreditLineFactory() internal view returns (CreditLineFactory) {
    return CreditLineFactory(config.getAddress(uint256(ConfigOptions.Addresses.CreditLineFactory)));
  }

  function updateAndGetInterestAndPrincipalOwedAsOf(CreditLine cl, uint256 blockNumber)
    internal
    returns (uint256, uint256)
  {
    (uint256 interestAccrued, uint256 principalAccrued) = Accountant.calculateInterestAndPrincipalAccrued(
      cl,
      blockNumber,
      config.getLatenessGracePeriodInDays()
    );
    if (interestAccrued > 0) {
      // If we've accrued any interest, update interestAccruedAsOfBLock to the block that we've
      // calculated interest for. If we've not accrued any interest, then we keep the old value so the next
      // time the entire period is taken into account.
      cl.setInterestAccruedAsOfBlock(blockNumber);
    }
    return (cl.interestOwed().add(interestAccrued), cl.principalOwed().add(principalAccrued));
  }

  function withinCreditLimit(
    uint256 amount,
    uint256 unappliedBalance,
    CreditLine cl
  ) internal view returns (bool) {
    return cl.balance().add(amount).sub(unappliedBalance) <= cl.limit();
  }

  function withinTransactionLimit(uint256 amount) internal view returns (bool) {
    return amount <= config.getNumber(uint256(ConfigOptions.Numbers.TransactionLimit));
  }

  function calculateNewTermEndBlock(CreditLine cl, uint256 balance) internal view returns (uint256) {
    // If there's no balance, there's no loan, so there's no term end block
    if (balance == 0) {
      return 0;
    }
    // Don't allow any weird bugs where we add to your current end block. This
    // function should only be used on new credit lines, when we are setting them up
    if (cl.termEndBlock() != 0) {
      return cl.termEndBlock();
    }
    return blockNumber().add(BLOCKS_PER_DAY.mul(cl.termInDays()));
  }

  function calculateNextDueBlock(CreditLine cl) internal view returns (uint256) {
    uint256 blocksPerPeriod = cl.paymentPeriodInDays().mul(BLOCKS_PER_DAY);
    uint256 balance = cl.balance();
    uint256 nextDueBlock = cl.nextDueBlock();
    uint256 curBlockNumber = blockNumber();
    // You must have just done your first drawdown
    if (nextDueBlock == 0 && balance > 0) {
      return curBlockNumber.add(blocksPerPeriod);
    }

    // Active loan that has entered a new period, so return the *next* nextDueBlock.
    // But never return something after the termEndBlock
    if (balance > 0 && curBlockNumber >= nextDueBlock) {
      uint256 blocksToAdvance = (curBlockNumber.sub(nextDueBlock).div(blocksPerPeriod)).add(1).mul(blocksPerPeriod);
      nextDueBlock = nextDueBlock.add(blocksToAdvance);
      return Math.min(nextDueBlock, cl.termEndBlock());
    }

    // Your paid off, or have not taken out a loan yet, so no next due block.
    if (balance == 0 && nextDueBlock != 0) {
      return 0;
    }
    // Active loan in current period, where we've already set the nextDueBlock correctly, so should not change.
    if (balance > 0 && curBlockNumber < nextDueBlock) {
      return nextDueBlock;
    }
    revert("Error: could not calculate next due block.");
  }

  function blockNumber() internal view virtual returns (uint256) {
    return block.number;
  }

  function underwriterCanCreateThisCreditLine(uint256 newAmount, Underwriter storage underwriter)
    internal
    view
    returns (bool)
  {
    uint256 underwriterLimit = underwriter.governanceLimit;
    require(underwriterLimit != 0, "underwriter does not have governance limit");
    uint256 creditCurrentlyExtended = getCreditCurrentlyExtended(underwriter);
    uint256 totalToBeExtended = creditCurrentlyExtended.add(newAmount);
    return totalToBeExtended <= underwriterLimit;
  }

  function withinMaxUnderwriterLimit(uint256 amount) internal view returns (bool) {
    return amount <= config.getNumber(uint256(ConfigOptions.Numbers.MaxUnderwriterLimit));
  }

  function getCreditCurrentlyExtended(Underwriter storage underwriter) internal view returns (uint256) {
    uint256 creditExtended;
    uint256 length = underwriter.creditLines.length;
    for (uint256 i = 0; i < length; i++) {
      CreditLine cl = CreditLine(underwriter.creditLines[i]);
      creditExtended = creditExtended.add(cl.limit());
    }
    return creditExtended;
  }

  function updateCreditLineAccounting(
    CreditLine cl,
    uint256 balance,
    uint256 interestOwed,
    uint256 principalOwed
  ) internal nonReentrant {
    // subtract cl from total loans outstanding
    totalLoansOutstanding = totalLoansOutstanding.sub(cl.balance());

    cl.setBalance(balance);
    cl.setInterestOwed(interestOwed);
    cl.setPrincipalOwed(principalOwed);

    // This resets lastFullPaymentBlock. These conditions assure that they have
    // indeed paid off all their interest and they have a real nextDueBlock. (ie. creditline isn't pre-drawdown)
    uint256 nextDueBlock = cl.nextDueBlock();
    if (interestOwed == 0 && nextDueBlock != 0) {
      // If interest was fully paid off, then set the last full payment as the previous due block
      uint256 mostRecentLastDueBlock;
      if (blockNumber() < nextDueBlock) {
        uint256 blocksPerPeriod = cl.paymentPeriodInDays().mul(BLOCKS_PER_DAY);
        mostRecentLastDueBlock = nextDueBlock.sub(blocksPerPeriod);
      } else {
        mostRecentLastDueBlock = nextDueBlock;
      }
      cl.setLastFullPaymentBlock(mostRecentLastDueBlock);
    }

    // Add new amount back to total loans outstanding
    totalLoansOutstanding = totalLoansOutstanding.add(balance);

    cl.setTermEndBlock(calculateNewTermEndBlock(cl, balance)); // pass in balance as a gas optimization
    cl.setNextDueBlock(calculateNextDueBlock(cl));
  }

  function getUSDCBalance(address _address) internal view returns (uint256) {
    return config.getUSDC().balanceOf(_address);
  }

  modifier onlyValidCreditLine(address clAddress) {
    require(creditLines[clAddress] != address(0), "Unknown credit line");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./GoldfinchConfig.sol";
import "./BaseUpgradeablePausable.sol";
import "../../interfaces/IERC20withDec.sol";

/**
 * @title CreditLine
 * @notice A "dumb" state container that represents the agreement between an Underwriter and
 *  the borrower. Includes the terms of the loan, as well as the current accounting state, such as interest owed.
 *  This contract purposefully has essentially no business logic. Really just setters and getters.
 * @author Goldfinch
 */

// solhint-disable-next-line max-states-count
contract CreditLine is BaseUpgradeablePausable {
  // Credit line terms
  address public borrower;
  address public underwriter;
  uint256 public limit;
  uint256 public interestApr;
  uint256 public paymentPeriodInDays;
  uint256 public termInDays;
  uint256 public lateFeeApr;

  // Accounting variables
  uint256 public balance;
  uint256 public interestOwed;
  uint256 public principalOwed;
  uint256 public termEndBlock;
  uint256 public nextDueBlock;
  uint256 public interestAccruedAsOfBlock;
  uint256 public writedownAmount;
  uint256 public lastFullPaymentBlock;

  function initialize(
    address owner,
    address _borrower,
    address _underwriter,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr
  ) public initializer {
    require(owner != address(0) && _borrower != address(0) && _underwriter != address(0), "Zero address passed in");
    __BaseUpgradeablePausable__init(owner);
    borrower = _borrower;
    underwriter = _underwriter;
    limit = _limit;
    interestApr = _interestApr;
    paymentPeriodInDays = _paymentPeriodInDays;
    termInDays = _termInDays;
    lateFeeApr = _lateFeeApr;
    interestAccruedAsOfBlock = block.number;
  }

  function setTermEndBlock(uint256 newTermEndBlock) external onlyAdmin {
    termEndBlock = newTermEndBlock;
  }

  function setNextDueBlock(uint256 newNextDueBlock) external onlyAdmin {
    nextDueBlock = newNextDueBlock;
  }

  function setBalance(uint256 newBalance) external onlyAdmin {
    balance = newBalance;
  }

  function setInterestOwed(uint256 newInterestOwed) external onlyAdmin {
    interestOwed = newInterestOwed;
  }

  function setPrincipalOwed(uint256 newPrincipalOwed) external onlyAdmin {
    principalOwed = newPrincipalOwed;
  }

  function setInterestAccruedAsOfBlock(uint256 newInterestAccruedAsOfBlock) external onlyAdmin {
    interestAccruedAsOfBlock = newInterestAccruedAsOfBlock;
  }

  function setWritedownAmount(uint256 newWritedownAmount) external onlyAdmin {
    writedownAmount = newWritedownAmount;
  }

  function setLastFullPaymentBlock(uint256 newLastFullPaymentBlock) external onlyAdmin {
    lastFullPaymentBlock = newLastFullPaymentBlock;
  }

  function setLateFeeApr(uint256 newLateFeeApr) external onlyAdmin {
    lateFeeApr = newLateFeeApr;
  }

  function setLimit(uint256 newAmount) external onlyAdminOrUnderwriter {
    limit = newAmount;
  }

  function authorizePool(address configAddress) external onlyAdmin {
    GoldfinchConfig config = GoldfinchConfig(configAddress);
    address poolAddress = config.getAddress(uint256(ConfigOptions.Addresses.Pool));
    address usdcAddress = config.getAddress(uint256(ConfigOptions.Addresses.USDC));
    // Approve the pool for an infinite amount
    bool success = IERC20withDec(usdcAddress).approve(poolAddress, uint256(-1));
    require(success, "Failed to approve USDC");
  }

  modifier onlyAdminOrUnderwriter() {
    require(isAdmin() || _msgSender() == underwriter, "Restricted to owner or underwriter");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./GoldfinchConfig.sol";
import "./BaseUpgradeablePausable.sol";
import "../periphery/Borrower.sol";
import "./CreditLine.sol";
import "./ConfigHelper.sol";

/**
 * @title CreditLineFactory
 * @notice Contract that allows us to create other contracts, such as CreditLines and BorrowerContracts
 * @author Goldfinch
 */

contract CreditLineFactory is BaseUpgradeablePausable {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  event BorrowerCreated(address indexed borrower, address indexed owner);

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    __BaseUpgradeablePausable__init(owner);
    config = _config;
  }

  function createCreditLine() external returns (address) {
    CreditLine newCreditLine = new CreditLine();
    return address(newCreditLine);
  }

  /**
   * @notice Allows anyone to create a Borrower contract instance
   * @param owner The address that will own the new Borrower instance
   */
  function createBorrower(address owner) external returns (address) {
    Borrower borrower = new Borrower();
    borrower.initialize(owner, config);
    emit BorrowerCreated(address(borrower), owner);
    return address(borrower);
  }

  function updateGoldfinchConfig() external onlyAdmin {
    config = GoldfinchConfig(config.configAddress());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BaseUpgradeablePausable.sol";
import "./ConfigOptions.sol";

/**
 * @title GoldfinchConfig
 * @notice This contract stores mappings of useful "protocol config state", giving a central place
 *  for all other contracts to access it. For example, the TransactionLimit, or the PoolAddress. These config vars
 *  are enumerated in the `ConfigOptions` library, and can only be changed by admins of the protocol.
 * @author Goldfinch
 */

contract GoldfinchConfig is BaseUpgradeablePausable {
  mapping(uint256 => address) public addresses;
  mapping(uint256 => uint256) public numbers;

  event AddressUpdated(address owner, uint256 index, address oldValue, address newValue);
  event NumberUpdated(address owner, uint256 index, uint256 oldValue, uint256 newValue);

  function initialize(address owner) public initializer {
    __BaseUpgradeablePausable__init(owner);
  }

  function setAddress(uint256 addressIndex, address newAddress) public onlyAdmin {
    require(addresses[addressIndex] == address(0), "Address has already been initialized");

    emit AddressUpdated(msg.sender, addressIndex, addresses[addressIndex], newAddress);
    addresses[addressIndex] = newAddress;
  }

  function setNumber(uint256 index, uint256 newNumber) public onlyAdmin {
    emit NumberUpdated(msg.sender, index, numbers[index], newNumber);
    numbers[index] = newNumber;
  }

  function setTreasuryReserve(address newTreasuryReserve) public onlyAdmin {
    uint256 key = uint256(ConfigOptions.Addresses.TreasuryReserve);
    emit AddressUpdated(msg.sender, key, addresses[key], newTreasuryReserve);
    addresses[key] = newTreasuryReserve;
  }

  /*
    Using custom getters incase we want to change underlying implementation later,
    or add checks or validations later on.
  */
  function getAddress(uint256 addressKey) public view returns (address) {
    return addresses[addressKey];
  }

  function getNumber(uint256 number) public view returns (uint256) {
    return numbers[number];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/AccessControl.sol";

/**
 * @title PauserPausable
 * @notice Inheriting from OpenZeppelin's Pausable contract, this does small
 *  augmentations to make it work with a PAUSER_ROLE, leveraging the AccessControl contract.
 *  It is meant to be inherited.
 * @author Goldfinch
 */

contract PauserPausable is AccessControlUpgradeSafe, PausableUpgradeSafe {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  // solhint-disable-next-line func-name-mixedcase
  function __PauserPausable__init() public initializer {
    __Pausable_init_unchained();
  }

  /**
   * @dev Pauses all functions guarded by Pause
   *
   * See {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the PAUSER_ROLE.
   */

  function pause() public onlyPauserRole {
    _pause();
  }

  /**
   * @dev Unpauses the contract
   *
   * See {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the Pauser role
   */
  function unpause() public onlyPauserRole {
    _unpause();
  }

  modifier onlyPauserRole() {
    require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to perform this action");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../core/BaseUpgradeablePausable.sol";
import "../core/ConfigHelper.sol";
import "../core/CreditLine.sol";
import "../../interfaces/IERC20withDec.sol";
import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @title Goldfinch's Borrower contract
 * @notice These contracts represent the a convenient way for a borrower to interact with Goldfinch
 *  They are 100% optional. However, they let us add many sophisticated and convient features for borrowers
 *  while still keeping our core protocol small and secure. We therefore expect most borrowers will use them.
 *  This contract is the "official" borrower contract that will be maintained by Goldfinch governance. However,
 *  in theory, anyone can fork or create their own version, or not use any contract at all. The core functionality
 *  is completely agnostic to whether it is interacting with a contract or an externally owned account (EOA).
 * @author Goldfinch
 */

contract Borrower is BaseUpgradeablePausable, BaseRelayRecipient {
  using SafeMath for uint256;

  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  address private constant USDT_ADDRESS = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address private constant BUSD_ADDRESS = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(owner != address(0), "Owner cannot be empty");
    __BaseUpgradeablePausable__init(owner);
    config = _config;

    trustedForwarder = config.trustedForwarderAddress();

    // Handle default approvals. Pool, and OneInch for maximum amounts
    address oneInch = config.oneInchAddress();
    IERC20withDec usdc = config.getUSDC();
    usdc.approve(config.poolAddress(), uint256(-1));
    usdc.approve(oneInch, uint256(-1));
    bytes memory data = abi.encodeWithSignature("approve(address,uint256)", oneInch, uint256(-1));
    invoke(USDT_ADDRESS, data);
    invoke(BUSD_ADDRESS, data);
  }

  /**
   * @notice Allows a borrower to drawdown on their creditline through the CreditDesk.
   * @param creditLineAddress The creditline from which they would like to drawdown
   * @param amount The amount, in USDC atomic units, that a borrower wishes to drawdown
   * @param addressToSendTo The address where they would like the funds sent. If the zero address is passed,
   *  it will be defaulted to the contracts address (msg.sender). This is a convenience feature for when they would
   *  like the funds sent to an exchange or alternate wallet, different from the authentication address
   */
  function drawdown(
    address creditLineAddress,
    uint256 amount,
    address addressToSendTo
  ) external onlyAdmin {
    config.getCreditDesk().drawdown(creditLineAddress, amount);

    if (addressToSendTo == address(0) || addressToSendTo == address(this)) {
      addressToSendTo = _msgSender();
    }

    transferERC20(config.usdcAddress(), addressToSendTo, amount);
  }

  function drawdownWithSwapOnOneInch(
    address creditLineAddress,
    uint256 amount,
    address addressToSendTo,
    address toToken,
    uint256 minTargetAmount,
    uint256[] calldata exchangeDistribution
  ) public onlyAdmin {
    // Drawdown to the Borrower contract
    config.getCreditDesk().drawdown(creditLineAddress, amount);

    // Do the swap
    swapOnOneInch(config.usdcAddress(), toToken, amount, minTargetAmount, exchangeDistribution);

    // Default to sending to the owner, and don't let funds stay in this contract
    if (addressToSendTo == address(0) || addressToSendTo == address(this)) {
      addressToSendTo = _msgSender();
    }

    // Fulfill the send to
    bytes memory _data = abi.encodeWithSignature("balanceOf(address)", address(this));
    uint256 receivedAmount = toUint256(invoke(toToken, _data));
    transferERC20(toToken, addressToSendTo, receivedAmount);
  }

  function transferERC20(
    address token,
    address to,
    uint256 amount
  ) public onlyAdmin {
    bytes memory _data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
    invoke(token, _data);
  }

  /**
   * @notice Allows a borrower to payback loans by calling the `pay` function directly on the CreditDesk
   * @param creditLineAddress The credit line to be paid back
   * @param amount The amount, in USDC atomic units, that the borrower wishes to pay
   */
  function pay(address creditLineAddress, uint256 amount) external onlyAdmin {
    bool success = config.getUSDC().transferFrom(_msgSender(), address(this), amount);
    require(success, "Failed to transfer USDC");
    config.getCreditDesk().pay(creditLineAddress, amount);
  }

  function payMultiple(address[] calldata creditLines, uint256[] calldata amounts) external onlyAdmin {
    require(creditLines.length == amounts.length, "Creditlines and amounts must be the same length");

    uint256 totalAmount;
    for (uint256 i = 0; i < amounts.length; i++) {
      totalAmount = totalAmount.add(amounts[i]);
    }

    // Do a single transfer, which is cheaper
    bool success = config.getUSDC().transferFrom(_msgSender(), address(this), totalAmount);
    require(success, "Failed to transfer USDC");

    ICreditDesk creditDesk = config.getCreditDesk();
    for (uint256 i = 0; i < amounts.length; i++) {
      creditDesk.pay(creditLines[i], amounts[i]);
    }
  }

  function payInFull(address creditLineAddress, uint256 amount) external onlyAdmin {
    bool success = config.getUSDC().transferFrom(_msgSender(), creditLineAddress, amount);
    require(success, "Failed to transfer USDC");

    config.getCreditDesk().applyPayment(creditLineAddress, amount);
    require(CreditLine(creditLineAddress).balance() == 0, "Failed to fully pay off creditline");
  }

  function payWithSwapOnOneInch(
    address creditLineAddress,
    uint256 originAmount,
    address fromToken,
    uint256 minTargetAmount,
    uint256[] memory exchangeDistribution
  ) external onlyAdmin {
    transferFrom(fromToken, _msgSender(), address(this), originAmount);
    IERC20withDec usdc = config.getUSDC();
    swapOnOneInch(fromToken, address(usdc), originAmount, minTargetAmount, exchangeDistribution);
    uint256 usdcBalance = usdc.balanceOf(address(this));
    config.getCreditDesk().pay(creditLineAddress, usdcBalance);
  }

  function payMultipleWithSwapOnOneInch(
    address[] memory creditLines,
    uint256[] memory minAmounts,
    uint256 originAmount,
    address fromToken,
    uint256[] memory exchangeDistribution
  ) external onlyAdmin {
    require(creditLines.length == minAmounts.length, "Creditlines and amounts must be the same length");

    uint256 totalMinAmount = 0;
    for (uint256 i = 0; i < minAmounts.length; i++) {
      totalMinAmount = totalMinAmount.add(minAmounts[i]);
    }

    transferFrom(fromToken, _msgSender(), address(this), originAmount);

    IERC20withDec usdc = config.getUSDC();
    swapOnOneInch(fromToken, address(usdc), originAmount, totalMinAmount, exchangeDistribution);

    ICreditDesk creditDesk = config.getCreditDesk();
    for (uint256 i = 0; i < minAmounts.length; i++) {
      creditDesk.pay(creditLines[i], minAmounts[i]);
    }

    uint256 remainingUSDC = usdc.balanceOf(address(this));
    if (remainingUSDC > 0) {
      bool success = usdc.transfer(creditLines[0], remainingUSDC);
      require(success, "Failed to transfer USDC");
    }
  }

  function transferFrom(
    address erc20,
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    bytes memory _data;
    // Do a low-level invoke on this transfer, since Tether fails if we use the normal IERC20 interface
    _data = abi.encodeWithSignature("transferFrom(address,address,uint256)", sender, recipient, amount);
    invoke(address(erc20), _data);
  }

  function swapOnOneInch(
    address fromToken,
    address toToken,
    uint256 originAmount,
    uint256 minTargetAmount,
    uint256[] memory exchangeDistribution
  ) internal {
    bytes memory _data = abi.encodeWithSignature(
      "swap(address,address,uint256,uint256,uint256[],uint256)",
      fromToken,
      toToken,
      originAmount,
      minTargetAmount,
      exchangeDistribution,
      0
    );
    invoke(config.oneInchAddress(), _data);
  }

  /**
   * @notice Performs a generic transaction.
   * @param _target The address for the transaction.
   * @param _data The data of the transaction.
   * Mostly copied from Argent:
   * https://github.com/argentlabs/argent-contracts/blob/develop/contracts/wallet/BaseWallet.sol#L111
   */
  function invoke(address _target, bytes memory _data) internal returns (bytes memory) {
    // External contracts can be compiled with different Solidity versions
    // which can cause "revert without reason" when called through,
    // for example, a standard IERC20 ABI compiled on the latest version.
    // This low-level call avoids that issue.

    bool success;
    bytes memory _res;
    // solhint-disable-next-line avoid-low-level-calls
    (success, _res) = _target.call(_data);
    if (!success && _res.length > 0) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    } else if (!success) {
      revert("VM: wallet invoke reverted");
    }
    return _res;
  }

  function toUint256(bytes memory _bytes) internal pure returns (uint256 value) {
    assembly {
      value := mload(add(_bytes, 0x20))
    }
  }

  // OpenZeppelin contracts come with support for GSN _msgSender() (which just defaults to msg.sender)
  // Since there are two different versions of the function in the hierarchy, we need to instruct solidity to
  // use the relay recipient version which can actually pull the real sender from the parameters.
  // https://www.notion.so/My-contract-is-using-OpenZeppelin-How-do-I-add-GSN-support-2bee7e9d5f774a0cbb60d3a8de03e9fb
  function _msgSender() internal view override(ContextUpgradeSafe, BaseRelayRecipient) returns (address payable) {
    return BaseRelayRecipient._msgSender();
  }

  function _msgData() internal view override(ContextUpgradeSafe, BaseRelayRecipient) returns (bytes memory ret) {
    return BaseRelayRecipient._msgData();
  }

  function versionRecipient() external view override returns (string memory) {
    return "2.0.0";
  }
}

