/**
 *Submitted for verification at Etherscan.io on 2020-12-22
*/

/*

website: volts.finance

  ______   __                               
 /      \ /  |                              
/$$$$$$  |$$ |____   _____  ____    _______ 
$$ |  $$ |$$      \ /     \/    \  /       |
$$ |  $$ |$$$$$$$  |$$$$$$ $$$$  |/$$$$$$$/ 
$$ |  $$ |$$ |  $$ |$$ | $$ | $$ |$$      \ 
$$ \__$$ |$$ |  $$ |$$ | $$ | $$ | $$$$$$  |
$$    $$/ $$ |  $$ |$$ | $$ | $$ |/     $$/ 
 $$$$$$/  $$/   $$/ $$/  $$/  $$/ $$$$$$$/  


OHMS staking contract of the Volts-Ecosystem

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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

interface OHMS {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256);
    function tokenFromReflection(uint256 rAmount) external view returns(uint256);
}

contract Staking is Ownable {

    struct User {
        uint256 reflectionBalance;
        uint256 paidReflection;
        uint256 ohmsBalance;
    }

    address[] private userArray;

    using SafeMath for uint256;

    mapping (address => User) public users;

    uint256 public reflectionTillNowPerToken = 0;
    uint256 public lastUpdatedBlock;
    uint256 public rewardPerBlock;
    uint256 public scale = 1e18;

    // init with 1 instead of 0 to avoid division by zero
    uint256 public totalStakedReflection = 1;
    uint256 public totalRewardReflection = 0;
    uint256 public totalStakedToken = 1;
    uint256 public totalOhmsReward = 0;
    
    OHMS public ohms;

    event Deposit(address user, uint256 amount);
    event Restake(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event EmergencyWithdraw(address user, uint256 amount);
    event RewardClaimed(address user, uint256 amount);
    event RewardPerBlockChanged(uint256 oldValue, uint256 newValue);

    constructor (address _ohms, uint256 _rewardPerBlock) public {
        ohms = OHMS(_ohms);
        rewardPerBlock = _rewardPerBlock;
        lastUpdatedBlock = block.number;
    }

    // Sets the rewards in OHMS per block
    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        update();
        emit RewardPerBlockChanged(rewardPerBlock, _rewardPerBlock);
        rewardPerBlock = _rewardPerBlock;
    }

    // Returns the amount of OHMS rewarded to stakers per block
    function getRewardPerBlock() external view returns (uint256){
        return rewardPerBlock;
    }

    // View function to see user's true OHMS balance including fees
    function getUserDepositAmount(address _user) public view returns (uint256){
        User storage user = users [_user];
        return ohms.tokenFromReflection(user.reflectionBalance);
    }

    // View function to see a user's staked OHMS balance. i.e number of OHMS belonging to them in the contract that are currently earning rewards
    function getActiveUserDepositAmount(address _user) public view returns (uint256){
        User storage user = users [_user];
        return user.ohmsBalance;
    }

    function getClaimableFees(address _user) external view returns (uint256){
        uint256 total = getUserDepositAmount(_user);
        uint256 staked = getActiveUserDepositAmount(_user);
        return total.sub(staked);
    }

    // View function to return the total number of OHMS staked in the contract that are currently earning rewards
    function getActiveTotalStaked() external view returns (uint256){
        return totalStakedToken;
    }

    //  View function to see true amount of OHMS staked in the contract in including fees
    function getTotalStaked() external view returns (uint256){
        return ohms.tokenFromReflection(totalStakedReflection);
    }

    // View function to get the amount staked in the contract in reflections.
    function getTotalStakedReflection() external view returns (uint256){
        return totalStakedReflection;
    }

    // View function to get the remaining reward balance in the contract in OHMS.
    function getTotalRemainingReward() external view returns (uint256){
        return ohms.tokenFromReflection(totalRewardReflection);
    }

    // View function to get the remaining reward balance in the contract in reflections.
    function getTotalRewardReflection() external view returns (uint256){
        return totalRewardReflection;
    }


    // Update reward variables of the pool to be up-to-date.
    function update() public {
        if (block.number <= lastUpdatedBlock) {
            return;
        }
        uint256 rewardAmount = (block.number - lastUpdatedBlock).mul(rewardPerBlock);
        totalOhmsReward = totalOhmsReward.add(rewardAmount);
        uint256 reflectionRewardAmount = ohms.reflectionFromToken(rewardAmount, false).div(1000);

        reflectionTillNowPerToken = reflectionTillNowPerToken.add(reflectionRewardAmount.div(totalStakedToken));
        lastUpdatedBlock = block.number;
    }
 
    // View function to see pending reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        User storage user = users[_user];
        uint256 accReflectionPerToken = reflectionTillNowPerToken;

        if (block.number > lastUpdatedBlock) {
            uint256 rewardAmount = (block.number - lastUpdatedBlock).mul(rewardPerBlock);
            uint256 reflectionRewardAmount = (ohms.reflectionFromToken(rewardAmount, false)).div(1000);
            accReflectionPerToken = accReflectionPerToken.add(reflectionRewardAmount.div(totalStakedToken));
        }
        return ohms.tokenFromReflection((user.ohmsBalance.mul(accReflectionPerToken).sub(user.paidReflection)).mul(1000));
    }

    function deposit(uint256 amount) public {
        User storage user = users[msg.sender];
        update();
        userArray.push(address(msg.sender));

        if (user.ohmsBalance > 0) {
            uint256 _pendingReflection = (user.ohmsBalance.mul(reflectionTillNowPerToken).sub(user.paidReflection)).mul(1000);
            uint256 _ohmsReward = ohms.tokenFromReflection(_pendingReflection);
            
            if(totalRewardReflection.sub(_pendingReflection) > 0){
                if(_ohmsReward > 0){                
                    totalRewardReflection = totalRewardReflection.sub(_pendingReflection);
                    ohms.transfer(address(msg.sender), _ohmsReward);
                    emit RewardClaimed(msg.sender, _ohmsReward);
                }
            }
        }

        uint256 reflectionAmount = ohms.reflectionFromToken(amount, true);

        if(amount > 0){
            user.reflectionBalance = user.reflectionBalance.add(reflectionAmount);
            totalStakedReflection = totalStakedReflection.add(reflectionAmount);
            ohms.transferFrom(address(msg.sender), address(this), amount);
            emit Deposit(msg.sender, amount);
        }

        activate();
        user.paidReflection = user.ohmsBalance.mul(reflectionTillNowPerToken);

    }

    function withdraw(uint256 amount) public {
        User storage user = users[msg.sender];
        require(user.reflectionBalance >= ohms.reflectionFromToken(amount, false), "withdraw amount exceeds deposited amount");
        update();

        uint256 _pendingReward = (user.ohmsBalance.mul(reflectionTillNowPerToken).sub(user.paidReflection)).mul(1000);
        uint256 _ohmsReward = ohms.tokenFromReflection(_pendingReward);

        if(totalRewardReflection > _pendingReward){
            if(_ohmsReward > 0){                
                totalRewardReflection = totalRewardReflection.sub(_pendingReward);
                ohms.transfer(address(msg.sender), _ohmsReward);
                emit RewardClaimed(msg.sender, _ohmsReward);
            }
        }

        uint256 reflectionAmount = ohms.reflectionFromToken(amount, false);

        if (amount > 0) {
            user.reflectionBalance = user.reflectionBalance.sub(reflectionAmount);
            totalStakedReflection = totalStakedReflection.sub(reflectionAmount);
            ohms.transfer(address(msg.sender), amount);
            emit Withdraw(msg.sender, amount);
        }
        
        activate();
        user.paidReflection = user.ohmsBalance.mul(reflectionTillNowPerToken);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        User storage user = users[msg.sender];

        totalStakedReflection = totalStakedReflection.sub(user.reflectionBalance);
        uint256 ohmsAmount = ohms.tokenFromReflection(user.reflectionBalance);
        ohms.transfer(address(msg.sender), ohmsAmount);

        emit EmergencyWithdraw(msg.sender, ohmsAmount);

        user.reflectionBalance = 0;
        user.paidReflection = 0;
        user.ohmsBalance = 0;
    }

    // Send OHMS rewards to the contract for staking
    function sendRewards(uint256 amount) public {
        ohms.transferFrom(address(msg.sender), address(this), amount);
        uint256 reflectionAmount = ohms.reflectionFromToken(amount, true);
        totalRewardReflection = totalRewardReflection.add(reflectionAmount);
    }

    function restakeRewards() public {
        User storage user = users[msg.sender];
        update();
        uint256 _pendingReward = (user.ohmsBalance.mul(reflectionTillNowPerToken).sub(user.paidReflection)).mul(1000);

        if(totalRewardReflection > _pendingReward){
            user.reflectionBalance = user.reflectionBalance.add(_pendingReward);
            totalStakedReflection = totalStakedReflection.add(_pendingReward);
            totalRewardReflection = totalRewardReflection.sub(_pendingReward);
            emit Restake(msg.sender, ohms.tokenFromReflection(_pendingReward));
        }

        activate();
        user.paidReflection = user.ohmsBalance.mul(reflectionTillNowPerToken);

    }


    function activate() public {
        User storage user = users[msg.sender];
        uint256 trueOhmsBalance = ohms.tokenFromReflection(user.reflectionBalance);
        
        if(trueOhmsBalance >= user.ohmsBalance){
            uint256 difference = trueOhmsBalance.sub(user.ohmsBalance);
            totalStakedToken = totalStakedToken.add(difference);
        }
        else {
            uint256 difference = user.ohmsBalance.sub(trueOhmsBalance);
            totalStakedToken = totalStakedToken.sub(difference);
        }  

        user.ohmsBalance = trueOhmsBalance;  
    }

}