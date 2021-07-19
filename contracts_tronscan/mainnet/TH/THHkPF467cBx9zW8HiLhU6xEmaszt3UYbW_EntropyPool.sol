//SourceUnit: EntropyPool.sol

pragma solidity ^0.5.10;

import './IERC20.sol';
import './SafeMath.sol';

contract EntropyPool{
    using SafeMath for uint256;

    address payable public owner;
    address payable public admin_fee;

    event CoinExchanged(address indexed addr, uint256 amount);
    event NewDeposit(uint256 amount);

    IERC20 usdt;
    IERC20 ndx;

    uint256 public usdt_pool_balance;
    uint256 public exchanged_tokens;
    uint40 public init_time;

    constructor() public {
        owner = msg.sender;
    
    	ndx = IERC20(0x563CB80479ca86cffC16160d80433B4Ceaac07d2); //NDX contract mainnet
    	//ndx = IERC20(0xB7eF020E3b15b2f4cD73fBbc03B7833688B9e5a1); //NDX contract shasta
    	usdt = IERC20(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C); //USDT contract mainnet
    	//usdt = IERC20(0xd98BF77669F75dfBFEe95643a313acD0Ba5E9b62); //USDT contract shasta
        admin_fee = address(0x2d097516aEd475dFB92bA611e1E5fd665e67dbB3);  //cold wallet mainnet
        //admin_fee = address(0x2d097516aEd475dFB92bA611e1E5fd665e67dbB3);  //cold wallet shasta 

	usdt_pool_balance = 0;
	exchanged_tokens = 0;
        init_time = uint40(block.timestamp);
    }


    function exchange(uint256 amount) public {

	uint256 ten = 10;
	uint256 ndx_base = ten.pwr(ndx.decimals()); 
	//1 ndx at least
    	require(amount >= ndx_base);
	uint256 base = 100;
	uint256 exchange_price =  base.add((block.timestamp.sub(init_time)).div(1 days));
	
	if(exchange_price > 1000)
		exchange_price = 1000;

	usdt_pool_balance = usdt.balanceOf(address(this));
        require(usdt_pool_balance >= amount.mul(exchange_price).div(1000));
	
	ndx.transferFrom(msg.sender, address(this), amount);

	ndx.burn(amount);

	exchanged_tokens = exchanged_tokens.add(amount);

	//99% transfer to sender
	uint256 interm = amount.mul(exchange_price);
        usdt.transfer(msg.sender, interm.div(1000).mul(99).div(100));

	//1% admin fee
        usdt.transfer(admin_fee, interm.div(1000).div(100));

	emit CoinExchanged(msg.sender, amount);
    }

    /*
        Only external call
    */
    function exchangeRate() view external returns(uint256 _exchange_price) {
	uint256 base = 100;
	uint256 exchange_price =  base.add((block.timestamp.sub(init_time)).div(1 days));
	return exchange_price;
    }
    function contractInfo() view external returns(uint256 _usdt_pool_balance, uint256 _exchanged_tokens,  uint40 _init_time) {
    	 uint256 balance = usdt.balanceOf(address(this));
	 return (balance, exchanged_tokens,  init_time);
    }
}


//SourceUnit: IERC20.sol

pragma solidity  >=0.5.0 <0.7.0;
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 _value) external returns (bool success);
    function burnFrom(address _from, uint256 _value) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value); 
}


//SourceUnit: SafeMath.sol

pragma solidity  >=0.5.0 <0.7.0;
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

  /**
   * @dev gives square root of given x.
   */
  function sqrt(uint256 x)
  internal
  pure
  returns(uint256 y) {
    uint256 z = ((add(x, 1)) / 2);
    y = x;
    while (z < y) {
      y = z;
      z = ((add((x / z), z)) / 2);
    }
  }

  /**
   * @dev gives square. multiplies x by x
   */
  function sq(uint256 x)
  internal
  pure
  returns(uint256) {
    return (mul(x, x));
  }

  /**
   * @dev x to the power of y
   */
  function pwr(uint256 x, uint256 y)
  internal
  pure
  returns(uint256) {
    if (x == 0)
      return (0);
    else if (y == 0)
      return (1);
    else {
      uint256 z = x;
      for (uint256 i = 1; i < y; i++)
        z = mul(z, x);
      return (z);
    }
  }
}