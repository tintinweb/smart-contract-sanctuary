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

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./libraries/Level.sol";
import "./libraries/UserLibrary.sol";
import "./libraries/DecimalMath.sol";
import "./datatypes/LevelStats.sol";
import "./datatypes/UserStats.sol";
import "./datatypes/UserAttackInfo.sol";
import "./datatypes/UserPoints.sol";
import "./interfaces/IArmoryNft.sol";
import "./interfaces/IBank.sol";
import "./interfaces/ICryptoClysm.sol";

contract CryptoClysm is ICryptoClysm, OwnableUpgradeable {
    using Level for LevelStats[];
    using UserLibrary for UserStats;
    using DecimalMath for uint128;
    using DecimalMath for uint256;

    event ArmoryNftSet(address indexed armoryNft);
    event UserPointSet(address indexed user, UserPoints points);
    event Registered(address indexed user);

    enum HitResult {
        WIN,
        LOSE,
        DRAW
    }

    uint64 constant UPKEEP_PERIOD = 1 days;

    uint256 public totalUsers;
    LevelStats[] public levels;

    mapping(address => UserStats) private _userStats;
    mapping(address => UserPoints) public userPoints;
    address public armoryNft;
    address public creditToken;
    address public bank;
    uint32 public techPointsIncrementPerLevel;

    modifier payUpkeepChecker(address user) {
        _payUpkeep(user);
        _;
    }

    function initialize(address bank_, uint32 techPointsIncrementPerLevel_)
        external
        initializer
    {
        require(bank_ != address(0), "BANK cannot be zero");

        __Ownable_init();

        bank = bank_;
        creditToken = IBank(bank_).creditToken();

        // Initialize zero level
        LevelStats memory stats;
        levels.push(stats);

        LevelStats memory newLevel = levels.generateNewLevel();
        levels.push(newLevel);

        require(
            techPointsIncrementPerLevel_ > 0,
            "invalid techPointsIncrement"
        );
        techPointsIncrementPerLevel = techPointsIncrementPerLevel_;
    }

    function register(UserPoints calldata points) external {
        require(_userStats[msg.sender].level == 0, "exist!");

        UserStats storage myStats = _userStats[msg.sender];

        emit Registered(msg.sender);

        _upgradeUserLevel(myStats);

        myStats.lastUpkeepPaidIndex = _getBlockTimestamp() / UPKEEP_PERIOD;
        _setUserPoints(msg.sender, points);
    }

    function setUserPoints(UserPoints calldata points) external {
        UserStats storage userStats = _userStats[msg.sender];
        userStats.techPoints -= 1;

        _setUserPoints(msg.sender, points);
    }

    function payUpkeep(address user) external override {
        _payUpkeep(user);
    }

    function buyArmory(uint256 armoryId, uint256 amount) external {
        _payUpkeep(msg.sender);
        (
            uint256 price,
            uint256 upkeep,
            uint32 attack,
            uint32 defense
        ) = IArmoryNft(armoryNft).mintArmory(msg.sender, armoryId, amount);
        IBank(bank).transferOpenToken(
            creditToken,
            msg.sender,
            address(0),
            price
        );
        _increaseUserArmory(msg.sender, upkeep, attack, defense);
    }

    function sellArmory(uint256 armoryId, uint256 amount) external {
        _payUpkeep(msg.sender);
        (
            uint256 price,
            uint256 upkeep,
            uint32 attack,
            uint32 defense
        ) = IArmoryNft(armoryNft).mintArmory(msg.sender, armoryId, amount);
        IBank(bank).transferOpenToken(
            creditToken,
            address(0),
            msg.sender,
            price
        );
        _decreaseUserArmory(msg.sender, upkeep, attack, defense);
    }

    function hit(address user) external {
        require(msg.sender == tx.origin, "Not EOD");

        _payUpkeep(msg.sender);
        _payUpkeep(user);

        UserStats storage attacker = _userStats[msg.sender];
        UserStats storage defenser = _userStats[msg.sender];
        require(
            attacker.level > 0 && defenser.level > 0,
            "User not registered"
        );

        UserAttackInfo memory attackerInfo = attacker.getUserAttackInfo();
        UserAttackInfo memory defenserInfo = defenser.getUserAttackInfo();

        require(attackerInfo.stamina > 0, "No stamina");
        require(attackerInfo.hp > 0 && defenserInfo.hp > 0, "Dead");

        HitResult result = attackerInfo.attack > defenserInfo.defense
            ? HitResult.WIN
            : (
                attackerInfo.attack < defenserInfo.defense
                    ? HitResult.LOSE
                    : HitResult.DRAW
            );
        uint32 attackPoints = ((
            result == HitResult.WIN
                ? attackerInfo.attack - defenserInfo.defense
                : defenserInfo.defense - attackerInfo.attack
        ) * 200) / (attackerInfo.attack + defenserInfo.defense);

        uint64 damage = attackPoints * 120;
        uint64 loseHp = damage / 10;

        bool attackerDead;
        bool defenserDead;

        if (result == HitResult.WIN) {
            (attackerDead, defenserDead) = _getDamage(
                attacker,
                defenser,
                loseHp,
                damage
            );
            if (attackerDead) {
                result = HitResult.DRAW;
            }
        } else if (result == HitResult.LOSE) {
            (attackerDead, defenserDead) = _getDamage(
                attacker,
                defenser,
                damage,
                loseHp
            );
            if (defenserDead) {
                result = HitResult.DRAW;
            }
        }

        _gainExp(attacker, result == HitResult.WIN, true);
        _gainExp(defenser, result == HitResult.LOSE, false);

        if (result == HitResult.WIN) {
            _takeOpenCredit(user, msg.sender, defenserDead);
        } else if (result == HitResult.LOSE) {
            _takeOpenCredit(msg.sender, user, attackerDead);
        }
        if (attacker.stamina.value > 0) {
            attacker.stamina.value -= 1;
        }
    }

    function _takeOpenCredit(
        address from,
        address to,
        bool full
    ) internal {
        uint256 availableCredit = IBank(bank).openTokenBalance(
            creditToken,
            from
        );

        uint256 creditTaken = full
            ? availableCredit
            : availableCredit.decimalMul(1000);
        if (creditTaken > 0) {
            IBank(bank).transferOpenToken(creditToken, from, to, creditTaken);
        }
    }

    function _getDamage(
        UserStats storage attacker,
        UserStats storage defenser,
        uint64 attackerDamage,
        uint64 defenserDamage
    ) internal returns (bool attackerDead, bool defenserDead) {
        if (attacker.hp > attackerDamage) {
            attacker.hp -= attackerDamage;
        } else {
            attacker.hp = 0;
            attackerDead = true;
        }

        if (defenser.hp > defenserDamage) {
            defenser.hp -= defenserDamage;
        } else {
            defenser.hp = 0;
            defenserDead = true;
        }
    }

    function _gainExp(
        UserStats storage user,
        bool win,
        bool attacker
    ) internal {
        uint128 increasePct = (win ? 500 : 100) +
            (attacker ? levels[user.level].hitXpGainPercentage : 0);

        uint128 newExp = levels[user.level].xpForNextLevel.decimalMul128(
            increasePct
        );
        user.exp += newExp;

        if (user.exp >= levels[user.level].xpForNextLevel) {
            user.exp -= levels[user.level].xpForNextLevel;
            _upgradeUserLevel(user);
        }
    }

    function _increaseUserArmory(
        address user,
        uint256 upkeep,
        uint32 attack,
        uint32 defense
    ) internal {
        UserStats storage myStats = _userStats[user];
        myStats.upkeep += upkeep;
        myStats.armoryAttack += attack;
        myStats.armoryDefense += defense;
    }

    function _decreaseUserArmory(
        address user,
        uint256 upkeep,
        uint32 attack,
        uint32 defense
    ) internal {
        UserStats storage myStats = _userStats[user];
        myStats.upkeep -= upkeep;
        myStats.armoryAttack -= attack;
        myStats.armoryDefense -= defense;
    }

    function _payUpkeep(address user) internal {
        UserStats storage myStats = _userStats[user];
        if (myStats.upkeep == 0) {
            return;
        }

        uint64 unpaidDays = (_getBlockTimestamp() / UPKEEP_PERIOD) -
            myStats.lastUpkeepPaidIndex;
        myStats.lastUpkeepPaidIndex = _getBlockTimestamp() / UPKEEP_PERIOD;
        uint256 totalUpkeepRequired = myStats.unpaidUpkeep +
            (myStats.upkeep * uint256(unpaidDays));
        uint256 availableCredit = IBank(bank).openTokenBalance(
            creditToken,
            user
        );
        if (availableCredit >= totalUpkeepRequired) {
            IBank(bank).transferOpenToken(
                creditToken,
                user,
                address(0),
                totalUpkeepRequired
            );
            myStats.unpaidUpkeep = 0;
        } else {
            IBank(bank).transferOpenToken(
                creditToken,
                user,
                address(0),
                availableCredit
            );
            myStats.unpaidUpkeep = totalUpkeepRequired - availableCredit;
        }
    }

    function _setUserPoints(address user, UserPoints calldata points) internal {
        uint32 totalPoints = levels[_userStats[user].level].characterPoints;
        require(
            points.hp +
                points.attack +
                points.defense +
                points.energy +
                points.stamina ==
                totalPoints,
            "invalid points!"
        );
        require(
            points.hp > 0 &&
                points.attack > 0 &&
                points.defense > 0 &&
                points.energy > 0 &&
                points.stamina > 0,
            "zero points!"
        );

        userPoints[user] = points;

        emit UserPointSet(user, points);
    }

    function _upgradeUserLevel(UserStats storage myStats) internal {
        myStats.level += 1;
        myStats.techPoints += techPointsIncrementPerLevel;
        if (levels.length == myStats.level) {
            LevelStats memory newLevel = levels.generateNewLevel();
            levels.push(newLevel);
        }

        uint32 points = levels[myStats.level].characterPoints;

        myStats.hp = uint64(points) * 250;
        myStats.attack = points;
        myStats.defense = points;
        myStats.energy.maxValue = uint64(points) * 100;
        myStats.energy.value = myStats.energy.maxValue;
        myStats.energy.lastUpdatedTime = _getBlockTimestamp();
        myStats.stamina.maxValue = uint64(points) / 5;
        myStats.stamina.value = myStats.stamina.maxValue;
        myStats.stamina.lastUpdatedTime = _getBlockTimestamp();
    }

    function getUserStats(address user)
        external
        view
        override
        returns (UserStats memory)
    {
        return _userStats[user];
    }

    function _getBlockTimestamp() internal view returns (uint64) {
        return uint64(block.timestamp);
    }

    function setArmoryNft(address armoryNft_) external onlyOwner {
        require(armoryNft_ != address(0), "ArmoryNFT cannot be zero");

        armoryNft = armoryNft_;

        emit ArmoryNftSet(armoryNft_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct LevelStats {
    uint32 level;
    uint32 characterPoints;
    uint32 hitXpGainPercentage;
    uint128 xpForNextLevel;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TimeIncreaseValue {
    uint64 value;
    uint64 lastUpdatedTime;
    uint64 maxValue;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct UserAttackInfo {
    uint64 hp;
    uint64 energy;
    uint64 stamina;
    uint32 attack;
    uint32 defense;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct UserPoints {
    uint32 hp;
    uint32 attack;
    uint32 defense;
    uint32 energy;
    uint32 stamina;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TimeIncreaseValue.sol";

struct UserStats {
    TimeIncreaseValue energy;
    TimeIncreaseValue stamina;
    uint32 techPoints;
    uint64 hp;
    uint32 level;
    uint64 lastUpkeepPaidIndex;
    uint32 attack;
    uint32 armoryAttack;
    uint32 defense;
    uint32 armoryDefense;
    uint32 alliance;
    uint128 exp;
    uint256 upkeep;
    uint256 unpaidUpkeep;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArmoryNft {
    function mintArmory(
        address user,
        uint256 id,
        uint256 amount
    )
        external
        returns (
            uint256,
            uint256,
            uint32,
            uint32
        );

    function burnArmory(
        address user,
        uint256 id,
        uint256 amount
    )
        external
        returns (
            uint256,
            uint256,
            uint32,
            uint32
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBank {
    function cryptoClysm() external view returns (address);

    function creditToken() external view returns (address);

    function openTokenBalance(address token, address user)
        external
        view
        returns (uint256);

    function transferOpenToken(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IArmoryNft.sol";
import "./ITreasury.sol";
import "../datatypes/UserStats.sol";

interface ICryptoClysm {
    function getUserStats(address user)
        external
        view
        returns (UserStats memory);

    function payUpkeep(address user) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury {
    function transferToken(
        address token,
        address receipient,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DecimalMath {
    uint32 constant DENOMINATOR = 10000;

    function decimalMul32(uint32 x, uint32 y) internal pure returns (uint32) {
        return (x * y) / DENOMINATOR;
    }

    function decimalMul128(uint128 x, uint128 y)
        internal
        pure
        returns (uint128)
    {
        return (x * y) / uint128(DENOMINATOR);
    }

    function decimalMul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y) / uint256(DENOMINATOR);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../datatypes/TimeIncreaseValue.sol";
import "./DecimalMath.sol";

library EnergyLibrary {
    // Increase 1 stamina every 2 minutes
    uint64 constant ENERGY_UPDATE_DURATION = 5 minutes;
    uint64 constant ENERGY_INCREASE_PERCENTAGE = 10; // 10%

    function updateEnergy(TimeIncreaseValue storage energy) internal {
        require(energy.maxValue > 0, "No energy");

        uint64 timePassed = uint64(block.timestamp) - energy.lastUpdatedTime;
        uint64 ticks = timePassed / ENERGY_UPDATE_DURATION;
        uint64 newValue = energy.value +
            (energy.maxValue * ticks * ENERGY_INCREASE_PERCENTAGE) /
            100;
        energy.value = newValue > energy.maxValue ? energy.maxValue : newValue;
        energy.lastUpdatedTime =
            energy.lastUpdatedTime +
            ticks *
            ENERGY_UPDATE_DURATION;
    }

    function getEnergy(TimeIncreaseValue memory energy)
        internal
        view
        returns (uint64)
    {
        if (energy.maxValue == 0) {
            return 0;
        }

        uint64 timePassed = uint64(block.timestamp) - energy.lastUpdatedTime;
        uint64 ticks = timePassed / ENERGY_UPDATE_DURATION;
        uint64 newValue = energy.value +
            (energy.maxValue * ticks * ENERGY_INCREASE_PERCENTAGE) /
            100;

        return newValue > energy.maxValue ? energy.maxValue : newValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../datatypes/LevelStats.sol";
import "./DecimalMath.sol";

library Level {
    using DecimalMath for uint32;
    using DecimalMath for uint128;

    uint32 constant pointsUpgradeMultiplier = 10045;

    function generateNewLevel(LevelStats[] memory levels)
        internal
        pure
        returns (LevelStats memory)
    {
        require(levels.length > 0, "!initialized");
        if (levels.length == 1) {
            return firstLevelStats();
        } else {
            LevelStats memory lastLevel = levels[levels.length - 1];
            uint32 newLevel = lastLevel.level + 1;
            require(uint256(newLevel) == levels.length + 1, "level overflow");
            return
                LevelStats({
                    level: newLevel,
                    characterPoints: lastLevel.characterPoints.decimalMul32(
                        pointsUpgradeMultiplier
                    ),
                    xpForNextLevel: lastLevel.xpForNextLevel.decimalMul128(
                        levelMultiplier(newLevel)
                    ),
                    hitXpGainPercentage: hitXpGainPercentage(newLevel)
                });
        }
    }

    function firstLevelStats() internal pure returns (LevelStats memory) {
        return
            LevelStats({
                level: 1,
                characterPoints: 20,
                xpForNextLevel: 100,
                hitXpGainPercentage: hitXpGainPercentage(1)
            });
    }

    function levelMultiplier(uint32 level) internal pure returns (uint128) {
        if (level < 10) {
            return 15000;
        } else if (level == 10) {
            return 13000;
        } else if (level < 39) {
            return 11000;
        } else if (level < 79) {
            return 10500;
        } else {
            return 10100;
        }
    }

    function hitXpGainPercentage(uint32 level) internal pure returns (uint32) {
        if (level < 20) {
            return 500;
        } else if (level < 40) {
            return 300;
        } else if (level < 80) {
            return 200;
        } else {
            return 100;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../datatypes/TimeIncreaseValue.sol";
import "./DecimalMath.sol";

library StaminaLibrary {
    // Increase 1 stamina every 2 minutes
    uint64 constant STAMINA_UPDATE_DURATION = 2 minutes;
    uint64 constant STAMINA_INCREASE = 1;

    function updateStamina(TimeIncreaseValue storage stamina) internal {
        require(stamina.maxValue > 0, "No stamina");

        uint64 timePassed = uint64(block.timestamp) - stamina.lastUpdatedTime;
        uint64 ticks = timePassed / STAMINA_UPDATE_DURATION;
        uint64 newValue = stamina.value + ticks * STAMINA_INCREASE;
        stamina.value = newValue > stamina.maxValue
            ? stamina.maxValue
            : newValue;
        stamina.lastUpdatedTime =
            stamina.lastUpdatedTime +
            ticks *
            STAMINA_UPDATE_DURATION;
    }

    function getStamina(TimeIncreaseValue memory stamina)
        internal
        view
        returns (uint64)
    {
        if (stamina.maxValue == 0) {
            return 0;
        }

        uint64 timePassed = uint64(block.timestamp) - stamina.lastUpdatedTime;
        uint64 ticks = timePassed / STAMINA_UPDATE_DURATION;
        uint64 newValue = stamina.value + ticks;

        return newValue > stamina.maxValue ? stamina.maxValue : newValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../datatypes/UserStats.sol";
import "../datatypes/UserAttackInfo.sol";
import "../datatypes/TimeIncreaseValue.sol";
import "./StaminaLibrary.sol";
import "./EnergyLibrary.sol";

library UserLibrary {
    using StaminaLibrary for TimeIncreaseValue;
    using EnergyLibrary for TimeIncreaseValue;

    function getUserAttackInfo(UserStats storage userStats)
        internal
        returns (UserAttackInfo memory)
    {
        userStats.stamina.updateStamina();
        userStats.energy.updateEnergy();

        return
            UserAttackInfo({
                hp: userStats.hp,
                energy: userStats.energy.value,
                stamina: userStats.stamina.value,
                attack: (
                    userStats.unpaidUpkeep > 0
                        ? userStats.attack
                        : userStats.attack + userStats.armoryAttack
                ) + userStats.alliance / 10,
                defense: (
                    userStats.unpaidUpkeep > 0
                        ? userStats.defense
                        : userStats.defense + userStats.armoryDefense
                ) + userStats.alliance / 10
            });
    }
}