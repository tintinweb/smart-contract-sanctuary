/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: contracts/Gulper.sol

pragma solidity ^0.5.0;



contract IERC20Wrapper is IERC20
{
    function deposit() payable public;
    function withdraw(uint _amount) public;
}

contract BalancerPool is IERC20 
{   
    function calcPoolOutGivenSingleIn(
            uint tokenBalanceIn,
            uint tokenWeightIn,
            uint poolSupply,
            uint totalWeight,
            uint tokenAmountIn,
            uint swapFee)
        public pure
        returns (uint poolAmountOut);

    function joinswapExternAmountIn(
            address tokenIn,
            uint256 tokenAmountIn,
            uint256 minPoolAmountOut)
        public;
}

contract Gulper
{
    // goal: a contract to receive funds in the form of eth and erc20s and spend them in predetermined ways

    using SafeMath for uint256;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant POOL = 0x5277a42ef95ECa7637fFa9E69B65A12A089FE12b;

    constructor () 
        public 
    { 
        IERC20Wrapper(WETH).approve(POOL, uint(-1));
        moneyMoneyMoneyMONEY = 204189300000000000; // the money already raised since the release of the audited dEth contract 
    }

    uint public moneyMoneyMoneyMONEY; 

    event gulped(uint _ether, uint _poolTokens, uint _pokeReward);

    function getGulpDetails()
        public
        view
        returns (uint _wethBalanceToConvert, uint _minTokensToClaim, uint _pokeReward)
    {
        uint ethBalance = address(this).balance;
        uint wethBalance = ethBalance.add(IERC20Wrapper(WETH).balanceOf(address(this)));
        // following line pays out 0.1% of the weth to the person poking this contract
        _pokeReward = wethBalance.div(1000);
        _wethBalanceToConvert = wethBalance.sub(_pokeReward);
        uint wethPoolBalance = IERC20Wrapper(WETH).balanceOf(POOL);
        uint poolBalance = BalancerPool(POOL).totalSupply();
        uint tokensOut = BalancerPool(POOL)
            .calcPoolOutGivenSingleIn(
                wethPoolBalance,
                5 * 10**18,
                poolBalance,
                10 * 10**18,
                _wethBalanceToConvert,
                10**17);
        _minTokensToClaim = tokensOut.mul(95 * 10**9).div(100 * 10**9);
    }

    function gulp() 
        public
    {
        // goals: 
        // 1. take the ether balance of address(this) and send it to the permafrost

        // logic:
        // *get the eth balance of this
        // *make wrapped ether
        // *calculate the min amount of pool tokens that we should receive for that much eth
        // *call joinswapExternAmountIn() for that amount of weth
        // *send the pool tokens to 0x01
        // *send a reward to msg.sender for poking the contract. 

        (uint wethBalanceToConvert, uint minTokensToClaim, uint pokeReward) = getGulpDetails();
        IERC20Wrapper(WETH).deposit.value(address(this).balance)();
        BalancerPool(POOL).joinswapExternAmountIn(WETH, wethBalanceToConvert, minTokensToClaim);
        uint poolTokensToBurn = BalancerPool(POOL).balanceOf(address(this)); 
        BalancerPool(POOL).transfer(address(1), poolTokensToBurn);
        moneyMoneyMoneyMONEY = moneyMoneyMoneyMONEY.add(wethBalanceToConvert);

        IERC20Wrapper(WETH).withdraw(pokeReward);
        emit gulped(wethBalanceToConvert, poolTokensToBurn, pokeReward);
        msg.sender.call.value(pokeReward)("");
    }

    event ethReceived(address _from, uint _amount); 

    function totalRaised() 
        public
        view
        returns (uint _totalRaised)
    {
        _totalRaised = moneyMoneyMoneyMONEY
            .add(address(this).balance)
            .add(IERC20Wrapper(WETH).balanceOf(address(this)));  
    }

    function () 
        external 
        payable 
    { 
        emit ethReceived(msg.sender, msg.value);
    }
}