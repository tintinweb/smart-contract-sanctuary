// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./IClam.sol";
import "../farming/IGemLocker.sol";
import "../IGemToken.sol";
import "../RNG/IRNG.sol";

contract ClamShop is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    IGemLocker public gemLocker;
    IGemToken public gemToken;
    IClam public clam;
    IRNG public rng;
    address public treasury;
    uint256 public price;
    uint256 public priceNextWeek;
    uint256 public burnRate;
    uint256 public clamsPerWeek;
    uint256 public mintedThisWeek;
    uint256 public lastWeeklyTimeStamp;
    uint256 public soldOutTimeStamp;

    mapping(address => bytes32) public rngRequestHashForFarmedClam;

    uint256 public clamsPerWeekCheckerNum;
    uint256 public clamsPerWeekSubtractNum;

    event ClamBought(address indexed purchaser, uint256 price, bytes32 requestHash);
    event ClamBoughtWithVestedToken(uint256 price, uint256 vestedUsed);
    event ClamCollected(address indexed purchaser, uint256 tokenId);
    event ClamPriceUpdated(uint256 price);
    event ClamPriceSet(uint256 price);
    event BurnRateSet(uint256 burnRate);
    event ClamsPerWeekSet(uint256 clamsPerWeek);
    event ClamsPerWeekSubtractNumSet(uint256 newClamsPerWeekSubtractNum);
    event ClamsPerWeekCheckerNumSet(uint256 newClamsPerWeekCheckerNum);
    event TreasurySet(address treasury);
    event RNGSet(address rngContractAddress);
    event RNGRequestHashSetToZero(address account);

    modifier buyingIsPossible() {
        require(mintedThisWeek < clamsPerWeek, "ClamShop: weekly mint allowance reached");
        require(
            rngRequestHashForFarmedClam[msg.sender] == bytes32(0),
            "ClamShop: user has outstanding clam to collect. Need to collect first before buying another one."
        );
        _;
    }

    function initialize(
        address _clam,
        address _gemLocker,
        address _gemToken,
        address _rng,
        address _treasury,
        uint256 _price,
        uint256 _burnRate
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        require(
            _clam != address(0) && _gemToken != address(0) && _rng != address(0) && _treasury != address(0),
            "ClamShop: empty addresses"
        );
        require(_burnRate <= 100, "ClamShop: burn rate larger than 100");
        clam = IClam(_clam); // add minter role for this in clam contract
        gemLocker = IGemLocker(_gemLocker);
        gemToken = IGemToken(_gemToken);
        rng = IRNG(_rng); // add bonafide role for this in rng contract
        treasury = _treasury;
        price = _price;
        clamsPerWeek = 250;
        burnRate = _burnRate;
        lastWeeklyTimeStamp = block.timestamp;
    }

    function isCurrentWeek() external view returns (bool) {
        return block.timestamp < lastWeeklyTimeStamp.add(1 weeks);
    }

    function canUnlockGemVestedAmount(address _user) external view returns (uint256) {
        return gemLocker.totalLockedRewards(_user);
    }

    /**
     * @dev get current Clam price
     */
    function getUpdatedPrice() public returns (uint256) {
        uint256 currentTimeStamp = block.timestamp;

        uint256 secondsSinceWeekStart = currentTimeStamp.sub(lastWeeklyTimeStamp);

        if (secondsSinceWeekStart < 1 weeks) {
            return price;
        }

        uint256 updatedPrice = updatePrice();
        return updatedPrice;
    }

    function updatePrice() private returns (uint256) {
        if (soldOutTimeStamp != 0) {
            // sold out quick, raise the price
            uint256 secondsUntilSoldOut = soldOutTimeStamp.sub(lastWeeklyTimeStamp);
            uint256 halfAWeek = 3 days + 12 hours;

            if (secondsUntilSoldOut <= halfAWeek) {
                priceNextWeek = price.mul(2);
            } else {
                uint256 halfWeekOverFlowWithPrecisionAdjust = secondsUntilSoldOut.sub(halfAWeek).mul(100e18);
                uint256 timeRatio = halfWeekOverFlowWithPrecisionAdjust.div(halfAWeek);
                uint256 mulByPriceAndReadjust = price.mul(timeRatio).div(100e18);
                priceNextWeek = price.add(mulByPriceAndReadjust);
            }

            soldOutTimeStamp = 0;
        } else {
            // only fraction sold, lower the price
            uint256 unMintedRatio = clamsPerWeek.mul(100).sub(mintedThisWeek.mul(100)).div(clamsPerWeek);
            uint256 priceReduction = unMintedRatio <= 50 ? unMintedRatio : 50;
            priceNextWeek = price.sub(price.mul(priceReduction).div(100));
        }

        price = priceNextWeek;
        mintedThisWeek = 0;
        lastWeeklyTimeStamp = lastWeeklyTimeStamp.add(1 weeks);

        if (clamsPerWeek > clamsPerWeekCheckerNum) {
            clamsPerWeek = uint256(clamsPerWeek.sub(clamsPerWeekSubtractNum));
        }

        emit ClamPriceUpdated(price);

        return price;
    }

    function buyClamWithVestedTokens() external payable buyingIsPossible nonReentrant {
        uint256 vestedTokens = gemLocker.totalLockedRewards(msg.sender);
        uint256 currentPrice = getUpdatedPrice();
        uint256 unlockedVested = vestedTokens >= currentPrice ? currentPrice : vestedTokens;
        uint256 getFromUser = currentPrice.sub(unlockedVested);
        if (getFromUser > 0) {
            gemToken.transferFrom(msg.sender, address(this), getFromUser);
            gemLocker.forceUnlock(msg.sender, vestedTokens);
        } else {
            gemLocker.forceUnlock(msg.sender, currentPrice);
        }
        _finishTransaction(currentPrice);
        emit ClamBoughtWithVestedToken(currentPrice, unlockedVested);
    }

    /**
     * @dev Main continuous Clam NFT mint function. Mints Clams for $GEM
     * Able to buy one clam at a time.
     */
    function buyClam() external payable buyingIsPossible nonReentrant {
        uint256 currentPrice = getUpdatedPrice();
        gemToken.transferFrom(msg.sender, address(this), currentPrice);
        _finishTransaction(currentPrice);
    }

    function _finishTransaction(uint256 currentPrice) internal {
        uint256 burnAmount = currentPrice.mul(burnRate).div(100);
        gemToken.burn(burnAmount);

        uint256 remainingBalance = gemToken.balanceOf(address(this));
        gemToken.transfer(treasury, remainingBalance);

        uint256 oracleFee = rng.getOracleFee();
        require(msg.value >= oracleFee, "ClamShop: Insufficient BNB sent");

        bytes32 hashRequest = rng.requestRNG{value: oracleFee}(msg.sender);
        rngRequestHashForFarmedClam[msg.sender] = hashRequest;

        emit ClamBought(msg.sender, currentPrice, hashRequest);

        mintedThisWeek = uint256(mintedThisWeek.add(1));

        if (mintedThisWeek == clamsPerWeek) {
            soldOutTimeStamp = block.timestamp;
        }

        getUpdatedPrice(); // ensure price is updated after purchase
    }

    /// @notice collect your Clam
    function collectClam() external {
        require(
            rngRequestHashForFarmedClam[msg.sender] != bytes32(0),
            "ClamShop: user has no purchased clam to collect"
        );

        bytes32 requestHash = rngRequestHashForFarmedClam[msg.sender];
        rngRequestHashForFarmedClam[msg.sender] = bytes32(0); // zero

        uint256 rand = rng.getRNGFromHashRequest(requestHash);
        require(rand != uint256(0), "ClamShop: cannot collect clam. RNG has not been received yet");

        clam.mint(msg.sender, rand, false); // isMaxima = false

        emit ClamCollected(msg.sender, rand);
    }

    // owner mode
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;

        emit ClamPriceSet(_price);
    }

    function setRng(address _rng) external onlyOwner {
        rng = IRNG(_rng);

        emit RNGSet(_rng);
    }

    function setBurnRate(uint256 _burnRate) external onlyOwner {
        require(_burnRate <= 100, "ClamShop: burn rate larger than 100");

        burnRate = _burnRate;
        emit BurnRateSet(_burnRate);
    }

    function setClamsPerWeek(uint256 _clamsPerWeek) external onlyOwner {
        clamsPerWeek = _clamsPerWeek;

        emit ClamsPerWeekSet(_clamsPerWeek);
    }

    function setClamsPerWeekCheckerNum(uint256 _clamsPerWeekCheckerNum) external onlyOwner {
        clamsPerWeekCheckerNum = _clamsPerWeekCheckerNum;

        emit ClamsPerWeekCheckerNumSet(_clamsPerWeekCheckerNum);
    }

    function setClamsPerWeekSubtractNum(uint256 _clamsPerWeekSubtractNum) external onlyOwner {
        clamsPerWeekSubtractNum = _clamsPerWeekSubtractNum;

        emit ClamsPerWeekSubtractNumSet(_clamsPerWeekSubtractNum);
    }

    /// @dev used for when RNG has failed to deliver
    function setRngRequestHashForFarmedClamToZero(address _account) external onlyOwner {
        rngRequestHashForFarmedClam[_account] = 0x0000000000000000000000000000000000000000000000000000000000000000;

        emit RNGRequestHashSetToZero(_account);
    }

    function setTreasuryAddress(address _treasury) external onlyOwner {
        require(_treasury != address(0), "ClamShop: empty address");

        treasury = _treasury;

        emit TreasurySet(_treasury);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721EnumerableUpgradeable.sol";

interface IClam is IERC721EnumerableUpgradeable {
    struct ClamInfo {
        bool isMaxima;
        bool isAlive;
        uint256 birthTime;
        uint256 pearlsProduced;
        uint256 pearlProductionDelay;
        uint256 pearlProductionCapacity;
        uint256 dna;
        uint256 pearlProductionStart;
        uint256[] producedPearlIds;
        uint256 gemBoost;
    }

    function mint(
        address,
        uint256,
        bool
    ) external;

    function mintMaxima(address, uint256) external;

    function mintCommunityReward(
        address,
        uint256,
        bool
    ) external;

    function canCurrentlyProducePearl(uint256) external returns (bool);

    function canStillProducePearls(uint256) external view returns (bool);

    function incrementPearlCounter(uint256, uint256) external;

    function setNewProductionDelay(uint256, uint256) external;

    function getPearlProductionDelay(uint256) external view returns (uint256);

    function setNewProductionStart(uint256, uint256) external;

    function getPearlProductionStart(uint256) external view returns (uint256);

    function getClamData(uint256) external view returns (ClamInfo memory);

    function getPearlTraits(uint256) external view returns (uint8[10] memory, uint8[6] memory);

    function burn(uint256) external;

    function calculateBonusRewards(
        uint256 baseGemRewards,
        uint256 size,
        uint256 lifespan,
        uint256 rarityValue
    ) external pure returns (uint256);

    function currentBaseGemRewards() external returns (uint256);

    function setCurrentBaseGemRewards(uint256 baseGemRewards) external;

    event ClamHarvested(address user, uint256 clamId);
    event IncubationTimeSet(uint256 incubationTime);
    event ProductionDelaySet(uint256 clamId);
    event ProductionStartSet(uint256 clamId, uint256 timestamp);
    event PearlCounterIncremented(uint256 clamId);
    event ClamMaximaMonthlyCapSet(uint256 newCap);
    event DNADecoderSet(address newDnaDecoder);
    event PriceForShellSet(uint256 clamPriceForShell, uint256 pearlPriceForShell);
    event ProductionCapacitySet(uint256 minPearlProductionCapacity, uint256 maxPearlProductionCapacity);
    event ProductionDelayRangeSet(uint256 minPearlProductionDelay, uint256 maxPearlProductionDelay);
    event CommunityRewardedClam(address recipient, uint256 dna);
    event ClamMaximaMinted(address recipient, uint256 dna);
    event SetCurrentBaseGemRewards(uint256 baseGemRewards);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IGemLocker {
    /* View funcitons */
    function getDay() external view returns (uint256);

    function lockedFarmingRewardsLength(address _account) external view returns (uint256);

    function clamsStakedPerUserLength(address user) external view returns (uint256);

    function clamIdsStakedPerUserAt(address _account, uint256 _index) external view returns (uint256);

    function pearlsBurnedPerUserLength(address _account) external view returns (uint256);

    function pearlIdsBurnedPerUserAt(address _account, uint256 _index) external view returns (uint256);

    function totalLockedRewards(address _account) external view returns (uint256);

    function pendingFarmingRewards(address _account) external view returns (uint256);

    function pendingClamRewards(address _account) external view returns (uint256);

    function pendingPearlRewards(address _account) external view returns (uint256);

    function canUnlockAmount(address _account) external view returns (uint256);

    /* Mutative funcitons */
    function lockFarmingRewards(address _account, uint256 _amount) external;

    function lockClamRewards(
        address _account,
        uint256 _amount,
        uint256 _clamId
    ) external;

    function lockPearlRewards(
        address _account,
        uint256 _amount,
        uint256 _pearlId
    ) external;

    function unlockRewards(address _account) external;

    function depositStake(address _account, uint256 _deposited) external;

    function withdrawStake(
        address _account,
        uint256 _totalBalance,
        uint256 _withdrawn
    ) external;

    function forceUnlock(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./libs/IBEP20.sol";

interface IGemToken is IBEP20 {
    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IRNG {
    function getOracleFee() external view returns (uint256);

    function requestRNG(address) external payable returns (bytes32);

    function getRNGFromHashRequest(bytes32) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     */
    function mint(address beneficiary, uint256 amount) external returns (bool);

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
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address, uint256) external returns (bool);
}