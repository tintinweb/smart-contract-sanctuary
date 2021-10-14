/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: Context

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

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: IAccessControl

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
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

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

// Part: IERC165

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

// Part: StakeWarInternals

contract StakeWarInternals {
    bool private _characterLock = false;
    uint256 private securityKey;
    uint256 private SEED;
    Rarity private rarity;
    uint256 private raritySeed;
    uint256 public token;
    mapping(int8 => Lands) public land;
    mapping(int8 => Class) public class;
    mapping(address => uint256) public experience;
    mapping(address => bytes32) private levels;

    constructor(uint256 _token, uint256 _SEED) public {
        SEED = _SEED;
        token = _token;
    }

    function setCharacteristics(
        uint256 _raritySeed,
        uint48 _rarityValue,
        uint256 seed
    ) public /**securityCheck(seed)*/
    {
        require(!_characterLock);
        _characterLock = true;
        raritySeed = _raritySeed;
        rarity = determineRarity(_rarityValue, seed);
        class[0] = determineClass(_rarityValue, seed);
        land[0] = determineLand(_rarityValue, seed);
    }

    modifier securityCheck(uint256 SEED2) {
        uint256 product = 10342845128971034591361544103489827087510352052408961035512271613;
        require(SEED * SEED2 == product);
        _;
    }

    function getRarity(uint256 seed)
        public
        view
        securityCheck(seed)
        returns (Rarity)
    {
        return rarity;
    }

    function getRaritySeed(uint256 seed)
        public
        view
        securityCheck(seed)
        returns (uint256)
    {
        return raritySeed;
    }

    function getLevels(address game, uint256 seed)
        public
        view
        securityCheck(seed)
        returns (bytes32)
    {
        return levels[game];
    }

    function setClass(
        Class newClass,
        int8 index,
        uint256 seed
    ) public securityCheck(seed) {
        class[index] = newClass;
    }

    function setLand(
        Lands newLand,
        int8 index,
        uint256 seed
    ) public securityCheck(seed) {
        land[index] = newLand;
    }

    function updateLevel(
        address game,
        uint256 amount,
        bool increase,
        uint256 seed
    ) public securityCheck(seed) {
        if (increase) {
            levels[game] = bytes32(uint256(levels[game]) + amount);
        } else {
            levels[game] = bytes32(uint256(levels[game]) - amount);
        }
    }

    function updateExperience(
        address game,
        uint256 amount,
        bool increase,
        uint256 seed
    ) public securityCheck(seed) {
        if (increase) {
            experience[game] = uint256(experience[game]) + amount;
        } else {
            experience[game] = uint256(experience[game]) - amount;
        }
    }

    function determineRarity(uint48 rareValue, uint256 seed)
        public
        view
        securityCheck(seed)
        returns (Rarity)
    {
        rareValue = rareValue % 10**13;
        if (rareValue > 10**11) return Rarity.COMMON;
        else if (rareValue >= 10**10) return Rarity.FAIRLY_COMMON;
        else if (rareValue > 10**9) return Rarity.KEEPER;
        else if (rareValue > 10**8) return Rarity.SHINY;
        else if (rareValue > 10**7) return Rarity.BRONZE;
        else if (rareValue > 10**6) return Rarity.SILVER;
        else if (rareValue > 10**5) return Rarity.GOLD;
        else if (rareValue > 10**4) return Rarity.PLATNIUM;
        else if (rareValue > 10**3) return Rarity.SUPER_RARE;
        else if (rareValue > 10**2) return Rarity.SECRET;
        else if (rareValue > 10**1) return Rarity.SINGLES;
        else return Rarity.FORGOTTEN;
    }

    function determineClass(uint48 value, uint256 seed)
        internal
        view
        securityCheck(seed)
        returns (Class)
    {
        return classList[(value % uint32(classList.length)) + 1];
    }

    function determineLand(uint48 value, uint256 seed)
        internal
        view
        securityCheck(seed)
        returns (Lands)
    {
        return landList[(value % uint32(landList.length)) + 1];
    }

    /**
     * To String Methods
     */
    function toRarityEnglish(Rarity value, uint256 seed)
        public
        view
        securityCheck(seed)
        returns (string memory)
    {
        if (value == Rarity.FAIRLY_COMMON) return "Fairly Common";
        else if (value == Rarity.KEEPER) return "Keeper";
        else if (value == Rarity.SHINY) return "Shiny";
        else if (value == Rarity.BRONZE) return "Bronze";
        else if (value == Rarity.SILVER) return "Silver";
        else if (value == Rarity.GOLD) return "Gold";
        else if (value == Rarity.PLATNIUM) return "Platnium";
        else if (value == Rarity.SUPER_RARE) return "Super Rare";
        else if (value == Rarity.SECRET) return "Secret";
        else if (value == Rarity.SINGLES) return "Singles";
        else return "Common";
    }

    function toClassEnglish(Class value, uint256 seed)
        public
        view
        securityCheck(seed)
        returns (string memory)
    {
        if (value == Class.ARTIFICER) return "Artificer";
        else if (value == Class.BARBARIAN) return "Barbarian";
        else if (value == Class.BARD) return "Bard";
        else if (value == Class.CLERIC) return "Cleric";
        else if (value == Class.DRUID) return "Druid";
        else if (value == Class.PLAYER) return "Player";
        else if (value == Class.AVENGER) return "Avenger";
        else if (value == Class.SHAMAN) return "Shaman";
        else if (value == Class.ARDENT) return "Ardent";
        else if (value == Class.PSION) return "Psion";
        else if (value == Class.PRIEST) return "Priest";
        else if (value == Class.MONK) return "Monk";
        else if (value == Class.PALADIN) return "Paladin";
        else if (value == Class.RANGER) return "Ranger";
        else if (value == Class.ROGUE) return "Rogue";
        else if (value == Class.SORCERER) return "Sorcerer";
        else if (value == Class.WARDEN) return "Warden";
        else if (value == Class.WARLOCK) return "Warlock";
        else if (value == Class.WARLORD) return "Warlord";
        else if (value == Class.WIZARD) return "Wizard";
        else return "Fighter";
    }

    function toLandEnglish(Lands value, uint256 seed)
        public
        view
        securityCheck(seed)
        returns (string memory)
    {
        if (value == Lands.TELLBOUROGH) return "Tellbourogh";
        else if (value == Lands.ORLAL) return "Orlal";
        else if (value == Lands.SECOND_LANDING) return "Second Landing";
        else if (value == Lands.GENOGIA) return "Genogia";
        else if (value == Lands.GILBATREE) return "Gilbatree";
        else if (value == Lands.ARCEUS) return "Arceus";
        else if (value == Lands.GLACIA) return "Glacia";
        else if (value == Lands.ABYSS) return "Abyss";
        else if (value == Lands.DEEP) return "Deep";
        else if (value == Lands.HELL) return "Hell";
        else if (value == Lands.CONVERGENCE) return "Convergence";
        else if (value == Lands.AVILON) return "Avilon";
        else if (value == Lands.SARTOOK) return "Sartook";
        else return "Norvak";
    }

    enum Rarity {
        NULL,
        COMMON,
        FAIRLY_COMMON,
        KEEPER,
        SHINY,
        BRONZE,
        SILVER,
        GOLD,
        PLATNIUM,
        SUPER_RARE,
        FORGOTTEN,
        SECRET,
        SINGLES
    }
    Rarity[] rarityList = [
        Rarity.NULL,
        Rarity.COMMON,
        Rarity.FAIRLY_COMMON,
        Rarity.KEEPER,
        Rarity.SHINY,
        Rarity.BRONZE,
        Rarity.SILVER,
        Rarity.GOLD,
        Rarity.PLATNIUM,
        Rarity.SUPER_RARE,
        Rarity.FORGOTTEN,
        Rarity.SECRET,
        Rarity.SINGLES
    ];

    enum Class {
        NULL,
        ARTIFICER,
        AVENGER,
        ARDENT,
        BARBARIAN,
        BARD,
        CLERIC,
        DRUID,
        FIGHTER,
        MONK,
        PALADIN,
        PLAYER,
        PSION,
        RANGER,
        ROGUE,
        PRIEST,
        SHAMAN,
        SORCERER,
        WARDEN,
        WARLOCK,
        WARLORD,
        WIZARD
    }
    Class[] classList = [
        Class.NULL,
        Class.ARTIFICER,
        Class.AVENGER,
        Class.ARDENT,
        Class.BARBARIAN,
        Class.BARD,
        Class.CLERIC,
        Class.DRUID,
        Class.FIGHTER,
        Class.MONK,
        Class.PALADIN,
        Class.PLAYER,
        Class.PSION,
        Class.RANGER,
        Class.ROGUE,
        Class.PRIEST,
        Class.SHAMAN,
        Class.SORCERER,
        Class.WARDEN,
        Class.WARLOCK,
        Class.WARLORD,
        Class.WIZARD
    ];

    enum Lands {
        NULL,
        ABYSS,
        ARCEUS,
        AVILON,
        CONVERGENCE,
        DEEP,
        GENOGIA,
        GILBATREE,
        GLACIA,
        HELL,
        SARTOOK,
        SECOND_LANDING,
        TELLBOUROGH,
        NORVAK,
        ORLAL,
        FORGOTTEN
    }
    Lands[] landList = [
        Lands.NULL,
        Lands.ABYSS,
        Lands.ARCEUS,
        Lands.AVILON,
        Lands.CONVERGENCE,
        Lands.DEEP,
        Lands.GENOGIA,
        Lands.GILBATREE,
        Lands.GLACIA,
        Lands.HELL,
        Lands.NORVAK,
        Lands.ORLAL,
        Lands.SARTOOK,
        Lands.SECOND_LANDING,
        Lands.TELLBOUROGH,
        Lands.FORGOTTEN
    ];
}

