pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Dice.sol";
import "./Treasury.sol";
import "./Constants.sol";
import "./Inventory.sol";

/// @title Guild of Guardians PreSale Contract
/// @author Marc Griffiths
/// @notice This contract will be used to presale in game items for Guild of Guardians

contract GuildOfGuardiansPreSale is
    Constants,
    AccessControl,
    Treasury,
    Inventory
{
    constructor(address _usdEthPairAddress)
        Inventory(_usdEthPairAddress)
    {
        // Initialise roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PRODUCT_OWNER_ROLE, msg.sender);
        _setupRole(TREASURER_ROLE, msg.sender);
        _setupRole(IMMUTABLE_SYSTEM_ROLE, msg.sender);

        // Initialise chroma and upgrade chance, to 2 d.p. 200 is 2.00%
        settings.firstChromaChance = 1200;
        settings.secondChromaChance = 200;
        settings.rareToEpicUpgradeChance = 400;
        settings.rareToLegendaryUpgradeChance = 100;
        settings.epicToLegendaryUpgradeChance = 500;
        settings.petRareChance = 2700;
        settings.petEpicChance = 1000;
        settings.petLegendaryChance = 300;
        settings.rareHeroMythicChance = 3;
        settings.epicHeroMythicChance = 8;
        settings.legendaryHeroMythicChance = 22;

        // Initialise prices in USD, to 2 d.p 900 is $9.00
        productPrices[uint256(Product.RareHeroPack)][
            uint256(Price.FirstSale)
        ] = 1000;
        productPrices[uint256(Product.RareHeroPack)][
            uint256(Price.LastSale)
        ] = 1250;
        productPrices[uint256(Product.EpicHeroPack)][
            uint256(Price.FirstSale)
        ] = 4400;
        productPrices[uint256(Product.EpicHeroPack)][
            uint256(Price.LastSale)
        ] = 5500;
        productPrices[uint256(Product.LegendaryHeroPack)][
            uint256(Price.FirstSale)
        ] = 20000;
        productPrices[uint256(Product.LegendaryHeroPack)][
            uint256(Price.LastSale)
        ] = 25000;
        productPrices[uint256(Product.PetPack)][
            uint256(Price.FirstSale)
        ] = 6000;
        productPrices[uint256(Product.PetPack)][uint256(Price.LastSale)] = 7500;
        productPrices[uint256(Product.EnergyToken)][
            uint256(Price.FirstSale)
        ] = 12000;
        productPrices[uint256(Product.EnergyToken)][
            uint256(Price.LastSale)
        ] = 15000;
        productPrices[uint256(Product.BasicGuildToken)][
            uint256(Price.FirstSale)
        ] = 16000;
        productPrices[uint256(Product.BasicGuildToken)][
            uint256(Price.LastSale)
        ] = 20000;
        productPrices[uint256(Product.Tier1GuildToken)][
            uint256(Price.FirstSale)
        ] = 320000;
        productPrices[uint256(Product.Tier1GuildToken)][
            uint256(Price.LastSale)
        ] = 400000;
        productPrices[uint256(Product.Tier2GuildToken)][
            uint256(Price.FirstSale)
        ] = 1600000;
        productPrices[uint256(Product.Tier2GuildToken)][
            uint256(Price.LastSale)
        ] = 2000000;
        productPrices[uint256(Product.Tier3GuildToken)][
            uint256(Price.FirstSale)
        ] = 8000000;
        productPrices[uint256(Product.Tier3GuildToken)][
            uint256(Price.LastSale)
        ] = 10000000;

        // Initialise stock levels
        originalStock[uint256(Product.RareHeroPack)] = 0;
        originalStock[uint256(Product.EpicHeroPack)] = 0;
        originalStock[uint256(Product.LegendaryHeroPack)] = 0;
        originalStock[uint256(Product.EnergyToken)] = 0;
        originalStock[uint256(Product.BasicGuildToken)] = 0;
        originalStock[uint256(Product.Tier1GuildToken)] = 0;
        originalStock[uint256(Product.Tier2GuildToken)] = 0;
        originalStock[uint256(Product.Tier3GuildToken)] = 0;
        originalStock[uint256(Product.PetPack)] = 0;
        stockAvailable[uint256(Product.RareHeroPack)] = 0;
        stockAvailable[uint256(Product.EpicHeroPack)] = 0;
        stockAvailable[uint256(Product.LegendaryHeroPack)] = 0;
        stockAvailable[uint256(Product.EnergyToken)] = 0;
        stockAvailable[uint256(Product.BasicGuildToken)] = 0;
        stockAvailable[uint256(Product.Tier1GuildToken)] = 0;
        stockAvailable[uint256(Product.Tier2GuildToken)] = 0;
        stockAvailable[uint256(Product.Tier3GuildToken)] = 0;
        stockAvailable[uint256(Product.PetPack)] = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/introspection/ERC165.sol";

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
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
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

pragma solidity >=0.8.0 <0.9.0;

/**
    @notice     Used to generate two dice rolls.
                These are pseudo-random numbers.
                The first dice roll is exploitable as any smart contract can determine its value.
                The second dice roll includes the first dice roll, as well as the hash of a future block.
                Therefore the second dice roll is not available at the time the first dice roll is committed to.

                Inspired by the concept of commit-reveal, but simplified to save gas.

                Requires a trusted party to roll the second dice. However anyone can choose to audit/verify the second dice roll.

    @dev        maxDiceRoll - largest possible dice roll
                offset - number of blocks to look into the future for the second dice roll

    @author Immutable
*/

contract Dice {
    uint256 maxDiceRoll;
    uint8 offset;

    event SecondDiceRoll(
        uint256 indexed _firstDiceRoll,
        uint256 indexed _commitBlock,
        uint256 _secondDiceRoll
    );

    /// @param _maxDiceRoll largest dice roll possible
    /// @param _offset how many blocks to look into the future for second dice roll
    constructor(uint256 _maxDiceRoll, uint8 _offset) {
        maxDiceRoll = _maxDiceRoll;
        offset = _offset;
    }

    /// @notice Take the exploitable 'random' number from a previous block already committed to, and enhance it with the blockhash of a later block
    /// @param _firstDiceRoll The exploitable 'random' number generated previously
    /// @param _commitBlock The block that _firstDiceRoll was generated in
    /// @return A new 'random' number that was not available at the time of _commitBlock
    function getSecondDiceRoll(uint256 _firstDiceRoll, uint256 _commitBlock)
        public
        view
        returns (uint256)
    {
        return _getSecondDiceRoll(_firstDiceRoll, _commitBlock);
    }

    /// @notice Take the exploitable 'random' number from a previous block that was already committed to, and enhance it with the blockhash of a later block. Emit this new number as an event.
    /// @param _firstDiceRoll The exploitable 'random' number generated previously
    /// @param _commitBlock The block that _firstDiceRoll was generated in
    function emitSecondDiceRoll(uint256 _firstDiceRoll, uint256 _commitBlock)
        public
    {
        emit SecondDiceRoll(
            _firstDiceRoll,
            _commitBlock,
            _getSecondDiceRoll(_firstDiceRoll, _commitBlock)
        );
    }

    function _getSecondDiceRoll(uint256 _firstDiceRoll, uint256 _commitBlock)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        _firstDiceRoll,
                        _getFutureBlockhash(_commitBlock)
                    )
                )
            ) % maxDiceRoll;
    }

    function _getFutureBlockhash(uint256 _commitBlock)
        internal
        view
        returns (bytes32)
    {
        uint256 delta = block.number - _commitBlock;
        require(delta < offset + 256, "Called too late"); // Only the last 256 blockhashes are accessible to the smart contract
        require(delta >= offset + 1, "Called too early"); // The hash of commitBlock + offset isn't available until the following block
        bytes32 futureBlockhash = blockhash(_commitBlock + offset);
        require(futureBlockhash != bytes32(0), "Future blockhash empty"); // Sanity check to ensure we have a blockhash, which we will due to previous checks
        return futureBlockhash;
    }

    /// @notice Return a "random" number by hashing a variety of inputs such as the blockhash of the last block, the timestamp of this block, the buyers address, and a seed provided by the buyer.
    /// @dev This function is exploitable as a smart contract can see what random number would be generated and make a decision based on that. Must be used with getSecondDiceRoll()
    function getFirstDiceRoll(uint256 _userProvidedSeed)
        public
        view
        returns (uint256 randomNumber)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp,
                        msg.sender,
                        _userProvidedSeed
                    )
                )
            ) % maxDiceRoll;
    }

    /// @return true '_chance%' of the time where _chance is a percentage to 2 d.p. E.g. 1050 for 10.5%
    /// @dev _random must be a random number between 0 and _maxDiceRoll
    function _diceWin(
        uint256 _random,
        uint256 _chance,
        uint256 _maxDiceRoll
    ) internal pure returns (bool) {
        return _random < (_maxDiceRoll * _chance) / _maxDiceRoll;
    }

    /// @dev _random must be a random number between 0 and _maxDiceRoll
    /// @return true when _random falls between _lowerLimit and _upperLimit, where limits are percentages to 2 d.p. E.g. 1050 for 10.5%
    function _diceWinRanged(
        uint256 _random,
        uint256 _lowerLimit,
        uint256 _upperLimit,
        uint256 _maxDiceRoll
    ) internal pure returns (bool) {
        return
            _random < (_maxDiceRoll * _upperLimit) / _maxDiceRoll &&
            _random >= (_maxDiceRoll * _lowerLimit) / _maxDiceRoll;
    }
}

