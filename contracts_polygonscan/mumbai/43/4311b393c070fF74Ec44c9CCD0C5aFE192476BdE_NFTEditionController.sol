// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./NFTEditionLibrary.sol";
import "./interfaces/INFTEditionController.sol";

contract NFTEditionController is INFTEditionController, Initializable, AccessControlUpgradeable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using NFTEditionLibrary for address;
    address public eternalStorage;

    event PlayerEditionAdded(uint256 indexed _editionId);
    event PlayerEditionDiscountAdded(uint256 indexed _editionId);
    event PlayerClassTypeAdded(uint256 indexed _typeId);
    event InflationChanged(uint256 _inflationRate);
    event EditionItemMinted(uint256 indexed _editionId);

    address public dynamicNFTCollectionAddress;

    function initialize(address _eternalStorage, address _dynamicNFTCollectionAddress) public initializer {
        eternalStorage = _eternalStorage;
        dynamicNFTCollectionAddress = _dynamicNFTCollectionAddress;

        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addPlayerEdition(
        uint256 editionId, uint256 _playerId, bytes32 _name, uint16 _class, bytes32 _position, uint16 _overall, uint16 _hashRate) external override onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 _editionId = eternalStorage.addPlayerEdition(editionId, _playerId, _name, _class, _position, _overall, _hashRate);
        emit PlayerEditionAdded(_editionId);
    }

    function addPlayerEditionDiscount(uint256 _editionId, uint256 _duration, uint256 _discountPrice, bool _discountStatic) external override onlyRole(DEFAULT_ADMIN_ROLE)
    {
        eternalStorage.addPlayerEditionDiscount(_editionId, block.timestamp, _duration, _discountPrice, _discountStatic);
        emit PlayerEditionDiscountAdded(_editionId);
    }

    function addPlayerClassType(bytes32 _name, uint16 _typeId, uint16 _mintMax) external override onlyRole(DEFAULT_ADMIN_ROLE)
    {
        eternalStorage.addPlayerClassType(_name, _typeId, _mintMax);
        emit PlayerClassTypeAdded(_typeId);
    }

    function addInflation(uint16 _inflationRate) external override onlyRole(DEFAULT_ADMIN_ROLE)
    {
        eternalStorage.addInflation(_inflationRate);
        emit InflationChanged(_inflationRate);
    }

    function handleMint(uint256 _editionId) external override {
        require(
            IAccessControlUpgradeable(dynamicNFTCollectionAddress).hasRole(MINTER_ROLE, _msgSender()),
            "invalid caller"
        );

        require(eternalStorage.getEditionCanMinted(_editionId) > 0, "This edition can't be minted");

        eternalStorage.reduceEditionCanMinted(_editionId);
        emit EditionItemMinted(_editionId);
    }

    function getPlayerEdition(uint256 editionId) external override view returns (bytes32, uint16, bytes32, uint16, uint16, uint16, uint16)
    {
        return eternalStorage.getPlayerEdition(editionId);
    }

    function getPlayerEditionId(uint16 _class, bytes32 _position, uint256 _index) external override view returns (uint256)
    {
        return eternalStorage.getPlayerEditionId(_class, _position, _index);
    }

    function getEditionPrice(uint256 _editionId) external override view returns (uint256)
    {
        return eternalStorage.getEditionPrice(_editionId);
    }

    function getEditionPriceDiscounted(uint256 _editionId) external override view returns (uint256)
    {
        return eternalStorage.getEditionPriceDiscounted(_editionId);
    }

    function getEditionCanMinted(uint256 _editionId) external override view returns (uint256)
    {
        return eternalStorage.getEditionCanMinted(_editionId);
    }

    function getPlayersCountByFilter(uint16 _class, bytes32 _position) external override view returns (uint256)
    {
        return eternalStorage.getPlayersCountByFilter(_class, _position);
    }

    function getCardsInitialCountByPosition(bytes32 _position) external override view returns (uint256)
    {
        return eternalStorage.getCardsInitialCountByPosition(_position);
    }

    function getEditionIdFromRandom(uint256 _seed, bytes32 _position) external override view returns (uint256)
    {
        (uint256 classPart, uint256 offsetPart) = _getClassAndOffsetFromRandom(_seed);

    return getEditionIdFromClassPartAndOffset(classPart, offsetPart, _position);

    }

    function getClassByRarity(uint8 _index) external override view returns (uint16, uint16)
    {
        return eternalStorage.getClassByRarity(_index);
    }

    function getPlayersCount() external override view returns (uint256)
    {
        return eternalStorage.getPlayersCount();
    }

    function getEditionIdFromClassPartAndOffset(uint256 classPart, uint256 offsetPart, bytes32 _position) public view returns (uint256)
    {

        uint16 classIdByRarity;
        uint16 classRarity;

        uint256 countByPosition;


        uint256 totalCardsOnPosition = eternalStorage.getCardsInitialCountByPosition(_position);

        uint256 classOffset = classPart % totalCardsOnPosition;
        uint256 currentClassOffset = 0;

        for (uint8 i = 0; i < 100; i++) {
            (classIdByRarity, classRarity) = eternalStorage.getClassByRarity(i);

            countByPosition = eternalStorage.getPlayersCountByFilter(classIdByRarity, _position);

            currentClassOffset += countByPosition * classRarity;

            if (countByPosition == 0) {
                continue;
            }

            if (classOffset < currentClassOffset) {
                break;
            }
        }

        return eternalStorage.getPlayerEditionId(classIdByRarity, _position, offsetPart % countByPosition);
    }

    function _getClassAndOffsetFromRandom(uint256 _seed)
    public view returns (uint256, uint256)
    {
        return (
        uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, "ClassPart"))),
        uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, "OffsetPart")))
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @notice added by OWNIC
interface INFTEditionController {

