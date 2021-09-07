/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// SPDX-License-Identifier: MIT

// File libraries/Math.sol

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// File interfaces/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


// File libraries/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File libraries/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File libraries/RewardDistributionRecipient.sol

pragma solidity ^0.5.0;

contract RewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "!distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution) external onlyOwner {
        rewardDistribution = _rewardDistribution;
    }

    constructor() public {
        rewardDistribution = msg.sender;
    }
}


// File libraries/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File interfaces/IThoreum.sol

pragma solidity ^0.5.0;

interface IThoreum {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256);

    function tokenFromReflection(uint256 rAmount) external view returns (uint256);

    function isExcludedFromFee(address account) external view returns (bool);
}


// File libraries/ThoreumWrapper.sol

pragma solidity ^0.5.0;


contract ThoreumWrapper {
    using SafeMath for uint256;

    IThoreum public stakedToken;

    uint256 private _totalReflections;
    mapping(address => uint256) private _reflections;

    constructor(address _stakedToken) public {
        stakedToken = IThoreum(_stakedToken);
    }

    function totalSupply() public view returns (uint256) {
        return stakedToken.tokenFromReflection(_totalReflections);
    }

    function balanceOf(address account) public view returns (uint256) {
        return stakedToken.tokenFromReflection(_reflections[account]);
    }

    function stake(uint256 amount) public {
        _totalReflections = _totalReflections.add(stakedToken.reflectionFromToken(amount, !stakedToken.isExcludedFromFee(address(this))));
        _reflections[msg.sender] = _reflections[msg.sender].add(stakedToken.reflectionFromToken(amount, !stakedToken.isExcludedFromFee(address(this))));
        stakedToken.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalReflections = _totalReflections.sub(stakedToken.reflectionFromToken(amount, false));
        _reflections[msg.sender] = _reflections[msg.sender].sub(stakedToken.reflectionFromToken(amount, false));
        // don't deduct fee before transfer
        stakedToken.transfer(msg.sender, amount);
    }
}


// File ThunderBoost.sol

pragma solidity ^0.5.0;


contract ThunderBoost is ThoreumWrapper, RewardDistributionRecipient {
    IERC20 public rewardToken;
    uint256 public duration;
    uint256 public capPerAddress;

    // The withdrawal interval
    uint256 public withdrawalInterval;

    // Max withdrawal interval: 10000 days.
    uint256 public constant MAXIMUM_WITHDRAWAL_INTERVAL = 10000 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 nextWithdrawalUntil; // When can the user withdraw again.
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event EmergencyRewardWithdraw(address indexed user, uint256 amount);
    event EmergencyTokenWithdraw(address indexed user, address token, uint256 amount);
    event UpdateCapPerAddress(uint256 newAmount);
    event NewWithdrawalInterval(uint256 interval);

    constructor(address _stakedToken, address _rewardToken, uint256 _duration, uint256 _capPerAddress, uint256 _withdrawalInterval) public
    ThoreumWrapper(_stakedToken)
    RewardDistributionRecipient()
    {
        require(_duration > 0, "Cannot set duration 0");
        require(_stakedToken != _rewardToken, "_stakedToken must be different from _rewardToken");
        require(_withdrawalInterval <= MAXIMUM_WITHDRAWAL_INTERVAL, "Invalid withdrawal interval");

        rewardToken = IERC20(_rewardToken);
        duration = _duration;
        capPerAddress = _capPerAddress;
        withdrawalInterval = _withdrawalInterval;
    }

    function canWithdraw(address account) external view returns (bool) {
        UserInfo storage user = userInfo[account];
        return (block.timestamp >= user.nextWithdrawalUntil);
    }

    modifier updateReward(address account) {
        UserInfo storage user = userInfo[account];

        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            user.amount = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0 || lastTimeRewardApplicable() == lastUpdateTime) {
            return rewardPerTokenStored;
        }

        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalSupply())
        );
    }

    function earned(address account) public view returns (uint256) {
        UserInfo storage user = userInfo[account];

        return
        balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(user.amount);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) {
        UserInfo storage user = userInfo[msg.sender];

        require(amount > 0, "Cannot stake 0");
        require(periodFinish > 0, "Pool not started yet");

        require(balanceOf(msg.sender).add(amount) <= capPerAddress, "Cap per address reached");
        super.stake(amount);

        user.nextWithdrawalUntil = block.timestamp.add(withdrawalInterval);

        if (user.nextWithdrawalUntil >= periodFinish) {
            user.nextWithdrawalUntil = periodFinish;
        }

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        UserInfo storage user = userInfo[msg.sender];
        require(amount > 0, "Cannot withdraw 0");
        require(block.timestamp >= user.nextWithdrawalUntil, "Withdrawal locked");

        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        UserInfo storage user = userInfo[msg.sender];
        require(block.timestamp >= user.nextWithdrawalUntil, "Withdrawal locked");

        withdraw(balanceOf(msg.sender));
        getReward();

        user.nextWithdrawalUntil = 0;
    }

    function getReward() public updateReward(msg.sender) {
        UserInfo storage user = userInfo[msg.sender];

        uint256 reward = earned(msg.sender);

        if (reward > 0) {
            user.amount = 0;
            safeRewardsTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Notify 0 to end pool
    function notifyRewardAmount(uint256 newRewards) external onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = newRewards.div(duration);
        } else {
            uint256 remainingTime = periodFinish.sub(block.timestamp);
            uint256 leftoverRewards = remainingTime.mul(rewardRate);
            rewardRate = newRewards.add(leftoverRewards).div(duration);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);

        emit RewardAdded(newRewards);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 amount) external onlyOwner {
        require(amount <= rewardToken.balanceOf(address(this)), 'not enough token');
        safeRewardsTransfer(msg.sender, amount);
        emit EmergencyRewardWithdraw(msg.sender, amount);
    }

    // Withdraw Token. EMERGENCY ONLY.
    function emergencyTokenWithdraw(address _token, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_token);

        uint256 amount = _amount;

        if(amount > token.balanceOf(address(this))){
            amount = token.balanceOf(address(this));
        }

        token.transfer(msg.sender, amount);
        emit EmergencyTokenWithdraw(msg.sender, _token, amount);
    }

    function stopPool() external onlyOwner {
        rewardRate = 0;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
    }

    function setCapPerAddress(uint256 _newCap) external onlyOwner {
        require(_newCap > 0, "Cannot set 0");
        capPerAddress = _newCap;

        emit UpdateCapPerAddress(_newCap);
    }

    function safeRewardsTransfer(address _to, uint256 _amount) internal {
        if (rewardToken.balanceOf(address(this)) > 0) {
            uint256 rewardBal = rewardToken.balanceOf(address(this));
            if (_amount >= rewardBal) {
                rewardToken.transfer(_to, rewardBal);
            } else if (_amount > 0) {
                rewardToken.transfer(_to, _amount);
            }
        }
    }

    function updateWithdrawalInterval(uint256 _interval) external onlyOwner {
        require(_interval <= MAXIMUM_WITHDRAWAL_INTERVAL, "Invalid withdrawal interval");
        withdrawalInterval = _interval;
        emit NewWithdrawalInterval(_interval);
    }
}