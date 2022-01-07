//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TokenGovernor is AccessControl {
  bytes32 public constant TIMELOCK_ADMIN_ROLE =
    keccak256("TIMELOCK_ADMIN_ROLE");
  bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
  bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
  uint256 internal constant _DONE_TIMESTAMP = uint256(1);

  IERC20 public token;

  mapping(bytes32 => uint256) private _timestamps;
  uint256 private _minDelay;

  /**
   * @dev Emitted when a call is scheduled as part of operation `id`.
   */
  event CallScheduled(
    bytes32 indexed id,
    uint256 indexed index,
    address target,
    uint256 value,
    bytes data,
    bytes32 predecessor,
    uint256 delay
  );

  /**
   * @dev Emitted when a call is performed as part of operation `id`.
   */
  event CallExecuted(
    bytes32 indexed id,
    uint256 indexed index,
    address target,
    uint256 value,
    bytes data
  );

  /**
   * @dev Emitted when operation `id` is cancelled.
   */
  event Cancelled(bytes32 indexed id);

  /**
   * @dev Emitted when the minimum delay for future operations is modified.
   */
  event MinDelayChange(uint256 oldDuration, uint256 newDuration);

  /**
   * @dev Initializes the contract with a given `minDelay`.
   */
  constructor(
    IERC20 _token,
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors
  ) {
    token = _token;

    _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
    _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
    _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);

    // deployer + self administration
    _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
    _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

    // register proposers
    for (uint256 i = 0; i < proposers.length; ++i) {
      _setupRole(PROPOSER_ROLE, proposers[i]);
    }

    // register executors
    for (uint256 i = 0; i < executors.length; ++i) {
      _setupRole(EXECUTOR_ROLE, executors[i]);
    }

    _minDelay = minDelay;
    emit MinDelayChange(0, minDelay);
  }

  /**
   * @dev Modifier to make a function callable only by a certain role. In
   * addition to checking the sender's role, `address(0)` 's role is also
   * considered. Granting a role to `address(0)` is equivalent to enabling
   * this role for everyone.
   */
  modifier onlyRoleOrOpenRole(bytes32 role) {
    if (!hasRole(role, address(0))) {
      _checkRole(role, _msgSender());
    }
    _;
  }

  /**
   * @dev Contract might receive/hold ETH as part of the maintenance process.
   */
  receive() external payable {}

  /**
   * @dev Returns whether an id correspond to a registered operation. This
   * includes both Pending, Ready and Done operations.
   */
  function isOperation(bytes32 id) public view virtual returns (bool pending) {
    return getTimestamp(id) > 0;
  }

  /**
   * @dev Returns whether an operation is pending or not.
   */
  function isOperationPending(bytes32 id)
    public
    view
    virtual
    returns (bool pending)
  {
    return getTimestamp(id) > _DONE_TIMESTAMP;
  }

  /**
   * @dev Returns whether an operation is ready or not.
   */
  function isOperationReady(bytes32 id)
    public
    view
    virtual
    returns (bool ready)
  {
    uint256 timestamp = getTimestamp(id);
    return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
  }

  /**
   * @dev Returns whether an operation is done or not.
   */
  function isOperationDone(bytes32 id) public view virtual returns (bool done) {
    return getTimestamp(id) == _DONE_TIMESTAMP;
  }

  /**
   * @dev Returns the timestamp at with an operation becomes ready (0 for
   * unset operations, 1 for done operations).
   */
  function getTimestamp(bytes32 id)
    public
    view
    virtual
    returns (uint256 timestamp)
  {
    return _timestamps[id];
  }

  /**
   * @dev Returns the minimum delay for an operation to become valid.
   *
   * This value can be changed by executing an operation that calls `updateDelay`.
   */
  function getMinDelay() public view virtual returns (uint256 duration) {
    return _minDelay;
  }

  /**
   * @dev Returns the identifier of an operation containing a single
   * transaction.
   */
  function hashOperation(
    address target,
    uint256 value,
    bytes calldata data,
    bytes32 predecessor,
    bytes32 salt
  ) public pure virtual returns (bytes32 hash) {
    return keccak256(abi.encode(target, value, data, predecessor, salt));
  }

  /**
   * @dev Returns the identifier of an operation containing a batch of
   * transactions.
   */
  function hashOperationBatch(
    address[] calldata targets,
    uint256[] calldata values,
    bytes[] calldata datas,
    bytes32 predecessor,
    bytes32 salt
  ) public pure virtual returns (bytes32 hash) {
    return keccak256(abi.encode(targets, values, datas, predecessor, salt));
  }

  /**
   * @dev Schedule an operation containing a single transaction.
   *
   * Emits a {CallScheduled} event.
   *
   * Requirements:
   *
   * - the caller must have the 'proposer' role.
   */
  function schedule(
    address target,
    uint256 value,
    bytes calldata data,
    bytes32 predecessor,
    bytes32 salt,
    uint256 delay
  ) public virtual onlyRole(PROPOSER_ROLE) {
    bytes32 id = hashOperation(target, value, data, predecessor, salt);
    _schedule(id, delay);
    emit CallScheduled(id, 0, target, value, data, predecessor, delay);
  }

  /**
   * @dev Schedule an operation containing a batch of transactions.
   *
   * Emits one {CallScheduled} event per transaction in the batch.
   *
   * Requirements:
   *
   * - the caller must have the 'proposer' role.
   */
  function scheduleBatch(
    address[] calldata targets,
    uint256[] calldata values,
    bytes[] calldata datas,
    bytes32 predecessor,
    bytes32 salt,
    uint256 delay
  ) public virtual onlyRole(PROPOSER_ROLE) {
    require(targets.length == values.length, "TokenGovernor: length mismatch");
    require(targets.length == datas.length, "TokenGovernor: length mismatch");

    bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
    _schedule(id, delay);
    for (uint256 i = 0; i < targets.length; ++i) {
      emit CallScheduled(
        id,
        i,
        targets[i],
        values[i],
        datas[i],
        predecessor,
        delay
      );
    }
  }

  /**
   * @dev Schedule an operation that is to becomes valid after a given delay.
   */
  function _schedule(bytes32 id, uint256 delay) private {
    require(!isOperation(id), "TokenGovernor: operation already scheduled");
    require(delay >= getMinDelay(), "TokenGovernor: insufficient delay");
    _timestamps[id] = block.timestamp + delay;
  }

  /**
   * @dev Cancel an operation.
   *
   * Requirements:
   *
   * - the caller must have the 'proposer' role.
   */
  function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
    require(
      isOperationPending(id),
      "TokenGovernor: operation cannot be cancelled"
    );
    delete _timestamps[id];

    emit Cancelled(id);
  }

  /**
   * @dev Execute an (ready) operation containing a single transaction.
   *
   * Emits a {CallExecuted} event.
   *
   * Requirements:
   *
   * - the caller must have the 'executor' role.
   */
  function execute(
    address target,
    uint256 value,
    bytes calldata data,
    bytes32 predecessor,
    bytes32 salt
  ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
    bytes32 id = hashOperation(target, value, data, predecessor, salt);
    _beforeCall(id, predecessor);
    _call(id, 0, target, value, data);
    _afterCall(id);
  }

  /**
   * @dev Execute an (ready) operation containing a batch of transactions.
   *
   * Emits one {CallExecuted} event per transaction in the batch.
   *
   * Requirements:
   *
   * - the caller must have the 'executor' role.
   */
  function executeBatch(
    address[] calldata targets,
    uint256[] calldata values,
    bytes[] calldata datas,
    bytes32 predecessor,
    bytes32 salt
  ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
    require(targets.length == values.length, "TokenGovernor: length mismatch");
    require(targets.length == datas.length, "TokenGovernor: length mismatch");

    bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
    _beforeCall(id, predecessor);
    for (uint256 i = 0; i < targets.length; ++i) {
      _call(id, i, targets[i], values[i], datas[i]);
    }
    _afterCall(id);
  }

  /**
   * @dev Checks before execution of an operation's calls.
   */
  function _beforeCall(bytes32 id, bytes32 predecessor) private view {
    require(isOperationReady(id), "TokenGovernor: operation is not ready");
    require(
      predecessor == bytes32(0) || isOperationDone(predecessor),
      "TokenGovernor: missing dependency"
    );
  }

  /**
   * @dev Checks after execution of an operation's calls.
   */
  function _afterCall(bytes32 id) private {
    require(isOperationReady(id), "TokenGovernor: operation is not ready");
    _timestamps[id] = _DONE_TIMESTAMP;
  }

  /**
   * @dev Execute an operation's call.
   *
   * Emits a {CallExecuted} event.
   */
  function _call(
    bytes32 id,
    uint256 index,
    address target,
    uint256 value,
    bytes calldata data
  ) private {
    (bool success, ) = target.call{ value: value }(data);
    require(success, "TokenGovernor: underlying transaction reverted");

    emit CallExecuted(id, index, target, value, data);
  }

  /**
   * @dev Changes the minimum timelock duration for future operations.
   *
   * Emits a {MinDelayChange} event.
   *
   * Requirements:
   *
   * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
   * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
   */
  function updateDelay(uint256 newDelay) external virtual {
    require(
      msg.sender == address(this),
      "TokenGovernor: caller must be timelock"
    );
    emit MinDelayChange(_minDelay, newDelay);
    _minDelay = newDelay;
  }

  function tokenTransfer(address toAddress, uint256 amount) external {
    require(
      msg.sender == address(this),
      "TokenGovernor: caller must be timelock"
    );
    require(
      token.balanceOf(address(this)) >= amount,
      "TokenGovernor: not enough tokens"
    );
    require(
      token.transfer(toAddress, amount),
      "TokenGovernor: token transfer failed"
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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