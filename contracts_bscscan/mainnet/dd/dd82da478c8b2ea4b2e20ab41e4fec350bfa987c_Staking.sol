/**
 *Submitted for verification at BscScan.com on 2021-12-20
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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

// File: contracts/Staking/Staking.sol



pragma solidity ^0.8.0;





contract Staking {

    using SafeMath for uint256;



    address public tokenAddress;

    uint256 public totalStaked;

    IERC20 ERC20Interface;



    mapping(address => uint256) private stakedBalance;



    /**

     *  @dev Struct to store user's withdraw data

     */

    struct Withdraw {

        bool status;

        uint256 amount;

        uint256 withdrawTime;

    }

    mapping(address => Withdraw) private userWithdraw;



    /**

     *  @dev Emitted when user stake 'amount' value of tokens

     */

    event Staked(address indexed from, uint256 indexed amount);



    /**

     *  @dev Emitted when user unstake 'amount' value of tokens 

     */

    event Unstaked(address indexed from, uint256 indexed amount);



    constructor(address _tokenAddress) {

        require(_tokenAddress != address(0), "Zero token address");

        tokenAddress = _tokenAddress;

    }



    /**

     *  @dev Prevent under value in allowance

     */

    modifier _hasAllowance(address allower, uint256 amount) {

        ERC20Interface = IERC20(tokenAddress);

        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));

        require(amount <= ourAllowance, "Make sure to add enough allowance");

        _;

    }



    /**

     *  Requirements:

     *  `_address` User wallet address

     *  @dev returns user staking data

     */

    function balanceOfStake(address _address) 

        public 

        view 

        returns(uint256)

    {

        return (stakedBalance[_address]);

    }

    

    /**

     *  Requirements:

     *  `_address` User wallet address

     *  @dev returns user's withdraw data

     */

    function checkWithdrawInfo(address _address) 

        public 

        view 

        returns(bool, uint256, uint256)

    {

        return (

            userWithdraw[_address].status, 

            userWithdraw[_address].amount, 

            userWithdraw[_address].withdrawTime

        );

    }



    /**

     *  Requirements:

     *  `amount` Amount to be staked

     /**

     *  @dev to stake 'amount' value of tokens 

     *  once the user has given allowance to the staking contract

     */

    function stake(uint256 amount) 

        external 

        _hasAllowance(msg.sender, amount)

    {

        require(

            amount >= 250 * 10 ** 18, "Please increase your staking value!"

        );

        _stake(msg.sender, amount);



        uint256 totalAmount = stakedBalance[msg.sender].add(amount);

        stakedBalance[msg.sender] = totalAmount;

        totalStaked = totalStaked.add(amount);



        emit Staked(msg.sender, amount);

    }

    

    /**

     *  Requirements:

     *  `amount` Amount to be unstake

     /**

     *  @dev to unstake 'amount' value of tokens 

     */

    function unstake(uint256 amount) external {

        require(

            amount <= stakedBalance[msg.sender],

            "Insufficient stake"

        );

        _unstake(amount);

    }



    /**

     *  @dev to claim the withdraw

     */

    function claimWithdraw() external {

        require(

            userWithdraw[msg.sender].status, 

            "Not eligible to claim withdraw!"

        );

        require(

            userWithdraw[msg.sender].withdrawTime <= block.timestamp,

            "Maturity date is not over!"

        );



        _transferToUser(msg.sender, userWithdraw[msg.sender].amount);



        userWithdraw[msg.sender] = Withdraw(false, 0, 0);

    }



    function _stake(address payer, uint256 amount) private {

        ERC20Interface = IERC20(tokenAddress);

        ERC20Interface.transferFrom(payer, address(this), amount);

    }



    function _unstake(uint256 amount) private {

        uint256 totalAmount = stakedBalance[msg.sender].sub(amount);

        stakedBalance[msg.sender] = totalAmount; 

        totalStaked = totalStaked.sub(amount);



        uint256 prevAmountWithdraw = userWithdraw[msg.sender].amount;

        uint256 totalWithdrawAmount = prevAmountWithdraw.add(amount);



        userWithdraw[msg.sender] = Withdraw(true, totalWithdrawAmount, block.timestamp + 14 days);

        emit Unstaked(msg.sender, amount);

    }



    function _transferToUser(address to, uint256 amount) private {

        ERC20Interface = IERC20(tokenAddress);

        ERC20Interface.transfer(to, amount);

    }



}