/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

// File: contracts/IWastedWarrior.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IWastedWarrior {
    
    enum PackageRarity { NONE, PLASTIC, STEEL, GOLD, PLATINUM }
    
    event WarriorCreated(uint indexed warriorId, bool isBreed, bool isFusion, uint indexed packageType, address indexed buyer);
    event WarriorListed(uint indexed warriorId, uint price);
    event WarriorDelisted(uint indexed warriorId);
    event WarriorBought(uint indexed warriorId, address buyer, address seller, uint price);
    event WarriorOffered(uint indexed warriorId, address buyer, uint price);
    event WarriorOfferCanceled(uint indexed warriorId, address buyer);
    event NameChanged(uint indexed warriorId, string newName);
    event PetAdopted(uint indexed warriorId, uint indexed petId);
    event PetReleased(uint indexed warriorId, uint indexed petId);
    event ItemsEquipped(uint indexed warriorId, uint[] itemIds);
    event ItemsRemoved(uint indexed warriorId, uint[] itemIds);
    event WarriorLeveledUp(uint indexed warriorId, uint level, uint amount);
    event BreedingWarrior(uint indexed fatherId, uint indexed motherId, uint newId, address owner);
    event FusionWarrior(uint indexed firstWarriorId, uint indexed secondWarriorId, uint newId, address owner);
    event AddWarriorToBlacklist(uint warriorId);
    event RemoveWarriorFromBlacklist(uint warriorId);
    
    
    struct Collaborator {
        uint totalSupplyPlasticPackages;
        uint totalSupplySteelPackages;
        uint totalSupplyGoldPackages;
        uint totalSupplyPlatinumPackages;
        uint mintedPlasticPackages;
        uint mintedSteelPackages;
        uint mintedGoldPackages;
        uint mintedPlatinumPackages;
    }
    
    struct Warrior {
        string name;
        uint256 level;
        uint256 weapon;
        uint256 armor;
        uint256 accessory;
        bool isBreed;
        bool isFusion;
    }
    /**
     * @notice add collaborator info.
     * 
     */
    function addCollaborator(address collaborator, uint totalSupplyPlasticPackages, uint totalSupplySteelPackages, uint totalSupplyGoldPackages, uint totalSupplyPlatinumPackages) external; 
    
    /**
     * @notice get collaborator info.
     * 
     */
    function getInfoCollaborator(address addressCollab) external view returns(Collaborator memory);

    /**
     * @notice Gets warrior information.
     * 
     * @dev Prep function for staking.
     */
    function getWarrior(uint warriorId) external view returns (
        string memory name,
        bool isBreed,
        bool isFusion,
        uint level,
        uint pet,
        uint[3] memory equipment
    );
    
    /**
    * @notice get plastic package fee.
    */
    function getPlasticPackageFee() external view returns(uint);
    
    /**
    * @notice get steel package fee.
    */
    function getSteelPackageFee() external view returns(uint);
    
    /**
    * @notice get gold package fee.
    */
    function getGoldPackageFee() external view returns(uint);
    
    /**
    * @notice get platinum package fee.
    */
    function getPlatinumPackageFee() external view returns(uint);
    
     /**
     * @notice Function can level up a Warrior.
     * 
     * @dev Prep function for staking.
     */
    function levelUp(uint warriorId, uint amount) external;
    
    /**
     * @notice Get current level of given warrior.
     * 
     * @dev Prep function for staking.
     */
    function getWarriorLevel(uint warriorId) external view returns (uint);
    
    /**
     * @notice mint warrior for specific address.
     * 
     * @dev Function take 3 arguments are address of buyer, amount, rarityPackage.
     * 
     * Requirements: 
     * - onlyCollaborator
     */
    function mintFor(address buyer, uint amount, uint rarityPackage) external;

    /**
     * @notice Function to change Warrior's name.
     *
     * @dev Function take 2 arguments are warriorId, new name of warrior.
     * 
     * Requirements:
     * - `replaceName` must be a valid string.
     * - `replaceName` is not duplicated.
     * - You have to pay `serviceFeeToken` to change warrior's name.
     */
    function rename(uint warriorId, string memory replaceName) external;

    /**
     * @notice Owner equips items to their warrior by burning ERC1155 Equipment NFTs.
     *
     * Requirements:
     * - caller must be owner of the warrior.
     */
    function equipItems(uint warriorId, uint[] memory itemIds) external;

    /**
     * @notice Owner removes items from their warrior. ERC1155 Equipment NFTs are minted back to the owner.
     *
     * Requirements:
     * - Caller must be owner of the warrior.
     */
    function removeItems(uint warriorId, uint[] memory itemIds) external;

    /**
     * @notice Lists a warrior on sale.
     *
     * Requirements:
     * - Caller must be the owner of the warrior.
     */
    function listing(uint warriorId, uint price) external;

    /**
     * @notice Remove from a list on sale.
     */
    function delist(uint warriorId) external;

    /**
     * @notice Instant buy a specific warrior on sale.
     *
     * Requirements:
     * - Caller must be the owner of the warrior.
     * - Target warrior must be currently on sale time.
     * - Sent value must be exact the same as current listing price.
     * - Owner cannot buy.
     */
    function buy(uint warriorId) external payable;

    /**
     * @notice Gives offer for a warrior.
     *
     * Requirements:
     * - Owner cannot offer.
     */
    function offer(uint warriorId, uint offerPrice) external payable;

    /**
     * @notice Owner accept an offer to sell their warrior.
     */
    function acceptOffer(uint warriorId, address buyer) external;

    /**
     * @notice Abort an offer for a specific warrior.
     */
    function abortOffer(uint warriorId) external;

    /**
     * @notice Adopts a Pet.
     */
    function adoptPet(uint warriorId, uint petId) external;

    /**
     * @notice Abandons a Pet attached to a warrior.
     */
    function abandonPet(uint warriorId) external;
    
    /**
     * @notice Burn two warriors to create one new warrior.
     * 
     * @dev Prep function for fusion
     * 
     * Requirements:
     * - caller must be owner of the warriors.
     */
    function fusionWarrior(uint firstWarriorId, uint secondWarriorId, address owner) external;
    
    /**
     * @notice Breed based on two warriors.
     * 
     * @dev Prep function for breed
     * 
     * Requirements:
     * - caller must be owner of the warriors.
     */
    function breedingWarrior (uint fatherId, uint motherId, address owner) external;
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



