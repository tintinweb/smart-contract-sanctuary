// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./interfaces/ILiquidearn.sol";
import "./utils/Context.sol";
import "./utils/SafeMath.sol";
import "./utils/Ownable.sol";
contract Staking is Context, Ownable {
    using SafeMath for uint256;


    address public lEARN;
    address public lpToken;
    uint256 constant public SECONDS_IN_A_DAY = 86400;
    // uint256 public SECONDS_IN_A_DAY = 1;
    uint256 constant public STAKING_DAYS_MIN_LEARN = 7;
    uint256 constant public STAKING_DAYS_MIN_LP = 14;
    uint256 constant public STAKING_AMOUNT_MIN_LEARN = 10000000000000000000; //10
    uint256 constant public STAKING_AMOUNT_MIN_LP = 5000000000000000000; //5
    
    uint256 public rewardsRateLearn;
    uint256 public rewardsRateLp;

    mapping(bool => uint256) public totalStakingAmount;
    mapping(bool => uint256) public totalStakers;

    struct DepositInfo {
        uint256 amount;
        uint256 time;
        uint256 rewards;
        uint256 claimed;
    }

    mapping (address => mapping(bool => DepositInfo)) public userInfo;
    event Staking(address indexed sender, uint amount, bool isLpToken, uint time);
    event Unstaking(address indexed sender, uint amount, bool isLpToken, uint time);
    event Claim(address indexed sender, uint amount, bool isLpToken, uint time);

    function setLpToken(address _lpToken) external onlyOwner {
        lpToken = _lpToken;
    }

    function stake(uint256 amount, bool isLpToken) external {
        
        if (isLpToken) {
            require(amount >= STAKING_AMOUNT_MIN_LP, 'Staking: Invalid Staking Amount');
            IERC20(lpToken).transferFrom(msg.sender, address(this), amount);
        } else {
            require(amount >= STAKING_AMOUNT_MIN_LEARN, 'Staking: Invalid Staking Amount');
            ILiquidearn(lEARN).transferFrom(msg.sender, address(this), amount);
        }

        DepositInfo storage depositInfo = userInfo[msg.sender][isLpToken];
        if (depositInfo.amount != 0) {
            uint256 _reward = _checkReward(msg.sender, isLpToken);
            depositInfo.rewards = (depositInfo.rewards).add(_reward);
        } else {
            totalStakers[isLpToken] = totalStakers[isLpToken].add(1);
        }
        
        depositInfo.amount = depositInfo.amount + amount;
        depositInfo.time = block.number;

        totalStakingAmount[isLpToken] = totalStakingAmount[isLpToken].add(amount);

        emit Staking(msg.sender, amount, isLpToken, block.timestamp);
    }

    function _checkReward(address staker, bool isLpToken) internal view returns (uint256) {
        DepositInfo storage depositInfo = userInfo[staker][isLpToken];
        
        uint256 reward;
        if (isLpToken) {
            reward = depositInfo.amount * rewardsRateLp * (block.number - depositInfo.time) / (100 * 365 * SECONDS_IN_A_DAY);
        }
        else {
            reward = depositInfo.amount * rewardsRateLearn * (block.number - depositInfo.time) / (100 * 365 * SECONDS_IN_A_DAY);
        }
        return reward;
    }

    function checkReward(bool isLpToken) public view returns (uint256) {
        return _checkReward(msg.sender, isLpToken);
    }

    function _getPending(address staker, bool isLpToken) internal view returns (uint256) {
        DepositInfo storage depositInfo = userInfo[staker][isLpToken];
        uint256 pending = _checkReward(staker, isLpToken);
        pending = pending.add(depositInfo.rewards).sub(depositInfo.claimed);
        return pending;
    }

    function getPending(bool isLpToken) external view returns (uint256) {
        return _getPending(msg.sender, isLpToken);
    }

    function _claim(address staker, bool isLpToken) internal returns (uint256) {
        DepositInfo storage depositInfo = userInfo[staker][isLpToken];
        uint256 stakingDaysMin;
        if (isLpToken) {
            stakingDaysMin = STAKING_DAYS_MIN_LP * SECONDS_IN_A_DAY;
        } else {
            stakingDaysMin = STAKING_DAYS_MIN_LEARN * SECONDS_IN_A_DAY;
        }
        require(depositInfo.time + stakingDaysMin <= block.number, 'Staking: Not able to unstake yet');
        uint256 pending = _getPending(staker, isLpToken);
        depositInfo.claimed = depositInfo.claimed.add(pending);
        ILiquidearn(lEARN).mint(staker, pending);
        return pending;
    }

    function claim(bool isLpToken) external {
        uint256 amount = _claim(msg.sender, isLpToken);
        emit Claim(msg.sender, amount, isLpToken, block.timestamp);
    }

    function unstake(uint256 amount, bool isLpToken) external {
        DepositInfo storage depositInfo = userInfo[msg.sender][isLpToken];
        require(depositInfo.amount >= amount, "Staking: Insufficient Amount");
        uint256 stakingDaysMin;
        if (isLpToken) {
            stakingDaysMin = STAKING_DAYS_MIN_LP * SECONDS_IN_A_DAY;
        } else {
            stakingDaysMin = STAKING_DAYS_MIN_LEARN * SECONDS_IN_A_DAY;
        }
        require(depositInfo.time + stakingDaysMin <= block.number, 'Staking: Not able to unstake yet');
        
        if (isLpToken) {
            IERC20(lpToken).transfer(msg.sender, amount);
        } else {
            ILiquidearn(lEARN).transfer(msg.sender, amount);
        }

        uint256 claimedAmount = _claim(msg.sender, isLpToken);
        depositInfo.rewards = depositInfo.rewards.add(claimedAmount);
        
        totalStakingAmount[isLpToken] = totalStakingAmount[isLpToken].sub(amount);

        depositInfo.amount = depositInfo.amount.sub(amount);

        if (depositInfo.amount == 0) {
            totalStakers[isLpToken] = totalStakers[isLpToken].sub(1);
        }
        emit Unstaking(msg.sender, amount, isLpToken, block.timestamp);
    }

    function withdrawToken(uint amount, bool isLpToken) external onlyOwner {
        if (isLpToken) {
            IERC20(lpToken).transfer(msg.sender, amount);
        } else {
            ILiquidearn(lEARN).transfer(msg.sender, amount);
        }
    }

    function setLEARN(address _lEARN) external onlyOwner {
        lEARN = _lEARN;
    }
    function setRewardsLEARN(uint _rewardsRateLearn) external onlyOwner {
        rewardsRateLearn = _rewardsRateLearn;
    }
    function setRewardsLp(uint _rewardsRateLp) external onlyOwner {
        rewardsRateLp = _rewardsRateLp;
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
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.7.2;

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function initialize(address newOwner) internal {
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
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

pragma solidity 0.7.2;

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

import "./IERC20.sol";

interface ILiquidearn is IERC20 {
    function setStakingAddr0(address _staking) external;
    
    function setStakingAddr1(address _staking) external;

    function mint(address to, uint256 amount) external returns (bool);
        
    function burn(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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