// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "hardhat/console.sol";

contract GildLand is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // using SafeMath for uint256;
    // using SafeERC20 for IERC20;

    address public contributorAddr;
    uint256 public constant MAX_X = 1000;
    uint256 public constant MAX_Y = 1000;

    enum LandProp {
        GILD,
        WOOD,
        WATER,
        IRON,
        CLAY,
        CROP
    }

    struct LandInfo {
        address owner;
        string name;
        string color;
        uint256 extraGild;
        uint256 extraWood;
    }

    struct Army {
        uint256 lv1;
        uint256 lv2;
        uint256 lv3;
    }

    struct BuildingInfo {
        string id;
        string name;
        uint256 level;
        uint256 energyUsdPerBlockPerLevel;
        uint256 gild;
        uint256 wood;
        uint256 water;
        uint256 iron;
        uint256 clay;
        uint256 crop;
    }

    mapping(string => BuildingInfo) public building;

    // x => y => LandInfo
    mapping(uint256 => mapping(uint256 => LandInfo)) public lands;

    // x => y => Building
    mapping(uint256 => mapping(uint256 => BuildingInfo[])) public landBuilding;

    // x => y => army protector
    mapping(uint256 => mapping(uint256 => Army)) public armyProtectLand;

    // user address => x , y
    mapping(address => LandInfo[]) public users;

    // user address => army attacker
    mapping(address => Army) public armyAttacks;

    event Buy(address indexed user, uint256 x, uint256 y);

    modifier noContract() {
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    function initialize(address _contributorAddr) public initializer {
        contributorAddr = _contributorAddr;
    }

    function buy(uint256 x, uint256 y)
        external
        payable
        noContract
        nonReentrant
    {
        require(msg.value == 0.000000000000000001 ether, "buy: bnb!");
        LandInfo storage land = lands[x][y];
        require(land.owner == address(0), "buy: land has owner!");
        land.owner = msg.sender;

        emit Buy(msg.sender, x, y);
    }

    function transfer(address token) external payable {
        if (address(0) == token) {
            payable(contributorAddr).transfer(address(this).balance);
        } else {
            IERC20(token).transfer(
                contributorAddr,
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    function changeLandOwner(
        uint256 x,
        uint256 y,
        address currentOwner,
        address newOwner
    ) internal {
        LandInfo storage land = lands[x][y];
        require(currentOwner != address(0), "currentOwner 0!");
        require(newOwner != address(0), "newOwner 0!");
        require(currentOwner != newOwner, "currentOwner and newOwner same!");
        require(land.owner == currentOwner, "currentOwner is not valid!");

        land.owner = newOwner;
    }

    function battle(uint256 x, uint256 y) external noContract nonReentrant {
        LandInfo memory land = lands[x][y];
        require(land.owner != address(0), "no owner cannot attack!");
        require(land.owner != msg.sender, "your land!");

        Army memory armyAttack = armyAttacks[msg.sender];
        Army memory armyProtector = armyProtectLand[x][y];

        // TODO find calculate win score later
        bool isWin = armyAttack.lv1 > armyProtector.lv1;
        if (isWin) {
            // TODO calculate remaining army later
            // and transfer to new owner
            changeLandOwner(x, y, land.owner, msg.sender);
        }
    }

    function addArmyProtector(
        uint256 x,
        uint256 y,
        uint256 lv1
    ) external noContract nonReentrant {
        LandInfo storage land = lands[x][y];
        require(land.owner == msg.sender, "you are not owner!");
        armyProtectLand[x][y].lv1 = lv1;
    }

    function addArmyAttacker(uint256 lv1) external noContract nonReentrant {
        armyAttacks[msg.sender].lv1 = lv1;
    }

    function swapArmy(
        uint256 fromX,
        uint256 fromY,
        uint256 toX,
        uint256 toY,
        uint256 fromLv1,
        uint256 toLv1
    ) external noContract nonReentrant {
        LandInfo memory fromLand = lands[fromX][fromY];
        require(fromLand.owner == msg.sender, "you are not owner!");

        LandInfo memory toLand = lands[toX][toY];
        require(toLand.owner == msg.sender, "you are not owner!");
        require(fromX != toX && fromY != toY, "swap?");
        require(
            armyProtectLand[fromX][fromY].lv1 == fromLv1,
            "invalid swap from?"
        );
        require(armyProtectLand[toX][toY].lv1 == toLv1, "invalid swap to?");

        armyProtectLand[fromX][fromY].lv1 = toLv1;
        armyProtectLand[toX][toY].lv1 = fromLv1;
    }

    function _myLandInfo(uint256 x, uint256 y)
        internal
        view
        returns (LandInfo memory)
    {
        LandInfo memory land = lands[x][y];
        require(land.owner == msg.sender, "not your land!");

        return land;
    }

    function landBuildingList(uint256 x, uint256 y)
        external
        view
        returns (BuildingInfo[] memory)
    {
        BuildingInfo[] memory info = landBuilding[x][y];
        return info;
    }

    // building
    function addBuildingItem(
        string memory id,
        string memory name,
        uint256 energyUsdPerBlockPerLevel,
        uint256 gild,
        uint256 wood,
        uint256 water,
        uint256 iron,
        uint256 clay,
        uint256 crop
    ) public {
        BuildingInfo memory b = building[id];
        require(
            keccak256(abi.encodePacked(b.id)) ==
                keccak256(abi.encodePacked("")),
            "adding duplicate name"
        );
        building[id] = BuildingInfo(
            id,
            name,
            1,
            energyUsdPerBlockPerLevel,
            gild,
            wood,
            water,
            iron,
            clay,
            crop
        );
    }

    function upgradeBuilding(
        string memory id,
        uint256 x,
        uint256 y
    ) external noContract nonReentrant {
        _myLandInfo(x, y);
        BuildingInfo[] memory b = landBuilding[x][y];
        for (uint256 i = 0; i < b.length; i++) {
            if (
                keccak256(abi.encodePacked(b[i].id)) ==
                keccak256(abi.encodePacked(id))
            ) {
                b[i].level = b[i].level + 1;
            }
        }
    }

    function createBuilding(
        string memory id,
        uint256 x,
        uint256 y
    ) external {
        _myLandInfo(x, y);
        BuildingInfo memory b = building[id];
        require(
            keccak256(abi.encodePacked(b.id)) !=
                keccak256(abi.encodePacked("")),
            "no building to create"
        );

        BuildingInfo[] memory _landBuildingList = landBuilding[x][y];
        for (uint256 i = 0; i < _landBuildingList.length; i++) {
            if (
                keccak256(abi.encodePacked(_landBuildingList[i].id)) ==
                keccak256(abi.encodePacked(id))
            ) {
                revert("id already exists");
            }
        }

        landBuilding[x][y].push(
            BuildingInfo(
                b.id,
                b.name,
                b.level,
                b.energyUsdPerBlockPerLevel,
                b.gild,
                b.wood,
                b.water,
                b.iron,
                b.clay,
                b.crop
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}