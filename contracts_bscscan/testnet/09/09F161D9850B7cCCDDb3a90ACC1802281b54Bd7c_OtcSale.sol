// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDCIP {
    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function decimals() external pure returns (uint8);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    constructor() {
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Tooling for timepoints, timers and delays
 */
library Timers {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4; // 0.8+ protects us against int overflows, no need for safemath

import './libraries/ownable.sol';
import './interfaces/dcip.sol';
import './libraries/timers.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';

// Stores sum of all purchases made within cooldown period.
struct PurchaseInfo {
    Timers.BlockNumber cooldownEnd;
    uint256 totalBoughtInBNB;
    bool isInitialized;
}

contract OtcSale is Ownable {
    using SafeCast for uint256;
    using Timers for Timers.BlockNumber;

    IDCIP public token;
    uint256 public totalBNBEarned;
    uint256 public minimumDepositBNBAmount = 1 wei;
    uint256 public maximumDepositBNBAmount = 100000000 ether;
    uint256 public tokenRate;
    address private updater;

    mapping(address => bool) public blacklistedWallets;
    mapping(address => PurchaseInfo) public purchaseInfoCollection;
    uint256 public periodicalPurchaseLimit; // Within cooldown
    uint64 public blocksPerPeriod;

    constructor(
        IDCIP _tokenAddress,
        address _updater,
        uint256 _periodicalPurchaseLimit,
        uint64 _blocksPerPeriod
    ) {
        token = _tokenAddress;
        tokenRate = 999999999999999;
        periodicalPurchaseLimit = _periodicalPurchaseLimit;
        blocksPerPeriod = _blocksPerPeriod;
        updater = _updater;
    }

    function setCooldownPeriod(uint64 blocks) public onlyOwner returns (uint64) {
        blocksPerPeriod = blocks;
        return blocksPerPeriod;
    }

    function setPeriodicalPurchaseLimit(uint256 bnb) public onlyOwner returns (uint256) {
        periodicalPurchaseLimit = bnb;
        return bnb;
    }

    function buy() external payable returns (bool) {
        require(!blacklistedWallets[msg.sender], 'You are banned from the otcSale');
        require(tokenRate > 1, 'Invalid tokenPrice');
        require(
            msg.value >= minimumDepositBNBAmount && msg.value <= maximumDepositBNBAmount,
            'Purchase is too small or big'
        );
        require(
            !isPeriodicalPurchaseOverLimit(msg.sender, msg.value),
            'This purchase would exceed the allowed limits. Wait for the cooldown period to expire'
        );

        uint256 tokenAmount = ((msg.value * tokenRate) / ((10**18))) * (10**9);

        require(tokenAmount > 0, 'You need to buy at least 1 DCIP');

        require(token.balanceOf(address(this)) >= tokenAmount, 'Not enough DCIP available for sale'); // Enough DCIP balance for sale

        // updatePurchaseData(msg.sender, msg.value);

        totalBNBEarned = totalBNBEarned + msg.value;
        token.transfer(msg.sender, tokenAmount);
        emit Bought(msg.sender, tokenAmount);
        return true;
    }

    function updatePurchaseData(address adr, uint256 amount) internal returns (bool) {
        PurchaseInfo storage d = purchaseInfoCollection[adr];
        uint64 currentBlock = block.number.toUint64();
        if (!d.isInitialized || d.cooldownEnd.isExpired()) {
            // (re)create
            d.totalBoughtInBNB = amount;
            d.cooldownEnd = Timers.BlockNumber(currentBlock + blocksPerPeriod);
            d.isInitialized = true;
            return true;
        } else {
            d.totalBoughtInBNB = d.totalBoughtInBNB + amount;
            d.cooldownEnd = Timers.BlockNumber(currentBlock + blocksPerPeriod);
            return true;
        }
    }

    function isPeriodicalPurchaseOverLimit(address adr, uint256 amount) public view returns (bool) {
        return amount > periodicalPurchaseLimit;

        // PurchaseInfo storage d = purchaseInfoCollection[adr];
        // if (d.cooldownEnd.isExpired()) {
        //     return false; // TODO: What happens here if it is not yet initialized for first buy?
        // } else {
        //     return (d.totalBoughtInBNB + amount > periodicalPurchaseLimit);
        // }
    }

    function getTokenRate() public view returns (uint256) {
        return tokenRate;
    }

    function setUpdateAccount(address _updater) public onlyOwner returns (bool) {
        updater = _updater;
        return true;
    }

    function setTokenPrice(uint256 _rate) public returns (uint256) {
        require(msg.sender == updater, 'Address is unauthorized');
        require(_rate > 0, 'Rate must be higher than 0');
        tokenRate = _rate;
        return tokenRate;
    }

    function blackList(address wallet) public onlyOwner returns (bool) {
        blacklistedWallets[wallet] = true;
        return true;
    }

    function removeFromBlacklist(address wallet) public onlyOwner returns (bool) {
        blacklistedWallets[wallet] = false;
        return true;
    }

    function withdrawDCIP() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function withdrawBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBNBEarnedAmount() external view returns (uint256) {
        return totalBNBEarned;
    }

    event Bought(address indexed user, uint256 amount);
}