// Part: ERC165

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId; 
    }
}

// Part: AccessControl

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
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
            revert(string("Invalid Role"));
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(account == _msgSender());

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

// Part: Administerable

contract Administerable is AccessControl {
    bytes32 public constant GAME_CONTROL_ROLE = hex"0001";
    bytes32 public constant USER_ROLE = hex"0002";

    /// @dev Add `root` to the admin role as a member.
    constructor(address account) {
        _setupRole(DEFAULT_ADMIN_ROLE, account);
        _setupRole(GAME_CONTROL_ROLE, msg.sender);
        _setRoleAdmin(GAME_CONTROL_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    modifier onlyAdminOrGameControl() {
        require(isAdmin(msg.sender) || isGameControl(msg.sender));
        _;
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the game controller role.
    function isGameControl(address account) public view virtual returns (bool) {
        return hasRole(GAME_CONTROL_ROLE, account);
    }

    /// @dev Add an account to the admin role. Restricted to admins.
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Add an account to the game controller role. Restricted to admins.
    function addGameControl(address account) public virtual onlyAdmin {
        grantRole(GAME_CONTROL_ROLE, account);
    }

    /// @dev Remove an account from the game controller role. Restricted to admins.
    function removeGameControl(address account) public virtual onlyAdmin {
        revokeRole(GAME_CONTROL_ROLE, account);
    }

    /// @dev Remove oneself from the admin role.
    function renounceGameControl() public virtual {
        renounceRole(GAME_CONTROL_ROLE, msg.sender);
    }

    /// @dev Remove oneself from the admin role.
    function renounceAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

// File: StakeWarsCharacter.sol

contract StakeWarsCharacter is Administerable {
    bool public showCharacterDetails_ = false;
    uint256 private securityKey;

    //Address is ERC-721 Token not user
    mapping(address => StakeWarInternals) public registeredStakeWarriors;

    constructor(uint256 _securityKey) Administerable(msg.sender) {
        securityKey = _securityKey;
    }

    function isAfterReveal() public view returns (bool) {
        return showCharacterDetails_ || isAdmin(msg.sender);
    }

    modifier onlyAfterRelease() {
        require(isAfterReveal());
        _;
    }

    function showCharacterDetails() public onlyAdmin {
        showCharacterDetails_ = true;
    }

    /**
     * Character Functions
     */
    function getRaritySeed(address warrior)
        public
        view
        onlyAdminOrGameControl
        returns (uint256)
    {
        return registeredStakeWarriors[warrior].getRaritySeed(securityKey);
    }

    function getRarity(address warrior)
        public
        view
        onlyAfterRelease
        returns (StakeWarInternals.Rarity)
    {
        return registeredStakeWarriors[warrior].getRarity(securityKey);
    }

    function getRarityReadable(address warriorAddr)
        public
        view
        onlyAfterRelease
        returns (string memory)
    {
        StakeWarInternals warrior = registeredStakeWarriors[warriorAddr];
        return
            warrior.toRarityEnglish(
                warrior.getRarity(securityKey),
                securityKey
            );
    }

    function getClass(address warriorAddr, int8 index)
        public
        view
        returns (StakeWarInternals.Class)
    {
        StakeWarInternals warrior = registeredStakeWarriors[warriorAddr];
        StakeWarInternals.Class class = warrior.class(index);
        return class;
    }

    function getClassReadable(address warriorAddr, int8 index)
        public
        view
        returns (string memory)
    {
        StakeWarInternals warrior = registeredStakeWarriors[warriorAddr];
        return warrior.toClassEnglish(warrior.class(index), securityKey);
    }

    function getLand(address warrior, int8 index)
        public
        view
        returns (StakeWarInternals.Lands)
    {
        return registeredStakeWarriors[warrior].land(index);
    }

    function getLandReadable(address warriorAddr, int8 index)
        public
        view
        returns (string memory)
    {
        StakeWarInternals warrior = registeredStakeWarriors[warriorAddr];
        StakeWarInternals.Lands land = warrior.land(index);
        return warrior.toLandEnglish(warrior.land(index), securityKey);
    }

    function getLevels(address warrior, address game)
        public
        view
        onlyAfterRelease
        returns (bytes32)
    {
        return registeredStakeWarriors[warrior].getLevels(game, securityKey);
    }

    function setClass(
        address warrior,
        StakeWarInternals.Class newClass,
        int8 index
    ) public onlyAdminOrGameControl {
        registeredStakeWarriors[warrior].setClass(newClass, index, securityKey);
    }

    function setLand(
        address warrior,
        StakeWarInternals.Lands newLand,
        int8 index
    ) public onlyAdminOrGameControl {
        registeredStakeWarriors[warrior].setLand(newLand, index, securityKey);
    }

    function updateExperience(
        address warrior,
        address changedExperience,
        uint256 amount,
        bool increase
    ) public onlyAdminOrGameControl {
        registeredStakeWarriors[warrior].updateExperience(
            changedExperience,
            amount,
            increase,
            securityKey
        );
    }

    function updateLevel(
        address warrior,
        address changedExperience,
        uint256 amount,
        bool increase
    ) public onlyAdminOrGameControl {
        registeredStakeWarriors[warrior].updateLevel(
            changedExperience,
            amount,
            increase,
            securityKey
        );
    }
}