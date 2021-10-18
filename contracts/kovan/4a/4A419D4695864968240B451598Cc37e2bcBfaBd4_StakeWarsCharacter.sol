/**
 *Submitted for verification at Etherscan.io on 2021-10-17
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

// Part: StakeWarsInternals

contract StakeWarsInternals {
    bool private _characterLock = false;
    uint256 private securityKey;
    uint256 private raritySeed;
    mapping(uint8 => uint8) public land;
    mapping(uint8 => uint8) public class;
    mapping(address => uint256) public experience;
    mapping(address => bytes32) private levels;

    constructor(uint256 _securityKey) {
        securityKey = _securityKey;
    }

    function setCharacteristics(uint256 _raritySeed, uint256 _securityKey2)
        public
        securityCheck(_securityKey2)
    {
        require(!_characterLock);
        _characterLock = true;
        raritySeed = _raritySeed;

        uint48 rare48 = uint48(raritySeed);
        (class[0], ) = determineClass(rare48, _securityKey2);
        (land[0], ) = determineLand(rare48, _securityKey2);
    }

    modifier securityCheck(uint256 _securityKey2) {
        uint256 product = 176186238879358457371830500600305455299267039231006607144961;
        require(securityKey * _securityKey2 == product);
        _;
    }

    function getRaritySeed(uint256 _securityKey2)
        public
        view
        securityCheck(_securityKey2)
        returns (uint256)
    {
        return raritySeed;
    }

    function getRarity(uint256 _securityKey2)
        public
        view
        securityCheck(_securityKey2)
        returns (uint8, uint8)
    {
        uint8 length = uint8(rarityList.length);
        uint8 rareValue = uint8(uint8(raritySeed * _securityKey2) % 2**length);
        for (uint8 i = length - 1; i >= 0; i--) {
            if (rareValue >= 2**i) {
                return (rarityList[i - length], uint8(i - length));
            }
        }
        return (rarityList[0], 0);
    }

    function getLevels(address game, uint256 _securityKey2)
        public
        view
        securityCheck(_securityKey2)
        returns (bytes32)
    {
        return levels[game];
    }

    function setClass(
        uint8 newClass,
        uint8 index,
        uint256 _securityKey2
    ) public securityCheck(_securityKey2) {
        class[index] = newClass;
    }

    function setLand(
        uint8 newLand,
        uint8 index,
        uint256 _securityKey2
    ) public securityCheck(_securityKey2) {
        land[index] = newLand;
    }

    function updateLevel(
        address game,
        uint256 amount,
        bool increase,
        uint256 _securityKey2
    ) public securityCheck(_securityKey2) {
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
        uint256 _securityKey2
    ) public securityCheck(_securityKey2) {
        if (increase) {
            experience[game] = uint256(experience[game]) + amount;
        } else {
            experience[game] = uint256(experience[game]) - amount;
        }
    }

    function determineClass(uint48 value, uint256 _securityKey2)
        internal
        view
        securityCheck(_securityKey2)
        returns (uint8, uint8)
    {
        uint8 index = uint8(value % uint8(classList.length));
        return (classList[index], index);
    }

    function determineLand(uint48 value, uint256 _securityKey2)
        internal
        view
        securityCheck(_securityKey2)
        returns (uint8, uint8)
    {
        uint8 index = uint8(value % uint8(landList.length));
        return (landList[index], index);
    }

    uint8[] rarityList = [
        0, // "Common",
        1, // "Fairly Common",
        2, // "Keeper",
        3, // "Shiny",
        4, // "Bronze",
        5, // "Silver",
        6, // "Gold",
        7, // "Platnium",
        8, // "Super Rare",
        9, // "Truly Rare",
        10, // "Forgotten",
        11, // "Secret",
        12 // "Singles"
    ];

    uint8[] classList = [
        0, // "Artificer",
        1, // "Avenger",
        2, // "Ardent",
        3, // "Barbarian",
        4, // "Bard",
        5, // "Cleric",
        6, // "Druid",
        7, // "Fighter",
        8, // "Monk",
        9, // "Paladin",
        10, // "Player",
        11, // "Psion",
        12, // "Ranger",
        13, // "Rogue",
        14, // "Priest",
        15, // "Shaman",
        16, // "Sorcerer",
        17, // "Warden",
        18, // "Warlock",
        19, // "Warlord",
        20 // "Wizard"
    ];

    uint8[] landList = [
        0, // "Abyss",
        1, // "Arceus",
        2, // "Avilon",
        3, // "Convergence",
        4, // "Deep",
        5, // "Genogia",
        6, // "Gilbatree",
        7, // "Glacia",
        8, // "Hell",
        9, // "Norvak",
        10, // "Orlal",
        11, // "Sartook",
        12, // "Second Landing",
        13, // "Tellbourogh",
        14 // "Forgotten"
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
 * By default, the admin role for all roles is `_DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `_DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant _DEFAULT_ADMIN_ROLE = 0x00;

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
    bytes32 public constant _GAME_CONTROL_ROLE = hex"0001";
    bytes32 public constant _USER_ROLE = hex"0002";

    /// @dev Add `root` to the admin role as a member.
    constructor(address account) {
        _setupRole(_DEFAULT_ADMIN_ROLE, account);
        _setupRole(_GAME_CONTROL_ROLE, msg.sender);
        _setRoleAdmin(_GAME_CONTROL_ROLE, _DEFAULT_ADMIN_ROLE);
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
        return hasRole(_DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the game controller role.
    function isGameControl(address account) public view virtual returns (bool) {
        return hasRole(_GAME_CONTROL_ROLE, account);
    }

    /// @dev Add an account to the admin role. Restricted to admins.
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(_DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Add an account to the game controller role. Restricted to admins.
    function addGameControl(address account) public virtual onlyAdmin {
        grantRole(_GAME_CONTROL_ROLE, account);
    }

    /// @dev Remove an account from the game controller role. Restricted to admins.
    function removeGameControl(address account) public virtual onlyAdmin {
        revokeRole(_GAME_CONTROL_ROLE, account);
    }

    /// @dev Remove oneself from the admin role.
    function renounceGameControl() public virtual {
        renounceRole(_GAME_CONTROL_ROLE, msg.sender);
    }

    /// @dev Remove oneself from the admin role.
    function renounceAdmin() public virtual {
        renounceRole(_DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

// File: StakeWarsCharacter.sol

contract StakeWarsCharacter is Administerable {
    bool public showCharacterDetails = false;
    uint256 private securityKey;

    //Address is ERC-721 Token not user
    // mapping(address => StakeWarsInternals) public _registeredStakeWarriors;
    mapping(address => address) public _registeredStakeWarriors;
    //Addresses to supported games
    mapping(address => bool) public _registeredGames;

    constructor(uint256 _securityKey) Administerable(msg.sender) {
        securityKey = _securityKey;
    }

    modifier onlyAfterRelease() {
        require(showCharacterDetails || isAdmin(msg.sender));
        _;
    }

    function _showCharacterDetails() public onlyAdmin {
        showCharacterDetails = true;
    }

    function RegisterStakeWarrior(address player) public {
        // require(
        //     address(_registeredStakeWarriors[player]) == address(0),
        //     "Address is already registered"
        // );
        // StakeWarsInternals character = StakeWarsInternals(player);
        // _registeredStakeWarriors[player] = character;
    }

    function _registerGame(address game) public onlyAdmin {
        require(
            _registeredGames[game] == false,
            "Address is already registered"
        );
        _registeredGames[game] = true;
        addGameControl(game);
    }

    function _unregisterGame(address game) public onlyAdmin {
        require(
            _registeredGames[game] == true,
            "Address is not already registered"
        );
        _registeredGames[game] = false;
        removeGameControl(game);
    }

    /**
     * Character Functions
     */
    function _getRaritySeed(address warrior)
        public
        view
        onlyAdminOrGameControl
        returns (uint256)
    {
        return StakeWarsInternals(warrior).getRaritySeed(securityKey);
        //return warrior._registeredStakeWarriors[warrior].getRaritySeed(securityKey);
    }

    function GetRarity(address warrior)
        public
        view
        returns (
            // onlyAfterRelease
            string memory,
            uint8
        )
    {
        (uint8 rarity, uint8 index) = StakeWarsInternals(warrior).getRarity(
            securityKey
        );
        // (uint8 rarity, uint8 index) = _registeredStakeWarriors[warrior]
        //     .getRarity(securityKey);
        // (uint8 rarity, uint8 index) = (2, 2);
        if (rarity == 1) return ("Fairly Common", index);
        else if (rarity == 2) return ("Keeper", index);
        else if (rarity == 3) return ("Shiny", index);
        else if (rarity == 4) return ("Bronze", index);
        else if (rarity == 5) return ("Silver", index);
        else if (rarity == 6) return ("Gold", index);
        else if (rarity == 7) return ("Platnium", index);
        else if (rarity == 8) return ("Unobtainium", index);
        else if (rarity == 9) return ("Super Rare", index);
        else if (rarity == 10) return ("Truly Rare", index);
        else if (rarity == 11) return ("Forgotten", index);
        else if (rarity == 12) return ("Secret", index);
        else if (rarity == 13) return ("Singles", index);
        return ("Common", index);
    }

    function getRarityCount() public pure returns (uint8) {
        return 14;
    }

    function GetClass(address warriorAddr, uint8 index)
        public
        view
        returns (string memory, uint8)
    {
        uint8 classIndex = StakeWarsInternals(warriorAddr).class(index);

        // uint8 classIndex = _registeredStakeWarriors[warriorAddr].class(index);
        if (classIndex == 1) return ("Avenger", 1);
        else if (classIndex == 2) return ("Ardent", 2);
        else if (classIndex == 3) return ("Barbarian", 3);
        else if (classIndex == 4) return ("Bard", 4);
        else if (classIndex == 5) return ("Cleric", 5);
        else if (classIndex == 6) return ("Druid", 6);
        else if (classIndex == 7) return ("Fighter", 7);
        else if (classIndex == 8) return ("Monk", 8);
        else if (classIndex == 9) return ("Paladin", 9);
        else if (classIndex == 10) return ("Player", 10);
        else if (classIndex == 11) return ("Psion", 11);
        else if (classIndex == 12) return ("Ranger", 12);
        else if (classIndex == 13) return ("Rogue", 13);
        else if (classIndex == 14) return ("Priest", 14);
        else if (classIndex == 15) return ("Shaman", 15);
        else if (classIndex == 16) return ("Sorcerer", 16);
        else if (classIndex == 17) return ("Warden", 17);
        else if (classIndex == 18) return ("Warlock", 18);
        else if (classIndex == 19) return ("Warlord", 19);
        else if (classIndex == 20) return ("Wizard", 20);
        else return ("Artificer", 0);
    }

    function getClassCount() public pure returns (uint8) {
        return 21;
    }

    function GetLand(address warrior, uint8 index)
        public
        view
        returns (string memory, uint8)
    {
        uint8 land = StakeWarsInternals(warrior).land(index);
        // uint8 land = _registeredStakeWarriors[warrior].land(index);
        if (land == 1) return ("Arceus", 1);
        else if (land == 2) return ("Avilon", 2);
        else if (land == 3) return ("Convergence", 3);
        else if (land == 4) return ("Deep", 4);
        else if (land == 5) return ("Genogia", 5);
        else if (land == 6) return ("Gilbatree", 6);
        else if (land == 7) return ("Glacia", 7);
        else if (land == 8) return ("Hell", 8);
        else if (land == 9) return ("Norvak", 9);
        else if (land == 10) return ("Orlal", 10);
        else if (land == 11) return ("Sartook", 11);
        else if (land == 12) return ("Second Landing", 12);
        else if (land == 13) return ("Tellbourogh", 13);
        else if (land == 14) return ("Forgotten", 14);
        else return ("Abyss", 0);
    }

    function getLandCount() public pure returns (uint8) {
        return 15;
    }

    // function GetLevels(address warrior, address game)
    //     public
    //     view
    //     onlyAfterRelease
    //     returns (bytes32)
    // {
    //     return _registeredStakeWarriors[warrior].getLevels(game, securityKey);
    // }

    // function _setClass(
    //     address warrior,
    //     uint8 newClass,
    //     uint8 index
    // ) public onlyAdminOrGameControl {
    //     _registeredStakeWarriors[warrior].setClass(
    //         newClass,
    //         index,
    //         securityKey
    //     );
    // }

    // function _setLand(
    //     address warrior,
    //     uint8 newLand,
    //     uint8 index
    // ) public onlyAdminOrGameControl {
    //     _registeredStakeWarriors[warrior].setLand(newLand, index, securityKey);
    // }

    // function _updateExperience(
    //     address warrior,
    //     address changedExperience,
    //     uint256 amount,
    //     bool increase
    // ) public onlyAdminOrGameControl {
    //     _registeredStakeWarriors[warrior].updateExperience(
    //         changedExperience,
    //         amount,
    //         increase,
    //         securityKey
    //     );
    // }

    // function _updateLevel(
    //     address warrior,
    //     address changedExperience,
    //     uint256 amount,
    //     bool increase
    // ) public onlyAdminOrGameControl {
    //     _registeredStakeWarriors[warrior].updateLevel(
    //         changedExperience,
    //         amount,
    //         increase,
    //         securityKey
    //     );
    // }
}