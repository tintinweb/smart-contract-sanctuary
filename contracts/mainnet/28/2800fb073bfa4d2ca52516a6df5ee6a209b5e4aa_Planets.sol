// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ReentrancyGuard {
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

contract Planets is ReentrancyGuard {
    using SafeMath for uint256;
    address public governance;
    address public rewardToken;
    bool public killed;
    uint256 withdrawDeadline;
    mapping (address=>bool) tokens;
    mapping (address=>mapping (address=>uint256)) entryBlock;
    mapping (address=>uint256) public rewards;
    mapping (address=>uint256) totalValue;
    mapping (address=>uint256) public totalHolders;
    mapping (address=>mapping (address=>uint256)) public balance;
    
    event Deposit(address indexed owner, address indexed token, uint256 value);
    event Withdraw(address indexed owner, address indexed token, uint256 value, bool rewardOnly);

    constructor (address _governance, address _rewardToken) public {
        governance = _governance;
        rewardToken = _rewardToken;
        killed = false;
    }
    
    modifier govOnly() {
        require(msg.sender == governance);
        _;
    }
    
    modifier contractAlive() {
        require(killed==false);
        _;
    }
    
    function deposit(address _token, uint256 _amount) external contractAlive returns (bool) {
        require(tokens[_token] == true, "TOKEN_NOT_ALLOWED");
        require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount, "ALLOWANCE_NOT_ENOUGH");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        balance[msg.sender][_token] = balance[msg.sender][_token].add(_amount);
        totalHolders[_token] = totalHolders[_token].add(1);
        totalValue[_token] = totalValue[_token].add(_amount);
        entryBlock[msg.sender][_token] = block.number;
        emit Deposit(msg.sender, _token, _amount);
        return true;
    }

    function withdraw(address _token, bool _rewardOnly) external contractAlive nonReentrant returns (bool) {
        require(entryBlock[msg.sender][_token]>0, "NO_TOKEN_DEPOSIT");
        require(entryBlock[msg.sender][_token]!=block.number);
        require(rewards[_token]>0, "NO_REWARD_OFFERED_FOR_TOKEN");
        uint256 rewardAmount = block.number.sub(entryBlock[msg.sender][_token]).mul(rewards[_token]).mul(balance[msg.sender][_token]).div(totalValue[_token]);
        require(IERC20(rewardToken).balanceOf(address(this))>rewardAmount, "NOT_ENOUGH_REWARD_TOKEN_USE_EMERGENCY_WITHDRAW");
        require(rewardAmount>0, "NO_REWARDS_FOR_ADDRESS");
        if (!_rewardOnly) {
            require(balance[msg.sender][_token]>0);
            IERC20(_token).transfer(msg.sender, balance[msg.sender][_token]);
            totalHolders[_token] = totalHolders[_token].sub(1);
            totalValue[_token] = totalValue[_token].sub(balance[msg.sender][_token]);
            balance[msg.sender][_token] = 0;
            entryBlock[msg.sender][_token] = 0;

        } else {
            entryBlock[msg.sender][_token] = block.number;
        }
        IERC20(rewardToken).transfer(msg.sender, rewardAmount);
        emit Withdraw(msg.sender, _token, rewardAmount, _rewardOnly);
        return true;
    }

    function emergencyWithdraw(address _token) external nonReentrant returns (bool) {
        require(balance[msg.sender][_token]>0, "NO_INITIAL_BALANCE_FOUND");
        IERC20(_token).transfer(msg.sender, balance[msg.sender][_token]);
        totalValue[_token] = totalValue[_token].sub(balance[msg.sender][_token]);
        balance[msg.sender][_token] = 0;
        return true;
    }

    function adminWithdraw(uint256 _amount) external govOnly nonReentrant returns (bool) {
        IERC20(rewardToken).transfer(msg.sender, _amount);
        return true;
    }

    function addToken(address _token, uint256 _reward) external govOnly returns (bool) {
        tokens[_token] = true;
        rewards[_token] = _reward;
        return true;
    }

    function delToken(address _token) external govOnly returns (bool) {
        tokens[_token] = false;
        rewards[_token] = 0;
        return true;
    }
    
    function changeGovernance(address _governance) external govOnly returns (bool) {
        governance = _governance;
        return true;
    }

    function kill() external govOnly returns (bool) {
        killed = true;
        return true;
    }

    function unkill() external govOnly returns (bool) {
        killed = false;
        return true;
    }
 }