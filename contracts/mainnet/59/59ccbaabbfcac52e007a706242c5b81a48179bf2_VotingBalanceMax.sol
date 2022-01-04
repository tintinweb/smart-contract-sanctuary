/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

// File: contracts\interfaces\ILockedCvx.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ILockedCvx{
     struct LockedBalance {
        uint112 amount;
        uint112 boosted;
        uint32 unlockTime;
    }

    function lock(address _account, uint256 _amount, uint256 _spendRatio) external;
    function processExpiredLocks(bool _relock, uint256 _spendRatio, address _withdrawTo) external;
    function getReward(address _account, bool _stake) external;
    function balanceAtEpochOf(uint256 _epoch, address _user) view external returns(uint256 amount);
    function totalSupplyAtEpoch(uint256 _epoch) view external returns(uint256 supply);
    function epochCount() external view returns(uint256);
    function epochs(uint256 _id) external view returns(uint224,uint32);
    function checkpointEpoch() external;
    function balanceOf(address _account) external view returns(uint256);
    function totalSupply() view external returns(uint256 supply);
    function lockedBalances(
        address _user
    ) view external returns(
        uint256 total,
        uint256 unlockable,
        uint256 locked,
        LockedBalance[] memory lockData
    );
    function addReward(
        address _rewardsToken,
        address _distributor,
        bool _useBoost
    ) external;
    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external;
    function setStakeLimits(uint256 _minimum, uint256 _maximum) external;
    function setBoost(uint256 _max, uint256 _rate, address _receivingAddress) external;
    function setKickIncentive(uint256 _rate, uint256 _delay) external;
    function shutdown() external;
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external;
}

// File: contracts\interfaces\IVotingEligibility.sol

pragma solidity 0.6.12;

interface IVotingEligibility{
    function isEligible(address _account) external view returns(bool);
}

// File: @openzeppelin\contracts\math\SafeMath.sol


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

// File: contracts\VotingBalanceMax.sol

pragma solidity 0.6.12;


contract VotingBalanceMax{
    using SafeMath for uint256;

    address public constant locker = address(0xD18140b4B819b895A3dba5442F959fA44994AF50);
    address public immutable eligiblelist;
    uint256 public constant rewardsDuration = 86400 * 7;
    uint256 public constant lockDuration = rewardsDuration * 17;

    constructor(address _eligiblelist) public {
        eligiblelist = _eligiblelist;
    }

    function balanceOf(address _account) external view returns(uint256){

        //check eligibility list
        if(!IVotingEligibility(eligiblelist).isEligible(_account)){
            return 0;
        }

        //compute to find previous epoch
        uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
        uint256 epochindex = ILockedCvx(locker).epochCount() - 1;
        (, uint32 _enddate) = ILockedCvx(locker).epochs(epochindex);
        if(_enddate >= currentEpoch){
            //if end date is already the current epoch,  minus 1 to get the previous
            epochindex -= 1;
        }
        //get balances of current and previous
        uint256 balanceAtPrev = ILockedCvx(locker).balanceAtEpochOf(epochindex, _account);
        uint256 currentBalance = ILockedCvx(locker).balanceOf(_account);

        //return greater balance
        return max(balanceAtPrev, currentBalance);
    }

    function pendingBalanceOf(address _account) external view returns(uint256){

        //check eligibility list
        if(!IVotingEligibility(eligiblelist).isEligible(_account)){
            return 0;
        }

        //determine when current epoch would end
        uint256 currentEpochUnlock = block.timestamp.div(rewardsDuration).mul(rewardsDuration).add(lockDuration);

        //grab account lock list
        (,,,ILockedCvx.LockedBalance[] memory balances) = ILockedCvx(locker).lockedBalances(_account);
        
        //if most recent lock is current epoch, then lock amount is pending balance
        uint256 pending;
        if(balances[balances.length-1].unlockTime == currentEpochUnlock){
            pending = balances[balances.length-1].boosted;
        }

        return pending;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function totalSupply() view external returns(uint256){
        return ILockedCvx(locker).totalSupply();
    }
}