pragma solidity >=0.8.0 <0.9.0;

import "./Constants.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Treasury is Constants, AccessControl {
    event Withdraw(uint256 _amount);

    function withdraw(uint256 _amount) public {
        require(hasRole(TREASURER_ROLE, msg.sender), "Caller is not treasurer");
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");
        emit Withdraw(_amount);
    }
}

pragma solidity >=0.8.0 <0.9.0;

contract Constants {
    uint256 constant cMaxRandom = 10000;
    uint8 constant cFutureBlockOffset = 2;
    uint8 constant cNumRareHeroTypes = 16;
    uint8 constant cNumEpicHeroTypes = 11;
    uint8 constant cNumLegendaryHeroTypes = 8;
    uint256 constant numProduct = 9;

    uint8 constant cNumHeroTypes =
        cNumRareHeroTypes + cNumEpicHeroTypes + cNumLegendaryHeroTypes;

    uint16 constant cReferralDiscount = 500;
    uint16 constant cReferrerBonus = 500;

    bytes32 public constant PRODUCT_OWNER_ROLE =
        keccak256("PRODUCT_OWNER_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    bytes32 public constant IMMUTABLE_SYSTEM_ROLE =
        keccak256("IMMUTABLE_SYSTEM_ROLE");

    enum Product {
        RareHeroPack,
        EpicHeroPack,
        LegendaryHeroPack,
        PetPack,
        EnergyToken,
        BasicGuildToken,
        Tier1GuildToken,
        Tier2GuildToken,
        Tier3GuildToken
    }

    enum Rarity {Rare, Epic, Legendary, Common, NA}

    enum Price {FirstSale, LastSale}
}

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Constants.sol";
import "./Dice.sol";
import "./ExchangeRate.sol";
import "./Referral.sol";

contract Inventory is Constants, AccessControl, Dice, ExchangeRate, Referral {
    address[cNumHeroTypes] public mythicOwner;
    Settings settings;
    uint256[numProduct] public originalStock;
    uint256[numProduct] public stockAvailable;
    bool public stockFixed = false;
    uint256[2][numProduct] public productPrices;

    struct Settings {
        uint256 firstChromaChance;
        uint256 secondChromaChance;
        uint256 rareToEpicUpgradeChance;
        uint256 rareToLegendaryUpgradeChance;
        uint256 epicToLegendaryUpgradeChance;
        uint256 petRareChance;
        uint256 petEpicChance;
        uint256 petLegendaryChance;
        uint256 rareHeroMythicChance;
        uint256 epicHeroMythicChance;
        uint256 legendaryHeroMythicChance;
    }

    struct AllocatedOrder {
        uint256 firstDiceRoll;
        uint16[] order;
    }

    struct DetailedAllocation {
        Product product;
        Rarity rarity;
        uint8 heroPetType;
        uint8 chroma;
        bool potentialMythic;
    }

    event AllocateOrder(
        AllocatedOrder _allocatedOrder,
        address indexed _owner,
        uint256 _orderPrice
    );
    event PermanentlyLockStock();
    event GiftOrder(address indexed _giftRecipient);
    event ClaimMythic(
        AllocatedOrder _allocatedOrder,
        uint256 _mythicOrderLine,
        address indexed _customerAddr
    );

    constructor(address _usdEthPairAddress)
        Dice(cMaxRandom, cFutureBlockOffset)
        ExchangeRate(_usdEthPairAddress)
        Referral(cReferralDiscount, cReferrerBonus)
    {}

    /// STOCK:

    /// @notice Allows product owner to add additional waves of stock
    /// @param _stockToAdd Additional stock as an array indexed by product id
    function addStock(uint16[] memory _stockToAdd) public {
        require(
            hasRole(PRODUCT_OWNER_ROLE, msg.sender),
            "Caller is not product owner"
        );
        require(!stockFixed, "No more stock can be added");
        for (uint256 i = 0; i < numProduct; i++) {
            originalStock[i] += _stockToAdd[i];
            stockAvailable[i] += _stockToAdd[i];
        }
    }

    /// @notice Allows product owner to lock stock so that buyers know nomore will be created
    function permanentlyLockStock() public {
        require(
            hasRole(PRODUCT_OWNER_ROLE, msg.sender),
            "Caller is not product owner"
        );
        require(!stockFixed, "Stock already locked");
        stockFixed = true;
        emit PermanentlyLockStock();
    }

    function _updateStockLevels(uint16[] memory _order) internal {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        stockAvailable[uint8(Product.RareHeroPack)] -= _order[
            uint8(Product.RareHeroPack)
        ];
        stockAvailable[uint8(Product.EpicHeroPack)] -= _order[
            uint8(Product.EpicHeroPack)
        ];
        stockAvailable[uint8(Product.LegendaryHeroPack)] -= _order[
            uint8(Product.LegendaryHeroPack)
        ];
        stockAvailable[uint8(Product.PetPack)] -= _order[
            uint8(Product.PetPack)
        ];
        stockAvailable[uint8(Product.EnergyToken)] -= _order[
            uint8(Product.EnergyToken)
        ];
        stockAvailable[uint8(Product.BasicGuildToken)] -= _order[
            uint8(Product.BasicGuildToken)
        ];
        stockAvailable[uint8(Product.Tier1GuildToken)] -= _order[
            uint8(Product.Tier1GuildToken)
        ];
        stockAvailable[uint8(Product.Tier2GuildToken)] -= _order[
            uint8(Product.Tier2GuildToken)
        ];
        stockAvailable[uint8(Product.Tier3GuildToken)] -= _order[
            uint8(Product.Tier3GuildToken)
        ];
    }

    function _countStock() internal view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < numProduct; i++) {
            count += stockAvailable[i];
        }
        return count;
    }

    /// ALLOCATION:

    /// @param _allocatedOrder The order and allocated random number
    /// @param _secondDiceRoll random number as result of `getSecondDiceRoll`
    /// @return the allocated rarity, type, chroma, and mythic status for each order line
    function decodeAllocation(
        AllocatedOrder memory _allocatedOrder,
        uint256 _secondDiceRoll
    ) public view returns (DetailedAllocation[] memory) {
        uint256 numLines = _calcNumOrderLines(_allocatedOrder.order);
        // DetailedAllocation[uint(numLines)] detailedAllocation;
        DetailedAllocation[] memory detailedAllocation =
            new DetailedAllocation[](numLines);
        uint16 orderLineNumber;
        // Process Rare hero packs
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.RareHeroPack)];
            i++
        ) {
            Rarity rarity =
                _rarityAllocation(
                    Rarity.Rare,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(3),
                                orderLineNumber
                            )
                        )
                    )
                );
            uint8 chroma =
                _chromaAllocation(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(2),
                                orderLineNumber
                            )
                        )
                    )
                );
            uint8 heroType =
                _heroTypeAllocation(
                    rarity,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(1),
                                orderLineNumber
                            )
                        )
                    )
                );
            bool potentialMythic =
                _mythicAllocation(
                    rarity,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(4),
                                orderLineNumber
                            )
                        )
                    )
                );
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.RareHeroPack,
                rarity: rarity,
                heroPetType: heroType,
                chroma: chroma,
                potentialMythic: potentialMythic
            });
            orderLineNumber++;
        }
        // Process Epic hero packs
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.EpicHeroPack)];
            i++
        ) {
            Rarity rarity =
                _rarityAllocation(
                    Rarity.Epic,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(3),
                                orderLineNumber
                            )
                        )
                    )
                );
            uint8 chroma =
                _chromaAllocation(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(2),
                                orderLineNumber
                            )
                        )
                    )
                );
            uint8 heroType =
                _heroTypeAllocation(
                    rarity,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(1),
                                orderLineNumber
                            )
                        )
                    )
                );
            bool potentialMythic =
                _mythicAllocation(
                    rarity,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(4),
                                orderLineNumber
                            )
                        )
                    )
                );
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.EpicHeroPack,
                rarity: rarity,
                heroPetType: heroType,
                chroma: chroma,
                potentialMythic: potentialMythic
            });
            orderLineNumber++;
        }
        // Process Legendary hero packs
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.LegendaryHeroPack)];
            i++
        ) {
            Rarity rarity =
                _rarityAllocation(
                    Rarity.Legendary,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(3),
                                orderLineNumber
                            )
                        )
                    )
                );
            uint8 chroma =
                _chromaAllocation(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(2),
                                orderLineNumber
                            )
                        )
                    )
                );
            uint8 heroType =
                _heroTypeAllocation(
                    rarity,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(1),
                                orderLineNumber
                            )
                        )
                    )
                );
            bool potentialMythic =
                _mythicAllocation(
                    rarity,
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(4),
                                orderLineNumber
                            )
                        )
                    )
                );
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.LegendaryHeroPack,
                rarity: rarity,
                heroPetType: heroType,
                chroma: chroma,
                potentialMythic: potentialMythic
            });
            orderLineNumber++;
        }
        // Process pet packs
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.PetPack)];
            i++
        ) {
            uint8 petType =
                _petTypeAllocation(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(1),
                                orderLineNumber
                            )
                        )
                    )
                );
            Rarity petRarity =
                _petRarityAllocation(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                _secondDiceRoll,
                                uint256(2),
                                orderLineNumber
                            )
                        )
                    )
                );
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.PetPack,
                rarity: petRarity,
                heroPetType: petType,
                chroma: 0,
                potentialMythic: false
            });
            orderLineNumber++;
        }

        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.BasicGuildToken)];
            i++
        ) {
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.BasicGuildToken,
                rarity: Rarity.NA,
                heroPetType: 0,
                chroma: 0,
                potentialMythic: false
            });
            orderLineNumber++;
        }
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.Tier1GuildToken)];
            i++
        ) {
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.Tier1GuildToken,
                rarity: Rarity.NA,
                heroPetType: 0,
                chroma: 0,
                potentialMythic: false
            });
            orderLineNumber++;
        }
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.Tier2GuildToken)];
            i++
        ) {
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.Tier2GuildToken,
                rarity: Rarity.NA,
                heroPetType: 0,
                chroma: 0,
                potentialMythic: false
            });
            orderLineNumber++;
        }
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.Tier3GuildToken)];
            i++
        ) {
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.Tier3GuildToken,
                rarity: Rarity.NA,
                heroPetType: 0,
                chroma: 0,
                potentialMythic: false
            });
            orderLineNumber++;
        }
        for (
            uint256 i = 0;
            i < _allocatedOrder.order[uint256(Product.EnergyToken)];
            i++
        ) {
            detailedAllocation[orderLineNumber] = DetailedAllocation({
                product: Product.EnergyToken,
                rarity: Rarity.NA,
                heroPetType: 0,
                chroma: 0,
                potentialMythic: false
            });
            orderLineNumber++;
        }
        return detailedAllocation;
    }

    /// @notice If a customer is allocated a potential mythic, Immutable will call this function to claim it for them. Only one mythic exists for each hero type hence cannot be claimed by more than one customer
    /// @param _allocatedOrder The allocated order purchased by the customer
    /// @param _mythicOrderLine The order line containing the potential mythic
    /// @param _secondDiceRoll random number as result of `getSecondDiceRoll`
    function claimMythicForCustomer(
        AllocatedOrder memory _allocatedOrder,
        uint256 _mythicOrderLine,
        address _customerAddr,
        uint256 _secondDiceRoll
    ) public {
        require(
            hasRole(IMMUTABLE_SYSTEM_ROLE, msg.sender),
            "Caller is not immutable"
        );
        if (
            _confirmMythic(_allocatedOrder, _mythicOrderLine, _secondDiceRoll)
        ) {
            uint256 heroType =
                _getMythicHeroType(
                    _allocatedOrder,
                    _mythicOrderLine,
                    _secondDiceRoll
                );
            mythicOwner[heroType] = _customerAddr;
        }
        emit ClaimMythic(_allocatedOrder, _mythicOrderLine, _customerAddr);
    }

    /// @notice If a customer is allocated a potential mythic, they need to call this function to confirm it is still available. Only one mythic exists for each hero type hence cannot be claimed by more than one customer
    /// @param _allocatedOrder The allocated order purchased by the customer
    /// @param _mythicOrderLine The order line containing the potential mythic
    /// @param _secondDiceRoll random number as result of `getSecondDiceRoll`
    /// @return true if the mythic is still available, false if already sold
    function confirmMythic(
        AllocatedOrder memory _allocatedOrder,
        uint256 _mythicOrderLine,
        uint256 _secondDiceRoll
    ) public view returns (bool) {
        return
            _confirmMythic(_allocatedOrder, _mythicOrderLine, _secondDiceRoll);
    }

    function _confirmMythic(
        AllocatedOrder memory _allocatedOrder,
        uint256 _mythicOrderLine,
        uint256 _secondDiceRoll
    ) internal view returns (bool) {
        DetailedAllocation[] memory detailedAllocations =
            decodeAllocation(_allocatedOrder, _secondDiceRoll);
        DetailedAllocation memory potentialMythicAllocation =
            detailedAllocations[_mythicOrderLine];
        uint256 heroType = potentialMythicAllocation.heroPetType;
        if (
            potentialMythicAllocation.potentialMythic &&
            mythicOwner[heroType] == address(0)
        ) {
            return true;
        } else {
            return false;
        }
    }

    function _getMythicHeroType(
        AllocatedOrder memory _allocatedOrder,
        uint256 _mythicOrderLine,
        uint256 _secondDiceRoll
    ) internal view returns (uint256) {
        DetailedAllocation[] memory detailedAllocations =
            decodeAllocation(_allocatedOrder, _secondDiceRoll);
        DetailedAllocation memory potentialMythicAllocation =
            detailedAllocations[_mythicOrderLine];
        return potentialMythicAllocation.heroPetType;
    }

    /// @notice Allocate stock
    /// @dev Function will throw underflow exception if insufficient stock
    function _allocateStock(
        uint16[] memory _order,
        address _owner,
        uint256 _orderPrice
    ) internal {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        _updateStockLevels(_order);

        uint256 firstDiceRoll = getFirstDiceRoll(_countStock());

        AllocatedOrder memory ao =
            AllocatedOrder({firstDiceRoll: firstDiceRoll, order: _order});
        emit AllocateOrder(ao, _owner, _orderPrice);
    }

    function _rarityAllocation(Rarity _originalRarity, uint256 _random)
        internal
        view
        returns (Rarity finalRarity)
    {
        uint256 score = _random % cMaxRandom;
        if (_originalRarity == Rarity.Rare) {
            if (
                _diceWinRanged(
                    score,
                    0,
                    settings.rareToLegendaryUpgradeChance,
                    cMaxRandom
                )
            ) {
                return Rarity.Legendary;
            } else if (
                _diceWinRanged(
                    score,
                    settings.rareToLegendaryUpgradeChance,
                    settings.rareToLegendaryUpgradeChance +
                        settings.rareToEpicUpgradeChance,
                    cMaxRandom
                )
            ) {
                return Rarity.Epic;
            } else {
                return Rarity.Rare;
            }
        }
        if (_originalRarity == Rarity.Epic) {
            if (
                _diceWin(
                    score,
                    settings.epicToLegendaryUpgradeChance,
                    cMaxRandom
                )
            ) {
                return Rarity.Legendary;
            } else {
                return Rarity.Epic;
            }
        }
        return _originalRarity;
    }

    function _mythicAllocation(Rarity _rarity, uint256 _random)
        internal
        view
        returns (bool)
    {
        uint256 score = _random % cMaxRandom;
        if (
            _rarity == Rarity.Rare &&
            _diceWin(score, settings.rareHeroMythicChance, cMaxRandom)
        ) {
            return true;
        }
        if (
            _rarity == Rarity.Epic &&
            _diceWin(score, settings.epicHeroMythicChance, cMaxRandom)
        ) {
            return true;
        }
        if (
            _rarity == Rarity.Legendary &&
            _diceWin(score, settings.legendaryHeroMythicChance, cMaxRandom)
        ) {
            return true;
        }
        return false;
    }

    function _chromaAllocation(uint256 _random) internal view returns (uint8) {
        uint256 score = _random % cMaxRandom;
        if (_diceWin(score, settings.secondChromaChance, cMaxRandom)) {
            return 2;
        }
        if (_diceWin(score, settings.firstChromaChance, cMaxRandom)) {
            return 1;
        }
        return 0;
    }

    //[email protected] See https://docs.google.com/spreadsheets/d/1etc3RR2LN_mXRnbvh54p9ZYPrwtqKhGymdqUna_MJzY/edit#gid=142152434 for explanation
    function _heroTypeAllocation(Rarity _heroRarity, uint256 _random)
        internal
        view
        returns (uint8)
    {
        uint8 heroType;
        uint256 score = _random % cMaxRandom;

        if (_heroRarity == Rarity.Legendary) {
            // Assign a hero type between 1 and 8
            heroType = uint8((score % cNumLegendaryHeroTypes) + 1);
        } else if (_heroRarity == Rarity.Epic) {
            // Assign a hero type between 9 and 19
            heroType = uint8(
                (score % cNumEpicHeroTypes) + cNumLegendaryHeroTypes + 1
            );
        } else if (_heroRarity == Rarity.Rare) {
            // Assign a hero type between 20 and 35
            heroType = uint8(
                (score % cNumRareHeroTypes) +
                    cNumEpicHeroTypes +
                    cNumLegendaryHeroTypes +
                    1
            );
        }
        return heroType;
    }

    function _petTypeAllocation(uint256 _random) internal view returns (uint8) {
        return uint8((_random % 3) + 1);
    }

    function _petRarityAllocation(uint256 _random)
        internal
        view
        returns (Rarity)
    {
        uint256 score = _random % cMaxRandom;
        uint256 startLimit = 0;
        if (_diceWinRanged(score, 0, settings.petLegendaryChance, cMaxRandom)) {
            return Rarity.Legendary;
        }
        startLimit += settings.petLegendaryChance;
        if (
            _diceWinRanged(
                score,
                startLimit,
                settings.petEpicChance,
                cMaxRandom
            )
        ) {
            return Rarity.Epic;
        }
        startLimit += settings.petEpicChance;
        if (
            _diceWinRanged(
                score,
                startLimit,
                settings.petRareChance,
                cMaxRandom
            )
        ) {
            return Rarity.Rare;
        }
        return Rarity.Common;
    }

    function _calcNumOrderLines(uint16[] memory _order)
        internal
        view
        returns (uint256)
    {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        uint256 numLines;
        for (uint256 i = 0; i < numProduct; i++) {
            numLines += _order[i];
        }
        return numLines;
    }

    /// COST:

    /// @param _productId Product ID
    /// @return Dynamic cost of specified product in USD
    function getProductCostUsd(uint8 _productId) public view returns (uint256) {
        uint256 multiplier = 1 * 10**6;
        uint256 firstPrice =
            productPrices[_productId][uint256(Price.FirstSale)];
        uint256 lastPrice = productPrices[_productId][uint256(Price.LastSale)];

        uint256 itemsSold =
            originalStock[uint8(_productId)] -
                stockAvailable[uint8(_productId)];

        if (itemsSold == 0) {
            return firstPrice;
        }

        uint256 relativePriceMovement =
            (itemsSold * multiplier) / originalStock[uint8(_productId)];

        uint256 maxPriceChange = lastPrice - firstPrice;

        uint256 actualPriceChange =
            (maxPriceChange * relativePriceMovement) / multiplier;

        return firstPrice + actualPriceChange;
    }

    /// @param _productId Product ID
    /// @return Dynamic cost of specified product in ETH
    function getProductCostWei(uint8 _productId) public view returns (uint256) {
        return getWeiPrice(getProductCostUsd(_productId));
    }

    /// @param _order Ordered quantity of each product type
    /// @return Total order cost in USD
    function calcOrderCostUsd(uint16[] memory _order)
        public
        view
        returns (uint256)
    {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        uint256 orderCost;
        for (uint8 i = 0; i < _order.length; i++) {
            orderCost += _calcOrderLineCost(i, _order[i]);
        }
        return orderCost;
    }

    /// @param _order Ordered quantity of each product type
    /// @return Total order cost in WEI
    function calcOrderCostWei(uint16[] memory _order)
        public
        view
        returns (uint256)
    {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        return getWeiPrice(calcOrderCostUsd(_order));
    }

    function _calcOrderLineCost(uint8 _productId, uint16 _quantity)
        internal
        view
        returns (uint256)
    {
        return getProductCostUsd(_productId) * _quantity;
    }

    /// CART:

    /// @notice Allows a purchase to be made, allocates a random number determine product allocation, and adjusts stock levels
    function purchase(uint16[] memory _order, address _referrer)
        public
        payable
    {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        _enforceOrderLimits(_order);

        uint256 orderCostUsd = calcOrderCostUsd(_order);
        uint256 referrerBonusUsd;
        uint256 discountUsd;

        if (_referrer != address(0)) {
            (referrerBonusUsd, discountUsd) = _calcReferrals(orderCostUsd);
        }

        (uint112 usdReserve, uint112 ethReserve, uint32 blockTimestampLast) =
            usdEthPair.getReserves();

        if (referrerBonusUsd > 0) {
            referrerBonuses[_referrer] += _calcWeiFromUsd(
                usdReserve,
                ethReserve,
                referrerBonusUsd
            );
        }
        uint256 discountWei =
            _calcWeiFromUsd(usdReserve, ethReserve, discountUsd);
        uint256 netWei =
            _calcWeiFromUsd(usdReserve, ethReserve, orderCostUsd) - discountWei;

        require(msg.value >= netWei, "Insufficient funds");

        _allocateStock(
            _order,
            msg.sender,
            orderCostUsd - referrerBonusUsd - discountUsd
        );
        if (msg.value - netWei > 0) {
            (bool success, ) =
                payable(msg.sender).call{value: msg.value - netWei}("");
            require(success, "Transfer failed");
        }
    }

    /// @notice Gift packs
    /// @param _giftOrder Products to gift
    /// @param _giftRecipient Address of gift recipient
    function giftPack(uint16[] memory _giftOrder, address _giftRecipient)
        public
    {
        require(
            hasRole(PRODUCT_OWNER_ROLE, msg.sender),
            "Caller is not product owner"
        );
        _enforceOrderLimits(_giftOrder);
        _allocateStock(_giftOrder, _giftRecipient, 0);
        emit GiftOrder(_giftRecipient);
    }

    /// @notice Add stock and immediately gift it
    /// @param _giftOrder Products to gift
    /// @param _giftRecipient Address of gift recipient
    function addStockAndGift(uint16[] memory _giftOrder, address _giftRecipient)
        public
    {
        require(
            hasRole(PRODUCT_OWNER_ROLE, msg.sender),
            "Caller is not product owner"
        );
        require(!stockFixed, "No more stock can be added");
        _enforceOrderLimits(_giftOrder);
        addStock(_giftOrder);
        _allocateStock(_giftOrder, _giftRecipient, 0);
        emit GiftOrder(_giftRecipient);
    }

    function _enforceOrderLimits(uint16[] memory _order) internal {
        require(_order.length == numProduct, "Unexpected number of orderlines");
        for (uint256 i = 0; i < numProduct; i++) {
            require(_order[i] <= 100, "Max limit 100 per item");
        }
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

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Constants.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract ExchangeRate is Constants, AccessControl {
    address public usdEthPairAddress;
    uint256 constant cUsdDecimals = 2;
    IUniswapV2Pair usdEthPair;

    event UpdateUsdToEthPair(address _usdToEthPairAddress);

    constructor(address _usdEthPairAddress) {
        usdEthPairAddress = _usdEthPairAddress;
        usdEthPair = IUniswapV2Pair(_usdEthPairAddress);
    }

    /// @notice Set the uniswap liquidity pool used to determine exchange rate
    /// @param _usdEthPairAddress address of the contract
    function updateUsdToEthPair(address _usdEthPairAddress) public {
        require(
            hasRole(PRODUCT_OWNER_ROLE, msg.sender),
            "Caller is not product owner"
        );
        usdEthPairAddress = _usdEthPairAddress;
        usdEthPair = IUniswapV2Pair(usdEthPairAddress);
        emit UpdateUsdToEthPair(_usdEthPairAddress);
    }

    /// @notice Calculate Wei price dynamically based on reserves on Uniswap for ETH / DAI pair
    /// @param _amountInUsd the amount to convert, in USDx100, e.g. 186355 for $1863.55 USD
    /// @return amount of wei needed to buy _amountInUsd
    function getWeiPrice(uint256 _amountInUsd) public view returns (uint256) {
        (uint112 usdReserve, uint112 ethReserve, uint32 blockTimestampLast) =
            usdEthPair.getReserves();
        return _calcWeiFromUsd(usdReserve, ethReserve, _amountInUsd);
    }

    function _calcWeiFromUsd(
        uint112 _usdReserve,
        uint112 _ethReserve,
        uint256 _amountInUsd
    ) public pure returns (uint256) {
        return
            (_amountInUsd * _ethReserve * (10**18)) /
            (_usdReserve * (10**cUsdDecimals));
    }
}

pragma solidity >=0.8.0 <0.9.0;

contract Referral {
    uint16 referralDiscount;
    uint16 referrerBonus;
    mapping(address => uint256) public referrerBonuses;

    event WithdrawBonus(uint256 _amount, address _referrer);

    constructor(uint16 _referralDiscount, uint16 _referrerBonus) {
        referralDiscount = _referralDiscount;
        referrerBonus = _referrerBonus;
    }

    function withdrawBonus() public {
        uint256 amount = referrerBonuses[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        referrerBonuses[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        emit WithdrawBonus(amount, msg.sender);
    }

    function _calcReferrals(uint256 _orderCost)
        internal
        view
        returns (uint256 toReferrer, uint256 discount)
    {
        toReferrer = (_orderCost * referrerBonus) / 10000;
        discount = (_orderCost * referralDiscount) / 10000;

        return (toReferrer, discount);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

