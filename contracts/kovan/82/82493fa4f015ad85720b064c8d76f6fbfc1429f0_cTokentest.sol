/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity =0.6.12;

contract SafeMath {
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


abstract contract ICEther{
    function mint() public virtual payable returns (uint);
    function redeem(uint redeemTokens)  public virtual returns (uint);
    function redeemUnderlying(uint redeemAmount)  public virtual returns (uint);
    function isCToken()  public virtual returns (bool);
    function exchangeRateCurrent()  public virtual returns (uint);
    function balanceOfUnderlying(address account)  public virtual returns (uint);
    function balanceOf(address account)  public virtual returns (uint256);
}


contract cTokentest is SafeMath{
    
    ICEther              public cToken;
    
    event DepositReceived(address indexed caller, uint256 amount);

    event BalanceBefore(address indexed caller, uint256 amount);
    event BalanceAfter(address indexed caller, uint256 amount);

    event Deposit(address indexed caller, uint256 amount);
    event Withdraw(address indexed caller, uint256 amount);

    uint256 public constant WAD               = 10**18;

    constructor(
        address cTokenAddress
    ) public {
    
        cToken               = ICEther(cTokenAddress);
        require(cToken.isCToken(), "GeneralTokenReserveSafeSaviour/invalid-ctoken-address");
        
    }
    
    function deposit() payable external{

        require(msg.value > 0, "Incorrect Amount");
        
        emit DepositReceived(msg.sender, msg.value);
        
        uint256 balanceBefore = cToken.balanceOf(address(this));
        
        emit BalanceBefore(msg.sender, balanceBefore);
        
        payable(address(cToken)).transfer(msg.value);
        
        emit BalanceAfter(msg.sender, cToken.balanceOf(address(this)));
        
        uint256 cTokenAmount = sub(cToken.balanceOf(address(this)), balanceBefore);

        emit Deposit(msg.sender, cTokenAmount);
    }
    
    
    function withdraw(uint256 cTokenAmount) external{
        
        require(cTokenAmount > 0, "GeneralTokenReserveSafeSaviour/null-collateralToken-amount");


        uint256 collateralReceived = mul(cToken.exchangeRateCurrent(),cTokenAmount)/WAD;

        require(cToken.redeem(cTokenAmount) == 0, "GeneralTokenReserveSafeSaviour/not-redeemable-ctoken");

        address payable sender = payable(msg.sender);

        sender.transfer(collateralReceived);

        emit Withdraw(msg.sender, cTokenAmount);

    }
    
    
}