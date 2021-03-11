// SPDX-License-Identifier: MIT
// File: [email protected]\contracts\token\ERC20\IERC20.sol
// File: [email protected]\contracts\math\SafeMath.sol
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AVS_staking is Ownable , ReentrancyGuard
{
    using SafeMath for uint256;
    IERC20 public avsAddress;
    uint256 public zeroDayStartTime;
    uint256 public dayDurationSec;
    uint256 public allAVSTokens;
    uint256 public totalStakers;
    uint256 public totalStakedAVS;
    uint256 public unfreezedAVSTokens;
    uint256 public freezedAVSTokens;
    uint256 public stakeIdLast;
    uint256 constant public MAX_NUM_DAYS = 180;
    StakeInfo[] public allStakes;

    mapping(address => StakeInfo[]) public stakeList;
    mapping(address => bool) public whitelist;

    struct StakeInfo
    {
        uint256 stakeId;
        uint256 startDay;
        uint256 numDaysStake;
        uint256 stakedAVS;
        uint256 freezedRewardAVSTokens;
    }

    modifier onlyWhenOpen
    {
        require(
            now >= zeroDayStartTime,
            "StakingAVS: Contract is not open yet"
        );
        _;
    }

    event AVSTokenIncome(address who, uint256 amount, uint256 day);
    event AVSTokenOutcome(address who, uint256 amount, uint256 day);
    event TokenFreezed(address who, uint256 amount, uint256 day);
    event TokenUnfreezed(address who, uint256 amount, uint256 day);
    event StakeStart(
        address who,
        uint256 AVSIncome,
        uint256 AVSEarnings,
        uint256 numDays,
        uint256 day,
        uint256 stakeId
    );
    event StakeEnd(
        address who,
        uint256 stakeId,
        uint256 AVSEarnings,
        uint256 servedNumDays,
        uint256 day
    );
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    constructor (IERC20 _AVSAddress, uint256 _zeroDayStartTime, uint256 _dayDurationSec) ReentrancyGuard() public {
        avsAddress = _AVSAddress;
        zeroDayStartTime = _zeroDayStartTime;
        dayDurationSec = _dayDurationSec;
    }

    function algoVestTokenDonation(uint256 amount) external nonReentrant
    {
        address sender = _msgSender();
        require(
            avsAddress.transferFrom(sender, address(this), amount),
            "StakingAVS: Could not get AVS tokens"
        );
        allAVSTokens = allAVSTokens.add(amount);
        unfreezedAVSTokens = unfreezedAVSTokens.add(amount);
        emit AVSTokenIncome(sender, amount, _currentDay());
    }

    function algoVestOwnerWithdraw(uint256 amount) external onlyOwner nonReentrant
    {
        address sender = _msgSender();
        require(
            sender == owner(),
            "StakingAVS: Sender is not owner"
        );
        require(
            allAVSTokens >= amount,
            "StakingAVS: Not enough value on this contract"
        );
        require(
            unfreezedAVSTokens >= amount,
            "StakingAVS: Not enough unfreezed value on this contract"
        );
        require(
            avsAddress.transfer(sender, amount),
            "StakingAVS: Could not send AVS tokens"
        );
        allAVSTokens = allAVSTokens.sub(amount);
        unfreezedAVSTokens = unfreezedAVSTokens.sub(amount);
        emit AVSTokenOutcome(sender, amount, _currentDay());
    }

    function stakeStart(uint256 amount, uint256 numDaysStake) external onlyWhenOpen nonReentrant
    {
        require(
            numDaysStake > 0 && numDaysStake <= MAX_NUM_DAYS && numDaysStake%15 == 0,
            "StakingAVS: Wrong number of days"
        );
        address sender = _msgSender();
        require(
            avsAddress.transferFrom(sender, address(this), amount),
            "StakingAVS: AVS token transfer failed"
        );
        uint256 currDay = _currentDay();
        emit AVSTokenIncome(sender, amount, currDay);
        uint256 avsEarnings = _getAlgoVestEarnings(amount, numDaysStake);
        // Freeze AVS tokens on contract
        require(
            unfreezedAVSTokens >= avsEarnings - amount,
            "StakingAVS: Insufficient funds of AVS tokens to this stake"
        );
        unfreezedAVSTokens = unfreezedAVSTokens.sub(avsEarnings-amount);
        freezedAVSTokens = freezedAVSTokens.add(avsEarnings-amount);
        emit TokenFreezed(sender, avsEarnings-amount, currDay);
        // Add stake into stakeList
        StakeInfo memory st = StakeInfo(
            ++stakeIdLast,
            currDay,
            numDaysStake,
            amount,
            avsEarnings - amount
        );
        stakeList[sender].push(st);
        allStakes.push(st);
        emit StakeStart(
            sender,
            amount,
            avsEarnings - amount,
            numDaysStake,
            currDay,
            stakeIdLast
        );
        if (stakeList[sender].length == 1){
            ++totalStakers;
        }
        totalStakedAVS = totalStakedAVS.add(amount);
    }

    function stakeEnd(uint256 stakeIndex, uint256 stakeId) external onlyWhenOpen nonReentrant
    {
        address sender = _msgSender();
        require(
            stakeIndex >= 0 && stakeIndex < stakeList[sender].length,
            "StakingAVS: Wrong stakeIndex"
        );
        StakeInfo storage st = stakeList[sender][stakeIndex];
        require(
            st.stakeId == stakeId,
            "StakingAVS: Wrong stakeId"
        );
        uint256 currDay = _currentDay();
        uint256 servedNumOfDays = min(currDay - st.startDay,st.numDaysStake);
        if (isWhitelisted(sender)) {
            uint256 avsTokensToReturn = _getAlgoVestEarnings(st.stakedAVS, servedNumOfDays);
            require(
                st.freezedRewardAVSTokens >= avsTokensToReturn - st.stakedAVS,
                "StakingAVS: Internal error!"
            );
            uint256 remainingAVSTokens = st.freezedRewardAVSTokens.sub(avsTokensToReturn - st.stakedAVS);
            unfreezedAVSTokens = unfreezedAVSTokens.add(remainingAVSTokens);
            freezedAVSTokens = freezedAVSTokens.sub(st.freezedRewardAVSTokens);
            emit TokenUnfreezed(sender, st.freezedRewardAVSTokens, currDay);
            allAVSTokens = allAVSTokens.sub(avsTokensToReturn - st.stakedAVS);
            avsAddress.transfer(sender, avsTokensToReturn);
            emit AVSTokenOutcome(sender, avsTokensToReturn, currDay);
            emit StakeEnd(
                sender,
                st.stakeId,
                avsTokensToReturn - st.stakedAVS,
                servedNumOfDays,
                currDay
            );
            totalStakedAVS = totalStakedAVS.sub(st.stakedAVS);
            _removeStake(stakeIndex, stakeId);
            if (stakeList[sender].length == 0){
                --totalStakers;
            }
        }
        else {
            if (servedNumOfDays < st.numDaysStake){
                uint256 avsTokensToReturn = _getAlgoVestEarningsPenalty(st.stakedAVS, servedNumOfDays);
                require(
                    st.freezedRewardAVSTokens >= avsTokensToReturn - st.stakedAVS,
                    "StakingAVS: Internal error!"
                );
                uint256 remainingAVSTokens = st.freezedRewardAVSTokens.sub(avsTokensToReturn - st.stakedAVS);
                unfreezedAVSTokens = unfreezedAVSTokens.add(remainingAVSTokens);
                freezedAVSTokens = freezedAVSTokens.sub(st.freezedRewardAVSTokens);
                emit TokenUnfreezed(sender, st.freezedRewardAVSTokens, currDay);
                allAVSTokens = allAVSTokens.sub(avsTokensToReturn - st.stakedAVS);
                avsAddress.transfer(sender, avsTokensToReturn);
                emit AVSTokenOutcome(sender, avsTokensToReturn - st.stakedAVS, currDay);
                emit StakeEnd(
                    sender,
                    st.stakeId,
                    avsTokensToReturn - st.stakedAVS,
                    servedNumOfDays,
                    currDay
                );
                totalStakedAVS = totalStakedAVS.sub(st.stakedAVS);
                _removeStake(stakeIndex, stakeId);
                if (stakeList[sender].length == 0){
                    --totalStakers;
                }
                //totalStakedAVS = totalStakedAVS.sub(st.stakedAVS);
            }
            else {
                uint256 avsTokensToReturn = _getAlgoVestEarnings(st.stakedAVS, st.numDaysStake);
                require(
                    st.freezedRewardAVSTokens >= avsTokensToReturn - st.stakedAVS,
                    "StakingAVS: Internal error!"
                );
                uint256 remainingAVSTokens = st.freezedRewardAVSTokens.sub(avsTokensToReturn - st.stakedAVS);
                unfreezedAVSTokens = unfreezedAVSTokens.add(remainingAVSTokens);
                freezedAVSTokens = freezedAVSTokens.sub(st.freezedRewardAVSTokens);
                emit TokenUnfreezed(sender, st.freezedRewardAVSTokens, currDay);
                allAVSTokens = allAVSTokens.sub(avsTokensToReturn - st.stakedAVS);
                avsAddress.transfer(sender, st.stakedAVS.add((avsTokensToReturn.sub(st.stakedAVS)).mul(98).div(100)));
                emit AVSTokenOutcome(sender, (avsTokensToReturn.sub(st.stakedAVS)).mul(98).div(100), currDay);

                emit StakeEnd(
                    sender,
                    st.stakeId,
                    avsTokensToReturn - st.stakedAVS,
                    servedNumOfDays,
                    currDay
                );
                totalStakedAVS = totalStakedAVS.sub(st.stakedAVS);
                _removeStake(stakeIndex, stakeId);
                if (stakeList[sender].length == 0){
                    --totalStakers;
                }
                //totalStakedAVS = totalStakedAVS.sub(st.stakedAVS);
            }
        }
    }
    function stakeListCount(address who) external view returns(uint256)
    {
        return stakeList[who].length;
    }

    function currentDay() external view onlyWhenOpen returns(uint256)
    {
        return _currentDay();
    }

    function lengthStakes() external view returns(uint256){
        return allStakes.length;
    }

    function sevenDays() external view returns(uint256)
    {
        if (allStakes.length == 0){
            return 0;
        }
        uint256 day_now = _currentDay();
        uint256 days_in_week = 7;
        uint256 day_week_ago = 0;
        uint256 counter = 0;
        uint256 all_percents = 0;
        uint256 step = allStakes.length.sub(1);
        uint256 stake_day = allStakes[step].startDay;
        uint256 num_stake_days = allStakes[step].numDaysStake;
        if (day_now >=  days_in_week){
            day_week_ago = day_now - days_in_week;
        }
        while (stake_day >= day_week_ago && step >= 0){
            uint256 num_of_parts = num_stake_days.div(15);
            uint256 perc = 1000;
            for (uint256 i=2; i<=num_of_parts; ++i){
                perc = perc.add(perc.mul(10).div(100));
            }
            all_percents = all_percents.add(perc);
            counter = counter.add(1);
            if (step != 0) {
                step = step.sub(1);
            }
            else {
                break;
            }
            stake_day = allStakes[step].startDay;
            num_stake_days = allStakes[step].numDaysStake;
        }
        uint256 final_percent = all_percents.div(counter);
        return final_percent;
    }

    function getEndDayOfStakeInUnixTime(
        address who,
        uint256 stakeIndex,
        uint256 stakeId
    )
        external
        view
        returns(uint256)
    {
        require(
            stakeIndex < stakeList[who].length,
            "StakingAVS: Wrong stakeIndex"
        );
        require(
            stakeId == stakeList[who][stakeIndex].stakeId,
            "StakingAVS: Wrong stakeId"
        );

        return getDayUnixTime(
            stakeList[who][stakeIndex].startDay.add(
                stakeList[who][stakeIndex].numDaysStake
            )
        );
    }

    function getStakeDivsNow(
        address who,
        uint256 stakeIndex,
        uint256 stakeId
    )
        external
        view
        returns(uint256)
    {
        require(
            stakeIndex < stakeList[who].length,
            "StakingAVS: Wrong stakeIndex"
        );
        require(
            stakeId == stakeList[who][stakeIndex].stakeId,
            "StakingAVS: Wrong stakeId"
        );

        uint256 currDay = _currentDay();
        uint256 servedDays = _getServedDays(
            currDay,
            stakeList[who][stakeIndex].startDay,
            stakeList[who][stakeIndex].numDaysStake
        );
        return _getAlgoVestEarnings(stakeList[who][stakeIndex].stakedAVS, servedDays);
    }

    function addInWhitelist(address _address) 
    external 
    onlyOwner 
    {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removeFromWhiteList(address _address) 
    external 
    onlyOwner 
    {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function getDayUnixTime(uint256 day) public view returns(uint256)
    {
        return zeroDayStartTime.add(day.mul(dayDurationSec));
    }

    function isWhitelisted(address _address) 
    public view 
    returns(bool) 
    {
        return whitelist[_address];
    }

    function _getServedDays(
        uint256 currDay,
        uint256 startDay,
        uint256 numDaysStake
    )
        private
        pure
        returns(uint256 servedDays)
    {
        servedDays = currDay.sub(startDay);
        if (servedDays > numDaysStake)
            servedDays = numDaysStake;
    }

    function _getAlgoVestEarnings(
        uint256 avsAmount, 
        uint256 numOfDays
        ) 
        private
        pure
        returns (uint256 reward)
    {
        require(
            numOfDays >= 0 && numOfDays <= MAX_NUM_DAYS,
            "StakingAVS: Wrong numOfDays"
        );
        uint256 num_of_parts = numOfDays.div(15);
        uint256 perc = 1000;
        for (uint256 i=2; i<=num_of_parts; ++i){
            perc += perc.mul(10).div(100);
        }
        uint256 rew = avsAmount.mul(perc).mul(numOfDays).div(3650000);
        return avsAmount.add(rew);
    }

    function _getAlgoVestEarningsPenalty(
        uint256 avsAmount, 
        uint256 numOfDays
        ) 
        private
        pure
        returns (uint256 reward)
    {
        require(
            numOfDays >= 0 && numOfDays <= MAX_NUM_DAYS,
            "StakingAVS: Wrong numOfDays"
        );
        uint256 num_of_parts = numOfDays.div(15);
        uint256 perc = 1000;
        for (uint256 i=2; i<=num_of_parts; ++i){
            perc += perc.mul(10).div(100);
        }
        uint256 rew = avsAmount.mul(perc).mul(numOfDays).div(3650000);
        return avsAmount.add(rew.mul(80).div(100));
    }

    function _currentDay() private view returns(uint256)
    {
        return now.sub(zeroDayStartTime).div(dayDurationSec);
    }

    function _removeStake(uint256 stakeIndex, uint256 stakeId) private
    {
        address sender = _msgSender();
        uint256 stakeListLength = stakeList[sender].length;
        require(
            stakeIndex >= 0 && stakeIndex < stakeListLength,
            "StakingAVS: Wrong stakeIndex"
        );
        StakeInfo storage st = stakeList[sender][stakeIndex];
        require(
            st.stakeId == stakeId,
            "StakingAVS: Wrong stakeId"
        );
        if (stakeIndex < stakeListLength - 1)
            stakeList[sender][stakeIndex] = stakeList[sender][stakeListLength - 1];
        stakeList[sender].pop();
    }

    function min (
        uint256 a, 
        uint256 b
        ) 
        private 
        pure 
        returns (uint256 minimum) 
    {
        //uint256 minimum;
        if(a > b){
            minimum = b;
        }
        else{
            minimum = a;
        }
        return minimum;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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
}