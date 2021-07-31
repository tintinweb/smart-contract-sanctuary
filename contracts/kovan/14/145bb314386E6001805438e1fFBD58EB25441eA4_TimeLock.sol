// SPDX-License-Identifier: MIT
// Inspired on TimeLock.sol from Compound.

pragma solidity ^0.8.0;
import "../access/AccessControl.sol";
import "./RevertMsgExtractor.sol";

interface ITimeLock {
    function setDelay(uint32 delay_) external;
    function schedule(address[] memory targets, bytes[] memory data, uint32 eta) external returns (bytes32 txHash);
    function cancel(address[] memory targets, bytes[] memory data, uint32 eta) external;
    function execute(address[] memory targets, bytes[] memory data, uint32 eta) external returns (bytes[] memory results);
}

contract TimeLock is ITimeLock, AccessControl {
    enum State {UNKNOWN, SCHEDULED, CANCELLED, EXECUTED}

    uint32 public constant GRACE_PERIOD = 14 days;
    uint32 public constant MINIMUM_DELAY = 2 days;
    uint32 public constant MAXIMUM_DELAY = 30 days;

    event DelaySet(uint32 indexed delay);
    event Cancelled(bytes32 indexed txHash, address[] indexed targets, bytes[] data, uint32 eta);
    event Executed(bytes32 indexed txHash, address[] indexed targets, bytes[] data, uint32 eta);
    event Scheduled(bytes32 indexed txHash, address[] indexed targets, bytes[] data, uint32 eta);

    uint32 public delay;
    mapping (bytes32 => State) public transactions;

    constructor(address governor) AccessControl() {
        delay = MINIMUM_DELAY;

        // msg.sender can schedule, cancel, and execute transactions
        _grantRole(ITimeLock.schedule.selector, governor); // bytes4(keccak256("schedule(address[],bytes[],uint32)"))
        _grantRole(ITimeLock.cancel.selector, governor); // bytes4(keccak256("cancel(address[],bytes[],uint32)"))
        _grantRole(ITimeLock.execute.selector, governor); // bytes4(keccak256("execute(address[],bytes[],uint32)"))

        // Changing the delay must now be executed through this TimeLock contract
        _grantRole(ITimeLock.setDelay.selector, address(this)); // bytes4(keccak256("setDelay(uint32)"))

        // Granting roles (schedule, cancel, execute, setDelay) must now be executed through this TimeLock contract
        _grantRole(ROOT, address(this));
        _revokeRole(ROOT, msg.sender);
    }

    /// @dev Change the delay for queueing and executing transactions
    function setDelay(uint32 delay_) external override auth {
        require(delay_ >= MINIMUM_DELAY, "Must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Must not exceed maximum delay.");
        delay = delay_;

        emit DelaySet(delay);
    }

    /// @dev Schedule a transaction batch for execution between `eta` and `eta + GRACE_PERIOD`
    function schedule(address[] memory targets, bytes[] memory data, uint32 eta)
        external override auth returns (bytes32 txHash)
    {
        require(targets.length == data.length, "Mismatched inputs");
        require(eta >= uint32(block.timestamp) + delay, "Must satisfy delay.");
        txHash = keccak256(abi.encode(targets, data, eta));
        require(transactions[txHash] == State.UNKNOWN, "Transaction not unknown.");
        transactions[txHash] = State.SCHEDULED;
        emit Scheduled(txHash, targets, data, eta);
    }

    /// @dev Cancel a scheduled transaction batch
    function cancel(address[] memory targets, bytes[] memory data, uint32 eta)
        external override auth
    {
        require(targets.length == data.length, "Mismatched inputs");
        bytes32 txHash = keccak256(abi.encode(targets, data, eta));
        require(transactions[txHash] == State.SCHEDULED, "Transaction hasn't been scheduled.");
        transactions[txHash] = State.CANCELLED;
        emit Cancelled(txHash, targets, data, eta);
    }

    /// @dev Execute a transaction batch
    function execute(address[] memory targets, bytes[] memory data, uint32 eta)
        external override auth returns (bytes[] memory results)
    {
        require(targets.length == data.length, "Mismatched inputs");
        require(uint32(block.timestamp) >= eta, "ETA not reached.");
        require(uint32(block.timestamp) <= eta + GRACE_PERIOD, "Transaction is stale.");
        bytes32 txHash = keccak256(abi.encode(targets, data, eta));
        require(transactions[txHash] == State.SCHEDULED, "Transaction hasn't been scheduled.");
        transactions[txHash] = State.EXECUTED;

        results = new bytes[](targets.length);
        for (uint256 i = 0; i < targets.length; i++){
            (bool success, bytes memory result) = targets[i].call(data[i]);
            if (!success) revert(RevertMsgExtractor.getRevertMsg(result));
            results[i] = result;
            emit Executed(txHash, targets, data, eta);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes4` identifier. These are expected to be the 
 * signatures for all the functions in the contract. Special roles should be exposed
 * in the external API and be unique:
 *
 * ```
 * bytes4 public constant ROOT = 0x00000000;
 * ```
 *
 * Roles represent restricted access to a function call. For that purpose, use {auth}:
 *
 * ```
 * function foo() public auth {
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `ROOT`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {setRoleAdmin}.
 *
 * WARNING: The `ROOT` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
contract AccessControl {
    struct RoleData {
        mapping (address => bool) members;
        bytes4 adminRole;
    }

    mapping (bytes4 => RoleData) private _roles;

    bytes4 public constant ROOT = 0x00000000;
    bytes4 public constant LOCK = 0xFFFFFFFF; // Used to disable further permissioning of a function

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role
     *
     * `ROOT` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes4 indexed role, bytes4 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call.
     */
    event RoleGranted(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes4 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Give msg.sender the ROOT role and create a LOCK role with itself as the admin role and no members. 
     * Calling setRoleAdmin(msg.sig, LOCK) means no one can grant that msg.sig role anymore.
     */
    constructor () {
        _grantRole(ROOT, msg.sender);   // Grant ROOT to msg.sender
        _setRoleAdmin(LOCK, LOCK);      // Create the LOCK role by setting itself as its own admin, creating an independent role tree
    }

    /**
     * @dev Each function in the contract has its own role, identified by their msg.sig signature.
     * ROOT can give and remove access to each function, lock any further access being granted to
     * a specific action, or even create other roles to delegate admin control over a function.
     */
    modifier auth() {
        require (_hasRole(msg.sig, msg.sender), "Access denied");
        _;
    }

    /**
     * @dev Allow only if the caller has been granted the admin role of `role`.
     */
    modifier admin(bytes4 role) {
        require (_hasRole(_getRoleAdmin(role), msg.sender), "Only admin");
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes4 role, address account) external view returns (bool) {
        return _hasRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes4 role) external view returns (bytes4) {
        return _getRoleAdmin(role);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.

     * If ``role``'s admin role is not `adminRole` emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRoleAdmin(bytes4 role, bytes4 adminRole) external virtual admin(role) {
        _setRoleAdmin(role, adminRole);
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
    function grantRole(bytes4 role, address account) external virtual admin(role) {
        _grantRole(role, account);
    }

    
    /**
     * @dev Grants all of `role` in `roles` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function grantRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _grantRole(roles[i], account);
        }
    }

    /**
     * @dev Sets LOCK as ``role``'s admin role. LOCK has no members, so this disables admin management of ``role``.

     * Emits a {RoleAdminChanged} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function lockRole(bytes4 role) external virtual admin(role) {
        _setRoleAdmin(role, LOCK);
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
    function revokeRole(bytes4 role, address account) external virtual admin(role) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all of `role` in `roles` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - For each `role` in `roles`, the caller must have ``role``'s admin role.
     */
    function revokeRoles(bytes4[] memory roles, address account) external virtual {
        for (uint256 i = 0; i < roles.length; i++) {
            require (_hasRole(_getRoleAdmin(roles[i]), msg.sender), "Only admin");
            _revokeRole(roles[i], account);
        }
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
    function renounceRole(bytes4 role, address account) external virtual {
        require(account == msg.sender, "Renounce only for self");

        _revokeRole(role, account);
    }

    function _hasRole(bytes4 role, address account) internal view returns (bool) {
        return _roles[role].members[account];
    }

    function _getRoleAdmin(bytes4 role) internal view returns (bytes4) {
        return _roles[role].adminRole;
    }

    function _setRoleAdmin(bytes4 role, bytes4 adminRole) internal virtual {
        if (_getRoleAdmin(role) != adminRole) {
            _roles[role].adminRole = adminRole;
            emit RoleAdminChanged(role, adminRole);
        }
    }

    function _grantRole(bytes4 role, address account) internal {
        if (!_hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes4 role, address account) internal {
        if (_hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/sushiswap/BoringSolidity/blob/441e51c0544cf2451e6116fe00515e71d7c42e2c/contracts/BoringBatchable.sol

pragma solidity >=0.6.0;


library RevertMsgExtractor {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function getRevertMsg(bytes memory returnData)
        internal pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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