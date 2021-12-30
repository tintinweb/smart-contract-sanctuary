/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT
// File: contracts/IBEP20.sol



pragma solidity ^0.8.0;

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
     * IMPORTANT:  Beware that changingan allowance with this method brings the risk
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
// File: contracts/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: contracts/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/SafeMath.sol


// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// File: contracts/GHSP-Staking.sol



pragma solidity ^0.8.0;




/**
 * @title GHSP Staking
 * Distribute GHSP rewards over discrete-time schedules for the staking of GHSP on BSC network.
 * This contract is designed on a self-service model, where users will stake GHSP, unstake GHSP and claim rewards through their own transactions only.
 */
contract GHSPStaking is Ownable {

    /* ------------------------------ States --------------------------------- */

    using SafeMath for uint256;

    IBEP20 public immutable tokenAddress;               // contract address of bep20 token

    uint256 public allStakes;                           // total amount of staked token

    address[] stakers;                                  // all stakers

    address public feeAddress;                          // address for fee

    uint256 public harvestFee;                          // harvest fee

    uint256 public unstakeFee5;                         // unstake fee for <= 7 days

    uint256 public unstakeFee4;                         // unstake fee for <= 14 days

    uint256 public unstakeFee3;                         // unstake fee for <= 21 days

    uint256 public unstakeFee2;                         // unstake fee for <= 30 days
    
    uint256 public unstakeFee1;                         // unstake fee for > 30 days

    mapping(address => UserInfo) stakerInfos;

    struct UserInfo{
        uint256 stake;
        uint256 reward;
        uint256 lastUpdatedTime;
        uint256 lastStakedTime;
    }

    struct SnapStaking {                                // SnapShot of Staking
        address user;                                   // staker
        uint256 time;                                   // time
        bool status;                                    // stake or unstake
        uint256 amount;                                 // amount
        uint256 fee;                                    // fee
    }

    SnapStaking[] public stakingHistories;              // history of all staking

    struct SnapHarvest {                                // SnapShot of Harvesting
        address user;                                   // staker
        uint256 time;                                   // time
        bool status;                                    // not used
        uint256 amount;                                 // amount
        uint256 fee;                                    // fee
    }

    SnapHarvest[] public harvestingHistories;           // history of harvest

    bool public isRunning;                              // is running or not

    uint256 public decimal;                             // decimal of reward token

    uint256 public totalSupply;                         // total Supply of rewarding - min: 10K

    uint256 public totalStakingPeriodDays;              // total staking period by month - min: 1 Month

    uint256 private _totalRewards;                      // total Rewardings

    uint256 private _totalHarvest;                      // total amount of harvested             

    uint256 private _totalFee;                          // total amount of fee

    uint256 private _rewardCapacity;                    // total amount of token in contract for rewarding

    uint256 private _rewardAmountPerSecond;             // total rewarding per second
    
    /* ------------------------------ Events --------------------------------- */
    event Staked(address staker, uint256 tokenId);
    
    event UnStaked(address staker, uint256 tokenId);

    event Harvest(address staker, uint256 amount);

    event AdminDeposit(address admin, uint256 amount);

    event AdminWithdraw(address admin, uint256 amount);

    event AdminHarvest(address user, uint256 amount);

    event AdminUpdatedAPY(uint256 totalSupply_, uint256 totalPeriods_);

    event AdminUpdatedRunning(bool status);

    event AdminUpdatedHarvestFee(uint fee);

    event AdminUpdatedUnstakeFee1(uint fee);

    event AdminUpdatedUnstakeFee2(uint fee);
    
    event AdminUpdatedUnstakeFee3(uint fee);
    
    event AdminUpdatedUnstakeFee4(uint fee);
    
    event AdminUpdatedUnstakeFee5(uint fee);

    event AdminUpdatedFeeAddress(address feeAddress_);

    /* ------------------------------ Modifiers --------------------------------- */


    /* ------------------------------ User Functions --------------------------------- */

    /* 
        Contructor of contract
    params:
        - tokenAddress: Contract Address of BEP20 token
        - totalSupply: total amount of rewarding tokens
        - totalStakingPeriodDays: total time of staking for nft tokens
    */
    constructor(
        IBEP20 tokenAddress_,
        uint256 totalSupply_,
        uint256 totalStakingPeriodDays_,
        address feeAddress_,
        uint256 harvestFee_,
        uint256 unstakeFee1_,
        uint256 unstakeFee2_,
        uint256 unstakeFee3_,
        uint256 unstakeFee4_,
        uint256 unstakeFee5_
    ) {
        require(totalSupply_ >= 1e4 * (10 ** tokenAddress_.decimals()), "Contract Constructor: Not Enough Supply Amount, bigger than 10K");
        require(totalStakingPeriodDays_ > 0, "Contract Constructor: Not Enough Staking Period, bigger than 1 days");
        require(feeAddress_ != address(0), "Contract Constructor: Invalid fee address");
        
        tokenAddress = tokenAddress_;
        
        decimal = tokenAddress_.decimals();
        totalSupply = totalSupply_;
        totalStakingPeriodDays = totalStakingPeriodDays_;

        isRunning = true;

        feeAddress = feeAddress_;
        harvestFee = harvestFee_;
        unstakeFee1 = unstakeFee1_;
        unstakeFee2 = unstakeFee2_;
        unstakeFee3 = unstakeFee3_;
        unstakeFee4 = unstakeFee4_;
        unstakeFee5 = unstakeFee5_;
        
        _updateRewardAmountPerSecond();
    }

    /*
        Cal rewards per seconds from APY
    */
    function _updateRewardAmountPerSecond() private{
        _rewardAmountPerSecond = totalSupply / (totalStakingPeriodDays * 24 * 3600);
    }

    /*
        Update Rewardings(amount and time)
        notice: rewarding amount increases only isRunning
    */
    function _updateRewards(address staker) private {
        uint256 total = allStakes;
        uint256 count = stakerInfos[staker].stake;
        
        if(stakerInfos[staker].lastUpdatedTime == 0 || total == 0 || count == 0) return;

        uint256 current = block.timestamp;

        if(isRunning){
            uint256 rewarding = _calculateAddingRewards(staker);
            stakerInfos[staker].reward = stakerInfos[staker].reward + rewarding;
            _totalRewards = _totalRewards + rewarding;
        }

        stakerInfos[staker].lastUpdatedTime = current;
    }

    /*
        Get Adding rewardings not stored in storage
    */
    function _calculateAddingRewards(address staker) private view returns(uint256){
        uint256 total = allStakes;
        uint256 count = stakerInfos[staker].stake;
        
        if(!isRunning || stakerInfos[staker].lastUpdatedTime == 0 || total == 0 || count == 0)
            return 0;
        
        uint256 current = block.timestamp;
        uint256 rewarding = (current - stakerInfos[staker].lastUpdatedTime) * _rewardAmountPerSecond * count / total;

        return rewarding;
    }

    /*
        Get total Adding rewardings not stored in storage
    */
    function _calculateTotalAddingRewards() private view returns(uint256){
        uint256 totalAdding;
        for(uint256 i = 0; i < stakers.length; i++){
            totalAdding = totalAdding + _calculateAddingRewards(stakers[i]);
        }
        return totalAdding;
    }

    /*
        Update Rewardings for all stakers
    */
    function _updateAllRewards() private {
        for(uint256 i = 0; i < stakers.length; i++){
            _updateRewards(stakers[i]);
        }
    }

    /*
        Get Rewards amount per second by user
    */
    function rewardsPerSecond() external view returns(uint256){
        uint256 total = allStakes;
        uint256 count = stakerInfos[msg.sender].stake;
        if(total == 0 || count == 0) return 0;
        uint256 rewarding = _rewardAmountPerSecond * count / total;
        return rewarding;
    }

    /*
        Stake token
        note - user should call the token address and approve for the amount for this contract
    */
    function stake(uint256 amount) external {
        _updateRewards(msg.sender);

        allStakes = allStakes + amount;
        stakerInfos[msg.sender].stake = stakerInfos[msg.sender].stake + amount;
        stakingHistories.push(SnapStaking(msg.sender, block.timestamp, true, amount, 0));
        _addStakerToArray(msg.sender);
        
        stakerInfos[msg.sender].lastUpdatedTime = block.timestamp;
        stakerInfos[msg.sender].lastStakedTime = block.timestamp;

        tokenAddress.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /*
        Add staker to array, if not exists
    */
    function _addStakerToArray(address staker) private {
        for(uint256 i = 0; i < stakers.length; i ++){
            if(stakers[i] == staker){
                return;
            }
        }
        stakers.push(staker);
    }

    /*
        Unstake token
    */
    function unstake(uint256 amount) external {

        require(stakerInfos[msg.sender].stake >= amount, "GHSP UnStaking: not enough staked token amount.");
        _updateRewards(msg.sender);

        allStakes = allStakes - amount;
        stakerInfos[msg.sender].stake = stakerInfos[msg.sender].stake - amount;

        uint256 stakingTime = block.timestamp - stakerInfos[msg.sender].lastStakedTime;
        uint256 unstakeFee = 0;
        if(stakingTime > 30 days){
            unstakeFee = unstakeFee1;
        }
        else if(stakingTime > 21 days){
            unstakeFee = unstakeFee2;
        }
        else if(stakingTime > 14 days){
            unstakeFee = unstakeFee3;
        }
        else if(stakingTime > 7 days){
            unstakeFee = unstakeFee4;
        }
        else{
            unstakeFee = unstakeFee5;
        }
        
        stakingHistories.push(SnapStaking(msg.sender, block.timestamp, false, amount, unstakeFee));

        uint256 fee = amount * unstakeFee / 100;
        _totalFee = _totalFee + fee;

        tokenAddress.transfer(msg.sender, amount - fee);
        tokenAddress.transfer(feeAddress, fee);

        emit UnStaked(msg.sender, amount);
    }

    /*
        Harvest rewardings
    */
    function harvest(uint256 amount) external {
        _updateRewards(msg.sender);
        require(_rewardCapacity >= amount, "Harvest Rewarding: not enough reward capacity.");
        require(amount > 0 && stakerInfos[msg.sender].reward >= amount, "Harvest Rewarding: not enough rewards");

        stakerInfos[msg.sender].reward = stakerInfos[msg.sender].reward - amount;
        
        _totalHarvest = _totalHarvest + amount;
        _rewardCapacity = _rewardCapacity - amount;
        
        uint256 fee = amount * harvestFee / 100;

        _totalFee = _totalFee + fee;
        
        harvestingHistories.push(SnapHarvest(msg.sender, block.timestamp, true, amount, harvestFee));

        tokenAddress.transfer(msg.sender, amount - fee);
        tokenAddress.transfer(feeAddress, fee);

        emit Harvest(msg.sender, amount);
    }

    /*
        Get amount of staked token per user
    */
    function balanceOfStakes() external view returns (uint256){
        return stakerInfos[msg.sender].stake;
    }

    /*
        Get reward amounts
    */
    function balanceOfRewards() external view returns(uint256){
        return _balanceOfRewards(msg.sender);
    }

    function _balanceOfRewards(address staker) private view returns(uint256){
        return stakerInfos[msg.sender].reward + _calculateAddingRewards(staker);
    }

    /*
        Get logs of stake and unstake per user
    */
    function historyOfStakes() external view returns(uint256[] memory, uint256[] memory, bool[] memory, uint256[] memory){
        uint256 len = 0;
        for(uint256 i = 0; i < stakingHistories.length; i ++){
            if(stakingHistories[i].user == msg.sender){
                len ++;
            }
        }

        uint256[] memory times = new uint256[](len);
        uint256[] memory tokens = new uint256[](len);
        bool[] memory status = new bool[](len);
        uint256[] memory fees = new uint256[](len);

        uint256 index = 0;

        for(uint256 i = 0; i < stakingHistories.length; i ++){
            if(stakingHistories[i].user == msg.sender){
                times[index] = stakingHistories[i].time;
                tokens[index] = stakingHistories[i].amount;
                status[index] = stakingHistories[i].status;
                fees[index] = stakingHistories[i].fee;
                index ++;
            }
        }
        return (times, tokens, status, fees);
    }


    /*
        Get logs of harvest per user
    */
    function historyOfHarvest() external view returns(uint256[] memory, uint256[] memory, bool[] memory, uint256[] memory){
        uint256 len = 0;
        for(uint256 i = 0; i < harvestingHistories.length; i ++){
            if(harvestingHistories[i].user == msg.sender){
                len ++;
            }
        }

        uint256[] memory times = new uint256[](len);
        uint256[] memory amounts = new uint256[](len);
        bool[] memory status = new bool[](len);
        uint256[] memory fees = new uint256[](len);
        uint256 index = 0;

        for(uint256 i = 0; i < harvestingHistories.length; i ++){
            if(harvestingHistories[i].user == msg.sender){
                times[index] = harvestingHistories[i].time;
                amounts[index] = harvestingHistories[i].amount;
                status[index] = harvestingHistories[i].status;
                fees[index] = harvestingHistories[i].fee;
                index ++;
            }
        }
        return (times, amounts, status, fees);
    }

    /* ------------------------------ Admin Functions --------------------------------- */
    /*
        Deposit token for rewarding by admin
        note - user should call the token address and approve for the amount for this contract
    */
    function adminDepositReward(uint256 amount) external onlyOwner {
        _rewardCapacity = _rewardCapacity + amount;
        
        tokenAddress.transferFrom(msg.sender, address(this), amount);
        emit AdminDeposit(msg.sender, amount);
    }

    /*
        Withdraw rewarding token by admin
    */
    function adminWithdrawReward(uint256 amount) external onlyOwner {
        uint256 pendingRewards = _totalRewards + _calculateTotalAddingRewards() - _totalHarvest;
        require(_rewardCapacity - pendingRewards >= amount, "Admin Witdraw Rewards: not enough rewards capacity to withdraw");
        _rewardCapacity = _rewardCapacity - amount;

        tokenAddress.transfer(msg.sender, amount);
        emit AdminWithdraw(msg.sender, amount);
    }

    /*
        Get all logs of stake and unstake
    */
    function adminAllHistoriesOfStakes() external view onlyOwner returns(uint256[] memory, uint256[] memory, bool[] memory, uint256[] memory){
        uint256 len = stakingHistories.length;
        uint256[] memory times = new uint256[](len);
        uint256[] memory amounts = new uint256[](len);
        bool[] memory status = new bool[](len);
        uint256[] memory fees = new uint256[](len);

        for(uint256 i = 0; i < stakingHistories.length; i ++){
            times[i] = stakingHistories[i].time;
            amounts[i] = stakingHistories[i].amount;
            status[i] = stakingHistories[i].status;
            fees[i] = stakingHistories[i].fee;
        }
        return (times, amounts, status, fees);
    }

    /*
        Get all logs of harvest
    */
    function adminAllHistoriesOfHarvest() public view onlyOwner returns(uint256[] memory, uint256[] memory, bool[] memory, uint256[] memory){
        uint256 len = harvestingHistories.length;
        uint256[] memory times = new uint256[](len);
        uint256[] memory amounts = new uint256[](len);
        bool[] memory status = new bool[](len);
        uint256[] memory fees = new uint256[](len);

        for(uint256 i = 0; i < harvestingHistories.length; i ++){
            times[i] = harvestingHistories[i].time;
            amounts[i] = harvestingHistories[i].amount;
            status[i] = harvestingHistories[i].status;
            fees[i] = harvestingHistories[i].fee;
        }
        return (times, amounts, status, fees);
    }

    /*
        Get rewards of staker
    */
    function adminRewards(address staker) public view onlyOwner returns(uint256){
        return _balanceOfRewards(staker);
    }

    /*
        Start or stop staking logic by admin
    */
    function adminSetRunning(bool running_) public onlyOwner{
        if(running_ == isRunning) return;
        _updateAllRewards();
        isRunning = running_;
        emit AdminUpdatedRunning(isRunning);
    }


    /*
        Get Total Rewards, Harvest, Completed Harvest
    */
    function adminTotalRewardAndHarvest() public view onlyOwner returns(uint256, uint256, uint256, uint256){
        uint256 totalAdding = _calculateTotalAddingRewards();
        return (_rewardCapacity, _totalRewards + totalAdding, _totalHarvest, _totalFee);
    }

    /* 
        Update APY
    params:
        - nftTokenAddress: Contract Address of NFT
        - totalSupply: total amount of rewarding tokens
        - totalStakingPeriodDays: total time of staking for nft tokens by months
        - deciaml: decimal of rewarding token
    */
    function adminUpdateAPY(uint256 totalSupply_, uint256 totalPeriods_) public onlyOwner{
        require(totalSupply_ >= 1e4 * (10 ** decimal), "Admin Update APY: Not Enough Supply Amount, bigger than 10K");
        require(totalPeriods_ > 0, "Contract Constructor: Not Enough Staking Period, bigger than 1 (months)");

        _updateAllRewards();
        totalSupply = totalSupply_;
        totalStakingPeriodDays = totalPeriods_;
        _updateRewardAmountPerSecond();

        emit AdminUpdatedAPY(totalSupply, totalStakingPeriodDays);
    }

    function adminUpdateHarvestFee(uint fee) public onlyOwner{
        harvestFee = fee;

        emit AdminUpdatedHarvestFee(fee);
    }

    function adminUpdateUnstakeFee1(uint fee) public onlyOwner{
        unstakeFee1 = fee;

        emit AdminUpdatedUnstakeFee1(fee);
    }

    function adminUpdateUnstakeFee2(uint fee) public onlyOwner{
        unstakeFee2 = fee;

        emit AdminUpdatedUnstakeFee2(fee);
    }

    function adminUpdateUnstakeFee3(uint fee) public onlyOwner{
        unstakeFee3 = fee;

        emit AdminUpdatedUnstakeFee3(fee);
    }

    function adminUpdateUnstakeFee4(uint fee) public onlyOwner{
        unstakeFee4 = fee;

        emit AdminUpdatedUnstakeFee4(fee);
    }

    function adminUpdateUnstakeFee5(uint fee) public onlyOwner{
        unstakeFee5 = fee;

        emit AdminUpdatedUnstakeFee5(fee);
    }

    function adminUpdateFeeAddress(address address_) public onlyOwner{
        require(address_ != address(0), "Admin Update Fee Address: Invalid address");

        feeAddress = address_;

        emit AdminUpdatedFeeAddress(address_);
    }
}