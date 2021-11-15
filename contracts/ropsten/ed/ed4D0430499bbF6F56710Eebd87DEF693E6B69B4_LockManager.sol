// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IVotingPower.sol";
import "./interfaces/ITokenRegistry.sol";
import "./interfaces/IVotingPowerFormula.sol";
import "./interfaces/ILockManager.sol";
import "./lib/AccessControl.sol";

/**
 * @title LockManager
 * @dev Manages voting power for stakes that are locked within the Eden ecosystem, but not in the Voting Power prism
 */
contract LockManager is AccessControl, ILockManager {

    /// @notice Admin role to create voting power from locked stakes
    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");

    // Official record of staked balances for each account > token > locked stake
    mapping (address => mapping (address => LockedStake)) internal lockedStakes;

    /// @notice Voting power contract
    IVotingPower public votingPower;

    /// @notice modifier to restrict functions to only contracts that have been added as lockers
    modifier onlyLockers() {
        require(hasRole(LOCKER_ROLE, msg.sender), "Caller must have LOCKER_ROLE role");
        _;
    }

    /// @notice An event that's emitted when a user's staked balance increases
    event StakeLocked(address indexed user, address indexed token, uint256 indexed amount, uint256 votingPower);

    /// @notice An event that's emitted when a user's staked balance decreases
    event StakeUnlocked(address indexed user, address indexed token, uint256 indexed amount, uint256 votingPower);

    /**
     * @notice Create new LockManager contract
     * @param _votingPower VotingPower prism contract
     * @param _roleManager address that is in charge of assigning roles
     */
    constructor(address _votingPower, address _roleManager) {
        votingPower = IVotingPower(_votingPower);
        _setupRole(DEFAULT_ADMIN_ROLE, _roleManager);
    }

    /**
     * @notice Get total amount of tokens staked in contract by `staker`
     * @param staker The user with staked tokens
     * @param stakedToken The staked token
     * @return total amount staked
     */
    function getAmountStaked(address staker, address stakedToken) external view override returns (uint256) {
        return getStake(staker, stakedToken).amount;
    }

    /**
     * @notice Get total staked amount and voting power from `stakedToken` staked in contract by `staker`
     * @param staker The user with staked tokens
     * @param stakedToken The staked token
     * @return total staked
     */
    function getStake(address staker, address stakedToken) public view override returns (LockedStake memory) {
        return lockedStakes[staker][stakedToken];
    }

    /**
     * @notice Calculate the voting power that will result from locking `amount` of `token`
     * @param token token that will be locked
     * @param amount amount of token that will be locked
     * @return resulting voting power
     */
    function calculateVotingPower(address token, uint256 amount) public view override returns (uint256) {
        address registry = votingPower.tokenRegistry();
        require(registry != address(0), "LM::calculateVotingPower: registry not set");
        address tokenFormulaAddress = ITokenRegistry(registry).tokenFormulas(token);
        require(tokenFormulaAddress != address(0), "LM::calculateVotingPower: token not supported");
        
        IVotingPowerFormula tokenFormula = IVotingPowerFormula(tokenFormulaAddress);
        return tokenFormula.convertTokensToVotingPower(amount);
    }

    /**
     * @notice Grant voting power from locked `tokenAmount` of `token`
     * @param receiver recipient of voting power
     * @param token token that is locked
     * @param tokenAmount amount of token that is locked
     * @return votingPowerGranted amount of voting power granted
     */
    function grantVotingPower(
        address receiver, 
        address token, 
        uint256 tokenAmount
    ) external override onlyLockers returns (uint256 votingPowerGranted){
        votingPowerGranted = calculateVotingPower(token, tokenAmount);
        lockedStakes[receiver][token].amount = lockedStakes[receiver][token].amount + tokenAmount;
        lockedStakes[receiver][token].votingPower = lockedStakes[receiver][token].votingPower + votingPowerGranted;
        votingPower.addVotingPowerForLockedTokens(receiver, votingPowerGranted);
        emit StakeLocked(receiver, token, tokenAmount, votingPowerGranted);
    }

    /**
     * @notice Remove voting power by unlocking `tokenAmount` of `token`
     * @param receiver holder of voting power
     * @param token token that is being unlocked
     * @param tokenAmount amount of token that is being unlocked
     * @return votingPowerRemoved amount of voting power removed
     */
    function removeVotingPower(
        address receiver, 
        address token, 
        uint256 tokenAmount
    ) external override onlyLockers returns (uint256 votingPowerRemoved) {
        require(lockedStakes[receiver][token].amount >= tokenAmount, "LM::removeVotingPower: not enough tokens staked");
        LockedStake memory s = getStake(receiver, token);
        votingPowerRemoved = tokenAmount * s.votingPower / s.amount;
        lockedStakes[receiver][token].amount = lockedStakes[receiver][token].amount - tokenAmount;
        lockedStakes[receiver][token].votingPower = lockedStakes[receiver][token].votingPower - votingPowerRemoved;
        votingPower.removeVotingPowerForUnlockedTokens(receiver, votingPowerRemoved);
        emit StakeUnlocked(receiver, token, tokenAmount, votingPowerRemoved);
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILockManager {
    struct LockedStake {
        uint256 amount;
        uint256 votingPower;
    }

    function getAmountStaked(address staker, address stakedToken) external view returns (uint256);
    function getStake(address staker, address stakedToken) external view returns (LockedStake memory);
    function calculateVotingPower(address token, uint256 amount) external view returns (uint256);
    function grantVotingPower(address receiver, address token, uint256 tokenAmount) external returns (uint256 votingPowerGranted);
    function removeVotingPower(address receiver, address token, uint256 tokenAmount) external returns (uint256 votingPowerRemoved);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenRegistry {
    function owner() external view returns (address);
    function tokenFormulas(address) external view returns (address);
    function setTokenFormula(address token, address formula) external;
    function removeToken(address token) external;
    function changeOwner(address newOwner) external;
    event ChangedOwner(address indexed oldOwner, address indexed newOwner);
    event TokenAdded(address indexed token, address indexed formula);
    event TokenRemoved(address indexed token);
    event TokenFormulaUpdated(address indexed token, address indexed formula);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/PrismProxy.sol";

interface IVotingPower {

    struct Stake {
        uint256 amount;
        uint256 votingPower;
    }

    function setPendingProxyImplementation(address newPendingImplementation) external returns (bool);
    function acceptProxyImplementation() external returns (bool);
    function setPendingProxyAdmin(address newPendingAdmin) external returns (bool);
    function acceptProxyAdmin() external returns (bool);
    function proxyAdmin() external view returns (address);
    function pendingProxyAdmin() external view returns (address);
    function proxyImplementation() external view returns (address);
    function pendingProxyImplementation() external view returns (address);
    function proxyImplementationVersion() external view returns (uint8);
    function become(PrismProxy prism) external;
    function initialize(address _edenToken, address _owner) external;
    function owner() external view returns (address);
    function edenToken() external view returns (address);
    function tokenRegistry() external view returns (address);
    function lockManager() external view returns (address);
    function changeOwner(address newOwner) external;
    function setTokenRegistry(address registry) external;
    function setLockManager(address newLockManager) external;
    function stake(uint256 amount) external;
    function stakeWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function withdraw(uint256 amount) external;
    function addVotingPowerForLockedTokens(address account, uint256 amount) external;
    function removeVotingPowerForUnlockedTokens(address account, uint256 amount) external;
    function getEDENAmountStaked(address staker) external view returns (uint256);
    function getAmountStaked(address staker, address stakedToken) external view returns (uint256);
    function getEDENStake(address staker) external view returns (Stake memory);
    function getStake(address staker, address stakedToken) external view returns (Stake memory);
    function balanceOf(address account) external view returns (uint256);
    function balanceOfAt(address account, uint256 blockNumber) external view returns (uint256);
    event NewPendingImplementation(address indexed oldPendingImplementation, address indexed newPendingImplementation);
    event NewImplementation(address indexed oldImplementation, address indexed newImplementation);
    event NewPendingAdmin(address indexed oldPendingAdmin, address indexed newPendingAdmin);
    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);
    event Staked(address indexed user, address indexed token, uint256 indexed amount, uint256 votingPower);
    event Withdrawn(address indexed user, address indexed token, uint256 indexed amount, uint256 votingPower);
    event VotingPowerChanged(address indexed voter, uint256 indexed previousBalance, uint256 indexed newBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVotingPowerFormula {
    function convertTokensToVotingPower(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

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

import "../interfaces/IERC165.sol";

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
pragma solidity ^0.8.0;

contract PrismProxy {

    /// @notice Proxy admin and implementation storage variables
    struct ProxyStorage {
        // Administrator for this contract
        address admin;

        // Pending administrator for this contract
        address pendingAdmin;

        // Active implementation of this contract
        address implementation;

        // Pending implementation of this contract
        address pendingImplementation;

        // Implementation version of this contract
        uint8 version;
    }

    /// @dev Position in contract storage where prism ProxyStorage struct will be stored
    bytes32 constant PRISM_PROXY_STORAGE_POSITION = keccak256("prism.proxy.storage");

    /// @notice Emitted when pendingImplementation is changed
    event NewPendingImplementation(address indexed oldPendingImplementation, address indexed newPendingImplementation);

    /// @notice Emitted when pendingImplementation is accepted, which means implementation is updated
    event NewImplementation(address indexed oldImplementation, address indexed newImplementation);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address indexed oldPendingAdmin, address indexed newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address indexed oldAdmin, address indexed newAdmin);

    /**
     * @notice Load proxy storage struct from specified PRISM_PROXY_STORAGE_POSITION
     * @return ps ProxyStorage struct
     */
    function proxyStorage() internal pure returns (ProxyStorage storage ps) {        
        bytes32 position = PRISM_PROXY_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    /*** Admin Functions ***/
    
    /**
     * @notice Create new pending implementation for prism. msg.sender must be admin
     * @dev Admin function for proposing new implementation contract
     * @return boolean indicating success of operation
     */
    function setPendingProxyImplementation(address newPendingImplementation) public returns (bool) {
        ProxyStorage storage s = proxyStorage();
        require(msg.sender == s.admin, "Prism::setPendingProxyImp: caller must be admin");

        address oldPendingImplementation = s.pendingImplementation;

        s.pendingImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, s.pendingImplementation);

        return true;
    }

    /**
     * @notice Accepts new implementation for prism. msg.sender must be pendingImplementation
     * @dev Admin function for new implementation to accept it's role as implementation
     * @return boolean indicating success of operation
     */
    function acceptProxyImplementation() public returns (bool) {
        ProxyStorage storage s = proxyStorage();
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(msg.sender == s.pendingImplementation && s.pendingImplementation != address(0), "Prism::acceptProxyImp: caller must be pending implementation");
 
        // Save current values for inclusion in log
        address oldImplementation = s.implementation;
        address oldPendingImplementation = s.pendingImplementation;

        s.implementation = s.pendingImplementation;

        s.pendingImplementation = address(0);
        s.version++;

        emit NewImplementation(oldImplementation, s.implementation);
        emit NewPendingImplementation(oldPendingImplementation, s.pendingImplementation);

        return true;
    }

    /**
     * @notice Begins transfer of admin rights. The newPendingAdmin must call `acceptAdmin` to finalize the transfer.
     * @dev Admin function to begin change of admin. The newPendingAdmin must call `acceptAdmin` to finalize the transfer.
     * @param newPendingAdmin New pending admin.
     * @return boolean indicating success of operation
     */
    function setPendingProxyAdmin(address newPendingAdmin) public returns (bool) {
        ProxyStorage storage s = proxyStorage();
        // Check caller = admin
        require(msg.sender == s.admin, "Prism::setPendingProxyAdmin: caller must be admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = s.pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        s.pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

        return true;
    }

    /**
     * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
     * @dev Admin function for pending admin to accept role and update admin
     * @return boolean indicating success of operation
     */
    function acceptProxyAdmin() public returns (bool) {
        ProxyStorage storage s = proxyStorage();
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == s.pendingAdmin && msg.sender != address(0), "Prism::acceptProxyAdmin: caller must be pending admin");

        // Save current values for inclusion in log
        address oldAdmin = s.admin;
        address oldPendingAdmin = s.pendingAdmin;

        // Store admin with value pendingAdmin
        s.admin = s.pendingAdmin;

        // Clear the pending value
        s.pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, s.admin);
        emit NewPendingAdmin(oldPendingAdmin, s.pendingAdmin);

        return true;
    }

    /**
     * @notice Get current admin for prism proxy
     * @return admin address
     */
    function proxyAdmin() public view returns (address) {
        ProxyStorage storage s = proxyStorage();
        return s.admin;
    }

    /**
     * @notice Get pending admin for prism proxy
     * @return admin address
     */
    function pendingProxyAdmin() public view returns (address) {
        ProxyStorage storage s = proxyStorage();
        return s.pendingAdmin;
    }

    /**
     * @notice Address of implementation contract
     * @return implementation address
     */
    function proxyImplementation() public view returns (address) {
        ProxyStorage storage s = proxyStorage();
        return s.implementation;
    }

    /**
     * @notice Address of pending implementation contract
     * @return pending implementation address
     */
    function pendingProxyImplementation() public view returns (address) {
        ProxyStorage storage s = proxyStorage();
        return s.pendingImplementation;
    }

    /**
     * @notice Current implementation version for proxy
     * @return version number
     */
    function proxyImplementationVersion() public view returns (uint8) {
        ProxyStorage storage s = proxyStorage();
        return s.version;
    }

    /**
     * @notice Delegates execution to an implementation contract.
     * @dev Returns to the external caller whatever the implementation returns or forwards reverts
     */
    function _forwardToImplementation() internal {
        ProxyStorage storage s = proxyStorage();
        // delegate all other functions to current implementation
        (bool success, ) = s.implementation.delegatecall(msg.data);

        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize())

              switch success
              case 0 { revert(free_mem_ptr, returndatasize()) }
              default { return(free_mem_ptr, returndatasize()) }
        }
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

