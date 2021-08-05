/**
 *Submitted for verification at Etherscan.io on 2021-01-29
*/

// File: @openzeppelin\contracts\math\SafeMath.sol

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
}

// File: node_modules\@openzeppelin\contracts\GSN\Context.sol



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

// File: @openzeppelin\contracts\access\Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\StakingLocker.sol

pragma solidity 0.6.12;



interface ICldrn {
    function burnFrom(address account, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
}
contract StakingLocker is Ownable {
    using SafeMath for uint256;

    address public chef;
    ICldrn public cldrn;
    uint256 public allActiveBatches;
    uint256 public PERCENT_SCALE_FACTOR = 1000000000;

    modifier onlyChef(){
        require(msg.sender == chef, "onlychef");
        _;
    }

    struct PoolLockInfo {
        uint256 lockDuration;
        uint256 percentReleasedPerSec; //5% per hour -> PERCENT_SCALE_FACTOR * 5/3600
    }
    struct BurnBonus {
        uint256 startTime;
        uint256 endTime;
        uint256 bonusPercentPerSec; // 1% per hour -> PERCENT_SCALE_FACTOR * 1/3600n
    }
    struct UserLockInfo {
        uint256 totalEarnedFromPool;
        uint256 totalClaimed;

        uint256 pendingBatchSize;
        uint256 totalClaimedFromPendingBatch;
        uint256 lastLockStartTime;
        BurnBonus[] burnBonuses;
    }
    struct BonusTier {
        uint256 baseCost;
        uint256 bonusPercentPerSec; // 1% per hour -> PERCENT_SCALE_FACTOR * 1/3600
        uint256 durationInSecs;
        uint256 whalePowFac; //e.g. 2 => cost of bonus = (percentage of pool)*2*baseCost . penalise whales with bigger batches by charging more for burn. pendingBatchSize will be scaled with this factor.
    }
    
    event BoughtBonus(address indexed owner, uint256 indexed poolId, uint256 indexed bonusId, uint256 paid);
    event Locked(address indexed owner, uint256 indexed poolId, uint256 amt);

    // poolid => address => lockinfo
    mapping (uint256 => mapping (address => UserLockInfo)) public userLockInfo;
    mapping (uint256 => PoolLockInfo) public poolLockInfo;
    mapping (uint256 => BonusTier) public bonuses;
    function getUserLockInfo(uint256 _pid, address owner) external view returns (uint256,uint256,uint256,uint256,uint256){
        UserLockInfo storage l = userLockInfo[_pid][owner];
        return (l.totalEarnedFromPool, l.totalClaimed, l.pendingBatchSize, l.totalClaimedFromPendingBatch, l.lastLockStartTime);
    }
    function getUserBurnBonus(uint256 _pid, address owner, uint256 bonusIdx) external view returns (uint256,uint256,uint256){
        BurnBonus storage b = userLockInfo[_pid][owner].burnBonuses[bonusIdx];
        return (b.startTime, b.endTime,b.bonusPercentPerSec);
    }
    function getUserBurnBonusLength(uint256 _pid, address owner) external view returns (uint256){
        return userLockInfo[_pid][owner].burnBonuses.length;
    }
    constructor(address _chef, address _cldrn) public{
        chef = _chef;
        cldrn = ICldrn(_cldrn);
    }
    function setChef(address _a) public onlyOwner{
        chef = _a;
    }
    function setCldrn(address _a) public onlyOwner{
        cldrn = ICldrn(_a);
    }
    function setPoolLockInfo(uint256 pid, uint256 lockDuration, uint256 percentReleasedPerSec) external onlyOwner {
        poolLockInfo[pid] = PoolLockInfo(lockDuration, percentReleasedPerSec);
    }
    function setBonusTierInfo(uint256 bonusId, uint256 baseCost, uint256 bonusPercentPerSec, uint256 durationInSecs, uint256 whalePowFac) external onlyOwner {
        bonuses[bonusId] = BonusTier(baseCost, bonusPercentPerSec, durationInSecs,whalePowFac);
    }

    function getCost(uint256 bonusTierId, uint256 poolId, address buyer) public view returns (uint256){

        BonusTier storage t = bonuses[bonusTierId];
        UserLockInfo storage userInfo = userLockInfo[poolId][buyer];
        uint256 scalingFactor = PERCENT_SCALE_FACTOR ** t.whalePowFac;

        uint256 percentOwnershipOfBatches = userInfo.pendingBatchSize.mul(100 * PERCENT_SCALE_FACTOR).div(allActiveBatches); //percent is scaled by 1mil

        uint256 percentPremium = percentOwnershipOfBatches ** t.whalePowFac; //scaled by PERCENT_SCALE_FACTOR ** whalePowFac

        return t.baseCost.mul(scalingFactor.mul(100).add(percentPremium)).div(scalingFactor.mul(100));
    }
    function buyBonus(uint256 bonusTierId, uint256 poolId) external {
        BonusTier storage t = bonuses[bonusTierId];
        UserLockInfo storage userInfo = userLockInfo[poolId][msg.sender];
        uint256 cost = getCost(bonusTierId, poolId, msg.sender);
        cldrn.burnFrom(msg.sender, cost);
        BurnBonus memory b = BurnBonus(now, now+t.durationInSecs, t.bonusPercentPerSec);
        userInfo.burnBonuses.push(b);
        emit BoughtBonus(msg.sender, poolId, bonusTierId, cost);
    }
    // rewards already pre-transferred to this contract before this method is called
    function lockRewards(address owner, uint256 poolId, uint256 amt) public onlyChef{
        UserLockInfo storage i = userLockInfo[poolId][owner];
        allActiveBatches -= i.pendingBatchSize;
        i.totalEarnedFromPool += amt;
        i.lastLockStartTime = now;

        i.pendingBatchSize = i.totalEarnedFromPool - i.totalClaimed;
        allActiveBatches += i.pendingBatchSize;

        i.totalClaimedFromPendingBatch = 0;
        emit Locked(owner, poolId, amt);
    }
    function getAvgReleaseRate(address owner, uint256 poolId) public view returns (uint256){
        uint256 percentRewards = getPercentOverTime(owner, poolId);
        if (percentRewards== 0){
            return 0;
        }else {
            UserLockInfo storage i = userLockInfo[poolId][owner];
            uint256 validTrickleStart = i.lastLockStartTime + poolLockInfo[poolId].lockDuration;
            uint256 numSecs = now - validTrickleStart;
            return percentRewards.div(numSecs).mul(3600);
        }
    }
    function getPercentOverTime2(address owner, uint256 poolId) public view returns (uint256,uint256,uint256,uint256,uint256) {
        UserLockInfo storage i = userLockInfo[poolId][owner];
        if (i.pendingBatchSize == 0){
            return (0,0,0,0,0);
        } 
        uint256 validTrickleStart = i.lastLockStartTime + poolLockInfo[poolId].lockDuration;
        
        if (validTrickleStart >= now){
            return (validTrickleStart,now,0,0,0);
        } else {
            // calculate
            uint256 numSecs = now - validTrickleStart;
            uint256 baseRewards = poolLockInfo[poolId].percentReleasedPerSec.mul(numSecs);
            uint256 bonusRewards = 0;
            // (totalEarned - totalClaimed) * percentage
            for (uint k = 0 ; k < i.burnBonuses.length; k++){
                bonusRewards += getBurnBonusPercent(validTrickleStart, now, i.burnBonuses[k].startTime,i.burnBonuses[k].endTime,i.burnBonuses[k].bonusPercentPerSec);
            }
            uint256 totalRewards = baseRewards + bonusRewards;

            // percentage points are inflated by PERCENT_SCALE_FACTOR to allow representing decimals. max percentRewards = 100 * PERCENT_SCALE_FACTOR.
            if (totalRewards > 100 * PERCENT_SCALE_FACTOR){
                totalRewards = 100 * PERCENT_SCALE_FACTOR;
            }
            return (validTrickleStart, now, baseRewards, bonusRewards, totalRewards);
        }
    }
    function getPercentOverTime(address owner, uint256 poolId) internal view returns (uint256){
        UserLockInfo storage i = userLockInfo[poolId][owner];
        if (i.pendingBatchSize == 0){
            return 0;
        } 
        uint256 validTrickleStart = i.lastLockStartTime + poolLockInfo[poolId].lockDuration;
        
        if (validTrickleStart >= now){
            return 0;
        } else {
            // calculate
            uint256 numSecs = now - validTrickleStart;
            uint256 percentRewards = poolLockInfo[poolId].percentReleasedPerSec.mul(numSecs);
            // (totalEarned - totalClaimed) * percentage
            for (uint k = 0 ; k < i.burnBonuses.length; k++){
                percentRewards += getBurnBonusPercent(validTrickleStart, now, i.burnBonuses[k].startTime,i.burnBonuses[k].endTime,i.burnBonuses[k].bonusPercentPerSec);
            }
            // percentage points are inflated by PERCENT_SCALE_FACTOR to allow representing decimals. max percentRewards = 100 * PERCENT_SCALE_FACTOR.
            if (percentRewards > 100 * PERCENT_SCALE_FACTOR){
                percentRewards = 100 * PERCENT_SCALE_FACTOR;
            }
            return percentRewards;
        }
    }
    function pendingUnlock(address owner, uint256 poolId) public view returns (uint256){
        uint256 percentRewards = getPercentOverTime(owner, poolId);
        if (percentRewards== 0){
            return 0;
        }else {
            UserLockInfo storage i = userLockInfo[poolId][owner];
            uint256 pending = i.pendingBatchSize.mul(percentRewards).div(100).div(PERCENT_SCALE_FACTOR).sub(i.totalClaimedFromPendingBatch);
            return pending;
        }
    }
    function claimRewards(address owner, uint256 poolId) public returns (uint256){
        UserLockInfo storage i = userLockInfo[poolId][owner];
        if (i.totalEarnedFromPool == 0){
            return 0;
        }
        uint256 pending = pendingUnlock(owner, poolId);
        if (pending > 0){
            i.totalClaimed += pending;
            i.totalClaimedFromPendingBatch += pending;
            require(cldrn.transfer(owner, pending),"failed to claim");
        }

    }
    function getOverlap(uint256 start1, uint256 end1, uint256 start2, uint256 end2) public pure returns (uint256) {
        
        uint256 start = (start1 > start2) ? start1 : start2;
        uint256 end = (end1 < end2) ? end1 : end2;
        if (start >= end){
            return 0;
        }else{
            return end-start;
        }
    }
    function getBurnBonusPercent(uint256 windowStart, uint256 windowEnd, uint256 bonusStart, uint256 bonusEnd, uint256 bonusPercentPerSec) public pure returns (uint256){
        return getOverlap(windowStart, windowEnd, bonusStart, bonusEnd).mul(bonusPercentPerSec);
    }

}