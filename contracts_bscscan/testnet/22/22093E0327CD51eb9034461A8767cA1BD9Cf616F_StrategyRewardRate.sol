/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// File: @uniswap/v2-core/contracts/libraries/Math.sol

pragma solidity =0.5.16;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity-2.3.0/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity-2.3.0/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// File: openzeppelin-solidity-2.3.0/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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

// File: contracts/SafeToken.sol

pragma solidity 0.5.16;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call.value(value)(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

// File: contracts/StrategyRewardRate.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;







contract StrategyRewardRate is Ownable , ReentrancyGuard {
    using SafeToken for address;
    using SafeMath for uint256;


    /* ========== STATE VARIABLES ========== */

    IERC20 public stakingToken;
    IERC20 public REWARD_TOKEN;

    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;
    uint256 public rewardsDuration;

    uint256 public lastUpdateTime;
    uint256 public periodFinish;

    mapping(address => mapping (uint256 => uint256)) private _balances;
    mapping(address => mapping (uint256 => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping (uint256 => uint256)) public rewards;


    uint256 private _totalSupply;

    mapping (address => bool) public whitelisted;
    mapping (address => bool) public rewardsDistributions;

    bool public emergencyStop;

    address public goblin;

    /* mapping (address => uint256) private claimLock; */

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardToken,
        address _goblin
    ) public {

        REWARD_TOKEN = IERC20(_rewardToken);

        goblin = _goblin;

        rewardsDuration = 1 days;

    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account, uint256 id) external view returns (uint256) {
        return _balances[account][id];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account, uint256 id) public view returns (uint256) {
        return _balances[account][id].mul(rewardPerToken().sub(userRewardPerTokenPaid[account][id])).div(1e18).add(rewards[account][id]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function deposit(address user, uint256 id, uint256 amount) external nonReentrant updateReward(user, id)
     isNotEmergencyStop
     onlyGoblin
     {
        require(amount > 0, "Cannot stake 0");

        // remove user share
        _totalSupply = _totalSupply.sub(_balances[user][id]);
        _balances[user][id] = 0;

        // deposit amount include fee
        uint256 amounAfterFee = amount;
        _totalSupply = _totalSupply.add(amounAfterFee);
        _balances[user][id] = _balances[user][id].add(amounAfterFee);

        emit Staked(user, amount);
    }

    function withdraw(address user, uint256 id, uint256 amount) internal nonReentrant updateReward(user, id) {
        require(amount > 0, "Cannot withdraw 0");

        _totalSupply = _totalSupply.sub(amount);
        _balances[user][id] = _balances[user][id].sub(amount);

        emit Withdrawn(user, amount);
    }

    function getReward(address user, uint256 id) public nonReentrant updateReward(user, id) {
        uint256 reward = rewards[user][id];
        if (reward > 0) {
            rewards[user][id] = 0;

            address rewardsToken = address(REWARD_TOKEN);
            uint256 totalRewardAmount = rewardsToken.balanceOf(address(this));
            if(totalRewardAmount >= reward){
              rewardsToken.safeTransfer(user, reward);
              emit RewardPaid(user, reward);
            }
        }
    }

    function exit(address user, uint256 id) external onlyGoblin {
        uint256 amount = _balances[user][id];
        withdraw(user, id, amount);
        getReward(user, id);
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) public onlyRewardsDistribution {
        address rewardsToken = address(REWARD_TOKEN);

        rewardsToken.safeTransferFrom(msg.sender, address(this), reward);
        _notifyRewardAmount(reward);
    }


    function() external payable {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function _notifyRewardAmount(uint256 reward) internal updateReward(address(0), 0) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        IERC20 rewardsToken = IERC20(REWARD_TOKEN);
        uint256 balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function addRewardsDistribution(address _distributor) public onlyOwner
    {
        rewardsDistributions[_distributor] = true;
        emit AddRewardsDistribution(_distributor);
    }

    function removeRewardsDistribution(address _distributor) public onlyOwner
    {
        rewardsDistributions[_distributor] = false;
        emit RemoveRewardsDistribution(_distributor);
    }

    function addWhiteList(address _whitelistAddress) public onlyOwner
    {
        whitelisted[_whitelistAddress] = true;
        emit AddWhiteListAddress(_whitelistAddress);
    }

    function removeWhiteList(address _whitelistAddress) public onlyOwner
    {
        whitelisted[_whitelistAddress] = false;
        emit RemoveWhiteListAddress(_whitelistAddress);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(periodFinish == 0 || block.timestamp > periodFinish, "Reward duration can only be updated after the period ends");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function panic() public onlyOwner {
        emergencyStop = true;
        emit EmergencyWithdrawLp(emergencyStop);
    }

    /* ========== MODIFIERS ========== */

    /// @dev Throws if called by any account other than the goblin.
    modifier onlyGoblin() {
        require(isGoblin(), "caller is not the goblin");
        _;
    }

    /// @dev Returns true if the caller is the current goblin.
    function isGoblin() public view returns (bool) {
        return msg.sender == goblin;
    }

    modifier updateReward(address account, uint256 id) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account][id] = earned(account, id);
            userRewardPerTokenPaid[account][id] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyRewardsDistribution() {
        require(rewardsDistributions[msg.sender] , "Caller is not RewardsDistribution contract");
        _;
    }

    modifier onlyWhitelistOrEOA() {
        require(msg.sender == tx.origin || whitelisted[msg.sender] , "Caller is not EOA or whitelisted contract");
        _;
    }

    modifier isNotEmergencyStop() {
        require(!emergencyStop , "Emergency Stop");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event AddRewardsDistribution(address indexed distributor);
    event RemoveRewardsDistribution(address indexed distributor);
    event AddWhiteListAddress(address indexed whitelistAddress);
    event RemoveWhiteListAddress(address indexed whitelistAddress);
    event EmergencyWithdrawLp(bool _emergencyStop);
    event ClaimReward(address indexed user, uint256 amount);

}