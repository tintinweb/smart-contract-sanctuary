// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IEXRMintPass.sol";
import "./interfaces/IEXRInventory.sol";
import "./extensions/CouponSystem.sol";

error InventoryInsufficientPassBalance();
error InventoryCategoryExists();
error InventoryUnapprovedBurn();
error InventoryInvalidCoupon();
error InventoryZeroAddress();
error InventoryReusedSeed();

/**
 * @title   EXR Inventory Controller
 * @author  RacerDev
 * @notice  This contract controls the distribution of EXRInventory items for the EXR ecosystem.
 * @dev     Because Chainlink's VRF is not available at the time of development, random number
 *          generation is aided by a verifiably random seed generated off-chain.
 * @dev     This contract caters to the existing Inventory Items at the time of launch. If additional
 *          items need to be added, this contract should be replaced with a newer version.
 */
contract EXRInventoryController is
    ERC2771Context,
    AccessControl,
    Pausable,
    ReentrancyGuard,
    CouponSystem
{
    bytes32 public constant SYS_ADMIN_ROLE = keccak256("SYS_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public constant inventoryPassId = 3;

    mapping(bytes32 => bool) public usedSeeds;

    struct Category {
        uint8 exists;
        uint8 id;
        uint8[9] tokenIds;
    }

    Category[] public categories;

    IEXRMintPass public mintpassContract;
    IEXRInventory public inventoryContract;

    event InventoryUpdateMintpassInterface(address contractAddress);
    event InventoryUpdateInventoryInterface(address contractAddress);
    event InventoryItemsClaimed(uint256[] ids, uint256[] amounts);
    event InventoryRewardClaimed(address indexed user, uint256 qty);
    event InventoryCategoryAdded(uint256 category);
    event InventoryCategoryRemoved(uint8 category);
    event InventoryCategoryDoesNotExist(uint8 category);
    event AdminSignerUpdated(address signer);

    constructor(address adminSigner, address trustedForwarder)
        CouponSystem(adminSigner)
        ERC2771Context(trustedForwarder)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SYS_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    /*
     * ===================================== EXTERNAL
     */

    /**
     * @notice  Allow users with a valid coupon to claim Inventory Items
     * @dev     Mechanism for players to claim inventory items as a reward
     * @param   seed 32-byte hash of the random seed
     * @param   qty The number of inventory items to claim
     * @param   coupon The decoded r,s,v components of the signature
     */
    function claimRewardItems(
        bytes32 seed,
        uint256 qty,
        Coupon calldata coupon
    ) external whenNotPaused nonReentrant hasValidOrigin {
        if (usedSeeds[seed]) revert InventoryReusedSeed();

        usedSeeds[seed] = true;
        bytes32 digest = keccak256(
            abi.encode(address(this), block.chainid, CouponType.Reward, qty, seed, _msgSender())
        );
        if (!_verifyCoupon(digest, coupon)) revert InventoryInvalidCoupon();

        _claimRandomItems(seed, qty);
        emit InventoryRewardClaimed(_msgSender(), qty);
    }

    /**
     * @notice  Allows the holder of an Inventory Mint Pass to exchange it for Inventory Items
     * @dev     Caller must have a valid Coupon containing a seed distributed by the EXR API
     * @param   seed 32-byte hash of the random seed
     * @param   qty The number of inventory items to claim
     * @param   coupon The decoded r,s,v components of the signature
     */
    function burnToRedeemInventoryItems(
        bytes32 seed,
        uint256 qty,
        Coupon calldata coupon
    ) external whenNotPaused nonReentrant hasValidOrigin {
        if (mintpassContract.balanceOf(_msgSender(), inventoryPassId) == 0)
            revert InventoryInsufficientPassBalance();
        if (usedSeeds[seed]) revert InventoryReusedSeed();

        usedSeeds[seed] = true;
        bytes32 digest = keccak256(
            abi.encode(address(this), block.chainid, CouponType.Inventory, qty, seed, _msgSender())
        );
        if (!_verifyCoupon(digest, coupon)) revert InventoryInvalidCoupon();

        mintpassContract.authorizedBurn(_msgSender(), inventoryPassId);
        _claimRandomItems(seed, qty);
    }

    /*
     * ===================================== EXTERNAL | ADMIN
     */

    /**
     *   @notice    Allows an Admin user to create the {mintpassContract} interface
     *   @param     mintpass Address of the Mintpass contract
     */
    function setMintpassContract(address mintpass) external onlyRole(SYS_ADMIN_ROLE) {
        if (mintpass == address(0)) revert InventoryZeroAddress();
        mintpassContract = IEXRMintPass(mintpass);
        emit InventoryUpdateMintpassInterface(mintpass);
    }

    /**
     *   @notice    Allows an Admin user to create the {inventoryContract} interface
     *   @param     inventory Address of the Inventory Contract
     */
    function setInventoryContract(address inventory) external onlyRole(SYS_ADMIN_ROLE) {
        if (inventory == address(0)) revert InventoryZeroAddress();
        inventoryContract = IEXRInventory(inventory);
        emit InventoryUpdateInventoryInterface(inventory);
    }

    /**
     * @dev     Admin can replace signer public address from signer's keypair
     * @param   newSigner public address of the signer's keypair
     */
    function updateAdminSigner(address newSigner) external onlyRole(SYS_ADMIN_ROLE) {
        _replaceSigner(newSigner);
        emit AdminSignerUpdated(newSigner);
    }

    /**
     * @notice  Allows an Admin user to add a category of Inventory Items
     * @dev     Manually increments the category count required for looping through the categories
     * @param   categoryId the category index for accessing the {categoryToIds} array
     * @param   ids the token IDs to add to the category
     */
    function addCategory(uint8 categoryId, uint8[9] calldata ids)
        external
        onlyRole(SYS_ADMIN_ROLE)
    {
        for (uint256 i; i < categories.length; i++) {
            if (categories[i].id == categoryId) revert InventoryCategoryExists();
        }
        categories.push(Category({id: categoryId, exists: 1, tokenIds: ids}));
        emit InventoryCategoryAdded(categoryId);
    }

    /**
     * @notice  Retrieves a category, including its ID and the tokenIDs array
     * @dev     Convenience function for reviewing existing categories
     * @param   categoryId The ID of the category to be retrieved
     * @return  The category, along with its token IDs
     */
    function getCategory(uint256 categoryId) external view returns (Category memory) {
        return categories[categoryId];
    }

    /**
     * @notice  Allows an admin user to remove a category of inventory items
     * @dev     the {categories} array acts like an unordered list. Removing an item replaces it with
     *          the last item in the array and removes the redundant last item
     * @dev     The category identifier can be an integer greater than the length of the {categories}
     *          array
     * @param   category The ID of the category to remove (this is not the index in the array)
     */
    function removeCategory(uint8 category) external onlyRole(SYS_ADMIN_ROLE) {
        bool removed;
        for (uint256 i; i < categories.length; i++) {
            if (categories[i].id == category) {
                categories[i] = categories[categories.length - 1];
                categories.pop();
                removed = true;
                emit InventoryCategoryRemoved(category);
                break;
            }
        }

        if (!removed) {
            emit InventoryCategoryDoesNotExist(category);
        }
    }

    /**
     * @notice Allows a user with the PAUSER_ROLE to pause the contract
     * @dev    This can be used to deprecate the contract if it's replaced
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     *   @notice Allows a user with the PAUSER_ROLE to unpause the contract
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /*
     * ===================================== INTERNAL
     */

    /**
     * @notice  Claim random tokens
     * @dev     Uses the verified seed along with block data to select random token IDs
     * @dev     {categories} acts like an unordered list due the removal of a category by replacing
     *          with the last category in the array. The order does not matter however
     *          as each category has an equal chance of being selected, and categories are removed
     *          by referencind the {id} property of the struct.
     * @param   seed 32-byte hash of the random seed
     * @param   amount The number of tokens to mint
     */

    function _claimRandomItems(bytes32 seed, uint256 amount) internal {
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);

        for (uint256 i; i < amount; i++) {
            // Every category has an equal chance of being selected
            uint256 randomCategorySelector = (uint256(
                keccak256(abi.encode(seed, blockhash(block.number - 1), block.basefee, i))
            ) % (categories.length * 100)) + 1;

            uint256 id;
            for (uint256 ii; ii < categories.length; ii++) {
                if (randomCategorySelector < (ii + 1) * 100) {
                    id = _selectIdByRarity(randomCategorySelector, ii);
                    break;
                }
            }

            ids[i] = id;
            amounts[i] = 1;
        }

        inventoryContract.mintBatch(_msgSender(), ids, amounts, "");
        emit InventoryItemsClaimed(ids, amounts);
    }

    /**
     * @notice  Selects an id from the category based on rarity
     * @dev     Uses the seed and category ID to generate randomness
     * @dev     Tiers: Common (50% chance), Mid (35% chance), rare (15% chance)
     * @param   seed 32-byte hash of the random seed
     * @param   category the item category to select from
     */
    function _selectIdByRarity(uint256 seed, uint256 category) internal view returns (uint256) {
        uint256 randomIdSelector = (uint256(keccak256(abi.encode(seed, category))) % 3000) + 1;
        uint8[9] memory options = categories[category].tokenIds;

        if (randomIdSelector > 2500) {
            return options[0]; // common ( 2500 - 3000)
        } else if (randomIdSelector > 2000) {
            return options[1]; // common (2000 - 2500)
        } else if (randomIdSelector > 1500) {
            return options[2]; // common ( 1500 - 2000)
        } else if (randomIdSelector > 1150) {
            return options[3]; // mid (1150 - 1500)
        } else if (randomIdSelector > 800) {
            return options[4]; // mid (800 - 1150)
        } else if (randomIdSelector > 450) {
            return options[5]; // mid ( 450 - 800)
        } else if (randomIdSelector > 300) {
            return options[6]; // rare ( 300 - 450 )
        } else if (randomIdSelector > 150) {
            return options[7]; // rare ( 150 - 300)
        } else {
            return options[8]; // rare ( 0 - 150)
        }
    }

    // ======================================================== MODIFIERS

    /**
     * @dev Only allow contract calls from Biconomy's trusted forwarder
     */
    modifier hasValidOrigin() {
        require(
            isTrustedForwarder(msg.sender) || msg.sender == tx.origin,
            "Non-trusted forwarder contract not allowed"
        );
        _;
    }

    // ======================================================== OVERRIDES

    /**
     * @dev Override Context's _msgSender() to enable meta transactions for Biconomy
     *       relayer protocol, which allows for gasless TXs
     */
    function _msgSender()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    /**
     * @dev Override Context's _msgData(). This function is not used, but is required
     *      as an override
     */
    function _msgData()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (bytes calldata)
    {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IEXRMintPass {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function totalSupply(uint256 id) external view returns (uint256);

    function mint(
        address recipient,
        uint256 qty,
        uint256 tokenId,
        uint256 fragment
    ) external;

    function burnToRedeemPilot(address account, uint256 fragment) external;

    function authorizedBurn(address account, uint256 tokenId) external;

    function tokenMintCountsByFragment(uint256 fragment, uint256 tokenId)
        external
        view
        returns (uint256);

    function addressToPilotPassClaimsByFragment(uint256 fragment, address caller)
        external
        view
        returns (uint256);

    function incrementPilotPassClaimCount(
        address caller,
        uint256 fragment,
        uint256 qty
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IEXRInventory {
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

error InvalidSignature();

/**
 * @title   Coupon System
 * @author  RacerDev
 * @notice  Helper contract for verifying signed coupons using `ecrecover` to match the coupon signer
 *          to the `_adminSigner` variable set during construction.
 * @dev     The Coupon struct represents a decoded signature that was created off-chain
 */
contract CouponSystem {
    address internal _adminSigner;

    enum CouponType {
        MintPass,
        Pilot,
        Racecraft,
        Inventory,
        Reward
    }

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    constructor(address signer) {
        _adminSigner = signer;
    }

    /**
     * @dev     Admin can replace the admin signer address in the event the private key is compromised
     * @param   newSigner The public key (address) of the new signer keypair
     */
    function _replaceSigner(address newSigner) internal {
        _adminSigner = newSigner;
    }

    /**
     * @dev     Accepts an already hashed set of data
     * @param   digest The hash of the abi.encoded coupon data
     * @param   coupon The decoded r,s,v components of the signature
     * @return  Whether the recovered signer address matches the `_adminSigner`
     */
    function _verifyCoupon(bytes32 digest, Coupon calldata coupon) internal view returns (bool) {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        if (signer == address(0)) revert InvalidSignature();
        return signer == _adminSigner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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