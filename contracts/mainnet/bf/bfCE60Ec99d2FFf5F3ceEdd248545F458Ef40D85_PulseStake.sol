/**
 *
 * @title PulseStake, pulse token staking contract
 * @dev Holders of Pulse will have the choice to stake in the contract
 * for 5 different durations.
 *
 * Staking reward will be paid out in Pulse obtained
 * from the global tax on all Pulse transfers. 
 *      
 * Only one staking duration is allowed per user address.
 *
 */

pragma solidity >=0.6.0 <=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PulseStake is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct UserStakeBracketInfo {
        uint256 reward;
        uint256 initial;
        uint256 payday;
        uint256 startday;
    }
    
    IERC20 public Pulse;

    uint256 private percentageDivisor; 

    uint256 public totalStaked = 0;
    uint256 public totalRewards = 0;

    mapping (address => mapping(uint256 => UserStakeBracketInfo)) public stakes;
    mapping (uint256 => uint256) public bracketDays;
    mapping (uint256 => uint256) public stakeReward;
    mapping (uint256 => uint256) public totalStakedInBracket;
    mapping (uint256 => uint256) public totalRewardsInBracket;
    mapping (address => bool) public Staked;

    //events
    event userStaked(address User, uint256 Amount, uint256 BracketTierLengthDays);
    event userClaimed(address User, uint256 Amount, uint256 BracketTierLengthDays);
    event stakeRewardUpdated(uint256 stakeBracket, uint256 Percentage);

    constructor(address _pulse) public {
        Pulse = IERC20(_pulse);

        stakeReward[0] = 25;
        stakeReward[1] = 55;
        stakeReward[2] = 190;
        stakeReward[3] = 450;
        stakeReward[4] = 1200;

        bracketDays[0] = 14 days;
        bracketDays[1] = 31 days;
        bracketDays[2] = 90 days;
        bracketDays[3] = 183 days;
        bracketDays[4] = 365 days;

        percentageDivisor = 1000;
    }

    // public entry functions for staking
    function stake14(uint256 _amount) public nonReentrant {
        //
        stake(_amount, 0);
    }
    function stake1mo(uint256 _amount) public nonReentrant {
        //
        stake(_amount, 1);
    }
    function stake3mo(uint256 _amount) public nonReentrant {
        //
        stake(_amount, 2);
    }
    function stake6mo(uint256 _amount) public nonReentrant {
        //
        stake(_amount, 3);
    }
    function stake12mo(uint256 _amount) public nonReentrant {
        //
        stake(_amount, 4);
    }


    function stake(uint256 _amount, uint256 _stakeBracket) internal {
        require(stakes[_msgSender()][_stakeBracket].payday == 0, "PulseStake: User already staked for this bracket!");
        require(_amount >= 1e18, "PulseStake: Minimum of 1 token to stake!");
        require(!Staked[_msgSender()], "PulseStake: User is already stake in a pool!");
        
        // calculate reward
        uint256 _reward = calculateReward(_amount, _stakeBracket);

        // contract must have funds
        require(Pulse.balanceOf(address(this)) > totalOwedValue().add(_reward).add(_amount), "PulseStake: Contract does not have enough tokens, try again soon!");

        // wrapped transfer from revert 
        require(Pulse.transferFrom(_msgSender(), address(this), _amount), "PulseStake: Transfer Failed");

        stakes[_msgSender()][_stakeBracket].payday = block.timestamp.add(bracketDays[_stakeBracket]);
        stakes[_msgSender()][_stakeBracket].reward = _reward;
        stakes[_msgSender()][_stakeBracket].startday = block.timestamp;
        stakes[_msgSender()][_stakeBracket].initial = _amount;

        // update stats on total and on a per bracket basis
        totalStaked = totalStaked.add(_amount);
        totalRewards = totalRewards.add(_reward);
        totalStakedInBracket[_stakeBracket] = totalStakedInBracket[_stakeBracket].add(_amount);
        totalRewardsInBracket[_stakeBracket] = totalRewardsInBracket[_stakeBracket].add(_reward);

        Staked[_msgSender()] = true;
        emit userStaked(_msgSender(), _amount, bracketDays[_stakeBracket].div(1 days));
    }

    // public entry functions for staking
    function claim14() public nonReentrant {
        //
        claim(0);
    }
    function claim1mo() public nonReentrant {
        //
        claim(1);
    }
    function claim3mo() public nonReentrant {
        //
        claim(2);
    }
    function claim6mo() public nonReentrant {
        //
        claim(3);
    }
    function claim12mo() public nonReentrant {
        //
        claim(4);
    }

    function claim(uint256 _stakeBracket) internal {
        require(owedBalance(_msgSender(),_stakeBracket) > 0, "PulseStake: No rewards for this bracket!");
        require(block.timestamp >= stakes[_msgSender()][_stakeBracket].payday, "PulseStake: Too Early to withdraw from this bracket!");

        uint256 owed = (stakes[_msgSender()][_stakeBracket].reward).add(stakes[_msgSender()][_stakeBracket].initial);

        // update total and per bracket stats
        totalStaked = totalStaked.sub(stakes[_msgSender()][_stakeBracket].initial);
        totalRewards = totalRewards.sub(stakes[_msgSender()][_stakeBracket].reward);
        totalStakedInBracket[_stakeBracket] = totalStakedInBracket[_stakeBracket].sub(stakes[_msgSender()][_stakeBracket].initial);
        totalRewardsInBracket[_stakeBracket] = totalRewardsInBracket[_stakeBracket].sub(stakes[_msgSender()][_stakeBracket].reward);

        stakes[_msgSender()][_stakeBracket].initial = 0;
        stakes[_msgSender()][_stakeBracket].reward = 0;
        stakes[_msgSender()][_stakeBracket].payday = 0;
        stakes[_msgSender()][_stakeBracket].startday = 0;

        require(Pulse.transfer(_msgSender(), owed), "PulseStake: Transfer Failed");

        Staked[_msgSender()] = false;

        emit userClaimed(_msgSender(), owed, bracketDays[_stakeBracket].div(1 days));
    }

    function calculateReward(uint256 _amount, uint256 _stakeBracket) public view returns (uint256) {
        require(_amount > 1e18 && _stakeBracket >=0 && _stakeBracket <= 4, "PulseStake: Incorrect parameter entry!");

        // amount required to be 1e18, when percentage divisor < multiplier
        // no error will ocur
        return (_amount.mul(stakeReward[_stakeBracket])).div(percentageDivisor);
    }

    /* ===== Public View Functions ===== */

    function totalOwedValue() public view returns (uint256) {
        return totalStaked.add(totalRewards);
    }


    function owedBalance(address _address, uint256 _stakeBracket) public view returns(uint256) {
        return stakes[_address][_stakeBracket].initial.add(stakes[_address][_stakeBracket].reward);
    }

    /* ===== Owner Functions ===== */

    /* 
    * Allows the owner to withdraw leftover Pulse Tokens
    * NOTE: this will not allow the owner to withdraw reward allocation
    */
    function reclaimPulse(uint256 _amount) public onlyOwner {
        require(_amount <= Pulse.balanceOf(address(this)).sub(totalOwedValue()), "PulseStake: Attempting to withdraw too many tokens!");
        Pulse.transfer(_msgSender(), _amount);
    }


    /* 
    * Allows the owner to change the return rate for a given bracket
    * NOTE: changes to this rate will only affect those that stake AFTER this change.
    * Will not affect the currently staked amounts.
    */
    function changeReturnRateForBracket(uint256 _percentage, uint256 _stakeBracket) public onlyOwner {
        require(_stakeBracket <= 4);
        // TAKE NOTE OF FORMATTING:
        // stakeReward[0] = 25;
        // stakeReward[1] = 55;
        // stakeReward[2] = 190;
        // stakeReward[3] = 450;
        // stakeReward[4] = 1200;

        stakeReward[_stakeBracket] = _percentage;
        emit stakeRewardUpdated(_stakeBracket,_percentage);
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

import "../GSN/Context.sol";
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