pragma solidity ^0.8.0;

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

    constructor() {
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Strings.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/IAccessControl.sol


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

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;





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

// File: contracts/WastedWhitelist.sol

pragma solidity 0.8.7;


contract WastedWhitelist is AccessControl, ReentrancyGuard {
    IWastedWarrior public wastedWarrior;
    uint public balance;
    
    bytes32 public constant WASTED_ROLE = keccak256("WASTED_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");

    uint public maxBoughtPackages = 10;
    mapping(address => uint) public boughts; 

    constructor (IWastedWarrior wastedWarriorAddress) {
        wastedWarrior = wastedWarriorAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MEMBER_ROLE, CONTROLLER_ROLE);
    }
    
    function setMaxBoughtPackages (uint newQuantity) external onlyRole(CONTROLLER_ROLE) {
        maxBoughtPackages = newQuantity;
    }
    function setWastedWarrior(IWastedWarrior wastedWarriorAddress) external onlyRole(CONTROLLER_ROLE) {
        require(address(wastedWarriorAddress) != address(0));
        wastedWarrior = wastedWarriorAddress;
    }
    
    function buyWastedWarrior(uint amount, uint rarityPackage) external payable onlyRole(MEMBER_ROLE) {
        require(amount != 0, "WW: invalid amount");
        require(boughts[msg.sender] + amount < maxBoughtPackages, "WW: not eligible");

        if(rarityPackage == uint(IWastedWarrior.PackageRarity.PLASTIC)) {
            require(msg.value == wastedWarrior.getPlasticPackageFee() * amount, "WW: Not enough fee");
        } else if(rarityPackage == uint(IWastedWarrior.PackageRarity.STEEL)) {
            require(msg.value == wastedWarrior.getSteelPackageFee() * amount, "WW: Not enough fee");
        } else if (rarityPackage == uint(IWastedWarrior.PackageRarity.GOLD)) {
            require(msg.value == wastedWarrior.getGoldPackageFee() * amount, "WW: Not enough fee");
        } else if (rarityPackage == uint(IWastedWarrior.PackageRarity.PLATINUM)) {
            require(msg.value == wastedWarrior.getPlatinumPackageFee() * amount, "WW: Not enough fee");
        }

        balance += msg.value;
        boughts[msg.sender] += amount;
        wastedWarrior.mintFor(msg.sender, amount, rarityPackage);

    }

    function addMembersToWhitelist(address[] memory members) external onlyRole(getRoleAdmin(MEMBER_ROLE)) {
        require(members.length != 0, "WW: invalid");
        for(uint i = 0; i < members.length; i++) {
            _grantRole(MEMBER_ROLE, members[i]);
        }
    }

    function removeMembersFromWhitelist(address[] memory members) external onlyRole(getRoleAdmin(MEMBER_ROLE)) {
        require(members.length != 0, "WW: invalid");
        for(uint i = 0; i < members.length; i++) {
            _revokeRole(MEMBER_ROLE, members[i]);
        }
    }
    
    function withdraw() external onlyRole(WASTED_ROLE) nonReentrant {
        require(balance != 0, "WW: not enough");
        balance = 0;
        (bool isSuccess,) = address(msg.sender).call{value: balance}("");
        require(isSuccess);
    }
    
    function widthdrawAmount(uint amount) external onlyRole(WASTED_ROLE) nonReentrant {
        require(amount != 0 && amount <= balance, "WW: not valid");
        balance -= amount;
        (bool isSuccess,) = address(msg.sender).call{value: balance}("");
        require(isSuccess);
        
    }
}