    // TODO test 2
    function addPlayerEdition(uint256 editionId, uint256 _playerId, bytes32 _name, uint16 _class, bytes32 _position, uint16 _overall, uint16 _hashRate) external;

    function addPlayerEditionDiscount(uint256 _editionId, uint256 _duration, uint256 _discountPrice, bool _discountStatic) external;

    // TODO test 1
    function addPlayerClassType(bytes32 _name, uint16 _typeId, uint16 _mintMax) external;

    function addInflation(uint16 _inflationRate) external;

    function handleMint(uint256 _editionId) external;

    function getPlayerEdition(uint256 editionId) external returns (bytes32, uint16, bytes32, uint16, uint16, uint16, uint16);

    function getPlayerEditionId(uint16 _class, bytes32 _position, uint256 _index) external returns (uint256);

    function getEditionPrice(uint256 _editionId) external view returns (uint256);

    function getEditionPriceDiscounted(uint256 _editionId) external view returns (uint256);

    function getEditionCanMinted(uint256 _editionId) external view returns (uint256);

    function getPlayersCountByFilter(uint16 _class, bytes32 _position) external view returns (uint256);

    function getCardsInitialCountByPosition(bytes32 _position) external view returns (uint256);

    function getEditionIdFromRandom(uint256 _seed, bytes32 _position) external view returns (uint256);

    function getClassByRarity(uint8 _index) external view returns (uint16, uint16);

