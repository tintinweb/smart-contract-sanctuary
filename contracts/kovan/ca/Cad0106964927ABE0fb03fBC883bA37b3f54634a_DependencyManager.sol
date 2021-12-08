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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RoleAware.sol";
import "./Performer.sol";
import "../interfaces/IDependencyManager.sol";

/// @title Provides a single point of reference to verify integrity
/// of the roles structure and facilitate governance actions
/// within our system as well as performing cache invalidation for
/// roles and inter-contract relationships
contract DependencyManager is RoleAware, IDependencyManager {
    constructor(address _roles) RoleAware(_roles) {}

    address public override currentPerformer;

    address[] public managedContracts;
    mapping(uint256 => bool) public knownCharacters;
    mapping(uint256 => bool) public knownRoles;

    uint256[] public allCharacters;
    uint256[] public allRoles;

    function implementAsOwner(address performer) external onlyOwnerExec {
        uint256[] memory requiredTitle = Performer(performer).requiredTitle();

        for (uint256 i = 0; requiredTitle.length > i; i++) {
            _giveRole(requiredTitle[i], performer);
        }

        updCaches(performer);
        currentPerformer = performer;
        Performer(performer).implement();
        currentPerformer = address(0);

        uint256 len = requiredTitle.length;
        for (uint256 i = 0; len > i; i++) {
            _removeRole(requiredTitle[i], performer);
        }
    }

    /// Orchestrate roles and permission for contract
    function leadContract(
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

        updCaches(contr);
    }

    ///  Remove roles and permissions for contract
    function deactContract(address contr) external onlyOwnerExecDisabler {
        _deactContract(contr);
    }

    function _deactContract(address contr) internal {
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
        updRoleCache(role, actor);
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
        updRoleCache(role, actor);
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

    function updRoleCache(uint256 role, address contr) public override {
        uint256 len = managedContracts.length;
        for (uint256 i = 0; len > i; i++) {
            RoleAware(managedContracts[i]).updRoleCache(role, contr);
        }
    }

    function updCaches(address contr) public {
        // update this contract with all characters we know about
        uint256 len = allCharacters.length;
        for (uint256 i = 0; len > i; i++) {
            RoleAware(contr).updateMainCharacterCache(allCharacters[i]);
        }

        // update this contract with all roles for all contracts we know about
        len = allRoles.length;
        for (uint256 i = 0; len > i; i++) {
            for (uint256 j = 0; managedContracts.length > j; j++) {
                RoleAware(contr).updRoleCache(
                    allRoles[i],
                    managedContracts[j]
                );
            }
        }
    }

    function controlContracts() external view returns (address[] memory) {
        return managedContracts;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RoleAware.sol";

abstract contract Performer is RoleAware {
    function requiredTitle() external virtual returns (uint256[] memory);

    function implement() external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Users.sol";

/// @title Role management behavior
/// Main characters are for service discovery
/// Whereas roles are for access control
contract RoleAware {
    Users public immutable roles;
    mapping(uint256 => address) public mainCharacterCache;
    mapping(address => mapping(uint256 => bool)) public roleCache;

    constructor(address _roles) {
        require(_roles != address(0), "Please provide valid roles address");
        roles = Users(_roles);
    }

    modifier noIntermediary() {
        require(
            msg.sender == tx.origin,
            "Currently no intermediaries allowed for this function call"
        );
        _;
    }

    // @dev Throws if called by any account other than the owner or performer
    modifier onlyOwnerExec() {
        require(
            owner() == msg.sender || performer() == msg.sender,
            "Users: caller is not the owner"
        );
        _;
    }

    modifier onlyOwnerExecDisabler() {
        require(
            owner() == msg.sender ||
                performer() == msg.sender ||
                immobilizer() == msg.sender,
            "Caller is not the owner, performer or authorized immobilizer"
        );
        _;
    }

    modifier onlyOwnerExecActivator() {
        require(
            owner() == msg.sender ||
                performer() == msg.sender ||
                isAssetInitiator(msg.sender),
            "Caller is not the owner, performer or authorized activator"
        );
        _;
    }

    function updRoleCache(uint256 role, address contr) public virtual {
        roleCache[contr][role] = roles.getRole(role, contr);
    }

    function updateMainCharacterCache(uint256 role) public virtual {
        mainCharacterCache[role] = roles.mainCharacters(role);
    }

    function owner() internal view returns (address) {
        return roles.owner();
    }

    function performer() internal returns (address) {
        return roles.performer();
    }

    function immobilizer() internal view returns (address) {
        return mainCharacterCache[IMMOBILIZER];
    }

    function asset() internal view returns (address) {
        return mainCharacterCache[ASSET];
    }

    function lending() internal view returns (address) {
        return mainCharacterCache[LENDING];
    }

    function leverageRouter() internal view returns (address) {
        return mainCharacterCache[LEVERAGE_ROUTER];
    }

    function leverageTrading() internal view returns (address) {
        return mainCharacterCache[LEVERAGE_TRADING];
    }

    function feeManager() internal view returns (address) {
        return mainCharacterCache[FEE_MANAGER];
    }

    function price() internal view returns (address) {
        return mainCharacterCache[PRICE_MANAGER];
    }

    function manager() internal view returns (address) {
        return mainCharacterCache[TOP_MANAGER];
    }

    function incentiveIssuer() internal view returns (address) {
        return mainCharacterCache[INCENTIVE_ISSUER];
    }

    function assetManager() internal view returns (address) {
        return mainCharacterCache[ASSET_MANAGER];
    }

    function isBorrower(address contr) internal view returns (bool) {
        return roleCache[contr][BORROWER];
    }

    function isAssetTransferer(address contr) internal view returns (bool) {
        return roleCache[contr][ASSET_TRANSFERER];
    }

    function isLeverageTrader(address contr) internal view returns (bool) {
        return roleCache[contr][LEVERAGE_TRADER];
    }

    function isFeeRoot(address contr) internal view returns (bool) {
        return roleCache[contr][FEE_ROOT];
    }

    function isMargincallTaker(address contr) internal view returns (bool) {
        return roleCache[contr][MARGINCALL_TAKER];
    }

    function isLiquidatorBot(address contr) internal view returns (bool) {
        return roleCache[contr][LIQUIDATOR_BOT];
    }

    function isAuthorizedAssetTrader(address contr)
        internal
        view
        returns (bool)
    {
        return roleCache[contr][AUTHORIZED_ASSET_TRADER];
    }

    function isIncentiveCaller(address contr) internal view returns (bool) {
        return roleCache[contr][INCENTIVE_CALLER];
    }

    function isAssetInitiator(address contr) internal view returns (bool) {
        return roleCache[contr][ASSET_INITIATOR];
    }

    function isStakeFiner(address contr) internal view returns (bool) {
        return roleCache[contr][STAKE_FINER];
    }

    function isLender(address contr) internal view returns (bool) {
        return roleCache[contr][LENDER];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDependencyManager.sol";

// we chose not to go with an enum
// to make this list easy to extend
uint256 constant ASSET_TRANSFERER = 1;
uint256 constant MARGINCALL_TAKER = 2;
uint256 constant BORROWER = 3;
uint256 constant LEVERAGE_TRADER = 4;
uint256 constant FEE_ROOT = 5;
uint256 constant LIQUIDATOR_BOT = 6;
uint256 constant AUTHORIZED_ASSET_TRADER = 7;
uint256 constant INCENTIVE_CALLER = 8;
uint256 constant ASSET_INITIATOR = 9;
uint256 constant STAKE_FINER = 10;
uint256 constant LENDER = 11;

uint256 constant ASSET = 101;
uint256 constant LENDING = 102;
uint256 constant LEVERAGE_ROUTER = 103;
uint256 constant LEVERAGE_TRADING = 104;
uint256 constant FEE_MANAGER = 105;
uint256 constant PRICE_MANAGER = 106;
uint256 constant TOP_MANAGER = 107;
uint256 constant INCENTIVE_ISSUER = 108;
uint256 constant ASSET_MANAGER = 109;

uint256 constant IMMOBILIZER = 1001;
uint256 constant DEPENDENCY_MANAGER = 1002;

/// @title Manage permissions of contracts and ownership of everything
/// owned by a multisig wallet (0xEED9D1c6B4cdEcB3af070D85bfd394E7aF179CBd) during
/// beta and will then be transfered to governance
/// https://github.com/marginswap/governance
contract Users is Ownable {
    mapping(address => mapping(uint256 => bool)) public roles;
    mapping(uint256 => address) public mainCharacters;

    constructor() Ownable() {
        // token activation from the get-go
        roles[msg.sender][ASSET_INITIATOR] = true;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwnerExecDepController() {
        require(
            owner() == msg.sender ||
                performer() == msg.sender ||
                mainCharacters[DEPENDENCY_MANAGER] == msg.sender,
            "Users: caller is not the owner"
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

    /// @dev current performer
    function performer() public returns (address exec) {
        address depController = mainCharacters[DEPENDENCY_MANAGER];
        if (depController != address(0)) {
            exec = IDependencyManager(depController).currentPerformer();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDependencyManager {
    function currentPerformer() external returns (address);
}