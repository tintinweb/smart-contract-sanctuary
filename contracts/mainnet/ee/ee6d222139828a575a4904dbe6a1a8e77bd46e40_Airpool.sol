/**
 *Submitted for verification at Etherscan.io on 2020-11-06
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;

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

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Airpool is Ownable {
    using SafeMath for uint256;
    
    event Staked(
        address lpToken,
        address user,
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );
    
    event Unstaked(
        address user,
        address lpToken,
        uint256 amountToken
    );
    
    event RewardWithdrawn(
        address user,
        uint256 amount
    );
    
    uint256 private constant rewardMultiplier = 1e17;
    
    struct Stake {
        uint256 stakeAmount; // lp token address to token amount
        uint256 totalStakedAmountByUser; // sum of all lp tokens
        uint256 lastInteractionBlockNumber; // block number at last withdraw
        uint256 stakingPeriodEndTime;
    }
    
    mapping(address => Stake) public userToStakes; // user to stake
    uint256 public totalStakedAmount; // sum of stakes by all of the users across all lp
    
    address internal uniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address internal uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //address internal WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
     
    IUniswapV2Factory public uniswapFactory = IUniswapV2Factory(uniswapFactoryAddress);
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);

    address public token;
    address public lpToken;
    
    uint256 public blockMiningTime = 15;
    uint256 public blockReward = 100000000000000000;
    uint256 public stakingDuration = 2592000;
    uint256 public minimumAmount = 1000000000000000;
    uint256 public maximumAmount = 100000000000000000000; 

    constructor(address airdropToken, address pairToken) public {
        token = airdropToken;
        lpToken = pairToken;
        
        IERC20(token).approve(uniswapRouterAddress, 1e52); // approve uniswap router
        
        IERC20(token).approve(address(this), 1e52); // approve sending token
        IERC20(lpToken).approve(address(this), 1e52); // approve sending lp token
    }
    
    function setMinimumAmount(uint256 amount) external onlyOwner {
        require(
            amount != 0,
            "minimum amount cannot be zero"
        );
        minimumAmount = amount;
    }
    
    function setMaximumAmount(uint256 amount) external onlyOwner {
        require(
            amount != 0,
            "maximum amount cannot be zero"
        );
        maximumAmount = amount;
    }
    
    function setBlockReward(uint256 rewardAmount) external onlyOwner {
        require(
            rewardAmount != 0,
            "new reward cannot be zero"
        );
        blockReward = rewardAmount;
    }
    
    function setStakingDuration(uint256 duration) external onlyOwner {
        require(
            duration != 0,
            "new reward cannot be zero"
        );
        stakingDuration = duration;
    }

    function changeBlockMiningTime(uint256 newTime) external onlyOwner {
        require(
            newTime != 0,
            "new time cannot be zero"
        );
        blockMiningTime = newTime;
    }

    function supplyAirpool(
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin
    ) external payable {
        require(
            msg.value != 0, // must send ether
            "amount should be greater than 0"
        );
        
        require(
            msg.value >= minimumAmount,
            "amount too low"
        );
        
        require(
            msg.value > maximumAmount,
            "amount too high"
        );

        uint deadline = block.timestamp.add(2 hours); // set deadline to 2 hours from now

        (uint amountToken, uint amountETH, uint liquidity) = uniswapRouter.addLiquidityETH.value(msg.value)(
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline 
        );

        _withdrawReward(_msgSender()); // withdraw any existing rewards

        totalStakedAmount = totalStakedAmount.add(liquidity); // add stake amount to sum of all stakes across al lps
        
        Stake storage currentStake = userToStakes[_msgSender()];
        currentStake.stakingPeriodEndTime = block.timestamp.add(
            stakingDuration
        ); // set the staking period end time

        currentStake.stakeAmount =  currentStake.stakeAmount // add stake amount by lp
            .add(liquidity);
        
        currentStake.totalStakedAmountByUser = currentStake.totalStakedAmountByUser // add stake amount to sum of all stakes by user
            .add(liquidity);

        emit Staked(
            lpToken,
            _msgSender(),
            amountToken,
            amountETH,
            liquidity
        ); // broadcast event
    }
    
    function unstake() external {
        _withdrawReward(_msgSender());
        Stake storage currentStake = userToStakes[_msgSender()];
        uint256 stakeAmountToDeduct;
        bool executeUnstaking;
        uint256 stakeAmount = currentStake.stakeAmount;
            
        if (currentStake.stakeAmount == 0) {
            revert("no stake");
        }

        if (currentStake.stakingPeriodEndTime <= block.timestamp) {
            executeUnstaking = true;
        }

        require(
            executeUnstaking,
            "cannot unstake"
        );
        
        currentStake.stakeAmount = 0;
        
        currentStake.totalStakedAmountByUser = currentStake.totalStakedAmountByUser
            .sub(stakeAmount);
        
        stakeAmountToDeduct = stakeAmountToDeduct.add(stakeAmount);
        
        require(
            IERC20(lpToken).transferFrom(address(this), _msgSender(), stakeAmount), // transfer staked tokens back to the user
            "#transfer failed"
        );
        
        emit Unstaked(lpToken, _msgSender(), stakeAmount);
        
        totalStakedAmount = totalStakedAmount.sub(stakeAmountToDeduct); // subtract unstaked amount from total staked amount
    }
    
    function withdrawReward() external {
        _withdrawReward(_msgSender());
    }
    
    function getBlockCountSinceLastIntreraction(address user) public view returns(uint256) {
        uint256 lastInteractionBlockNum = userToStakes[user].lastInteractionBlockNumber;
        if (lastInteractionBlockNum == 0) {
            return 0;
        }
        
        return block.number.sub(lastInteractionBlockNum);
    }
    
    function getTotalStakeAmountByUser(address user) public view returns(uint256) {
        return userToStakes[user].totalStakedAmountByUser;
    }
    
    function getStakeAmountByUser(
        address user
    ) public view returns(uint256) {
        return userToStakes[user].stakeAmount;
    }
    
    function getRewardByAddress(
        address user
    ) public view returns(uint256) {
        if (totalStakedAmount == 0) {
            return 0;
        }
        
        Stake storage currentStake = userToStakes[user];
        
        uint256 blockCount = block.number
            .sub(currentStake.lastInteractionBlockNumber);
        
        uint256 totalReward = blockCount.mul(blockReward);
        
        return totalReward
            .mul(currentStake.totalStakedAmountByUser)
            .div(totalStakedAmount);
    }
    
    function _withdrawReward(address user) internal {
        uint256 rewardAmount = getRewardByAddress(user);
        
        if (rewardAmount != 0) {
            require(
                IERC20(token).transferFrom(address(this), user, rewardAmount), // get the tokens from user to the contract
                "#transferFrom failed"
            );
            emit RewardWithdrawn(user, rewardAmount);
        }
        
        userToStakes[user].lastInteractionBlockNumber = block.number;
    }
}