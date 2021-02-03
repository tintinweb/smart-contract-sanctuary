/**
 *Submitted for verification at Etherscan.io on 2021-02-02
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


LP token and VOLTS staking contract of the Volts-Ecosystem

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

interface StakedToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface RewardToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

contract Staking is Ownable {

    struct User {
        uint256 depositAmount;
        uint256 paidReward;
    }

    using SafeMath for uint256;

    mapping (address => User) public users;

    uint256 public rewardTillNowPerToken = 0;
    uint256 public lastUpdatedBlock;
    uint256 public rewardPerBlock;
    uint256 public scale = 1e18;
    uint256 public totalOhmsReward = 0;
    uint256 public totalStakedToken = 1;

    StakedToken public stakedToken;
    RewardToken public rewardToken;

    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event EmergencyWithdraw(address user, uint256 amount);
    event RewardClaimed(address user, uint256 amount);
    event RewardPerBlockChanged(uint256 oldValue, uint256 newValue);

    constructor (address _stakedToken, address _rewardToken, uint256 _rewardPerBlock) public {
        stakedToken = StakedToken(_stakedToken);
        rewardToken = RewardToken(_rewardToken);
        rewardPerBlock = _rewardPerBlock;
        lastUpdatedBlock = block.number;
    }

    // Returns the amount of OHMS rewarded to stakers per block
    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        update();
        emit RewardPerBlockChanged(rewardPerBlock, _rewardPerBlock);
        rewardPerBlock = _rewardPerBlock;
    }

    // Returns the amount of OHMS rewarded to stakers per block
    function getRewardPerBlock() external view returns (uint256){
        return rewardPerBlock;
    }

    // View function to see users staked balance on frontend.
    function getUserDepositAmount(address _user) external view returns (uint256){
        User storage user = users [_user];
        return user.depositAmount;
    }

    //  View function to see the amount staked in the contract in OHMS. 
    function getTotalStaked() external view returns (uint256){
        return stakedToken.balanceOf(address(this));
    }

    // View function to get the remaining reward balance in the contract in OHMS.
    function getTotalRemainingReward() external view returns (uint256){
        return rewardToken.balanceOf(address(this));
    }

    // Update reward variables of the pool to be up-to-date.
    function update() public {
        if (block.number <= lastUpdatedBlock) {
            return;
        }

        uint256 totalStakedToken;
        if(stakedToken.balanceOf(address(this)) > 0){
            totalStakedToken = stakedToken.balanceOf(address(this));
        }
        else{
            totalStakedToken = 1;
        }

        uint256 rewardAmount = (block.number - lastUpdatedBlock).mul(rewardPerBlock);
        totalOhmsReward = totalOhmsReward.add(rewardAmount);
        rewardTillNowPerToken = rewardTillNowPerToken.add(rewardAmount.mul(scale).div(totalStakedToken));
        lastUpdatedBlock = block.number;
    }

    // View function to see pending reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        User storage user = users[_user];
        uint256 accRewardPerToken = rewardTillNowPerToken;
        uint256 totalStakedToken;
        if(stakedToken.balanceOf(address(this)) > 0){
            totalStakedToken = stakedToken.balanceOf(address(this));
        }
        else{
            totalStakedToken = 1;
        }

        if (block.number > lastUpdatedBlock) {
            uint256 rewardAmount = (block.number - lastUpdatedBlock).mul(rewardPerBlock);
            accRewardPerToken = accRewardPerToken.add(rewardAmount.mul(scale).div(totalStakedToken));
        }
        return user.depositAmount.mul(accRewardPerToken).div(scale).sub(user.paidReward);
    }

    function deposit(uint256 amount) public {
        User storage user = users[msg.sender];
        update();

        if (user.depositAmount > 0) {
            uint256 _pendingReward = user.depositAmount.mul(rewardTillNowPerToken).div(scale).sub(user.paidReward);
            rewardToken.transfer(msg.sender, _pendingReward);
            emit RewardClaimed(msg.sender, _pendingReward);
        }

        user.depositAmount = user.depositAmount.add(amount);
        user.paidReward = user.depositAmount.mul(rewardTillNowPerToken).div(scale);

        stakedToken.transferFrom(address(msg.sender), address(this), amount);
        totalStakedToken = totalStakedToken.add(amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        User storage user = users[msg.sender];
        require(user.depositAmount >= amount, "withdraw amount exceeds deposited amount");
        update();

        uint256 _pendingReward = user.depositAmount.mul(rewardTillNowPerToken).div(scale).sub(user.paidReward);
        rewardToken.transfer(msg.sender, _pendingReward);
        emit RewardClaimed(msg.sender, _pendingReward);

        if (amount > 0) {
            user.depositAmount = user.depositAmount.sub(amount);
            stakedToken.transfer(address(msg.sender), amount);
            totalStakedToken = totalStakedToken.sub(amount);
            emit Withdraw(msg.sender, amount);
        }

        user.paidReward = user.depositAmount.mul(rewardTillNowPerToken).div(scale);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        User storage user = users[msg.sender];

        totalStakedToken = totalStakedToken.sub(user.depositAmount);
        stakedToken.transfer(msg.sender, user.depositAmount);

        emit EmergencyWithdraw(msg.sender, user.depositAmount);

        user.depositAmount = 0;
        user.paidReward = 0;
    }
}