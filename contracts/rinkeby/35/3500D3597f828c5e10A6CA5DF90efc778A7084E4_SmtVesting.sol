//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SmtVesting is Ownable {
    using SafeMath for uint256;

    /// @dev ERC20 basic token contract being held
    IERC20 public token;

    /// @dev Block number where the contract is deployed
    uint256 public immutable initialBlock;

    uint256 private constant ONE = 10**18;
    uint256 private constant DAY = 5760; // 24*60*60/15
    uint256 private constant WEEK = 40320; // 7*24*60*60/15
    uint256 private constant YEAR = 2102400; // 365*24*60*60/15
    uint256 private constant WEEKS_IN_YEAR = 52;
    uint256 private constant INITAL_ANUAL_DIST = 62500000 * ONE;
    uint256 private constant WEEK_BATCH_DIV = 45890222137623526749; //(0.995^0 + 0.995^1 ... + 0.995^51) = 45,894396603

    /// @dev First year comunity batch has been claimed
    bool public firstYCBClaimed;

    /// @dev Block number where last claim was executed
    uint256 public lastClaimedBlock;

    /// @dev Emitted when `owner` claims.
    event Claim(address indexed owner, uint256 amount);

    /**
     * @dev Sets the value for {initialBloc}.
     *
     * Sets ownership to the given `_owner`.
     *
     */
    constructor() {
        initialBlock = block.number;
        lastClaimedBlock = block.number;
    }

    /**
     * @dev Sets the value for `token`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_token` can't be zero address
     * - `token` should not be already set
     *
     */
    function setToken(address _token) external onlyOwner {
        require(_token != address(0), "token is the zero address");
        require(address(token) == address(0), "token is already set");
        token = IERC20(_token);
    }

    /**
     * @dev Claims next token batch.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     *
     */
    function claim() external onlyOwner {
        uint256 amount = claimableAmount();
        lastClaimedBlock = block.number;
        firstYCBClaimed = true;
        emit Claim(owner(), amount);
        token.transfer(_msgSender(), amount);
    }

    /**
     * @dev Gets the next token batch to be claimed since the last claim until current block.
     *
     */
    function claimableAmount() public view returns (uint256) {
        return _claimableAmount(firstYCBClaimed, block.number, lastClaimedBlock);
    }

    /**
     * @dev Gets the next token batch to be claimed since the last claim until current block.
     *
     */
    function _claimableAmount(
        bool isFirstYCBClaimed,
        uint256 blockNumber,
        uint256 lCBlock
    ) internal view returns (uint256) {
        uint256 total = 0;
        uint256 lastClaimedBlockYear = blockYear(lCBlock);
        uint256 currentYear = blockYear(blockNumber);

        total += accumulateAnualComBatch(isFirstYCBClaimed, blockNumber, lCBlock);

        if (lastClaimedBlockYear < currentYear) {
            total += accumulateFromPastYears(blockNumber, lCBlock);
        } else {
            total += accumulateCurrentYear(blockNumber, lCBlock);
        }

        return total;
    }

    /**
     * @dev Accumulates non claimed Anual Comunity Batches.
     *
     */
    function accumulateAnualComBatch(
        bool isFirstYCBClaimed,
        uint256 blockNumber,
        uint256 lCBlock
    ) public view returns (uint256) {
        uint256 acc = 0;
        uint256 currentYear = blockYear(blockNumber);
        uint256 lastClaimedBlockYear = blockYear(lCBlock);
        if (!isFirstYCBClaimed || lastClaimedBlockYear < currentYear) {
            uint256 from = isFirstYCBClaimed ? lastClaimedBlockYear + 1 : 0;
            for (uint256 y = from; y <= currentYear; y++) {
                acc += yearAnualCommunityBatch(y);
            }
        }

        return acc;
    }

    /**
     * @dev Accumulates non claimed Weekly Release Batches from a week in a previous year.
     *
     */
    function accumulateFromPastYears(uint256 blockNumber, uint256 lCBlock) public view returns (uint256) {
        uint256 acc = 0;
        uint256 lastClaimedBlockYear = blockYear(lCBlock);
        uint256 lastClaimedBlockWeek = blockWeek(lCBlock);
        uint256 currentYear = blockYear(blockNumber);
        uint256 currentWeek = blockWeek(blockNumber);

        // add what remains to claim from the claimed week
        acc += getWeekPortionFromBlock(lCBlock);

        {
            uint256 ww;
            uint256 yy;
            for (ww = lastClaimedBlockWeek + 1; ww < WEEKS_IN_YEAR; ww++) {
                acc += yearWeekRelaseBatch(lastClaimedBlockYear, ww);
            }

            // add complete weeks years until current year
            for (yy = lastClaimedBlockYear + 1; yy < currentYear; yy++) {
                for (ww = 0; ww < WEEKS_IN_YEAR; ww++) {
                    acc += yearWeekRelaseBatch(yy, ww);
                }
            }

            // current year until current week
            for (ww = 0; ww < currentWeek; ww++) {
                acc += yearWeekRelaseBatch(currentYear, ww);
            }
        }

        // portion of current week
        acc += getWeekPortionUntilBlock(blockNumber);

        return acc;
    }

    /**
     * @dev Accumulates non claimed Weekly Release Batches from a week in the current year.
     *
     */
    function accumulateCurrentYear(uint256 blockNumber, uint256 lCBlock) public view returns (uint256) {
        uint256 acc = 0;
        uint256 lastClaimedBlockWeek = blockWeek(lCBlock);
        uint256 currentYear = blockYear(blockNumber);
        uint256 currentWeek = blockWeek(blockNumber);

        if (lastClaimedBlockWeek < currentWeek) {
            // add what remains to claim from the claimed week
            acc += getWeekPortionFromBlock(lCBlock);

            {
                uint256 ww;
                // add remaining weeks until current
                for (ww = lastClaimedBlockWeek + 1; ww < currentWeek; ww++) {
                    acc += yearWeekRelaseBatch(currentYear, ww);
                }
            }
        }

        // portion of current week
        acc += getWeekPortionUntilBlock(blockNumber);

        return acc;
    }

    // Utility Functions

    /**
     * @dev Calculates the portion of Weekly Release Batch from a block to the end of that block's week.
     *
     */
    function getWeekPortionFromBlock(uint256 blockNumber) internal view returns (uint256) {
        uint256 blockNumberYear = blockYear(blockNumber);
        uint256 blockNumberWeek = blockWeek(blockNumber);

        uint256 blockNumberWeekBatch = yearWeekRelaseBatch(blockNumberYear, blockNumberWeek);
        uint256 weekLastBlock = yearWeekLastBlock(blockNumberYear, blockNumberWeek);
        return blockNumberWeekBatch.mul(weekLastBlock.sub(blockNumber)).div(WEEK);
    }

    /**
     * @dev Calculates the portion of Weekly Release Batch from the start of a block's week the block.
     *
     */
    function getWeekPortionUntilBlock(uint256 blockNumber) internal view returns (uint256) {
        uint256 blockNumberYear = blockYear(blockNumber);
        uint256 blockNumberWeek = blockWeek(blockNumber);

        uint256 blockNumberWeekBatch = yearWeekRelaseBatch(blockNumberYear, blockNumberWeek);
        uint256 weekFirsBlock = yearWeekFirstBlock(blockNumberYear, blockNumberWeek);
        return blockNumberWeekBatch.mul(blockNumber.sub(weekFirsBlock)).div(WEEK);
    }

    /**
     * @dev Calculates the Total Anual Distribution for a given year.
     *
     * TAD = (62500000) * (1 - 0.25)^y
     *
     * @param year Year zero based.
     */
    function yearAnualDistribution(uint256 year) public pure returns (uint256) {
        // 25% of year reduction => (1-0.25) = 0.75 = 3/4
        uint256 reductionN = 3**year;
        uint256 reductionD = 4**year;
        return INITAL_ANUAL_DIST.mul(reductionN).div(reductionD);
    }

    /**
     * @dev Calculates the Anual Comunity Batch for a given year.
     *
     * 20% * yearAnualDistribution
     *
     * @param year Year zero based.
     */
    function yearAnualCommunityBatch(uint256 year) public pure returns (uint256) {
        uint256 totalAnnualDistribution = yearAnualDistribution(year);
        return totalAnnualDistribution.mul(200).div(1000);
    }

    /**
     * @dev Calculates the Anual Weekly Batch for a given year.
     *
     * 80% * yearAnualDistribution
     *
     * @param year Year zero based.
     */
    function yearAnualWeeklyBatch(uint256 year) public pure returns (uint256) {
        uint256 yearAC = yearAnualCommunityBatch(year);
        return yearAnualDistribution(year).sub(yearAC);
    }

    /**
     * @dev Calculates weekly reduction percentage for a given week.
     *
     * WRP = (1 - 0.5)^w
     *
     * @param week Week zero based.
     */
    function weeklyRedPerc(uint256 week) internal pure returns (uint256) {
        uint256 reductionPerc = ONE;
        uint256 nineNineFive = ONE - 5000000000000000; // 1 - 0.5
        for (uint256 i = 0; i < week; i++) {
            reductionPerc = nineNineFive.mul(reductionPerc).div(ONE);
        }

        return reductionPerc;
    }

    /**
     * @dev Calculates W1 weekly release batch amount for a given year.
     *
     * yearAnualWeeklyBatch / (0.995^0 + 0.995^1 ... + 0.995^51)
     *
     * @param year Year zero based.
     */
    function yearFrontWeightedWRB(uint256 year) internal pure returns (uint256) {
        uint256 totalWeeklyAnualBatch = yearAnualWeeklyBatch(year);

        return totalWeeklyAnualBatch.mul(ONE).div(WEEK_BATCH_DIV);
    }

    /**
     * @dev Calculates the Weekly Release Batch amount for the given year and week.
     *
     * @param year Year zero based.
     * @param week Week zero based.
     */
    function yearWeekRelaseBatch(uint256 year, uint256 week) public pure returns (uint256) {
        uint256 yearW1 = yearFrontWeightedWRB(year);
        uint256 weeklyRedPercentage = weeklyRedPerc(week);

        return yearW1.mul(weeklyRedPercentage).div(ONE);
    }

    /**
     * @dev Gets first block of the given year.
     *
     * @param year Year zero based.
     */
    function yearFirstBlock(uint256 year) internal view returns (uint256) {
        return initialBlock.add(YEAR.mul(year));
    }

    /**
     * @dev Gets first block of the given year and week.
     *
     * @param year Year zero based.
     * @param week Week zero based.
     */
    function yearWeekFirstBlock(uint256 year, uint256 week) internal view returns (uint256) {
        uint256 yFB = yearFirstBlock(year);
        return yFB.add(WEEK.mul(week));
    }

    /**
     * @dev Gets last block of the given year and week.
     *
     * @param year Year zero based.
     * @param week Week zero based.
     */
    function yearWeekLastBlock(uint256 year, uint256 week) internal view returns (uint256) {
        return yearWeekFirstBlock(year, week + 1);
    }

    /**
     * @dev Gets the year of a given block.
     *
     * @param blockNumber Block number.
     */
    function blockYear(uint256 blockNumber) internal view returns (uint256) {
        return (blockNumber.sub(initialBlock)).div(YEAR);
    }

    /**
     * @dev Gets the week of a given block within the block year.
     *
     * @param blockNumber Block number.
     */
    function blockWeek(uint256 blockNumber) internal view returns (uint256) {
        return (blockNumber.sub(yearFirstBlock(blockYear(blockNumber)))).div(WEEK);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
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
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
library SafeMath {
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

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}