/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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

/**
 * @title Fund contract - Implements reward distribution
 */
contract BreakerFund {
    using SafeMath for uint;

    address public token;
    address public owner;
    address public coin; // ERC20 token (stablecoin; could be USDC)

    uint public totalRewardETH;
    uint public totalRewardCoins; // total reward in ERC20 tokens

    mapping (address => uint) public rewardETH; // user's address => Reward at time of withdraw (in ETH)
    mapping (address => uint) public owedETH; // user's address => Reward which can be withdrawn (in ETH)
    mapping (address => uint) public rewardCoins; // in ERC20 tokens
    mapping (address => uint) public owedCoins; // in ERC20 tokens

    /**
     * @dev Throws if passed address is a zero address
     */
    modifier nonZeroAddress(address _addr) {
        require(address(_addr) != address(0), "The address can't be zero");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    /**
     * @dev Sets an owner address
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Deposits reward in Ethers
     */
    function depositReward() public payable {
        totalRewardETH = totalRewardETH.add(msg.value);
    }

    /**
     * @dev Deposits reward (in ERC20 tokens - stablecoins that could be USDC)
     * @param _asset An address of the asset to make a transferFrom call
     * @param _amount Amount of transferred tokens
     */
    function depositCoinReward(address _asset, uint _amount) public {
        IERC20(coin).transferFrom(_asset, address(this), _amount);
        totalRewardCoins = totalRewardCoins.add(_amount);
    }

    /**
     * @dev Calculates a reward (in wei) for a user
     * @param _for User's address
     * @return A reward for the address (in wei)
     */
    function calcReward(address _for) public view returns(uint) {
        return IERC20(token).balanceOf(_for).mul(
            totalRewardETH.sub(rewardETH[_for])
        ).div(IERC20(token).totalSupply()).add(owedETH[_for]);
    }

    /**
     * @dev Calculates a reward (in ERC20 tokens) for a user
     * @param _for User's address
     * @return A reward for the address (in tokens)
     */
    function calcCoinReward(address _for) public view returns(uint) {
        return IERC20(token).balanceOf(_for).mul(
            totalRewardCoins.sub(rewardCoins[_for])
        ).div(IERC20(token).totalSupply()).add(owedCoins[_for]);
    }

    /**
     * @dev Withdraws reward (in wei) for a user
     * @return The reward (in wei)
     */
    function withdrawReward() public returns(uint) {
        uint value = calcReward(msg.sender);

        if (value > 0) {
            rewardETH[msg.sender] = totalRewardETH;
            owedETH[msg.sender] = 0;
            msg.sender.transfer(value);
        }

        return value;
    }

    /**
     * @dev Withdraws reward (in ERC20 tokens) for a user
     * @return The reward (in tokens)
     */
    function withdrawCoinReward() public returns(uint) {
        uint value = calcCoinReward(msg.sender);

        if (value > 0) {
            rewardCoins[msg.sender] = totalRewardCoins;
            owedCoins[msg.sender] = 0;
            IERC20(coin).transfer(msg.sender, value);
        }
        
        return value;
    }

    /**
     * @dev Credits a reward (in wei) to an owed balance
     * @param _for User's address
     * @return The reward (in wei)
     */
    function freezeReward(address _for) external nonZeroAddress(_for) returns(uint) {
        uint value = calcReward(_for);
        if (value > owedETH[_for]) {
            rewardETH[_for] = totalRewardETH;
            owedETH[_for] = value;
        }
        return value;
    }

    /**
     * @dev Credits a reward (in ERC20 tokens - stablecoins that could be USDC)
     * to an owed balance
     * @param _for User's address
     * @return The reward tokens
     */
    function freezeCoinReward(address _for) external nonZeroAddress(_for) returns(uint) {
        uint value = calcCoinReward(_for);
        if (value > owedCoins[_for]) {
            rewardCoins[_for] = totalRewardCoins;
            owedCoins[_for] = value;
        }
        return value;
    }

    /**
     * @dev Setup function that sets a token and stablecoin addresses
     * @param _token A token address
     * @param _coin A stablecoin address (could be USDC)
     */
    function setup(
        address _token, address _coin, address _owner
    ) external onlyOwner nonZeroAddress(_token) nonZeroAddress(_coin) nonZeroAddress(_owner) {
        token = _token;
        coin = _coin;
        owner = _owner;
    }

    /**
     * @dev A fallback function that acts as a depositReward()
     */
    receive() external payable {
        if (msg.value == 0) withdrawReward();
        else depositReward();
    }

    /**
     * @dev Destroys a contract and sends everything (both Ethers and ERC20 tokens) to {_receiver} address
     * @param _receiver A receiver's address of all Ethers and ERC20 tokens that belongs to the contract
     */
    function destroy(address payable _receiver) public onlyOwner nonZeroAddress(_receiver) {
        uint coinBalance = IERC20(coin).balanceOf(address(this));
        IERC20(coin).transfer(_receiver, coinBalance);
        selfdestruct(_receiver);
    }

}