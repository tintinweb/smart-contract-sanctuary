/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// File: contracts\SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256)
    {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }

    function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }
}

// File: contracts\DRCRebaser.sol

/* 
   SPDX-License-Identifier: MIT
   https://doggyrebase.co.in
   Copyright 2021
*/

pragma solidity 0.6.6;


interface PancakePairContract {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface DRCTokenInterface {
    //Public functions
    function maxScalingFactor() external view returns (uint256);

    function DRCScalingFactor() external view returns (uint256);

    //rebase permissioned
    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    ) external returns (uint256);
}

contract DRCRebaser {
    using SafeMath for uint256;

    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }

    /// @notice an event emitted when deviationThreshold is changed
    event NewDeviationThreshold(
        uint256 oldDeviationThreshold,
        uint256 newDeviationThreshold
    );

    /// @notice Governance address
    address public gov;

    /// @notice Spreads out getting to the target price
    uint256 public rebaseLag;

    /// @notice Peg target
    uint256 public targetRate;
    uint256 public initialRate;

    // If the current exchange rate is within this fractional percentage from the target, no supply
    // adjustment is performed.
    uint256 public deviationThreshold;

    /// @notice More than this much time must pass between rebase operations.
    uint256 public minRebaseTimeIntervalSec;

    /// @notice Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    /// @notice The rebase window begins this many seconds into the minRebaseTimeInterval period.
    // For example if minRebaseTimeInterval is 24hrs, it represents the time of day in seconds.
    uint256 public rebaseWindowOffsetSec;

    /// @notice The length of the time window where a rebase operation is allowed to execute, in seconds.
    uint256 public rebaseWindowLengthSec;

    /// @notice The number of rebase cycles since inception
    uint256 public epoch;

    uint256 public indexDelta;

    address public DRCAddress;

    address public pancakeDRCBUSDPair;

    mapping(address => bool) public whitelistFrom;

    constructor() public {
        minRebaseTimeIntervalSec = 2 minutes;
        rebaseWindowOffsetSec = 0;

        // Default target rate of 0.000001 BUSD
        initialRate = 10**3;
        targetRate = 2 * initialRate;

        // Default lag of 5
        rebaseLag = 1;

        // 10%
        deviationThreshold = 10;

        // 24 hours
        rebaseWindowLengthSec = 3 minutes;

        epoch = 0;

        pancakeDRCBUSDPair = 0x612d5c95E42927286Ef50f2c5C918c91B40C2276;
        DRCAddress = 0x6fF0f96D2c4C75Aaf51568120f7955Fe4472F587;

        gov = msg.sender;
    }

    function checkIndexDelta() public view returns (uint256) {
        uint256 _exchangeRate = getPrice();

        (uint256 _offPegPerc, bool _positive) = computeOffPegPerc(
            _exchangeRate
        );

        uint256 _indexDelta = _offPegPerc;

        if (_positive) {
            _indexDelta = _indexDelta.div(rebaseLag);
        }
        return _indexDelta;
    }

    function setWhitelistedFrom(address _addr, bool _whitelisted)
        external
        onlyGov
    {
        whitelistFrom[_addr] = _whitelisted;
    }

    function _isWhitelisted(address _from) internal view returns (bool) {
        return whitelistFrom[_from];
    }

    /**
     * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
     *
     * @dev The supply adjustment equals (_totalSupply * DeviationFromTargetRate) / rebaseLag
     *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
     *      and targetRate is 1e18
     */
    function rebase() public {
        // EOA only
        require(msg.sender == tx.origin);
        require(_isWhitelisted(msg.sender));
        // ensure rebasing at correct time
        _inRebaseWindow();

        require(lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) < now);

        // Snap the rebase time to the start of this window.
        lastRebaseTimestampSec = now;

        // get price from Pancake;
        uint256 exchangeRate = getPrice();

        // calculates % change to supply
        (uint256 offPegPerc, bool positive) = computeOffPegPerc(exchangeRate);

        indexDelta = offPegPerc;

        // Apply the Dampening factor for positive rebases
        if (positive) {
            indexDelta = indexDelta.div(rebaseLag);
        }
        // Increase epoch if positive or neutral rebase. Snap nepoch back to 0.
        if (positive || indexDelta == 0) {
            epoch = epoch.add(1);
        }

        // Increase nepoch if price below 10% of peg
        if (!positive) {
            epoch = epoch.add(1);
        }

        DRCTokenInterface DRC = DRCTokenInterface(DRCAddress);

        if (positive) {
            require(
                DRC.DRCScalingFactor().mul(uint256(10**9).add(indexDelta)).div(
                    10**9
                ) < DRC.maxScalingFactor(),
                "new scaling factor will be too big"
            );
        }

        // Positive rebase.
        if (positive) {
            DRC.rebase(epoch, indexDelta, positive);
            assert(DRC.DRCScalingFactor() <= DRC.maxScalingFactor());
        }

        if (!positive) {
            DRC.rebase(epoch, indexDelta, positive);
        }

        targetRate = targetRate + initialRate;
    }

    function getPrice() public view returns (uint256) {
        (uint256 BUSDReserve, uint256 DRCReserve, ) = PancakePairContract(
            pancakeDRCBUSDPair
        ).getReserves();
        uint256 DRCPrice = BUSDReserve.div(DRCReserve);
        return DRCPrice;
    }

    function setDeviationThreshold(uint256 deviationThreshold_)
        external
        onlyGov
    {
        require(deviationThreshold > 0);
        uint256 oldDeviationThreshold = deviationThreshold;
        deviationThreshold = deviationThreshold_;
        emit NewDeviationThreshold(oldDeviationThreshold, deviationThreshold_);
    }

    /**
     * @notice Sets the rebase lag parameter.
               It is used to dampen the applied supply adjustment by 1 / rebaseLag
               If the rebase lag R, equals 1, the smallest value for R, then the full supply
               correction is applied on each rebase cycle.
               If it is greater than 1, then a correction of 1/R of is applied on each rebase.
     * @param rebaseLag_ The new rebase lag parameter.
     */

    function setRebaseLag(uint256 rebaseLag_) external onlyGov {
        require(rebaseLag_ > 0);
        rebaseLag = rebaseLag_;
    }

    /**
     * @notice Sets the targetRate parameter.
     * @param targetRate_ The new target rate parameter.
     */

    function setTargetRate(uint256 targetRate_) external onlyGov {
        require(targetRate_ > 0);
        targetRate = targetRate_;
    }

    /**
     * @notice Sets the parameters which control the timing and frequency of
     *         rebase operations.
     *         a) the minimum time period that must elapse between rebase cycles.
     *         b) the rebase window offset parameter.
     *         c) the rebase window length parameter.
     * @param minRebaseTimeIntervalSec_ More than this much time must pass between rebase
     *        operations, in seconds.
     * @param rebaseWindowOffsetSec_ The number of seconds from the beginning of
              the rebase interval, where the rebase window begins.
     * @param rebaseWindowLengthSec_ The length of the rebase window in seconds.
     */
    function setRebaseTimingParameters(
        uint256 minRebaseTimeIntervalSec_,
        uint256 rebaseWindowOffsetSec_,
        uint256 rebaseWindowLengthSec_
    ) external onlyGov {
        require(minRebaseTimeIntervalSec_ > 0);
        require(rebaseWindowOffsetSec_ < minRebaseTimeIntervalSec_);

        minRebaseTimeIntervalSec = minRebaseTimeIntervalSec_;
        rebaseWindowOffsetSec = rebaseWindowOffsetSec_;
        rebaseWindowLengthSec = rebaseWindowLengthSec_;
    }

    /**
     * @return If the latest block timestamp is within the rebase time window it, returns true.
     *         Otherwise, returns false.
     */
    function inRebaseWindow() public view returns (bool) {
        // rebasing is delayed until there is a liquid market
        _inRebaseWindow();
        return true;
    }

    function _inRebaseWindow() internal view {
        require(
            now.mod(minRebaseTimeIntervalSec) >= rebaseWindowOffsetSec,
            "too early"
        );
        require(
            now.mod(minRebaseTimeIntervalSec) <
                (rebaseWindowOffsetSec.add(rebaseWindowLengthSec)),
            "too late"
        );
    }

    /**
     * @return Computes in % how far off market is from peg
     */
    function computeOffPegPerc(uint256 rate)
        private
        view
        returns (uint256, bool)
    {
        if (withinDeviationThreshold(rate)) {
            return (0, false);
        }

        // indexDelta =  (rate - targetRate) / targetRate
        if (rate > targetRate) {
            return (rate.sub(targetRate).mul(10**9).div(targetRate), true);
        } else {
            return (targetRate.sub(rate).mul(10**9).div(targetRate), false);
        }
    }

    /**
     * @param rate The current exchange rate, an 18 decimal fixed point number.
     * @return If the rate is within the deviation threshold from the target rate, returns true.
     *         Otherwise, returns false.
     */
    function withinDeviationThreshold(uint256 rate)
        private
        view
        returns (bool)
    {
        uint256 absoluteDeviationThreshold = targetRate
            .mul(deviationThreshold)
            .div(100);

        return (rate < targetRate &&
            targetRate.sub(rate) < absoluteDeviationThreshold);
    }
}