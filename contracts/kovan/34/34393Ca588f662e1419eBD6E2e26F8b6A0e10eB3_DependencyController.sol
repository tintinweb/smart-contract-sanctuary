// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor () {
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

pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RoleAware.sol";
import "./Executor.sol";
import "../interfaces/IDependencyController.sol";

/// @title Provides a single point of reference to verify integrity
/// of the roles structure and facilitate governance actions
/// within our system as well as performing cache invalidation for
/// roles and inter-contract relationships
contract DependencyController is RoleAware, IDependencyController {
    constructor(address _roles) RoleAware(_roles) {}

    address public override currentExecutor;

    address[] public managedContracts;
    mapping(uint256 => bool) public knownCharacters;
    mapping(uint256 => bool) public knownRoles;

    uint256[] public allCharacters;
    uint256[] public allRoles;

    function executeAsOwner(address executor) external onlyOwnerExec {
        uint256[] memory requiredRoles = Executor(executor).requiredRoles();

        for (uint256 i = 0; requiredRoles.length > i; i++) {
            _giveRole(requiredRoles[i], executor);
        }

        updateCaches(executor);
        currentExecutor = executor;
        Executor(executor).execute();
        currentExecutor = address(0);

        uint256 len = requiredRoles.length;
        for (uint256 i = 0; len > i; i++) {
            _removeRole(requiredRoles[i], executor);
        }
    }

    /// Orchestrate roles and permission for contract
    function manageContract(
        address contr,
        uint256[] memory charactersPlayed,
        uint256[] memory rolesPlayed
    ) external onlyOwnerExec {
        managedContracts.push(contr);

        // set up all characters this contract plays
        uint256 len = charactersPlayed.length;
        for (uint256 i = 0; len > i; i++) {
            uint256 character = charactersPlayed[i];
            _setMainCharacter(character, contr);
        }

        // all roles this contract plays
        len = rolesPlayed.length;
        for (uint256 i = 0; len > i; i++) {
            uint256 role = rolesPlayed[i];
            _giveRole(role, contr);
        }

        updateCaches(contr);
    }

    ///  Remove roles and permissions for contract
    function disableContract(address contr) external onlyOwnerExecDisabler {
        _disableContract(contr);
    }

    function _disableContract(address contr) internal {
        uint256 len = allRoles.length;
        for (uint256 i = 0; len > i; i++) {
            if (roles.getRole(allRoles[i], contr)) {
                _removeRole(allRoles[i], contr);
            }
        }

        len = allCharacters.length;
        for (uint256 i = 0; len > i; i++) {
            if (roles.mainCharacters(allCharacters[i]) == contr) {
                _setMainCharacter(allCharacters[i], address(0));
            }
        }
    }

    /// Activate role
    function giveRole(uint256 role, address actor) external onlyOwnerExec {
        _giveRole(role, actor);
    }

    /// Disable role
    function removeRole(uint256 role, address actor)
        external
        onlyOwnerExecDisabler
    {
        _removeRole(role, actor);
    }

    function _removeRole(uint256 role, address actor) internal {
        roles.removeRole(role, actor);
        updateRoleCache(role, actor);
    }

    function setMainCharacter(uint256 role, address actor)
        external
        onlyOwnerExec
    {
        _setMainCharacter(role, actor);
    }

    function _giveRole(uint256 role, address actor) internal {
        if (!knownRoles[role]) {
            knownRoles[role] = true;
            allRoles.push(role);
        }
        roles.giveRole(role, actor);
        updateRoleCache(role, actor);
    }

    function _setMainCharacter(uint256 character, address actor) internal {
        if (!knownCharacters[character]) {
            knownCharacters[character] = true;
            allCharacters.push(character);
        }
        roles.setMainCharacter(character, actor);
        updateMainCharacterCache(character);
    }

    function updateMainCharacterCache(uint256 character) public override {
        uint256 len = managedContracts.length;
        for (uint256 i = 0; len > i; i++) {
            RoleAware(managedContracts[i]).updateMainCharacterCache(character);
        }
    }

    function updateRoleCache(uint256 role, address contr) public override {
        uint256 len = managedContracts.length;
        for (uint256 i = 0; len > i; i++) {
            RoleAware(managedContracts[i]).updateRoleCache(role, contr);
        }
    }

    function updateCaches(address contr) public {
        // update this contract with all characters we know about
        uint256 len = allCharacters.length;
        for (uint256 i = 0; len > i; i++) {
            RoleAware(contr).updateMainCharacterCache(allCharacters[i]);
        }

        // update this contract with all roles for all contracts we know about
        len = allRoles.length;
        for (uint256 i = 0; len > i; i++) {
            for (uint256 j = 0; managedContracts.length > j; j++) {
                RoleAware(contr).updateRoleCache(
                    allRoles[i],
                    managedContracts[j]
                );
            }
        }
    }

    function allManagedContracts() external view returns (address[] memory) {
        return managedContracts;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RoleAware.sol";

abstract contract Executor is RoleAware {
    function requiredRoles() external virtual returns (uint256[] memory);

    function execute() external virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Roles.sol";

/// @title Role management behavior
/// Main characters are for service discovery
/// Whereas roles are for access control
contract RoleAware {
    Roles public immutable roles;
    mapping(uint256 => address) public mainCharacterCache;
    mapping(address => mapping(uint256 => bool)) public roleCache;

    constructor(address _roles) {
        require(_roles != address(0), "Please provide valid roles address");
        roles = Roles(_roles);
    }

    modifier noIntermediary() {
        require(
            msg.sender == tx.origin,
            "Currently no intermediaries allowed for this function call"
        );
        _;
    }

    // @dev Throws if called by any account other than the owner or executor
    modifier onlyOwnerExec() {
        require(
            owner() == msg.sender || executor() == msg.sender,
            "Roles: caller is not the owner"
        );
        _;
    }

    modifier onlyOwnerExecDisabler() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                disabler() == msg.sender,
            "Caller is not the owner, executor or authorized disabler"
        );
        _;
    }

    modifier onlyOwnerExecActivator() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                isTokenActivator(msg.sender),
            "Caller is not the owner, executor or authorized activator"
        );
        _;
    }

    function updateRoleCache(uint256 role, address contr) public virtual {
        roleCache[contr][role] = roles.getRole(role, contr);
    }

    function updateMainCharacterCache(uint256 role) public virtual {
        mainCharacterCache[role] = roles.mainCharacters(role);
    }

    function owner() internal view returns (address) {
        return roles.owner();
    }

    function executor() internal returns (address) {
        return roles.executor();
    }

    function disabler() internal view returns (address) {
        return mainCharacterCache[DISABLER];
    }

    function fund() internal view returns (address) {
        return mainCharacterCache[FUND];
    }

    function lending() internal view returns (address) {
        return mainCharacterCache[LENDING];
    }

    function marginRouter() internal view returns (address) {
        return mainCharacterCache[MARGIN_ROUTER];
    }

    function crossMarginTrading() internal view returns (address) {
        return mainCharacterCache[CROSS_MARGIN_TRADING];
    }

    function feeController() internal view returns (address) {
        return mainCharacterCache[FEE_CONTROLLER];
    }

    function price() internal view returns (address) {
        return mainCharacterCache[PRICE_CONTROLLER];
    }

    function admin() internal view returns (address) {
        return mainCharacterCache[ADMIN];
    }

    function incentiveDistributor() internal view returns (address) {
        return mainCharacterCache[INCENTIVE_DISTRIBUTION];
    }

    function tokenAdmin() internal view returns (address) {
        return mainCharacterCache[TOKEN_ADMIN];
    }

    function isBorrower(address contr) internal view returns (bool) {
        return roleCache[contr][BORROWER];
    }

    function isFundTransferer(address contr) internal view returns (bool) {
        return roleCache[contr][FUND_TRANSFERER];
    }

    function isMarginTrader(address contr) internal view returns (bool) {
        return roleCache[contr][MARGIN_TRADER];
    }

    function isFeeSource(address contr) internal view returns (bool) {
        return roleCache[contr][FEE_SOURCE];
    }

    function isMarginCaller(address contr) internal view returns (bool) {
        return roleCache[contr][MARGIN_CALLER];
    }

    function isLiquidator(address contr) internal view returns (bool) {
        return roleCache[contr][LIQUIDATOR];
    }

    function isAuthorizedFundTrader(address contr)
        internal
        view
        returns (bool)
    {
        return roleCache[contr][AUTHORIZED_FUND_TRADER];
    }

    function isIncentiveReporter(address contr) internal view returns (bool) {
        return roleCache[contr][INCENTIVE_REPORTER];
    }

    function isTokenActivator(address contr) internal view returns (bool) {
        return roleCache[contr][TOKEN_ACTIVATOR];
    }

    function isStakePenalizer(address contr) internal view returns (bool) {
        return roleCache[contr][STAKE_PENALIZER];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDependencyController.sol";

// we chose not to go with an enum
// to make this list easy to extend
uint256 constant FUND_TRANSFERER = 1;
uint256 constant MARGIN_CALLER = 2;
uint256 constant BORROWER = 3;
uint256 constant MARGIN_TRADER = 4;
uint256 constant FEE_SOURCE = 5;
uint256 constant LIQUIDATOR = 6;
uint256 constant AUTHORIZED_FUND_TRADER = 7;
uint256 constant INCENTIVE_REPORTER = 8;
uint256 constant TOKEN_ACTIVATOR = 9;
uint256 constant STAKE_PENALIZER = 10;

uint256 constant FUND = 101;
uint256 constant LENDING = 102;
uint256 constant MARGIN_ROUTER = 103;
uint256 constant CROSS_MARGIN_TRADING = 104;
uint256 constant FEE_CONTROLLER = 105;
uint256 constant PRICE_CONTROLLER = 106;
uint256 constant ADMIN = 107;
uint256 constant INCENTIVE_DISTRIBUTION = 108;
uint256 constant TOKEN_ADMIN = 109;

uint256 constant DISABLER = 1001;
uint256 constant DEPENDENCY_CONTROLLER = 1002;

/// @title Manage permissions of contracts and ownership of everything
/// owned by a multisig wallet (0xEED9D1c6B4cdEcB3af070D85bfd394E7aF179CBd) during
/// beta and will then be transfered to governance
/// https://github.com/marginswap/governance
contract Roles is Ownable {
    mapping(address => mapping(uint256 => bool)) public roles;
    mapping(uint256 => address) public mainCharacters;

    constructor() Ownable() {
        // token activation from the get-go
        roles[msg.sender][TOKEN_ACTIVATOR] = true;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwnerExecDepController() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                mainCharacters[DEPENDENCY_CONTROLLER] == msg.sender,
            "Roles: caller is not the owner"
        );
        _;
    }

    function giveRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        roles[actor][role] = true;
    }

    function removeRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        roles[actor][role] = false;
    }

    function setMainCharacter(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        mainCharacters[role] = actor;
    }

    function getRole(uint256 role, address contr) external view returns (bool) {
        return roles[contr][role];
    }

    /// @dev current executor
    function executor() public returns (address exec) {
        address depController = mainCharacters[DEPENDENCY_CONTROLLER];
        if (depController != address(0)) {
            exec = IDependencyController(depController).currentExecutor();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDependencyController {
    function currentExecutor() external returns (address);
}

