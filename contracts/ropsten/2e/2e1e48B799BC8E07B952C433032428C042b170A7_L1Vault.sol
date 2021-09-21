// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

interface IGatewayRouter {
    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "../BridgeBase.sol";

import "./IGatewayRouter.sol";

contract VaultArbitrum is BridgeBase {
    IGatewayRouter public gatewayRouter;

    constructor(address _router) public {
        require(_router != address(0), "Invalid address");
        gatewayRouter = IGatewayRouter(_router);
    }

    function setGateWayRouter(address _router) external onlyAdmin {
        require(_router != address(0), "Invalid address");
        gatewayRouter = IGatewayRouter(_router);
    }

    function _transferL2Implementation(
        uint256 amount,
        address token,
        bytes memory data,
        address destination
    ) internal override {
        SafeERC20.safeIncreaseAllowance(
            IERC20(token),
            address(gatewayRouter),
            amount
        );
        (uint256 maxGas, uint256 gasPriceBid, bytes memory _data) = abi.decode(
            data,
            (uint256, uint256, bytes)
        );
        gatewayRouter.outboundTransfer{value: msg.value}(
            token,
            destination,
            amount,
            maxGas,
            gasPriceBid,
            _data
        );
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IBridgeBase.sol";
import "../libraries/FeeOperations.sol";

abstract contract BridgeBase is IBridgeBase, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public constant FEES_EXCLUDED = keccak256("FEES_EXCLUDED");
    bytes32 public constant FEES_COLLECTOR = keccak256("FEES_COLLECTOR");

    uint256 fee;

    mapping(address => bool) public supportedTokens;
    mapping(address => mapping(address => uint256)) balances;

    event Deposit(
        address indexed account,
        address indexed erc20,
        uint256 value,
        uint256 feeValue
    );
    event TokenAdded(address indexed erc20);
    event TokenRemoved(address indexed erc20);
    event FeeChanged(uint256 fee);
    event WithdrawalCompleted(
        address accountTo,
        uint256 amount,
        address tokenAddress
    );

    constructor() internal {
        fee = 0;
        _setInitialRoles();
    }

    modifier onlySupportedToken(address tokenAddress) {
        require(supportedTokens[tokenAddress], "Unsupported token");
        _;
    }

    function addSupportedToken(address tokenAddress)
        external
        override
        onlyAdmin
    {
        require(tokenAddress != address(0), "Invalid token address");
        supportedTokens[tokenAddress] = true;
        emit TokenAdded(tokenAddress);
    }

    function setFee(uint256 newFee) external override onlyAdmin {
        fee = newFee;
        emit FeeChanged(fee);
    }

    function removeSupportedToken(address tokenAddress)
        external
        override
        onlyAdmin
    {
        require(tokenAddress != address(0), "Invalid token address");
        delete supportedTokens[tokenAddress];
        emit TokenRemoved(tokenAddress);
    }

    /**
     * @notice Deposits ERC20 token into vault and initiate L2 implementation specific transfer
     * @param amount Token amount
     * @param tokenAddress Token address on L2
     */
    function depositERC20(
        uint256 amount,
        address tokenAddress,
        bytes calldata data
    ) external payable override onlySupportedToken(tokenAddress) {
        _depositERC20(amount, tokenAddress, data, msg.sender);
    }

    /**
     * @notice Deposits ERC20 token into vault and initiate L2 implementation specific transfer for custom destination address
     * @param amount Token amount
     * @param tokenAddress Token address on L1
     * @param destination Destination of the token on L2
     */
    function depositERC20ForAddress(
        uint256 amount,
        address tokenAddress,
        bytes calldata data,
        address destination
    ) external payable override onlySupportedToken(tokenAddress) {
        _depositERC20(amount, tokenAddress, data, destination);
    }

    function _depositERC20(
        uint256 amount,
        address tokenAddress,
        bytes memory data,
        address destination
    ) private {
        require(amount != 0, "Amount cannot be zero");
        uint256 feeAbsolute = 0;
        if (!hasRole(FEES_EXCLUDED, msg.sender)) {
            feeAbsolute = FeeOperations.getFeeAbsolute(amount, fee);
            address feesCollector = getRoleMember(FEES_COLLECTOR, 0);
            SafeERC20.safeTransferFrom(
                IERC20(tokenAddress),
                msg.sender,
                feesCollector,
                feeAbsolute
            );

            amount = amount.sub(feeAbsolute);
        }

        SafeERC20.safeTransferFrom(
            IERC20(tokenAddress),
            msg.sender,
            address(this),
            amount
        );

        _transferL2Implementation(amount, tokenAddress, data, destination);
        balances[tokenAddress][msg.sender] = balances[tokenAddress][msg.sender]
            .add(amount);
        emit Deposit(msg.sender, tokenAddress, amount, feeAbsolute);
    }

    function _transferL2Implementation(
        uint256 amount,
        address tokenAddress,
        bytes memory data,
        address destination
    ) internal virtual;

    function withdrawTo(
        address accountTo,
        uint256 amount,
        address tokenAddress
    ) internal nonReentrant {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = balances[tokenAddress][accountTo];
        require(balance >= amount, "Not enough tokens on balance");
        require(
            token.balanceOf(address(this)) >= amount,
            "Not enough tokens on balance"
        );
        balances[tokenAddress][accountTo] = balance.sub(amount);
        SafeERC20.safeTransfer(token, accountTo, amount);
        emit WithdrawalCompleted(accountTo, amount, tokenAddress);
    }

    /// @dev Initial function used to set the initial roles
    function _setInitialRoles() private {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FEES_EXCLUDED, _msgSender());
        _setupRole(FEES_COLLECTOR, _msgSender());
        _setRoleAdmin(FEES_COLLECTOR, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(FEES_EXCLUDED, DEFAULT_ADMIN_ROLE);
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Permissions: Only admins allowed"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
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
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface IBridgeBase {
    function addSupportedToken(address tokenAddress) external;

    function setFee(uint256 newFee) external;

    function removeSupportedToken(address tokenAddress) external;

    function depositERC20(uint256 amount, address tokenAddress, bytes calldata data) external payable;

    function depositERC20ForAddress(uint256 amount, address tokenAddress, bytes calldata data, address destination) external payable;
}

// SPDX-License-Identifier: MIT

/**
 * Created on 2021-06-07 08:50
 * @summary: Vault for storing ERC20 tokens that will be transferred by external event-based system to another network. The destination network can be checked on "connectedNetwork"
 * @author: Composable Finance - Pepe Blasco
 */
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";

library FeeOperations {
    using SafeMath for uint256;

    uint256 internal constant feeFactor = 10000;

    function getFeeAbsolute(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return amount.mul(fee).div(feeFactor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm

pragma solidity ^0.6.8;

import "../BridgeBase.sol";
import "./IZkSync.sol";

contract VaultZkSync is BridgeBase {

    address zkSync;

    constructor(address _zkSync) public {
        require(_zkSync != address(0), "Invalid address");
        zkSync = _zkSync;
    }

    function setZkSyncAddress(address _zkSync) external onlyAdmin {
        require(_zkSync != address(0), "Invalid address");
        zkSync = _zkSync;
    }

    function _transferL2Implementation(
        uint256 _amount,
        address token,
        bytes memory,
        address destination
    ) internal override {
        // approve the tokens for transfer
        SafeERC20.safeIncreaseAllowance(IERC20(token), zkSync, _amount);
        uint104 amount = uint104(_amount);

        IZkSync(zkSync).depositERC20(
            IERC20(token),
            amount,
            destination
        );
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IZkSync {

    // @notice Deposit ERC20 token to Layer 2 - transfer ERC20 tokens from user into contract, validate it, register deposit
    /// @param _token Token address
    /// @param _amount Token amount
    /// @param _franklinAddr Receiver Layer 2 address
    function depositERC20(IERC20 _token, uint104 _amount, address _franklinAddr) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SampleTokenERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) public ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IL2VaultConfig.sol";
import "../interfaces/IComposableHolding.sol";
import "../interfaces/ITokenFactory.sol";
import "../libraries/FeeOperations.sol";
import "./VaultConfigBase.sol";

contract L2VaultConfig is VaultConfigBase, IL2VaultConfig {
    using SafeMath for uint256;

    uint256 nonce;
    uint256 public override minFee;
    uint256 public override maxFee;
    uint256 public override feeThreshold;
    uint256 public override transferLockupTime;
    uint256 public override minLimitLiquidityBlocks;
    uint256 public override maxLimitLiquidityBlocks;
    address public override feeAddress;

    string internal constant override tokenName = "IOU-";
    // @dev remoteTokenAddress[networkID][addressHere] = addressThere
    mapping(uint256 => mapping(address => address)) public override remoteTokenAddress;
    mapping(address => uint256) public override lockedTransferFunds;

    /*
    UNISWAP = 2
    SUSHISWAP = 3
    CURVE = 4
    */
    mapping(uint256 => address) private supportedAMMs;

    /// @notice Public function to query the supported tokens list
    /// @dev token address => WhitelistedToken struct
    mapping(address => WhitelistedToken) public whitelistedTokens;

    struct WhitelistedToken
    {
        uint256 minTransferAllowed;
        uint256 maxTransferAllowed;
        address underlyingReceiptAddress;
    }

    event MinFeeChanged(uint256 newMinFee);
    event MaxFeeChanged(uint256 newMaxFee);
    event MinLiquidityBlockChanged(uint256 newMinLimitLiquidityBlocks);
    event MaxLiquidityBlockChanged(uint256 newMaxLimitLiquidityBlocks);
    event ThresholdFeeChanged(uint256 newFeeThreshold);
    event FeeAddressChanged(address feeAddress);
    event LockupTimeChanged(
        address indexed _owner,
        uint256 _oldVal,
        uint256 _newVal,
        string valType
    );
    event TokenAdded(
        address indexed erc20,
        address indexed remoteTokenAddress,
        uint256 indexed remoteNetworkID
    );
    event TokenRemoved(
        address indexed erc20,
        address indexed remoteTokenAddress,
        uint256 indexed remoteNetworkID
    );

    constructor(address _feeAddress, address _composableHolding) public {
        require(
            _composableHolding != address(0),
            "Invalid ComposableHolding address"
        );
        require(_feeAddress != address(0), "Invalid fee address");

        nonce = 0;
        // 0.25%
        minFee = 25;
        // 5%
        maxFee = 500;
        // 30% of liquidity
        feeThreshold = 30;
        transferLockupTime = 1 days;
        // 1 day
        minLimitLiquidityBlocks = 1;
        //yet to be decided
        maxLimitLiquidityBlocks = 100;

        feeAddress = _feeAddress;
        composableHolding = IComposableHolding(_composableHolding);
    }

    function getSupportedAMM(uint256 networkId)
    external
    view
    override
    returns (address)
    {
        return supportedAMMs[networkId];
    }

    function getUnderlyingReceiptAddress(address token)
    external
    view
    override
    returns(address)
    {
        return whitelistedTokens[token].underlyingReceiptAddress;
    }

    // @notice: checks for the current balance of this contract's address on the ERC20 contract
    // @param tokenAddress  SC address of the ERC20 token to get liquidity from
    function getCurrentTokenLiquidity(address tokenAddress)
    public
    view
    override
    returns (uint256)
    {
        uint256 tokenBalance = getTokenBalance(tokenAddress);
        // remove the locked transfer funds from the balance of the vault
        return tokenBalance.sub(lockedTransferFunds[tokenAddress]);
    }

    function calculateFeePercentage(address tokenAddress, uint256 amount)
    external
    view
    override
    returns (uint256)
    {
        uint256 tokenLiquidity = getTokenBalance(tokenAddress);

        if (tokenLiquidity == 0) {
            return maxFee;
        }

        if ((amount.mul(100)).div(tokenLiquidity) > feeThreshold) {
            // Flat fee since it's above threshold
            return maxFee;
        }

        uint256 maxTransfer = tokenLiquidity.mul(feeThreshold).div(100);
        uint256 percentTransfer = amount.mul(100).div(maxTransfer);

        return
        percentTransfer.mul(maxFee.sub(minFee)).add(minFee.mul(100)).div(
            100
        );
    }

    /// @notice Public function to add address of the AMM used to swap tokens
    /// @param ammID the integer constant for the AMM
    /// @param ammAddress Address of the AMM
    /// @dev AMM should be a wrapper created by us over the AMM implementation
    function addSupportedAMM(uint256 ammID, address ammAddress)
    public
    override
    onlyOwner
    validAddress(ammAddress)
    {
        supportedAMMs[ammID] = ammAddress;
    }

    /// @notice Public function to remove address of the AMM
    /// @param ammID the integer constant for the AMM
    function removeSupportedAMM(uint256 ammID) public override onlyOwner {
        delete supportedAMMs[ammID];
    }

    // @notice: Adds a supported token to the contract, allowing for anyone to deposit their tokens.
    // @param tokenAddress  SC address of the ERC20 token to add to supported tokens
    function addWhitelistedToken(
        address tokenAddress,
        address tokenAddressRemote,
        uint256 remoteNetworkID,
        uint256 minTransferAmount,
        uint256 maxTransferAmount
    ) external override onlyOwner validAddress(tokenAddress) validAddress(tokenAddressRemote) {
        require(remoteNetworkID > 0, "Invalid network ID");
        require(maxTransferAmount > minTransferAmount, "Invalid token economics");

        _deployIOU(tokenAddress);
        whitelistedTokens[tokenAddress].minTransferAllowed = minTransferAmount;
        whitelistedTokens[tokenAddress].maxTransferAllowed = maxTransferAmount;
        remoteTokenAddress[remoteNetworkID][tokenAddress] = tokenAddressRemote;

        emit TokenAdded(tokenAddress, tokenAddressRemote, remoteNetworkID);
    }

    // @notice: removes supported token from the contract, avoiding new deposits and withdrawals.
    // @param tokenAddress  SC address of the ERC20 token to remove from supported tokens
    function removeWhitelistedToken(address tokenAddress, uint256 remoteNetworkID)
    external
    override
    onlyOwner
    onlySupportedRemoteTokens(remoteNetworkID, tokenAddress)
    {
        emit TokenRemoved(
            tokenAddress,
            remoteTokenAddress[remoteNetworkID][tokenAddress],
            remoteNetworkID
        );
        delete remoteTokenAddress[remoteNetworkID][tokenAddress];
        delete whitelistedTokens[tokenAddress];
    }

    function setTransferLockupTime(uint256 lockupTime)
    external
    override
    onlyOwner
    {
        emit LockupTimeChanged(
            msg.sender,
            transferLockupTime,
            lockupTime,
            "Transfer"
        );
        transferLockupTime = lockupTime;
    }

    function setLockedTransferFunds(address _token, uint256 _amount)
    external
    override
    validAddress(_token)
    onlyOwnerOrVault(msg.sender)
    {
        lockedTransferFunds[_token] = _amount;
    }

    // @notice: Updates the minimum fee
    // @param newMinFee
    function setMinFee(uint256 newMinFee) external override onlyOwner {
        require(
            newMinFee < FeeOperations.feeFactor,
            "Min fee cannot be more than fee factor"
        );
        require(newMinFee < maxFee, "Min fee cannot be more than max fee");

        minFee = newMinFee;
        emit MinFeeChanged(newMinFee);
    }

    // @notice: Updates the maximum fee
    // @param newMaxFee
    function setMaxFee(uint256 newMaxFee) external override onlyOwner {
        require(
            newMaxFee < FeeOperations.feeFactor,
            "Max fee cannot be more than fee factor"
        );
        require(newMaxFee > minFee, "Max fee cannot be less than min fee");

        maxFee = newMaxFee;
        emit MaxFeeChanged(newMaxFee);
    }

    // @notice: Updates the minimum limit liquidity block
    // @param newMinLimitLiquidityBlocks
    function setMinLimitLiquidityBlocks(uint256 newMinLimitLiquidityBlocks)
    external
    override
    onlyOwner
    {
        require(
            newMinLimitLiquidityBlocks < maxLimitLiquidityBlocks,
            "Min liquidity block cannot be more than max liquidity block"
        );

        minLimitLiquidityBlocks = newMinLimitLiquidityBlocks;
        emit MinLiquidityBlockChanged(newMinLimitLiquidityBlocks);
    }

    // @notice: Updates the maximum limit liquidity block
    // @param newMaxLimitLiquidityBlocks
    function setMaxLimitLiquidityBlocks(uint256 newMaxLimitLiquidityBlocks)
    external
    override
    onlyOwner
    {
        require(
            newMaxLimitLiquidityBlocks > minLimitLiquidityBlocks,
            "Max liquidity block cannot be lower than min liquidity block"
        );

        maxLimitLiquidityBlocks = newMaxLimitLiquidityBlocks;
        emit MaxLiquidityBlockChanged(newMaxLimitLiquidityBlocks);
    }

    // @notice: Updates the fee threshold
    // @param newThresholdFee
    function setThresholdFee(uint256 newThresholdFee)
    external
    override
    onlyOwner
    {
        require(
            newThresholdFee < 100,
            "Threshold fee cannot be more than threshold factor"
        );

        feeThreshold = newThresholdFee;
        emit ThresholdFeeChanged(newThresholdFee);
    }

    // @notice: Updates the account where to send deposit fees
    // @param newFeeAddress
    function setFeeAddress(address newFeeAddress) external override onlyOwner {
        require(newFeeAddress != address(0), "Invalid fee address");

        feeAddress = newFeeAddress;
        emit FeeAddressChanged(feeAddress);
    }

    function generateId()
    external
    override
    onlyVault(msg.sender)
    returns (bytes32)
    {
        nonce = nonce + 1;
        return keccak256(abi.encodePacked(block.number, vault, nonce));
    }

    /// @dev Internal function called when deploy a receipt IOU token based on already deployed ERC20 token
    function _deployIOU(address underlyingToken) private returns (address) {
        require(
            address(receiptTokenFactory) != address(0),
            "IOU token factory not initialized"
        );
        require(address(vault) != address(0), "Vault not initialized");

        address newIou = receiptTokenFactory.createIOU(
            underlyingToken,
            tokenName,
            vault
        );

        whitelistedTokens[underlyingToken].underlyingReceiptAddress = newIou;

        emit TokenReceiptCreated(underlyingToken);
        return newIou;
    }

    function inTokenTransferLimits(address _token, uint256 _amount) external override returns(bool){
        return (whitelistedTokens[_token].minTransferAllowed <= _amount && whitelistedTokens[_token].maxTransferAllowed >= _amount);
    }

    modifier onlyOwnerOrVault(address _addr) {
        require(
            _addr == owner() || _addr == vault,
            "Only vault or owner can call this"
        );
        _;
    }

    modifier onlyVault(address _addr) {
        require(_addr == vault, "Only vault can call this");
        _;
    }

    modifier onlySupportedRemoteTokens(
        uint256 networkID,
        address tokenAddress
    ) {
        require(
            remoteTokenAddress[networkID][tokenAddress] != address(0),
            "Unsupported token in this network"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "./IComposableHolding.sol";
import "./IVaultConfigBase.sol";

interface IL2VaultConfig is IVaultConfigBase {
    function minFee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function feeThreshold() external view returns (uint256);

    function transferLockupTime() external view returns (uint256);

    function minLimitLiquidityBlocks() external view returns (uint256);

    function maxLimitLiquidityBlocks() external view returns (uint256);

    function feeAddress() external view returns (address);

    function remoteTokenAddress(uint256 id, address token)
    external
    view
    returns (address);

    function lockedTransferFunds(address token) external view returns (uint256);

    function getSupportedAMM(uint256 networkId) external view returns (address);

    function calculateFeePercentage(address tokenAddress, uint256 amount)
    external
    view
    returns (uint256);

    function addSupportedAMM(uint256 ammID, address ammAddress) external;

    function removeSupportedAMM(uint256 ammID) external;

    function setTransferLockupTime(uint256 lockupTime) external;

    function setMinFee(uint256 newMinFee) external;

    function setMaxFee(uint256 newMaxFee) external;

    function setMinLimitLiquidityBlocks(uint256 newMinLimitLiquidityBlocks)
    external;

    function setMaxLimitLiquidityBlocks(uint256 newMaxLimitLiquidityBlocks)
    external;

    function setThresholdFee(uint256 newThresholdFee) external;

    function setFeeAddress(address newFeeAddress) external;

    function setLockedTransferFunds(address _token, uint256 _amount) external;

    function generateId() external returns (bytes32);

    function inTokenTransferLimits(address,uint) external returns(bool);

    function addWhitelistedToken(
        address tokenAddress,
        address tokenAddressRemote,
        uint256 remoteNetworkID,
        uint256 minTransferAmount,
        uint256 maxTransferAmount
    ) external;

    function removeWhitelistedToken(address token, uint256 remoteNetworkID) external;

    function getCurrentTokenLiquidity(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface IComposableHolding {
    function transfer(address _token, address _receiver, uint256 _amount) external;

    function setUniqRole(bytes32 _role, address _address) external;

    function approve(address spender, address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface ITokenFactory {
    function createIOU(
        address underlyingAddress,
        string calldata _tokenName,
        address _owner
    ) external returns (address);

    function createReceipt(
        address underlyingAddress,
        string calldata _tokenName,
        address _owner
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IComposableHolding.sol";
import "../interfaces/ITokenFactory.sol";
import "../interfaces/IReceiptBase.sol";
import "../interfaces/IVaultConfigBase.sol";

abstract contract VaultConfigBase is IVaultConfigBase, Ownable {
    ITokenFactory internal receiptTokenFactory;
    IComposableHolding internal composableHolding;

    address public vault;

    event TokenReceiptCreated(address underlyingToken);

    /// @notice Get ComposableHolding
    function getComposableHolding() external view override returns (address) {
        return address(composableHolding);
    }

    function setVault(address _vault)
    external
    override
    validAddress(_vault)
    onlyOwner
    {
        vault = _vault;
    }

    /// @notice External function used to set the Receipt Token Factory Address
    /// @dev Address of the factory need to be set after the initialization in order to use the vault
    /// @param receiptTokenFactoryAddress Address of the already deployed Receipt Token Factory
    function setReceiptTokenFactoryAddress(address receiptTokenFactoryAddress)
    external
    override
    onlyOwner
    validAddress(receiptTokenFactoryAddress)
    {
        receiptTokenFactory = ITokenFactory(receiptTokenFactoryAddress);
    }

    function getTokenBalance(address _token) virtual public override view returns (uint256) {
        require(
            address(composableHolding) != address(0),
            "Composable Holding address not set"
        );
        return IERC20(_token).balanceOf(address(composableHolding));
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }

    modifier validAmount(uint256 _value) {
        require(_value > 0, "Invalid amount");
        _;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface IVaultConfigBase {
    function getComposableHolding() external view returns (address);

    function getTokenBalance(address _token) external view returns (uint256);

    function setReceiptTokenFactoryAddress(address receiptTokenFactoryAddress)
    external;

    function getUnderlyingReceiptAddress(address token)
    external
    view
    returns (address);

    function setVault(address _vault) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReceiptBase is IERC20 {
    function burn(address from, uint256 amount) external;

    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm

/**
 * Created on 2021-06-07 08:50
 * @summary: Vault for storing ERC20 tokens that will be transferred by external event-based system to another network. The destination network can be checked on "connectedNetwork"
 * @author: Composable Finance - Pepe Blasco
 */
pragma solidity ^0.6.8;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "../interfaces/IComposableHolding.sol";
import "../interfaces/IComposableExchange.sol";
import "../interfaces/IReceiptBase.sol";
import "../interfaces/ITokenFactory.sol";
import "../interfaces/IL2VaultConfig.sol";

import "../libraries/FeeOperations.sol";

//@title: Composable Finance L2 ERC20 Vault
contract L2Vault is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(uint256 => bool) public pausedNetwork;

    IL2VaultConfig public vaultConfig;
    IComposableHolding public composableHolding;

    mapping(bytes32 => bool) public hasBeenWithdrawn;
    mapping(bytes32 => bool) public hasBeenUnlocked;
    mapping(bytes32 => bool) public hasBeenRefunded;

    bytes32 public lastWithdrawID;
    bytes32 public lastUnlockID;
    bytes32 public lastRefundedID;

    mapping(address => uint256) public lastTransfer;
    /// @dev Store the address of the IOU token receipt

    event TransferInitiated(
        address indexed account,
        address indexed erc20,
        address remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 value,
        address remoteDestinationAddress,
        bytes32 uniqueId,
        uint256 transferDelay
    );

    event TransferToDifferentTokenInitiated(
        address owner,
        address indexed erc20,
        address tokenOut,
        address remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 value,
        uint256 ammID,
        address remoteDestinationAddress,
        bytes32 uniqueId,
        uint256 transferDelay
    );

    event WithdrawalCompleted(
        address indexed accountTo,
        uint256 amount,
        uint256 netAmount,
        address indexed tokenAddress,
        bytes32 indexed uniqueId
    );
    event LiquidityMoved(
        address indexed _owner,
        address indexed _to,
        uint256 amount
    );
    event TransferFundsRefunded(
        address indexed tokenAddress,
        address indexed user,
        uint256 amount,
        bytes32 uniqueId
    );
    event TransferFundsUnlocked(
        address indexed tokenAddress,
        uint256 amount,
        bytes32 uniqueId
    );

    event PauseNetwork(address admin, uint256 networkID);
    event UnpauseNetwork(address admin, uint256 networkID);
    event FeeTaken(
        address indexed _owner,
        address indexed _user,
        address indexed _token,
        uint256 _amount,
        uint256 _fee,
        bytes32 uniqueId
    );

    event DepositLiquidity(
        address indexed tokenAddress,
        address indexed provider,
        uint256 amount,
        uint256 blocks
    );

    event LiquidityWithdrawn(
        address indexed tokenAddress,
        address indexed provider,
        uint256 amount
    );

    event LiquidityRefunded(
        address indexed tokenAddress,
        address indexed user,
        uint256 amount,
        bytes32 uniqueId
    );

    event WithdrawOnRemoteNetworkStarted(
        address indexed account,
        address indexed erc20,
        address remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 value,
        address remoteDestinationAddress,
        bytes32 uniqueId
    );

    event WithdrawOnRemoteNetworkForDifferentTokenStarted(
        address indexed account,
        address indexed remoteTokenAddress,
        uint256 indexed remoteNetworkID,
        uint256 value,
        uint256 amountOutMin,
        address remoteDestinationAddress,
        uint256 remoteAmmId,
        bytes32 uniqueId
    );

    function initialize(address _vaultConfig) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        vaultConfig = IL2VaultConfig(_vaultConfig);
        composableHolding = IComposableHolding(
            vaultConfig.getComposableHolding()
        );
    }

    /// @notice External callable function to pause the contract
    function pauseNetwork(uint256 networkID) external onlyOwner {
        pausedNetwork[networkID] = true;
        emit PauseNetwork(msg.sender, networkID);
    }

    /// @notice External callable function to unpause the contract
    function unpauseNetwork(uint256 networkID) external onlyOwner {
        pausedNetwork[networkID] = false;
        emit UnpauseNetwork(msg.sender, networkID);
    }

    // @notice transfer ERC20 token to another l2 vault
    // @param amount amount of tokens to deposit
    // @param tokenAddress  SC address of the ERC20 token to deposit
    // @param transferDelay delay in seconds for the relayer to execute the transaction
    function transferERC20ToLayer(
        uint256 amount,
        address tokenAddress,
        address remoteDestinationAddress,
        uint256 remoteNetworkID,
        uint256 transferDelay
    )
        external
        validAmount(amount)
        onlySupportedRemoteTokens(remoteNetworkID, tokenAddress)
        nonReentrant
        whenNotPausedNetwork(remoteNetworkID)
    {
        _transferERC20ToLayer(tokenAddress, amount);

        emit TransferInitiated(
            msg.sender,
            tokenAddress,
            vaultConfig.remoteTokenAddress(remoteNetworkID, tokenAddress),
            remoteNetworkID,
            amount,
            remoteDestinationAddress,
            vaultConfig.generateId(),
            transferDelay
        );
    }

    // @notice transfer ERC20 token to another l2 vault
    // @param amount amount of tokens to deposit
    // @param tokenAddress  SC address of the ERC20 token to deposit
    // @param transferDelay delay in seconds for the relayer to execute the transaction
    // @param tokenOut  SC address of the ERC20 token to receive tokens
    // @param remoteAmmId remote integer constant for the AMM
    function transferERC20ToLayerForDifferentToken(
        uint256 amount,
        address tokenAddress,
        address remoteDestinationAddress,
        uint256 remoteNetworkID,
        uint256 transferDelay,
        address tokenOut,
        uint256 remoteAmmId
    )
        external
        nonReentrant
        validAmount(amount)
        whenNotPausedNetwork(remoteNetworkID)
    {
        address remoteTokenAddress = vaultConfig.remoteTokenAddress(remoteNetworkID, tokenAddress);
        require(remoteTokenAddress != address(0), "Unsupported token in this network");
        _transferERC20ToLayer(tokenAddress, amount);

        emit TransferToDifferentTokenInitiated(
            msg.sender,
            tokenAddress,
            tokenOut,
            remoteTokenAddress,
            remoteNetworkID,
            amount,
            remoteAmmId,
            remoteDestinationAddress,
            vaultConfig.generateId(),
            transferDelay
        );
    }

    function _transferERC20ToLayer(address tokenAddress, uint256 amount)
    private
    inTokenTransferLimits(tokenAddress, amount)
    {
        require(lastTransfer[msg.sender].add(vaultConfig.transferLockupTime()) < block.timestamp, "Transfer not yet possible");
        IERC20Upgradeable(tokenAddress).safeTransferFrom(
            msg.sender,
            address(composableHolding),
            amount
        );

        vaultConfig.setLockedTransferFunds(tokenAddress, vaultConfig.transferLockupTime().add(amount));

        lastTransfer[msg.sender] = block.timestamp;
    }

    function provideLiquidity(
        uint256 amount,
        address tokenAddress,
        uint256 blocksForActiveLiquidity
    )
        external
        validAddress(tokenAddress)
        validAmount(amount)
        onlySupportedToken(tokenAddress)
        nonReentrant
        whenNotPaused
    {
        require(
            blocksForActiveLiquidity >= vaultConfig.minLimitLiquidityBlocks() &&
                blocksForActiveLiquidity <= vaultConfig.maxLimitLiquidityBlocks(),
            "not within block approve range"
        );
        IERC20Upgradeable(tokenAddress).safeTransferFrom(
            msg.sender,
            address(composableHolding),
            amount
        );
        IReceiptBase(vaultConfig.getUnderlyingReceiptAddress(tokenAddress)).mint(
            msg.sender,
            amount
        );
        emit DepositLiquidity(
            tokenAddress,
            msg.sender,
            amount,
            blocksForActiveLiquidity
        );
    }

    function withdrawLiquidity(address tokenAddress, uint256 amount)
        external
        validAddress(tokenAddress)
        validAmount(amount)
        enoughLiquidityInVault(tokenAddress, amount)
    {
        _burnIOUTokens(tokenAddress, msg.sender, amount);

        composableHolding.transfer(tokenAddress, msg.sender, amount);
        emit LiquidityWithdrawn(tokenAddress, msg.sender, amount);
    }

    // @notice called by the relayer to restore the user's liquidity
    //         when `withdrawDifferentTokenTo` fails on the destination layer
    // @param _user address of the user account
    // @param _amount amount of tokens
    // @param _tokenAddress  address of the ERC20 token
    // @param _id the id generated by the withdraw method call by the user
    function refundLiquidity(
        address _user,
        uint256 _amount,
        address _tokenAddress,
        bytes32 _id
    )
        external
        onlyOwner
        validAmount(_amount)
        enoughLiquidityInVault(_tokenAddress, _amount)
        nonReentrant
    {
        require(hasBeenRefunded[_id] == false, "Already refunded");

        hasBeenRefunded[_id] = true;
        lastRefundedID = _id;

        IReceiptBase(vaultConfig.getUnderlyingReceiptAddress(_tokenAddress)).mint(_user, _amount);

        emit LiquidityRefunded(_tokenAddress, _user, _amount, _id);
    }

    /// @notice External function called to withdraw liquidity in different token
    /// @param tokenIn Address of the token provider have
    /// @param tokenOut Address of the token provider want to receive
    /// @param amountIn Amount of tokens provider want to withdraw
    /// @param amountOutMin Minimum amount of token user should get
    function withdrawLiquidityToDifferentToken(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 ammID,
        bytes calldata data
    )
        external
        validAmount(amountIn)
        onlySupportedToken(tokenOut)
        onlySupportedToken(tokenIn)
        differentAddresses(tokenIn, tokenOut)
        isAMMSupported(ammID)
    {
        _burnIOUTokens(tokenIn, msg.sender, amountIn);
        composableHolding.transfer(tokenIn, address(this), amountIn);
        IERC20Upgradeable(tokenIn).safeApprove(vaultConfig.getSupportedAMM(ammID), amountIn);
        uint256 amountToSend = IComposableExchange(vaultConfig.getSupportedAMM(ammID)).swap(
            tokenIn,
            tokenOut,
            amountIn,
            amountOutMin,
            data
        );
        IERC20Upgradeable(tokenOut).safeTransfer(msg.sender, amountToSend);
        emit LiquidityWithdrawn(tokenOut, msg.sender, amountToSend);
    }

    function withdrawLiquidityOnAnotherL2Network(
        address tokenAddress,
        uint256 amount,
        address remoteDestinationAddress,
        uint256 _networkID
    )
        external
        validAddress(tokenAddress)
        validAmount(amount)
        onlySupportedRemoteTokens(_networkID, tokenAddress)
    {
        _burnIOUTokens(tokenAddress, msg.sender, amount);

        emit WithdrawOnRemoteNetworkStarted(
            msg.sender,
            tokenAddress,
            vaultConfig.remoteTokenAddress(_networkID, tokenAddress),
            _networkID,
            amount,
            remoteDestinationAddress,
            vaultConfig.generateId()
        );
    }

    /// @notice External function called to withdraw liquidity in different token on another network
    /// @param tokenIn Address of the token provider have
    /// @param tokenOut Address of the token provider want to receive
    /// @param amountIn Amount of tokens provider want to withdraw
    /// @param networkID Id of the network want to receive the other token
    /// @param amountOutMin Minimum amount of token user should get
    function withdrawLiquidityToDifferentTokenOnAnotherL2Network(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 networkID,
        uint256 amountOutMin,
        address remoteDestinationAddress,
        uint256 remoteAmmId
    )
        external
        validAmount(amountIn)
        onlySupportedToken(tokenOut)
        onlySupportedToken(tokenIn)
        onlySupportedRemoteTokens(networkID, tokenOut)
    {
        _withdrawToNetworkInDifferentToken(
            tokenIn,
            tokenOut,
            amountIn,
            networkID,
            amountOutMin,
            remoteDestinationAddress,
            remoteAmmId
        );
    }

    /// @dev internal function to withdraw different token on another network
    /// @dev use this approach to avoid stack too deep error
    function _withdrawToNetworkInDifferentToken(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 networkID,
        uint256 amountOutMin,
        address remoteDestinationAddress,
        uint256 remoteAmmId
    ) internal differentAddresses(tokenIn, tokenOut) {
        _burnIOUTokens(tokenIn, msg.sender, amountIn);

        emit WithdrawOnRemoteNetworkForDifferentTokenStarted(
            msg.sender,
            vaultConfig.remoteTokenAddress(networkID, tokenOut),
            networkID,
            amountIn,
            amountOutMin,
            remoteDestinationAddress,
            remoteAmmId,
            vaultConfig.generateId()
        );
    }

    function _burnIOUTokens(
        address tokenAddress,
        address provider,
        uint256 amount
    ) internal {
        IReceiptBase receipt = IReceiptBase(vaultConfig.getUnderlyingReceiptAddress(tokenAddress));
        require(receipt.balanceOf(provider) >= amount, "IOU Token balance to low");
        receipt.burn(provider, amount);
    }

    // @notice: method called by the relayer to release funds
    // @param accountTo eth address to send the withdrawal tokens
    function withdrawTo(
        address accountTo,
        uint256 amount,
        address tokenAddress,
        bytes32 id
    )
        external
        onlySupportedToken(tokenAddress)
        enoughLiquidityInVault(tokenAddress, amount)
        nonReentrant
        onlyOwner
        whenNotPaused
        notAlreadyWithdrawn(id)
    {
        _withdraw(accountTo, amount, tokenAddress, address(0), id, 0, 0, "");
    }

    // @notice: method called by the relayer to release funds in different token
    // @param accountTo eth address to send the withdrawal tokens
    // @param amount amount of token in
    // @param tokenIn address of the token in
    // @param tokenOut address of the token out
    // @param id withdrawal id
    // @param amountOutMin minimum amount out user want
    // @param data additional data required for each AMM implementation
    function withdrawDifferentTokenTo(
        address accountTo,
        uint256 amount,
        address tokenIn,
        address tokenOut,
        bytes32 id,
        uint256 amountOutMin,
        uint256 ammID,
        bytes calldata data
    )
        external
        onlySupportedToken(tokenIn)
        nonReentrant
        onlyOwner
        whenNotPaused
        notAlreadyWithdrawn(id)
    {
        _withdraw(
            accountTo,
            amount,
            tokenIn,
            tokenOut,
            id,
            amountOutMin,
            ammID,
            data
        );
    }

    function _withdraw(
        address accountTo,
        uint256 amount,
        address tokenIn,
        address tokenOut,
        bytes32 id,
        uint256 amountOutMin,
        uint256 ammID,
        bytes memory data
    ) private {
        hasBeenWithdrawn[id] = true;
        lastWithdrawID = id;
        uint256 withdrawAmount = _takeFees(tokenIn, amount, accountTo, id);

        if (tokenOut == address(0)) {
            composableHolding.transfer(tokenIn, accountTo, withdrawAmount);
        } else {
            require(vaultConfig.getSupportedAMM(ammID) != address(0), "AMM not supported");
            composableHolding.transfer(tokenIn, address(this), withdrawAmount);
            IERC20Upgradeable(tokenIn).safeApprove(vaultConfig.getSupportedAMM(ammID), withdrawAmount);
            uint256 amountToSend = IComposableExchange(vaultConfig.getSupportedAMM(ammID))
            .swap(tokenIn, tokenOut, withdrawAmount, amountOutMin, data);
            require(amountToSend >= amountOutMin, "AMM: Price to low");
            IERC20Upgradeable(tokenOut).safeTransfer(accountTo, amountToSend);
        }

        emit WithdrawalCompleted(
            accountTo,
            amount,
            withdrawAmount,
            tokenIn,
            id
        );
    }

    function _takeFees(
        address token,
        uint256 amount,
        address accountTo,
        bytes32 withdrawRequestId
    ) private returns (uint256) {
        uint256 fee = vaultConfig.calculateFeePercentage(token, amount);
        uint256 feeAbsolute = FeeOperations.getFeeAbsolute(amount, fee);
        uint256 withdrawAmount = amount.sub(feeAbsolute);

        if (feeAbsolute > 0) {
            composableHolding.transfer(token, vaultConfig.feeAddress(), feeAbsolute);
            emit FeeTaken(
                msg.sender,
                accountTo,
                token,
                amount,
                feeAbsolute,
                withdrawRequestId
            );
        }
        return withdrawAmount;
    }

    /**
     * @notice Will be called once the contract is paused and token's available liquidity will be manually moved back to L1
     * @param _token Token's balance the owner wants to withdraw
     * @param _to Receiver address
     */
    function saveFunds(address _token, address _to)
        external
        onlyOwner
        whenPaused
        validAddress(_token)
        validAddress(_to)
    {
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(composableHolding));
        require(balance > 0, "nothing to transfer");
        composableHolding.transfer(_token, _to, balance);
        emit LiquidityMoved(msg.sender, _to, balance);
    }

    /**
     * @notice The idea is to be able to withdraw to a controlled address certain amount of
               token liquidity in order to re-balance among different L2s (manual bridge to L1
               and then act accordingly)
     * @param _token Token's balance the owner wants to withdraw
     * @param _to Receiver address
     * @param _amount the amount of tokens to withdraw from the vault
     */
    function withdrawFunds(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner validAddress(_token) validAddress(_to) {
        uint256 tokenLiquidity = vaultConfig.getCurrentTokenLiquidity(_token);
        require(
            tokenLiquidity >= _amount,
            "withdrawFunds: vault balance is low"
        );
        composableHolding.transfer(_token, _to, _amount);
        emit LiquidityMoved(msg.sender, _to, _amount);
    }

    /*
    this method is called by the relayer after a successful transfer of tokens between layers
    this is called to unlock the funds to be added in the liquidity of the vault
    */
    function unlockTransferFunds(
        address _token,
        uint256 _amount,
        bytes32 _id
    ) public whenNotPaused onlyOwner {
        require(hasBeenUnlocked[_id] == false, "Already unlocked");
        require(
            vaultConfig.lockedTransferFunds(_token) >= _amount,
            "More amount than available"
        );

        hasBeenUnlocked[_id] = true;
        lastUnlockID = _id;

        // update the lockedTransferFunds for the token
        vaultConfig.setLockedTransferFunds(
            _token,
            vaultConfig.lockedTransferFunds(_token).sub(_amount)
        );

        emit TransferFundsUnlocked(_token, _amount, _id);
    }

    /*
    called by the relayer to return the tokens back to user in case of a failed
    transfer between layers. this method will mark the `id` as used and emit
    the event that funds has been claimed by the user
    */
    function refundTransferFunds(
        address _token,
        address _user,
        uint256 _amount,
        bytes32 _id
    ) external onlyOwner nonReentrant {
        require(hasBeenRefunded[_id] == false, "Already refunded");

        // unlock the funds
        if (hasBeenUnlocked[_id] == false) {
            unlockTransferFunds(_token, _amount, _id);
        }

        hasBeenRefunded[_id] = true;
        lastRefundedID = _id;

        composableHolding.transfer(_token, _user, _amount);

        emit TransferFundsRefunded(_token, _user, _amount, _id);
    }

    function getRemoteTokenAddress(uint256 _networkID, address _tokenAddress)
    external
    view
    returns (address tokenAddressRemote)
    {
        tokenAddressRemote = vaultConfig.remoteTokenAddress(_networkID, _tokenAddress);
    }

    /// @notice External callable function to pause the contract
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    /// @notice External callable function to unpause the contract
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }

    modifier validAmount(uint256 _value) {
        require(_value > 0, "Invalid amount");
        _;
    }

    modifier onlySupportedToken(address tokenAddress) {
        require(
            vaultConfig.getUnderlyingReceiptAddress(tokenAddress) != address(0),
            "Unsupported token"
        );
        _;
    }

    modifier onlySupportedRemoteTokens(
        uint256 networkID,
        address tokenAddress
    ) {
        require(
            vaultConfig.remoteTokenAddress(networkID, tokenAddress) !=
            address(0),
            "Unsupported token in this network"
        );
        _;
    }

    modifier whenNotPausedNetwork(uint256 networkID) {
        require(paused() == false, "Contract is paused");
        require(pausedNetwork[networkID] == false, "Network is paused");
        _;
    }

    modifier differentAddresses(
        address tokenAddress,
        address tokenAddressReceive
    ) {
        require(tokenAddress != tokenAddressReceive, "Same token address");
        _;
    }

    modifier isAMMSupported(uint256 ammID) {
        require(vaultConfig.getSupportedAMM(ammID) != address(0), "AMM not supported");
        _;
    }

    modifier enoughLiquidityInVault(address tokenAddress, uint256 amount) {
        require(
            vaultConfig.getCurrentTokenLiquidity(tokenAddress) >= amount,
            "Not enough tokens in the vault"
        );
        _;
    }

    modifier notAlreadyWithdrawn(bytes32 id) {
        require(hasBeenWithdrawn[id] == false, "Already withdrawn");
        _;
    }

    modifier inTokenTransferLimits(address token, uint256 amount) {
        require(vaultConfig.inTokenTransferLimits(token, amount), "Amount out of token transfer limits");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface IComposableExchange {
    function swap(address tokenA, address tokenB, uint256 amountIn, uint256 amountOut, bytes calldata data) external returns(uint256);

    function getAmountsOut(address tokenIn, address tokenOut, uint256 amountIn, bytes calldata data) external returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../interfaces/ITokenFactory.sol";
import "./IOU/IOUToken.sol";
import "./receipt/ReceiptToken.sol";

contract TokenFactory is ITokenFactory, AccessControl {
    bytes32 public constant COMPOSABLE_VAULT = keccak256("COMPOSABLE_VAULT");

    event TokenCreated(
        address indexed underlyingAsset,
        address indexed iouToken,
        string tokenType
    );

    event VaultChanged(address indexed newAddress);

    constructor(address _vault, address _vaultConfig) public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(COMPOSABLE_VAULT, _vault);
        _setupRole(COMPOSABLE_VAULT, _vaultConfig);
        _setRoleAdmin(COMPOSABLE_VAULT, DEFAULT_ADMIN_ROLE);
    }

    /// @notice External function used by admin of the contract to set the vault address
    /// @param _vaultAddress new vault address
    function changeVaultAddress(address _vaultAddress)
    external
    validAddress(_vaultAddress)
    onlyAdmin
    {
        uint256 rolesCount = getRoleMemberCount(COMPOSABLE_VAULT);
        for (uint256 i = 0; i < rolesCount; i++) {
            address _vault = getRoleMember(COMPOSABLE_VAULT, i);
            revokeRole(COMPOSABLE_VAULT, _vault);
        }
        grantRole(COMPOSABLE_VAULT, _vaultAddress);

        emit VaultChanged(_vaultAddress);
    }

    /// @notice External function called only by vault to create a new IOU token
    /// @param underlyingAddress Address of the ERC20 deposited token to get the info from
    /// @param tokenName Token prefix
    function createIOU(
        address underlyingAddress,
        string calldata tokenName,
        address _owner
    )
    external
    override
    validAddress(underlyingAddress)
    onlyVault
    returns (address)
    {
        uint256 chainId = 0;
        assembly {
            chainId := chainid()
        }

        IOUToken newIou = new IOUToken(
            underlyingAddress,
            tokenName,
            _getChainId(),
            _owner
        );

        emit TokenCreated(underlyingAddress, address(newIou), "IOU");

        return address(newIou);
    }

    /// @notice External function called only by vault to create a new Receipt token
    /// @param underlyingAddress Address of the ERC20 deposited token to get the info from
    /// @param tokenName Token prefix
    function createReceipt(
        address underlyingAddress,
        string calldata tokenName,
        address _owner
    )
    external
    override
    validAddress(underlyingAddress)
    onlyVault
    returns (address)
    {
        ReceiptToken newReceipt = new ReceiptToken(
            underlyingAddress,
            tokenName,
            _getChainId(),
            _owner
        );

        emit TokenCreated(underlyingAddress, address(newReceipt), "RECEIPT");

        return address(newReceipt);
    }

    function _getChainId() private pure returns (uint256) {
        uint256 chainId = 0;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    modifier onlyVault() {
        require(
            hasRole(COMPOSABLE_VAULT, _msgSender()),
            "Permissions: Only vault allowed"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Permissions: Only admins allowed"
        );
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "../ReceiptBase.sol";

// This contract is used for printing IOU tokens
contract IOUToken is ReceiptBase {
    string public receiptType = "IOU";

    constructor(
        address underlyingAddress,
        string memory prefix,
        uint256 _chainId,
        address admin
    ) public ReceiptBase(underlyingAddress, prefix, _chainId, admin) {}
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "../ReceiptBase.sol";

// This contract is used for printing IOU tokens
contract ReceiptToken is ReceiptBase {
    string public receiptType = "RECEIPT";

    constructor(
        address underlyingAddress,
        string memory prefix,
        uint256 _chainId,
        address admin
    ) public ReceiptBase(underlyingAddress, prefix, _chainId, admin) {}
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// This contract is used for printing IOU tokens
contract ReceiptBase is ERC20 {
    ERC20 public underlyingToken;
    string public constant details = "https://composable.finance";
    uint256 public chainId;
    address private _owner;

    constructor(
        address underlyingAddress,
        string memory prefix,
        uint256 _chainId,
        address owner
    )
        public
        ERC20(
            string(abi.encodePacked(prefix, ERC20(underlyingAddress).name())),
            string(abi.encodePacked(prefix, ERC20(underlyingAddress).symbol()))
        )
    {
        underlyingToken = ERC20(underlyingAddress);
        chainId = _chainId;
        _owner = owner;
    }

    /**
     * @notice Mint new receipt tokens to some user
     * @param to Address of the user that gets the receipt tokens
     * @param amount Amount of receipt tokens that will get minted
     */
    function mint(address to, uint256 amount) public onlySameChain onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burn receipt tokens from some user
     * @param from Address of the user that gets the receipt tokens burn
     * @param amount Amount of receipt tokens that will get burned
     */
    function burn(address from, uint256 amount) public onlySameChain onlyOwner {
        _burn(from, amount);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlySameChain() {
        uint256 _chainId = 0;
        assembly {
            _chainId := chainid()
        }
        require(_chainId == chainId, "Wrong chain");

        _;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm

pragma solidity ^0.6.8;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FundKeeper is Ownable {
    uint256 public amountToSend;
    mapping(address => bool) public fundsTransfered;

    event NewAmountToSend(uint256 newAmount);
    event FundSent(uint256 amount, address indexed user);
    event Paid(address indexed _from, uint256 _value);

    constructor() public {
        amountToSend = 0.05 ether;
    }

    receive() external payable {
        Paid(msg.sender, msg.value);
    }

    function setAmountToSend(uint256 amount) external onlyOwner {
        amountToSend = amount;
        emit NewAmountToSend(amount);
    }

    function sendFunds(address user) external onlyOwner {
        require(!fundsTransfered[user], "reward already sent");
        require(address(this).balance >= amountToSend, "Contract balance low");

        (bool sent, ) = user.call{value: amountToSend}("");
        require(sent, "Failed to send Polygon");

        fundsTransfered[user] = true;
        emit FundSent(amountToSend, user);
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IL1VaultConfig.sol";
import "../interfaces/IComposableHolding.sol";
import "../interfaces/ITokenFactory.sol";
import "./VaultConfigBase.sol";

contract L1VaultConfig is VaultConfigBase, IL1VaultConfig {
    string internal constant override tokenName = "R-";

    /// @notice Public function to query the supported wallets
    /// @dev wallet address => bool supported/not supported
    mapping(address => bool) public override whitelistedWallets;

    /// @notice Public function to query the supported tokens list
    /// @dev token address => WhitelistedToken struct
    mapping(address => WhitelistedToken) public whitelistedTokens;

    struct WhitelistedToken
    {
        uint256 maxAssetCap;
        address underlyingReceiptAddress;
        bool allowToWithdraw;
    }

    /// @notice event emitted when a new wallet is added to the whitelist
    /// @param wallet address of the wallet
    event WalletAddedToWhitelist(address indexed wallet);

    /// @notice event emitted when a wallet is removed from the whitelist
    /// @param wallet address of the wallet
    event WalletRemovedFromWhitelist(address indexed wallet);

    constructor(address _composableHolding) public {
        require(
            _composableHolding != address(0),
            "Invalid ComposableHolding address"
        );
        composableHolding = IComposableHolding(_composableHolding);
    }

    /// @notice external function used to define a max cap per asset
    /// @param _token Token address
    /// @param _maxCap Cap
    function setMaxCapAsset(address _token, uint256 _maxCap)
    external
    override
    onlySupportedToken(_token)
    validAmount(_maxCap)
    onlyOwnerOrVault(msg.sender)
    {
        require(getTokenBalance(_token) <= _maxCap, "Current token balance is higher");
        whitelistedTokens[_token].maxAssetCap = _maxCap;
    }


    /// @notice External function used to set the underlying Receipt Address
    /// @param _token Underlying token
    /// @param _receipt Receipt token
    function setUnderlyingReceiptAddress(address _token, address _receipt)
    external
    override
    onlyOwner
    validAddress(_token)
    validAddress(_receipt)
    {
        whitelistedTokens[_token].underlyingReceiptAddress = _receipt;
    }

    function getUnderlyingReceiptAddress(address _token)
    external
    override
    view
    returns(address)
    {
        return whitelistedTokens[_token].underlyingReceiptAddress;
    }

    /// @notice external function used to add token in the whitelist
    /// @param _token ERC20 token address
    function addWhitelistedToken(address _token, uint256 _maxCap)
    external
    override
    onlyOwner
    validAddress(_token)
    validAmount(_maxCap)
    {
        whitelistedTokens[_token].maxAssetCap = _maxCap;
        _deployReceipt(_token);
    }

    /// @notice external function used to remove token from the whitelist
    /// @param _token ERC20 token address
    function removeWhitelistedToken(address _token)
    external
    override
    onlyOwner
    validAddress(_token)
    {
        delete whitelistedTokens[_token];
    }

    /// @notice external function used to add wallet in the whitelist
    /// @param _wallet Wallet address
    function addWhitelistedWallet(address _wallet)
    external
    onlyOwner
    validAddress(_wallet)
    {
        whitelistedWallets[_wallet] = true;

        emit WalletAddedToWhitelist(_wallet);
    }

    /// @notice external function used to remove wallet from the whitelist
    /// @param _wallet Wallet address
    function removeWhitelistedWallet(address _wallet)
    external
    onlyOwner
    validAddress(_wallet)
    {
        require(whitelistedWallets[_wallet] == true, "Not registered");
        delete whitelistedWallets[_wallet];

        emit WalletRemovedFromWhitelist(_wallet);
    }

    /// @notice External function called by the owner to pause asset withdrawal
    /// @param _token address of the ERC20 token
    function pauseWithdraw(address _token)
    external
    override
    onlySupportedToken(_token)
    onlyOwner
    {
        require(whitelistedTokens[_token].allowToWithdraw, "Already paused");
        delete whitelistedTokens[_token].allowToWithdraw;
    }

    /// @notice External function called by the owner to unpause asset withdrawal
    /// @param _token address of the ERC20 token
    function unpauseWithdraw(address _token)
    external
    override
    onlySupportedToken(_token)
    onlyOwner
    {
        require(!whitelistedTokens[_token].allowToWithdraw, "Already allowed");
        whitelistedTokens[_token].allowToWithdraw = true;
    }

    /// @dev Internal function called when deploy a receipt Receipt token based on already deployed ERC20 token
    function _deployReceipt(address underlyingToken) private returns (address) {
        require(
            address(receiptTokenFactory) != address(0),
            "Receipt token factory not initialized"
        );
        require(address(vault) != address(0), "Vault not initialized");

        address newReceipt = receiptTokenFactory.createReceipt(
            underlyingToken,
            tokenName,
            vault
        );
        whitelistedTokens[underlyingToken].underlyingReceiptAddress = newReceipt;
        emit TokenReceiptCreated(underlyingToken);
        return newReceipt;
    }

    function isTokenSupported(address _token) public override view returns(bool) {
        return whitelistedTokens[_token].underlyingReceiptAddress != address(0);
    }

    function allowToWithdraw(address _token) public override view returns(bool) {
        return whitelistedTokens[_token].allowToWithdraw;
    }

    function getMaxAssetCap(address _token) external override view returns(uint) {
        return whitelistedTokens[_token].maxAssetCap;
    }

    modifier onlyOwnerOrVault(address _addr) {
        require(
            _addr == owner() || _addr == vault,
            "Only vault or owner can call this"
        );
        _;
    }

    modifier onlySupportedToken(address _tokenAddress) {
        require(isTokenSupported(_tokenAddress), "Token is not supported");
        _;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "./IVaultConfigBase.sol";

interface IL1VaultConfig is IVaultConfigBase {
    function allowToWithdraw(address token) external view returns (bool);

    function getMaxAssetCap(address token) external view returns (uint256);

    function whitelistedWallets(address wallet) external view returns (bool);

    function setUnderlyingReceiptAddress(address _token, address _receipt)
    external;

    function setMaxCapAsset(address _token, uint256 _maxCap) external;

    function pauseWithdraw(address _token) external;

    function unpauseWithdraw(address _token) external;

    function isTokenSupported(address) external view returns(bool);

    function addWhitelistedToken(address _token, uint256 _maxCap) external;

    function removeWhitelistedToken(address _token) external;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "../interfaces/IBridgeBase.sol";
import "../interfaces/IComposableHolding.sol";
import "../interfaces/ITokenFactory.sol";
import "../interfaces/IReceiptBase.sol";
import "../interfaces/IBridgeAggregator.sol";
import "../interfaces/IL1VaultConfig.sol";

/// @title L1Vault
contract L1Vault is
OwnableUpgradeable,
ReentrancyGuardUpgradeable,
PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IL1VaultConfig public l1VaultConfig;
    IBridgeAggregator private bridgeAggregator;

    /// @notice event emitted when a token is moved to another account
    /// @param token address of the token
    /// @param destination address of the receiver
    /// @param amount token amount send
    event FundsMoved(
        address indexed token,
        address indexed destination,
        uint256 amount
    );

    /// @notice event emitted when a token is added to the whitelist
    /// @param token address of the token
    /// @param maxCap amount of the max cap of the token
    event TokenAddedToWhitelist(address indexed token, uint256 maxCap);

    /// @notice event emitted when a token is removed from the whitelist
    /// @param token address of the token
    event TokenRemovedFromWhitelist(address indexed token);

    /// @notice event emitted when a new wallet is added to the whitelist
    /// @param wallet address of the wallet
    event WalletAddedToWhitelist(address indexed wallet);

    /// @notice event emitted when a wallet is removed from the whitelist
    /// @param wallet address of the wallet
    event WalletRemovedFromWhitelist(address indexed wallet);

    /// @notice event emitted when a token max cap is modified
    /// @param token address of the token
    /// @param newMaxCap amount of the max cap of the token
    event TokenMaxCapEdited(address indexed token, uint256 newMaxCap);

    /// @notice event emitted when user make a deposit
    /// @param sender address of the person who made the token deposit
    /// @param token address of the token
    /// @param amount amount of token deposited on this action
    /// @param totalAmount total amount of token deposited
    /// @param timestamp block.timestamp timestamp of the deposit
    event ProvideLiquidity(
        address indexed sender,
        address indexed token,
        uint256 amount,
        uint256 indexed totalAmount,
        uint256 timestamp
    );

    /// @notice event emitted when user withdraw token from the contract
    /// @param sender address of the person who withdraw his token
    /// @param token address of the token
    /// @param amount amount of token withdrawn
    /// @param totalAmount total amount of token remained deposited
    /// @param timestamp block.timestamp timestamp of the withdrawal
    event WithdrawLiquidity(
        address indexed sender,
        address indexed token,
        uint256 amount,
        uint256 indexed totalAmount,
        uint256 timestamp
    );

    event TokenReceiptCreated(address underlyingToken);

    function initialize(address _vaultConfig) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        l1VaultConfig = IL1VaultConfig(_vaultConfig);
    }

    /// @notice External function used by owner to set the bridge aggregator address
    /// @param _bridgeAggregator Address of the bridge aggregator
    function setBridgeAggregator(address _bridgeAggregator)
    external
    onlyOwner
    validAddress(_bridgeAggregator)
    {
        bridgeAggregator = IBridgeAggregator(_bridgeAggregator);
    }

    /// @param _token Address of the ERC20 compatible token
    function getReceiptTokenBalance(address _token)
    public
    view
    returns (uint256)
    {
        return
        IReceiptBase(l1VaultConfig.getUnderlyingReceiptAddress(_token))
        .balanceOf(msg.sender);
    }

    /// @notice callable function used to send asset to another wallet
    /// @param _destination address of the token receiver
    /// @param _token address of the token
    /// @param _amount amount send
    function moveFunds(
        address _destination,
        address _token,
        uint256 _amount
    ) external onlyOwner validAddress(_destination) validAmount(_amount) {
        require(l1VaultConfig.whitelistedWallets(_destination) == true, "Wallet not recognized");
        require(l1VaultConfig.getTokenBalance(_token) >= _amount, "Not enough liquidity");

        IComposableHolding(l1VaultConfig.getComposableHolding()).transfer(_token, _destination, _amount);
        emit FundsMoved(_token, _destination, _amount);
    }

    /// @notice External function used to move tokens to Layer2 networks
    /// @param destinationNetwork chain id of the destination network
    /// @param destination Address of the receiver on the L2 network
    /// @param token Address of the ERC20 token
    /// @param amount Amount need to be send
    /// @param _data Additional data that different bridge required in order to mint token
    function bridgeTokens(
        uint256 destinationNetwork,
        uint256 bridgeId,
        address destination,
        address token,
        uint256 amount,
        bytes calldata _data
    ) external onlyOwner validAddress(destination) validAmount(amount) {
        IComposableHolding(l1VaultConfig.getComposableHolding()).approve(address(bridgeAggregator), token, amount);
        bridgeAggregator.bridgeTokens(
            destinationNetwork,
            bridgeId,
            destination,
            token,
            amount,
            _data
        );
    }

    /// @notice External callable function used to withdraw liquidity from contract
    /// @dev This function withdraw all the liquidity provider staked
    /// @param _token address of the token
    function withdrawLiquidity(address _token) external nonReentrant {
        require(l1VaultConfig.allowToWithdraw(_token), "Withdraw paused for this token");
        uint256 _providerBalance = getReceiptTokenBalance(_token);
        require(_providerBalance > 0, "Provider balance too low");
        require(
            l1VaultConfig.getTokenBalance(_token) >= _providerBalance,
            "Not enough tokens in the vault"
        );
        IReceiptBase(l1VaultConfig.getUnderlyingReceiptAddress(_token)).burn(
            msg.sender,
            _providerBalance
        );

        IComposableHolding(l1VaultConfig.getComposableHolding()).transfer(_token, msg.sender, _providerBalance);

        emit WithdrawLiquidity(
            msg.sender,
            _token,
            _providerBalance,
            0,
            block.timestamp
        );
    }

    /// @notice External callable function used to add liquidity to contract
    /// @param _token address of the deposited token
    /// @param _amount amount of token deposited
    function provideLiquidity(address _token, uint256 _amount)
    external
    whenNotPaused
    validAmount(_amount)
    onlySupportedToken(_token)
    notOverMaxCap(_token, _amount)
    {
        IERC20Upgradeable(_token).safeTransferFrom(
            msg.sender,
            l1VaultConfig.getComposableHolding(),
            _amount
        );
        _provideLiquidity(_token, _amount, msg.sender);
    }

    /// @dev Internal function that contains the deposit logic
    function _provideLiquidity(
        address _token,
        uint256 _amount,
        address _to
    ) internal returns (bool) {
        address underlyingTokenReceipt = l1VaultConfig.getUnderlyingReceiptAddress(_token);
        IReceiptBase(underlyingTokenReceipt).mint(msg.sender, _amount);

        emit ProvideLiquidity(
            _to,
            _token,
            _amount,
            IReceiptBase(underlyingTokenReceipt).balanceOf(msg.sender),
            block.timestamp
        );
        return true;
    }

    /// @notice External callable function to pause the contract
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    /// @notice External callable function to unpause the contract
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }

    modifier validAmount(uint256 _value) {
        require(_value > 0, "Invalid amount");
        _;
    }

    modifier onlySupportedToken(address _tokenAddress) {
        require(l1VaultConfig.isTokenSupported(_tokenAddress),
            "Token is not supported"
        );
        _;
    }

    modifier notOverMaxCap(address _token, uint256 _amount) {
        uint256 _tokenBalance = l1VaultConfig.getTokenBalance(_token);
        require(
            _tokenBalance.add(_amount) <= l1VaultConfig.getMaxAssetCap(_token),
            "Amount exceed max cap per asset"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface IBridgeAggregator {
    /// @notice event emitted when a token is send to L2 network
    /// @param destination address of the receiver
    /// @param token address of the token
    /// @param amount token amount send
    /// @param amount token amount send
    event AssetSend(
        address indexed destination,
        address indexed token,
        uint256 amount,
        uint256 chainId
    );


    function addBridge(uint256 destinationNetwork, uint256 bridgeID, address bridgeAddress) external;

    function bridgeTokens(
        uint256 destinationNetwork,
        uint256 bridgeId,
        address _destination,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "../interfaces/IBridgeAggregator.sol";
import "../interfaces/IBridgeBase.sol";

/// @title BridgeAggregator
/// @notice Composable contract responsible with multiple bridge logic
contract BridgeAggregator is OwnableUpgradeable, IBridgeAggregator {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public vaultAddress;
    address public composableHolding;

    mapping(uint256 => mapping(uint256 => address)) public supportedBridges;

    function initialize(
        address _composableHolding,
        address _vaultAddress
    ) public initializer {
        __Ownable_init();
        vaultAddress = _vaultAddress;
        composableHolding = _composableHolding;
    }

    /// @notice External function called by admin to add bridge
    /// @param destinationNetwork Chain ID of the destination network
    /// @param bridgeID ID of the bridge
    /// @param bridgeAddress Address of the bridge
    function addBridge(uint256 destinationNetwork, uint256 bridgeID, address bridgeAddress)
    external
    override
    onlyOwner
    validAddress(bridgeAddress)
    {
        require(supportedBridges[destinationNetwork][bridgeID] == address(0), "Bridge already exist");
        supportedBridges[destinationNetwork][bridgeID] = bridgeAddress;
    }

    /// @notice External function called by admin to remove supported bridge
    /// @param destinationNetwork Chain ID of the destination network
    /// @param bridgeID Id of the bridge to remove
    /// @dev destinationNetwork is used to identify the bridge
    function removeBridge(uint256 destinationNetwork, uint256 bridgeID)
    external
    onlyOwner
    {
        delete supportedBridges[destinationNetwork][bridgeID];
    }

    /// @notice External function called only by the address of the vault to bridge token to L2
    /// @param destinationNetwork chain id of the destination network
    /// @param receiver Address of the receiver on the L2 network
    /// @param token Address of the ERC20 token
    /// @param amount Amount need to be send
    /// @param _data Additional data that different bridge required in order to mint token
    function bridgeTokens(
        uint256 destinationNetwork,
        uint256 bridgeId,
        address receiver,
        address token,
        uint256 amount,
        bytes calldata _data
    )
    external
    override
    onlyVault
    validAmount(amount)
    {
        address _bridgeAddress = supportedBridges[destinationNetwork][bridgeId];
        require(_bridgeAddress != address(0), "Invalid bridge id");
        IERC20Upgradeable(token).safeTransferFrom(composableHolding, address(this), amount);
        IERC20Upgradeable(token).safeApprove(_bridgeAddress, amount);
        IBridgeBase(_bridgeAddress).depositERC20ForAddress(
            amount,
            token,
            _data,
            receiver
        );
        emit AssetSend(receiver, token, amount, destinationNetwork);
    }

    function getTokenBalance(address _token) public view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(composableHolding));
    }

    modifier validAmount(uint256 _value) {
        require(_value > 0, "Invalid amount");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vaultAddress, "Permissions: Only vault allowed");
        _;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "../../interfaces/IComposableExchange.sol";
import "./ISwapRouter.sol";
import "./IQuoter.sol";

// @title UniswapWrapper
// @notice Uniswap V3
contract UniswapWrapper is IComposableExchange, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ISwapRouter public swapRouter;
    IQuoter public quoter;

    function initialize(address swapRouterAddress, address quoterAddress)
    public
    initializer
    {
        swapRouter = ISwapRouter(swapRouterAddress);
        quoter = IQuoter(quoterAddress);
    }

    function swap(address tokenIn, address tokenOut, uint256 amount, uint256 amountOutMin, bytes calldata data)
    override
    external
    returns (uint256)
    {
        IERC20Upgradeable(tokenIn).safeTransferFrom(msg.sender, address(this), amount);
        IERC20Upgradeable(tokenIn).safeApprove(address(swapRouter), amount);
        (uint256 deadline, uint160 sqrtPriceLimitX96, uint24 fee) = abi.decode(data, (uint256, uint160, uint24));

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            tokenIn,
            tokenOut,
            fee,
            msg.sender,
            deadline,
            amount,
            amountOutMin,
            sqrtPriceLimitX96
        );
        return swapRouter.exactInputSingle(params);
    }

    function getAmountsOut(address tokenIn, address tokenOut, uint256 amountIn, bytes calldata data) external override returns (uint256) {
        (uint160 sqrtPriceLimitX96, uint24 fee) = abi.decode(data, (uint160, uint24));
        return quoter.quoteExactInputSingle(
            tokenIn,
            tokenOut,
            fee,
            amountIn,
            sqrtPriceLimitX96
        );
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

pragma experimental ABIEncoderV2;

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes calldata path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes calldata path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "../../interfaces/IComposableExchange.sol";
import "./ISushiswapRouter.sol";

contract SushiswapWrapper is IComposableExchange, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ISushiswapRouter public swapRouter;

    function initialize(address swapRouterAddress) public initializer {
        __Ownable_init();
        swapRouter = ISushiswapRouter(swapRouterAddress);
    }

    function swap(address tokenIn, address tokenOut, uint256 amount, uint256 amountOutMin, bytes calldata data)
    override
    external
    returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint deadline;

        if (data.length != 0) {
            (deadline) = abi.decode(data, (uint256));
        } else {
            deadline = block.timestamp;
        }

        IERC20Upgradeable(tokenIn).safeTransferFrom(msg.sender, address(this), amount);
        IERC20Upgradeable(tokenIn).safeIncreaseAllowance(address(swapRouter), amount);

        uint[] memory amounts = swapRouter.swapExactTokensForTokens(amount, amountOutMin, path, msg.sender, deadline);
        return amounts[1];
    }

    function getAmountsOut(address tokenIn, address tokenOut, uint256 amountIn, bytes calldata)
    external
    override
    returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint[] memory amounts = swapRouter.getAmountsOut(amountIn, path);
        return amounts[1];
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface ISushiswapRouter {

    // Swaps an exact amount of input tokens for as many output tokens as possible,
    // along the route determined by the path.
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "../../interfaces/IComposableExchange.sol";
import "./ICurveRouter.sol";
import "./IAddressProvider.sol";

contract CurveWrapper is IComposableExchange, OwnableUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    IAddressProvider public addressProvider;

    function initialize(address _addr) public initializer {
        __Ownable_init();
        addressProvider = IAddressProvider(_addr);
    }

    function swap(address tokenIn, address tokenOut, uint256 amount, uint256 amountOutMin, bytes calldata)
    override
    external
    returns (uint256) {
        // 2 is the id of the curve exchange contract
        // https://curve.readthedocs.io/registry-address-provider.html#address-ids
        ICurveRouter swapRouter = ICurveRouter(addressProvider.get_address(2));

        IERC20Upgradeable(tokenIn).safeTransferFrom(msg.sender, address(this), amount);
        IERC20Upgradeable(tokenIn).safeIncreaseAllowance(address(swapRouter), amount);

        return swapRouter.exchange_with_best_rate(tokenIn, tokenOut, amount, amountOutMin, msg.sender);
    }

    function getAmountsOut(address tokenIn, address tokenOut, uint256 amountIn, bytes calldata)
    external
    override
    returns(uint256) {
        ICurveRouter swapRouter = ICurveRouter(addressProvider.get_address(2));

        (, uint256 amountOut) = swapRouter.get_best_rate(tokenIn, tokenOut, amountIn);

        return amountOut;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface ICurveRouter {

    // uses high gas fee to find the pool with best rate
    function exchange_with_best_rate(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address recipient
    ) external payable returns (uint256 amountReceived);

    // needs a pool address to swap from
    function exchange(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address recipient
    ) external payable returns (uint256 amountReceived);

    // returns the address of the pool to exchange from and the excepted amount received
    function get_best_rate(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (address pool, uint256 amountOut);

}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface IAddressProvider {

    // Fetch the address associated with `_id`
    function get_address(
        uint256 _id
    ) external view returns (address contractAddress);

}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "../../interfaces/IComposableExchange.sol";
import "./IExchangeProxy.sol";


contract BalancerV1Wrapper is IComposableExchange, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IExchangeProxy public exchange;

    function initialize(address _exchangeAddress) public initializer {
        __Ownable_init();
        exchange = IExchangeProxy(_exchangeAddress);
    }

    function swap(address tokenIn, address tokenOut, uint256 amount, uint256 amountOutMin, bytes calldata data)
    override
    external
    returns (uint256)
    {
        IERC20Upgradeable(tokenIn).safeTransferFrom(msg.sender, address(this), amount);
        IERC20Upgradeable(tokenIn).safeIncreaseAllowance(address(exchange), amount);

        (uint256 nPools) = abi.decode(data, (uint256));

        return exchange.smartSwapExactIn(
            TokenInterface(tokenIn), TokenInterface(tokenOut), amount, amountOutMin, nPools
        );
    }

    function getAmountsOut(address tokenIn, address tokenOut, uint256 amountIn, bytes calldata data)
    external
    override
    returns (uint256) {
        (uint256 nPools) = abi.decode(data, (uint256));
        (, uint amountOut) = exchange.viewSplitExactIn(
            tokenIn, tokenOut, amountIn, nPools
        );
        return amountOut;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

interface TokenInterface {
}

// https://docs.balancer.fi/v/v1/smart-contracts/exchange-proxy
// https://github.com/balancer-labs/balancer-registry/blob/master/contracts/ExchangeProxy.sol
interface IExchangeProxy {

    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint    swapAmount; // tokenInAmount / tokenOutAmount
        uint    limitReturnAmount; // minAmountOut / maxAmountIn
        uint    maxPrice;
    }

    function smartSwapExactIn(
        TokenInterface tokenIn,
        TokenInterface tokenOut,
        uint totalAmountIn,
        uint minTotalAmountOut,
        uint nPools
    ) external payable returns (uint totalAmountOut);

    function viewSplitExactIn(
        address tokenIn,
        address tokenOut,
        uint swapAmount,
        uint nPools
    ) external view returns (Swap[] memory swaps, uint totalOutput);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
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
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library EnumerableSetUpgradeable {
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

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "../interfaces/IInvestmentStrategy.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

abstract contract InvestmentStrategyBase is IInvestmentStrategy, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant COMPOSABLE_HOLDING = keccak256("COMPOSABLE_HOLDING");

    function initializeBase(address _admin, address _investor)
    internal
    initializer
    {
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setRoleAdmin(COMPOSABLE_HOLDING, DEFAULT_ADMIN_ROLE);
        _setupRole(COMPOSABLE_HOLDING, _investor);
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }

    modifier validAmount(uint256 _value) {
        require(_value > 0, "Invalid amount");
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Permissions: Only admins allowed"
        );
        _;
    }

    modifier onlyInvestor() {
        require(
            hasRole(COMPOSABLE_HOLDING, _msgSender()),
            "Permissions: Only investor allowed"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface IInvestmentStrategy {
    function makeInvestment(address token, uint256 amount, bytes calldata data) external returns(uint);

    function withdrawInvestment(address token, uint256 amount, bytes calldata data) external;

    function claimTokens(bytes calldata data) external returns (address);

    function investmentAmount(address token) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./CTokenInterfaces.sol";
import "./IComptroller.sol";
import "../../core/InvestmentStrategyBase.sol";

contract CompoundInvestmentStrategy is InvestmentStrategyBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public composableHolding;

    IComptroller public comptroller;

    address public compToken;

    mapping(address => address) public cTokens;

    function initialize(
        address _admin,
        address _composableHolding,
        address _comptroller,
        address _compToken
    ) public
    initializer
    {
        initializeBase(_admin, _composableHolding);
        composableHolding = _composableHolding;
        comptroller = IComptroller(_comptroller);
        compToken = _compToken;
    }

    function setCTokensAddress(address token, address cToken)
    external
    onlyAdmin
    validAddress(token)
    validAddress(cToken)
    {
        require(CErc20Interface(cToken).underlying() == token, "Wrong cToken address");
        cTokens[token] = cToken;
    }

    function makeInvestment(address token, uint256 amount, bytes calldata)
    external
    onlyInvestor
    nonReentrant
    override
    returns (uint)
    {
        address cToken = cTokens[token];
        require(cToken != address(0), "cToken address not set");
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);

        IERC20Upgradeable(token).safeApprove(cToken, amount);
        uint mintedTokens = CErc20Interface(cToken).mint(amount);
        return mintedTokens;
    }

    function withdrawInvestment(address cToken, uint256 amount, bytes calldata)
    external
    onlyInvestor
    nonReentrant
    override
    {
        CErc20Interface cTokenERC20 = CErc20Interface(cToken);
        address underlyingToken = cTokenERC20.underlying();
        require(cTokens[underlyingToken] == cToken, "Wrong cToken address");
        require(cTokenERC20.redeem(amount) == 0, "Withdraw fail");
        IERC20Upgradeable(underlyingToken).safeTransfer(composableHolding, IERC20Upgradeable(underlyingToken).balanceOf(address(this)));
    }

    function claimTokens(bytes calldata) external override returns (address) {
        comptroller.claimComp(address(this));
        IERC20Upgradeable(compToken).safeTransfer(composableHolding, IERC20Upgradeable(compToken).balanceOf(address(this)));
        return compToken;
    }

    function investmentAmount(address token)
    external
    override
    validAddress(token)
    returns (uint)
    {
        address cToken = cTokens[token];
        require(cToken != address(0), "cToken address not set");
        return CErc20Interface(cToken).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "./EIP20NonStandardInterface.sol";

interface CErc20Interface is EIP20NonStandardInterface {
    function underlying() external view returns (address);

    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function borrowRatePerBlock() external returns (uint);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function balanceOfUnderlying(address) external returns (uint);
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

interface IComptroller {
    // Claim all the COMP accrued by holder in all markets
    function claimComp(address holder) external;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "../interfaces/IComposableHolding.sol";
import "../interfaces/IInvestmentStrategy.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract ComposableHolding is IComposableHolding, ReentrancyGuardUpgradeable, AccessControlUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant COMPOSABLE_VAULT = keccak256("COMPOSABLE_VAULT");

    mapping(address => bool) public investmentStrategies;

    event FoundsInvested(
        address indexed strategy,
        address indexed token,
        uint256 indexed amount,
        uint cTokensReceived
    );

    event FoundsWithdrawed(
        address indexed strategy,
        address indexed token,
        uint256 indexed amount
    );

    event TokenClaimed(
        address indexed strategy,
        address indexed rewardTokenAddress
    );

    function initialize(address _admin)
    public
    initializer
    {
        __ReentrancyGuard_init();
        __Pausable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setRoleAdmin(COMPOSABLE_VAULT, DEFAULT_ADMIN_ROLE);
    }

    /// @notice External function used by admin of the contract to add uniq role address
    /// @param _role rol of the actor
    /// @param _actor address of the actor
    function setUniqRole(bytes32 _role, address _actor)
    external
    override
    validAddress(_actor)
    onlyAdmin
    {
        uint256 rolesCount = getRoleMemberCount(_role);
        for (uint256 i = 0; i < rolesCount; i++) {
            address _oldRoleAddress = getRoleMember(_role, i);
            revokeRole(_role, _oldRoleAddress);
        }
        grantRole(_role, _actor);
    }

    // @notice External function to transfer tokens by the vault or by admins
    // @param _token ERC20 token address
    // @param _receiver Address of the receiver, vault or EOA
    // @param _amount Amount to transfer
    function transfer(address _token, address _receiver, uint256 _amount)
    external
    override
    validAddress(_token)
    validAddress(_receiver)
    onlyVaultOrAdmin
    whenNotPaused
    {
        require(IERC20Upgradeable(_token).balanceOf(address(this)) >= _amount, "Not enough token in the contract");
        IERC20Upgradeable(_token).safeTransfer(_receiver, _amount);
    }

    /// @notice External function called in order to allow other party to spend from this contract
    /// @param spender Address of the spender
    /// @param token Address of the ERC20 token
    /// @param amount Amount allow to spend
    function approve(address spender, address token, uint256 amount)
    external
    override
    whenNotPaused
    validAddress(spender)
    onlyVaultOrAdmin
    {
        IERC20Upgradeable(token).safeApprove(spender, amount);
    }

    /// @notice External function called only by the admin to add IInvestmentStrategy supported contracts
    /// @param strategyAddress IInvestmentStrategy contract address
    function addInvestmentStrategy(address strategyAddress)
    external
    onlyAdmin
    validAddress(strategyAddress)
    {
        investmentStrategies[strategyAddress] = true;
    }

    /// @notice External function called by the admin to invest founds in one of the IInvestmentStrategy from the contract
    /// @param token Address of the ERC20 token admin decide to invest
    /// @param amount Amount of the tokens admin want to invest
    /// @param investmentStrategy Address of the IInvestmentStrategy admin want to use
    /// @param data dynamic data that strategy required
    function invest(address token, uint256 amount, address investmentStrategy, bytes calldata data)
    external
    onlyAdmin
    validAddress(token)
    validAddress(investmentStrategy)
    validAmount(amount)
    {
        require(investmentStrategies[investmentStrategy], "Invalid strategy");
        require(IERC20Upgradeable(token).balanceOf(address(this)) >= amount, "Not enough tokens");
        IERC20Upgradeable(token).safeApprove(investmentStrategy, amount);
        uint mintedTokens = IInvestmentStrategy(investmentStrategy).makeInvestment(token, amount, data);
        emit FoundsInvested(investmentStrategy, token, amount, mintedTokens);
    }

    /// @notice External function called by the admin to withdraw investment
    /// @param token Address of the ERC20 token admin use to invest or the receipt token
    /// @param amount Amount of the tokens need to be withdrawed
    /// @param investmentStrategy address of the strategy
    /// @param data dynamic data that strategy required
    function withdrawInvestment(address token, uint256 amount, address investmentStrategy, bytes calldata data)
    external
    onlyAdmin
    validAddress(token)
    validAddress(investmentStrategy)
    validAmount(amount)
    {
        require(investmentStrategies[investmentStrategy], "Invalid strategy");
        IInvestmentStrategy(investmentStrategy).withdrawInvestment(token, amount, data);
        emit FoundsWithdrawed(investmentStrategy, token, amount);
    }

    /// @notice External function used to claim tokens that different DAO issues for the investors
    /// @param investmentStrategy address of the strategy
    /// @param data dynamic data that strategy required
    function claim(address investmentStrategy, bytes calldata data)
    external
    onlyAdmin
    validAddress(investmentStrategy)
    {
        require(investmentStrategies[investmentStrategy], "Invalid strategy");
        address rewardTokenAddress = IInvestmentStrategy(investmentStrategy).claimTokens(data);
        emit TokenClaimed(investmentStrategy, rewardTokenAddress);
    }

    function pause() external whenNotPaused onlyAdmin {
        _pause();
    }

    function unpause() external whenPaused onlyAdmin {
        _unpause();
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }

    modifier validAmount(uint256 _value) {
        require(_value > 0, "Invalid amount");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admins allowed");
        _;
    }

    modifier onlyVaultOrAdmin() {
        require(hasRole(COMPOSABLE_VAULT, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Permissions: Not allowed");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC677 is IERC20 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;
import "./IERC677.sol";

interface IForeignOmnibridge {
    function withinLimit(address token, uint256 amount)
        external
        view
        returns (bool);

    function relayTokens(
        IERC677 token,
        address receiver,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "./IForeignOmnibridge.sol";
import "../BridgeBase.sol";

contract VaultXdai is BridgeBase {
    IForeignOmnibridge public xDaiOmniBridgeAddress;

    constructor(address _xDaiOmniBridgeAddress) public {
        xDaiOmniBridgeAddress = IForeignOmnibridge(_xDaiOmniBridgeAddress);
    }

    function setDaiOmniBridgeAddress(address _router) external onlyAdmin {
        require(_router != address(0), "Invalid address");
        xDaiOmniBridgeAddress = IForeignOmnibridge(_router);
    }

    function _transferL2Implementation(
        uint256 amount,
        address token,
        bytes memory,
        address destination
    ) internal override {
        require(
            xDaiOmniBridgeAddress.withinLimit(token, amount),
            "Amount exceeds limit of the bridge"
        );

        SafeERC20.safeIncreaseAllowance(
            IERC20(token),
            address(xDaiOmniBridgeAddress),
            amount
        );
        xDaiOmniBridgeAddress.relayTokens(IERC677(token), destination, amount);
    }
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "./IRootChainManager.sol";
import "../BridgeBase.sol";

contract VaultPolygon is BridgeBase {
    IRootChainManager public rootChainManager;

    constructor(address _rootChainManager) public {
        rootChainManager = IRootChainManager(_rootChainManager);
    }

    function setRootChainManager(address _router) external onlyAdmin {
        require(_router != address(0), "Invalid address");
        rootChainManager = IRootChainManager(_router);
    }

    function _transferL2Implementation(
        uint256 amount,
        address token,
        bytes memory,
        address destination
    ) internal override {
        address predicateAddress = rootChainManager.typeToPredicate(
            rootChainManager.tokenToType(token)
        );
        SafeERC20.safeIncreaseAllowance(
            IERC20(token),
            predicateAddress,
            amount
        );
        bytes memory encodedAmount = abi.encode(amount);
        rootChainManager.depositFor(destination, token, encodedAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

interface IRootChainManager {
    event TokenMapped(
        address indexed rootToken,
        address indexed childToken,
        bytes32 indexed tokenType
    );

    event PredicateRegistered(
        bytes32 indexed tokenType,
        address indexed predicateAddress
    );

    function registerPredicate(bytes32 tokenType, address predicateAddress)
        external;

    function typeToPredicate(bytes32 tokenType) external returns (address);

    function tokenToType(address token) external returns (bytes32);

    function mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function cleanMapToken(address rootToken, address childToken) external;

    function remapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function exit(bytes calldata inputData) external;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm

pragma solidity ^0.6.8;

import "./iOVM_L1ERC20Bridge.sol";
import "../BridgeBase.sol";

contract VaultOptimism is BridgeBase {

    address l1ERC20Bridge;

    constructor(address _l1ERC20Bridge) public {
        l1ERC20Bridge = _l1ERC20Bridge;
    }

    function setL1ERC20BridgeAddress(address _l1ERC20Bridge) external onlyAdmin {
        l1ERC20Bridge = _l1ERC20Bridge;
    }

    function _transferL2Implementation(
        uint256 amount,
        address token,
        bytes memory data,
        address destination
    ) internal override {

        // approve the tokens for transfer
        SafeERC20.safeIncreaseAllowance(IERC20(token), l1ERC20Bridge, amount);

        // get the address of the token on l2
        (address l2TokenAddress, uint32 gasLimit) = abi.decode(data, (address, uint32));

        iOVM_L1ERC20Bridge(l1ERC20Bridge).depositERC20To(
            token,
            l2TokenAddress,
            destination,
            amount,
            gasLimit,
            ""
        );

    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

/**
 * @title iOVM_L1ERC20Bridge
 */
interface iOVM_L1ERC20Bridge {

    /**********
     * Events *
     **********/

    event ERC20DepositInitiated (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    event ERC20WithdrawalFinalized (
        address indexed _l1Token,
        address indexed _l2Token,
        address indexed _from,
        address _to,
        uint256 _amount,
        bytes _data
    );

    /********************
     * Public Functions *
     ********************/

    /**
     * @dev deposit an amount of the ERC20 to the caller's balance on L2.
     * @param _l1Token Address of the L1 ERC20 we are depositing
     * @param _l2Token Address of the L1 respective L2 ERC20
     * @param _amount Amount of the ERC20 to deposit
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositERC20 (
        address _l1Token,
        address _l2Token,
        uint _amount,
        uint32 _l2Gas,
        bytes calldata _data
    )
        external;

    /**
     * @dev deposit an amount of ERC20 to a recipient's balance on L2.
     * @param _l1Token Address of the L1 ERC20 we are depositing
     * @param _l2Token Address of the L1 respective L2 ERC20
     * @param _to L2 address to credit the withdrawal to.
     * @param _amount Amount of the ERC20 to deposit.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositERC20To (
        address _l1Token,
        address _l2Token,
        address _to,
        uint _amount,
        uint32 _l2Gas,
        bytes calldata _data
    )
        external;


    /*************************
     * Cross-chain Functions *
     *************************/

    /**
     * @dev Complete a withdrawal from L2 to L1, and credit funds to the recipient's balance of the
     * L1 ERC20 token.
     * This call will fail if the initialized withdrawal from L2 has not been finalized.
     *
     * @param _l1Token Address of L1 token to finalizeWithdrawal for.
     * @param _l2Token Address of L2 token where withdrawal was initiated.
     * @param _from L2 address initiating the transfer.
     * @param _to L1 address to credit the withdrawal to.
     * @param _amount Amount of the ERC20 to deposit.
     * @param _data Data provided by the sender on L2. This data is provided
     *   solely as a convenience for external contracts. Aside from enforcing a maximum
     *   length, these contracts provide no guarantees about its content.
     */
    function finalizeERC20Withdrawal (
        address _l1Token,
        address _l2Token,
        address _from,
        address _to,
        uint _amount,
        bytes calldata _data
    )
        external;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "../BridgeBase.sol";

import "./IRainbowBridge.sol";

contract VaultNear is BridgeBase {
    IRainbowBridge public rainbowBridge;

    constructor(address _rainbow) public {
        require(_rainbow != address(0), "Invalid address");
        rainbowBridge = IRainbowBridge(_rainbow);
    }

    function setRainbowBridge(address _rainbow) external onlyAdmin {
        require(_rainbow != address(0), "Invalid address");
        rainbowBridge = IRainbowBridge(_rainbow);
    }

    function _transferL2Implementation(
        uint256 amount,
        address token,
        bytes memory data,
        address
    ) internal override {
        SafeERC20.safeIncreaseAllowance(
            IERC20(token),
            address(rainbowBridge),
            amount
        );
        string memory accountId = abi.decode(data, (string));
        rainbowBridge.lockToken(token, amount, accountId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

interface IRainbowBridge {
    function lockToken(
        address ethToken,
        uint256 amount,
        string calldata accountId
    ) external payable;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity ^0.6.8;

import "../BridgeBase.sol";
import "./IMoonriverBridge.sol";

contract VaultMoonriver is BridgeBase {
    IMoonriverBridge public moonriverBridge;

    constructor(address _bridge) public {
        require(_bridge != address(0), "Invalid address");
        moonriverBridge = IMoonriverBridge(_bridge);
    }

    function setBridge(address _bridge) external onlyAdmin {
        require(_bridge != address(0), "Invalid address");
        moonriverBridge = IMoonriverBridge(_bridge);
    }

    function _transferL2Implementation(
        uint256 amount,
        address token,
        bytes memory data,
        address destination
    ) internal override {
        SafeERC20.safeIncreaseAllowance(
            IERC20(token),
            address(moonriverBridge),
            amount
        );
        uint256 chainId = abi.decode(data, (uint256));
        moonriverBridge.sendERC20SToken(chainId, destination, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

interface IMoonriverBridge {
    function sendERC20SToken(uint256 destinationChainID, address recipient, uint256 amount) external;

    function sendERC721MoonToken(uint256 destinationChainID, address recipient, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
// @unsupported: ovm

pragma solidity ^0.6.8;

import "./IBobaERC20Bridge.sol";
import "../BridgeBase.sol";

contract VaultBoba is BridgeBase {
    IBobaERC20Bridge bobaBridge;

    constructor(address _bobaBridge) public {
        require(_bobaBridge != address(0), "Invalid address");
        bobaBridge = IBobaERC20Bridge(_bobaBridge);
    }

    function setBobaBridge(address _bobaBridge) external onlyAdmin {
        require(_bobaBridge != address(0), "Invalid address");
        bobaBridge = IBobaERC20Bridge(_bobaBridge);
    }

    function _transferL2Implementation(
        uint256 amount,
        address token,
        bytes memory data,
        address destination
    ) internal override {
        // approve the tokens for transfer
        SafeERC20.safeIncreaseAllowance(
            IERC20(token),
            address(bobaBridge),
            amount
        );

        // get the address of the token on l2
        (address l2TokenAddress, uint32 gasLimit) = abi.decode(
            data,
            (address, uint32)
        );

        bobaBridge.depositERC20To(
            token,
            l2TokenAddress,
            destination,
            amount,
            gasLimit,
            ""
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

interface IBobaERC20Bridge {
    function depositERC20To (
        address _l1Token,
        address _l2Token,
        address _to,
        uint _amount,
        uint32 _l2Gas,
        bytes calldata _data
    )
        external;


 
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}