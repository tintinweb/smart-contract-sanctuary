// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;

import "@yield-protocol/utils-v2/contracts/access/AccessControl.sol";
import "@yield-protocol/vault-interfaces/IOracle.sol";
import "../../math/CastBytes32Bytes6.sol";


/**
 * @title CompositeMultiOracle
 */
contract CompositeMultiOracle is IOracle, AccessControl {
    using CastBytes32Bytes6 for bytes32;

    uint8 public constant override decimals = 18;   // All prices are converted to 18 decimals

    event SourceSet(bytes6 indexed baseId, bytes6 indexed quoteId, address indexed source);
    event PathSet(bytes6 indexed baseId, bytes6 indexed quoteId, bytes6[] indexed path);

    struct Source {
        address source;
        uint8 decimals;
    }

    mapping(bytes6 => mapping(bytes6 => Source)) public sources;
    mapping(bytes6 => mapping(bytes6 => bytes6[])) public paths;

    /**
     * @notice Set or reset an oracle source
     */
    function setSource(bytes6 base, bytes6 quote, address source) external auth {
        _setSource(base, quote, source);
    }

    /**
     * @notice Set or reset a number of oracle sources
     */
    function setSources(bytes6[] memory bases, bytes6[] memory quotes, address[] memory sources_) external auth {
        require(
            bases.length == quotes.length && 
            bases.length == sources_.length,
            "Mismatched inputs"
        );
        for (uint256 i = 0; i < bases.length; i++) {
            _setSource(bases[i], quotes[i], sources_[i]);
        }
    }

    /**
     * @notice Set or reset an price path
     */
    function setPath(bytes6 base, bytes6 quote, bytes6[] memory path) external auth {
        _setPath(base, quote, path);
    }

    /**
     * @notice Set or reset a number of price paths
     */
    function setPaths(bytes6[] memory bases, bytes6[] memory quotes, bytes6[][] memory paths_) external auth {
        require(
            bases.length == quotes.length && 
            bases.length == paths_.length,
            "Mismatched inputs"
        );
        for (uint256 i = 0; i < bases.length; i++) {
            _setPath(bases[i], quotes[i], paths_[i]);
        }
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price.
     * @return value
     */
    function peek(bytes32 base, bytes32 quote, uint256 amount)
        external view virtual override
        returns (uint256 value, uint256 updateTime)
    {
        uint256 price = 1e18;
        bytes6 base_ = base.b6();
        bytes6 quote_ = quote.b6();
        bytes6[] memory path = paths[base_][quote_];
        for (uint256 p = 0; p < path.length; p++) {
            (price, updateTime) = _peek(base_, path[p], price, updateTime);
            base_ = path[p];
        }
        (price, updateTime) = _peek(base_, quote_, price, updateTime);
        value = price * amount / 1e18;
    }

    /**
     * @notice Retrieve the value of the amount at the latest oracle price.. Same as `peek` for this oracle.
     * @return value
     */
    function get(bytes32 base, bytes32 quote, uint256 amount)
        external virtual override
        returns (uint256 value, uint256 updateTime)
    {
        uint256 price = 1e18;
        bytes6 base_ = base.b6();
        bytes6 quote_ = quote.b6();
        bytes6[] memory path = paths[base_][quote_];
        for (uint256 p = 0; p < path.length; p++) {
            (price, updateTime) = _get(base_, path[p], price, updateTime);
            base_ = path[p];
        }
        (price, updateTime) = _get(base_, quote_, price, updateTime);
        value = price * amount / 1e18;
    }

    function _peek(bytes6 base, bytes6 quote, uint256 priceIn, uint256 updateTimeIn)
        private view returns (uint priceOut, uint updateTimeOut)
    {
        Source memory source = sources[base][quote];
        require (source.source != address(0), "Source not found");
        (priceOut, updateTimeOut) = IOracle(source.source).peek(base, quote, 10 ** source.decimals);   // Get price for one unit
        priceOut = priceIn * priceOut / (10 ** source.decimals);                                       // Fixed point according to decimals
        updateTimeOut = (updateTimeOut < updateTimeIn) ? updateTimeOut : updateTimeIn;                 // Take the oldest update time
    }

    function _get(bytes6 base, bytes6 quote, uint256 priceIn, uint256 updateTimeIn)
        private returns (uint priceOut, uint updateTimeOut)
    {
        Source memory source = sources[base][quote];
        require (source.source != address(0), "Source not found");
        (priceOut, updateTimeOut) = IOracle(source.source).get(base, quote, 10 ** source.decimals);    // Get price for one unit
        priceOut = priceIn * priceOut / (10 ** source.decimals);                                       // Fixed point according to decimals
        updateTimeOut = (updateTimeOut < updateTimeIn) ? updateTimeOut : updateTimeIn;                 // Take the oldest update time
    }

    function _setSource(bytes6 base, bytes6 quote, address source) internal {
        uint8 decimals_ = IOracle(source).decimals();
        require (decimals_ <= 18, "Unsupported decimals");
        sources[base][quote] = Source({
            source: source,
            decimals: decimals_
        });
        emit SourceSet(base, quote, source);
    }

    function _setPath(bytes6 base, bytes6 quote, bytes6[] memory path) internal {
        bytes6 base_ = base;
        for (uint256 p = 0; p < path.length; p++) {
            require (sources[base_][path[p]].source != address(0), "Source not found");
            base_ = path[p];
        }
        paths[base][quote] = path;
        emit PathSet(base, quote, path);
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
pragma solidity ^0.8.0;

interface IOracle {
    /**
     * @notice Doesn't refresh the price, but returns the latest value available without doing any transactional operations:
     * @return value in wei
     */
    function peek(bytes32 base, bytes32 quote, uint256 amount) external view returns (uint256 value, uint256 updateTime);

    /**
     * @notice Does whatever work or queries will yield the most up-to-date price, and returns it.
     * @return value in wei
     */
    function get(bytes32 base, bytes32 quote, uint256 amount) external returns (uint256 value, uint256 updateTime);

    /**
     * @notice Number of decimals in the amounts returned by the oracle.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.1;


library CastBytes32Bytes6 {
    function b6(bytes32 x) internal pure returns (bytes6 y){
        require (bytes32(y = bytes6(x)) == x, "Cast overflow");
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