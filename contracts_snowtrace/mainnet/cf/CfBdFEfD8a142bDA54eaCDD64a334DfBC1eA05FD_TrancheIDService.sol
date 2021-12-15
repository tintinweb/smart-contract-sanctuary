// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./roles/RoleAware.sol";
import "./roles/DependsOnTranche.sol";

contract TrancheIDService is RoleAware, DependsOnTranche {
    uint256 public constant totalTrancheSlots = 1e8;
    uint256 public nextTrancheSlot = 1;

    struct TrancheSlot {
        uint256 nextTrancheIdRange;
        uint256 trancheSlot;
    }

    mapping(address => TrancheSlot) public trancheSlots;
    mapping(uint256 => address) public slotTranches;

    constructor(address _roles) RoleAware(_roles) {
        _charactersPlayed.push(TRANCHE_ID_SERVICE);
    }

    function getNextTrancheId() external returns (uint256 id) {
        require(isTranche(msg.sender), "Caller not a tranche contract");
        TrancheSlot storage slot = trancheSlots[msg.sender];
        require(slot.trancheSlot != 0, "Caller doesn't have a slot");
        id = slot.nextTrancheIdRange * totalTrancheSlots + slot.trancheSlot;
        slot.nextTrancheIdRange++;
    }

    function setupTrancheSlot() external returns (TrancheSlot memory) {
        require(isTranche(msg.sender), "Caller not a tranche contract");
        require(
            trancheSlots[msg.sender].trancheSlot == 0,
            "Tranche already has a slot"
        );
        trancheSlots[msg.sender] = TrancheSlot({
            nextTrancheIdRange: 1,
            trancheSlot: nextTrancheSlot
        });
        slotTranches[nextTrancheSlot] = msg.sender;
        nextTrancheSlot++;
        return trancheSlots[msg.sender];
    }

    function viewNextTrancheId(address trancheContract)
        external
        view
        returns (uint256)
    {
        TrancheSlot storage slot = trancheSlots[trancheContract];
        return slot.nextTrancheIdRange * totalTrancheSlots + slot.trancheSlot;
    }

    function viewTrancheContractByID(uint256 trancheId)
        external
        view
        returns (address)
    {
        return slotTranches[trancheId % totalTrancheSlots];
    }

    function viewSlotByTrancheContract(address tranche)
        external
        view
        returns (uint256)
    {
        return trancheSlots[tranche].trancheSlot;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Roles.sol";

/// @title DependentContract.
abstract contract DependentContract {
    mapping(uint256 => address) public mainCharacterCache;
    mapping(address => mapping(uint256 => bool)) public roleCache;

    uint256[] public _dependsOnCharacters;
    uint256[] public _dependsOnRoles;

    uint256[] public _charactersPlayed;
    uint256[] public _rolesPlayed;

    /// @dev returns all characters played by this contract (e.g. stable coin, oracle registry)
    function charactersPlayed() public view returns (uint256[] memory) {
        return _charactersPlayed;
    }

    /// @dev returns all roles played by this contract
    function rolesPlayed() public view returns (uint256[] memory) {
        return _rolesPlayed;
    }

    /// @dev returns all the character dependencies like FEE_RECIPIENT
    function dependsOnCharacters() public view returns (uint256[] memory) {
        return _dependsOnCharacters;
    }

    /// @dev returns all the roles dependencies of this contract like FUND_TRANSFERER
    function dependsOnRoles() public view returns (uint256[] memory) {
        return _dependsOnRoles;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./DependentContract.sol";

abstract contract DependsOnTranche is DependentContract {
    constructor() {
        _dependsOnRoles.push(TRANCHE);
    }

    function isTranche(address contr) internal view returns (bool) {
        return roleCache[contr][TRANCHE];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Roles.sol";
import "./DependentContract.sol";

/// @title Role management behavior
/// Main characters are for service discovery
/// Whereas roles are for access control
contract RoleAware is DependentContract {
    Roles public immutable roles;

    constructor(address _roles) {
        require(_roles != address(0), "Please provide valid roles address");
        roles = Roles(_roles);
    }

    /// @dev Throws if called by any account other than the owner
    modifier onlyOwner() {
        require(owner() == msg.sender, "Roles: caller is not the owner");
        _;
    }

    /// @dev Throws if called by any account other than the owner or executor
    modifier onlyOwnerExec() {
        require(
            owner() == msg.sender || executor() == msg.sender,
            "Roles: caller is not the owner or executor"
        );
        _;
    }

    /// @dev Throws if called by any account other than the owner or executor or disabler
    modifier onlyOwnerExecDisabler() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                disabler() == msg.sender,
            "Caller is not the owner, executor or authorized disabler"
        );
        _;
    }

    /// @dev Throws if called by any account other than the owner or executor or activator
    modifier onlyOwnerExecActivator() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                isActivator(msg.sender),
            "Caller is not the owner, executor or authorized activator"
        );
        _;
    }

    /// @dev Updates the role cache for a specific role and address
    function updateRoleCache(uint256 role, address contr) public virtual {
        roleCache[contr][role] = roles.roles(contr, role);
    }

    /// @dev Updates the main character cache for a speciic character
    function updateMainCharacterCache(uint256 role) public virtual {
        mainCharacterCache[role] = roles.mainCharacters(role);
    }

    /// @dev returns the owner's address
    function owner() internal view returns (address) {
        return roles.owner();
    }

    /// @dev returns the executor address
    function executor() internal returns (address) {
        return roles.executor();
    }

    /// @dev returns the disabler address
    function disabler() internal view returns (address) {
        return roles.mainCharacters(DISABLER);
    }

    /// @dev checks whether the passed address is activator or not
    function isActivator(address contr) internal view returns (bool) {
        return roles.roles(contr, ACTIVATOR);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IDependencyController.sol";

// we chose not to go with an enum
// to make this list easy to extend
uint256 constant FUND_TRANSFERER = 1;
uint256 constant MINTER_BURNER = 2;
uint256 constant TRANCHE = 3;
uint256 constant ORACLE_LISTENER = 4;
uint256 constant TRANCHE_TRANSFERER = 5;
uint256 constant UNDERWATER_LIQUIDATOR = 6;

uint256 constant FUND = 101;
uint256 constant STABLECOIN = 102;
uint256 constant FEE_RECIPIENT = 103;
uint256 constant STRATEGY_REGISTRY = 104;
uint256 constant TRANCHE_ID_SERVICE = 105;
uint256 constant ORACLE_REGISTRY = 106;
uint256 constant ISOLATED_LENDING = 107;
uint256 constant TWAP_ORACLE = 108;
uint256 constant CURVE_POOL = 109;

uint256 constant DISABLER = 1001;
uint256 constant DEPENDENCY_CONTROLLER = 1002;
uint256 constant ACTIVATOR = 1003;

/// @title Manage permissions of contracts and ownership of everything
/// owned by a multisig wallet during
/// beta and will then be transfered to governance
contract Roles is Ownable {
    mapping(address => mapping(uint256 => bool)) public roles;
    mapping(uint256 => address) public mainCharacters;

    event RoleGiven(uint256 indexed role, address player);
    event CharacterAssigned(
        uint256 indexed character,
        address playerBefore,
        address playerNew
    );
    event RoleRemoved(uint256 indexed role, address player);

    constructor(address targetOwner) Ownable() {
        transferOwnership(targetOwner);
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

    /// @dev assign role to an account
    function giveRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        emit RoleGiven(role, actor);
        roles[actor][role] = true;
    }

    /// @dev revoke role of a particular account
    function removeRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        emit RoleRemoved(role, actor);
        roles[actor][role] = false;
    }

    /// @dev set main character
    function setMainCharacter(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        emit CharacterAssigned(role, mainCharacters[role], actor);
        mainCharacters[role] = actor;
    }

    /// @dev returns the current executor
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