    function getPlayersCount() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";

// https://docs.synthetix.io/contracts/source/contracts/state
abstract contract State is Owned {

    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract) {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

// @notice added by OWNIC copied from openzeppelin and merged by us Pausable + AccessControlUpgradeable
contract ContextUpgradeSafe is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

contract AccessControlUpgradeable is Initializable, ContextUpgradeSafe, IAccessControlUpgradeable {

    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    uint256[49] private __gap;
}

contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

abstract contract Pausable is OwnableUpgradeSafe {
    uint256 public lastPauseTime;
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused() {
        require(
            !paused,
            "This action cannot be performed while the contract is paused"
        );
        _;
    }

    modifier whenPaused() {
        require(
            paused,
            "This action can be performed when the contract is paused"
        );
        _;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused == paused) {
            return;
        }

        paused = _paused;

        if (paused) {
            lastPauseTime = block.timestamp;
        }

        emit PauseChanged(paused);
    }
}

pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/contracts/owned
// SPDX-License-Identifier: MIT
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./EternalStorage.sol";

// @notice added by OWNIC
library NFTEditionLibrary {

    using SafeMath for uint256;

    function getPlayersCountByFilter(address _storageContract, uint16 _classId, bytes32 _position) public view returns (uint256)
    {
        return EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked(_classId, _position, "Count")));
    }

    function getCardsInitialCountByPosition(address _storageContract, bytes32 _position) public view returns (uint256)
    {
        return EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked(_position, "CardsCount")));
    }

    function getPlayersCount(address _storageContract) public view returns (uint256)
    {
        return EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("AllCount")));
    }

    function getPlayerEdition(address _storageContract, uint256 editionId) public view returns (bytes32, uint16, bytes32, uint16, uint16, uint16, uint16)
    {
        return (
        EternalStorage(_storageContract).getBytes32Value(keccak256(abi.encodePacked("edition_name", editionId))),
        EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_class", editionId))),
        EternalStorage(_storageContract).getBytes32Value(keccak256(abi.encodePacked("edition_position", editionId))),
        EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_overall", editionId))),
        EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_hash_rate", editionId))),
        EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_mint_max", editionId))),
        EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_minted", editionId)))
        );
    }

    function getPlayerEditionId(address _storageContract, uint16 _classId, bytes32 _position, uint256 _index) public view returns (uint256)
    {
        return EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked(_classId, _position, _index)));
    }

    function getEditionPrice(address _storageContract, uint256 _editionId) public view returns (uint256)
    {
        uint16 overall = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_overall", _editionId)));
        uint16 hashRate = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_hash_rate", _editionId)));
        uint16 canMinted = getEditionCanMinted(_storageContract, _editionId);
        uint16 inflation = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("inflation_rate")));
        return uint256(overall + hashRate) * inflation * 1e18 / canMinted;
    }

    function getEditionPriceDiscounted(address _storageContract, uint256 _editionId) public view returns (uint256)
    {
        uint256 _price = getEditionPrice(_storageContract, _editionId);
        uint256 _discountStartedAt = EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("discount_started_at", _editionId)));

        if (_discountStartedAt == 0) {
            return _price;
        }

        uint256 _secondsPassed = 0;

        if (block.timestamp > _discountStartedAt) {
            _secondsPassed = block.timestamp - _discountStartedAt;
        }
        uint256 _duration = EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("discount_duration", _editionId)));
        uint256 _discountPrice = EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("discount_price", _editionId)));
        bool _discountStatic = EternalStorage(_storageContract).getBooleanValue(keccak256(abi.encodePacked("discount_static", _editionId)));

        if (_secondsPassed >= _duration) {
            return _price;
        } else if (_discountStatic) {
            return _discountPrice;
        } else {
            uint256 _totalPriceChange = _price - _discountPrice;
            uint256 _currentPriceChange = _totalPriceChange * _secondsPassed / _duration;
            return _discountPrice + _currentPriceChange;
        }
    }

    function getEditionCanMinted(address _storageContract, uint256 _editionId) public view returns (uint16)
    {
        uint16 mintMax = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_mint_max", _editionId)));
        uint16 minted = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_minted", _editionId)));
        return mintMax - minted;
    }

    function getClassByRarity(address _storageContract, uint8 _index) public view returns (uint16, uint16)
    {
        uint16 classId = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("class_type_id_by_rarity", _index)));

        return (
        classId,
        EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("class_type_rarity", classId)))
        );
    }

    function addInflation(address _storageContract, uint16 _inflationRate) public returns (bool)
    {
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("inflation_rate")), _inflationRate);
        // TODO add inflation limitations
        return true;
    }

    function addPlayerEdition(
        address _storageContract,
        uint256 editionId, uint256 _playerId, bytes32 _name, uint16 _classId, bytes32 _position, uint16 _overall, uint16 _hashRate) public returns (uint256)
    {
        // todo check _playerId > 0 && _classId exist && _overall > 0

        EternalStorage(_storageContract).setBytes32Value(keccak256(abi.encodePacked("edition_name", editionId)), _name);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("edition_player_id", _playerId)), _playerId);
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("edition_class", editionId)), _classId);
        EternalStorage(_storageContract).setBytes32Value(keccak256(abi.encodePacked("edition_position", editionId)), _position);

        uint16 mintMax = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("class_type_rarity", _classId)));

        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("edition_mint_max", editionId)), mintMax);
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("edition_minted", editionId)), 0);
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("edition_hash_rate", editionId)), _hashRate);
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("edition_overall", editionId)), _overall);
        EternalStorage(_storageContract).setBooleanValue(keccak256(abi.encodePacked("edition_enabled", editionId)), true);

        uint256 idx = getPlayersCountByFilter(_storageContract, _classId, _position);
        uint256 positionCardsCount = getCardsInitialCountByPosition(_storageContract, _position);
        uint256 countAll = getPlayersCount(_storageContract);

        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked(_classId, _position, idx)), editionId);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("edition_index_in_filter", editionId)), idx);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked(_classId, _position, "Count")), idx + 1);

        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked(_position, "CardsCount")), positionCardsCount + mintMax);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("AllCount")), countAll + 1);

        return editionId;
    }

    function addPlayerEditionDiscount(
        address _storageContract, uint256 _editionId,
        uint256 _discountStartedAt, uint256 _duration, uint256 _discountPrice, bool _discountStatic) public returns (uint256)
    {
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("discount_started_at", _editionId)), _discountStartedAt);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("discount_duration", _editionId)), _duration);
        EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("discount_price", _editionId)), _discountPrice);
        EternalStorage(_storageContract).setBooleanValue(keccak256(abi.encodePacked("discount_static", _editionId)), _discountStatic);
        return getEditionPriceDiscounted(_storageContract, _editionId);
    }

    function reduceEditionCanMinted(address _storageContract, uint256 _editionId) public
    {
        uint16 minted = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_minted", _editionId)));
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("edition_minted", _editionId)), minted + 1);

        uint16 mintMax = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_mint_max", _editionId)));

        if (mintMax - minted == 1) {
            uint16 _classId = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("edition_class", _editionId)));
            bytes32 _position = EternalStorage(_storageContract).getBytes32Value(keccak256(abi.encodePacked("edition_position", _editionId)));
            uint256 countByFilter = getPlayersCountByFilter(_storageContract, _classId, _position);

            uint256 indexByFilter = EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("edition_index_in_filter", _editionId)));
            uint256 lastEditionToSwapIndex = EternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked(_classId, _position, countByFilter - 1)));
            EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked(_classId, _position, indexByFilter)), lastEditionToSwapIndex);
            EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked(_classId, _position, countByFilter)), 0);
            EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("edition_index_in_filter", _editionId)), 0);
            EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("edition_index_in_filter", lastEditionToSwapIndex)), indexByFilter);
            EternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked(_classId, _position, "Count")), countByFilter - 1);
        }
    }

    function addPlayerClassType(address _storageContract, bytes32 _name, uint16 _typeId, uint16 _rarity) public
    {
        // TODO add check _typeId > 0

        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("class_type_id", _typeId)), _typeId);
        EternalStorage(_storageContract).setBytes32Value(keccak256(abi.encodePacked("class_type_name", _typeId)), _name);
        EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("class_type_rarity", _typeId)), _rarity);

        bool alreadyInserted = false;
        uint16 lastClassRarity = 0;
        uint16 lastClassIdByRarity = 0;

        for (uint8 i = 0; i < 100; i++) {

            uint16 curClassIdByRarity = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("class_type_id_by_rarity", i)));
            uint16 curClassRarity = 0;

            if (curClassIdByRarity > 0) {
                curClassRarity = EternalStorage(_storageContract).getUInt16Value(keccak256(abi.encodePacked("class_type_rarity", curClassIdByRarity)));
            }

            if (!alreadyInserted) {
                if (_rarity > curClassRarity) {
                    EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("class_type_id_by_rarity", i)), _typeId);
                    alreadyInserted = true;
                }
            } else {

                EternalStorage(_storageContract).setUInt16Value(keccak256(abi.encodePacked("class_type_id_by_rarity", i)), lastClassIdByRarity);
            }

            lastClassRarity = curClassRarity;
            lastClassIdByRarity = curClassIdByRarity;

            if (curClassIdByRarity == 0) {
                break;
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";
import "./State.sol";

// https://docs.synthetix.io/contracts/source/contracts/eternalstorage
/**
 * @notice  This contract is based on the code available from this blog
 * https://blog.colony.io/writing-upgradeable-contracts-in-solidity-6743f0eecc88/
 * Implements support for storing a keccak256 key and value pairs. It is the more flexible
 * and extensible option. This ensures data schema changes can be implemented without
 * requiring upgrades to the storage contract.
 */
contract EternalStorage is Owned, State {

    constructor(address _owner, address _associatedContract) Owned(_owner) State(_associatedContract) {}

    /* ========== DATA TYPES ========== */
    mapping(bytes32 => uint) internal UIntStorage;
    // @notice added by OWNIC
    mapping(bytes32 => uint16) internal UInt16Storage;
    mapping(bytes32 => string) internal StringStorage;
    mapping(bytes32 => address) internal AddressStorage;
    mapping(bytes32 => bytes) internal BytesStorage;
    mapping(bytes32 => bytes32) internal Bytes32Storage;
    mapping(bytes32 => bool) internal BooleanStorage;
    mapping(bytes32 => int) internal IntStorage;

    // UIntStorage;
    function getUIntValue(bytes32 record) external view returns (uint) {
        return UIntStorage[record];
    }

    function setUIntValue(bytes32 record, uint value) external onlyAssociatedContract {
        UIntStorage[record] = value;
    }

    function deleteUIntValue(bytes32 record) external onlyAssociatedContract {
        delete UIntStorage[record];
    }

    // UInt16Storage;
    function getUInt16Value(bytes32 record) external view returns (uint16) {
        return UInt16Storage[record];
    }

    function setUInt16Value(bytes32 record, uint16 value) external onlyAssociatedContract {
        UInt16Storage[record] = value;
    }

    function deleteUInt16Value(bytes32 record) external onlyAssociatedContract {
        delete UInt16Storage[record];
    }

    // StringStorage
    function getStringValue(bytes32 record) external view returns (string memory) {
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string calldata value) external onlyAssociatedContract {
        StringStorage[record] = value;
    }

    function deleteStringValue(bytes32 record) external onlyAssociatedContract {
        delete StringStorage[record];
    }

    // AddressStorage
    function getAddressValue(bytes32 record) external view returns (address) {
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) external onlyAssociatedContract {
        AddressStorage[record] = value;
    }

    function deleteAddressValue(bytes32 record) external onlyAssociatedContract {
        delete AddressStorage[record];
    }

    // BytesStorage
    function getBytesValue(bytes32 record) external view returns (bytes memory) {
        return BytesStorage[record];
    }

    function setBytesValue(bytes32 record, bytes calldata value) external onlyAssociatedContract {
        BytesStorage[record] = value;
    }

    function deleteBytesValue(bytes32 record) external onlyAssociatedContract {
        delete BytesStorage[record];
    }

    // Bytes32Storage
    function getBytes32Value(bytes32 record) external view returns (bytes32) {
        return Bytes32Storage[record];
    }

    function setBytes32Value(bytes32 record, bytes32 value) external onlyAssociatedContract {
        Bytes32Storage[record] = value;
    }

    function deleteBytes32Value(bytes32 record) external onlyAssociatedContract {
        delete Bytes32Storage[record];
    }

    // BooleanStorage
    function getBooleanValue(bytes32 record) external view returns (bool) {
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) external onlyAssociatedContract {
        BooleanStorage[record] = value;
    }

    function deleteBooleanValue(bytes32 record) external onlyAssociatedContract {
        delete BooleanStorage[record];
    }

    // IntStorage
    function getIntValue(bytes32 record) external view returns (int) {
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) external onlyAssociatedContract {
        IntStorage[record] = value;
    }

    function deleteIntValue(bytes32 record) external onlyAssociatedContract {
        delete IntStorage[record];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}