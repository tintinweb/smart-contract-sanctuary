/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

// File: contracts/IERC20.sol

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

// File: contracts/SafeMath.sol

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

// File: contracts/owned.sol

pragma solidity ^0.5.10;
contract owned {
    address public owner;
 
    constructor() public {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}

// File: contracts/ECOPLocker.sol

pragma solidity ^0.5.10;




contract ECOPLocker is owned{
    using SafeMath for uint256;

    uint256[] public MONTH_TIER = [132392,110363,110363,110363,7343,7343,7343,7343,7343,7343,7343,7343,7343];
    uint256 constant public TOTAL_AMOUNT = 529568*10**18;

    event CoinWithdrawn(address indexed addr, uint256 amount);

    address payable user_addr;

    IERC20 ecop;

    uint256 public withdraw_tokens;

    uint40 public online_time;

    constructor(address payable ecopContractAddress, address payable userAddress) public {

    	ecop = IERC20(ecopContractAddress);

	user_addr = userAddress;

	withdraw_tokens = 0;

	//init online time for 1 year later
        online_time = uint40(block.timestamp+365*86400);
    }

    function setOnlineTime(uint40 ts) onlyOwner public {

	online_time = ts;
    }

    function withdraw() public {

	require(msg.sender == user_addr, "only authorized user.");

	uint256 amount = this.getAvailableAmount();
	
        require(amount > 0, "No available coins.");

	uint256 ecop_balance = ecop.balanceOf(address(this));

        require(ecop_balance >= amount, "No ECOP left for withdrawing");

	ecop.transfer(msg.sender, amount);

	withdraw_tokens = withdraw_tokens.add(amount);

	emit CoinWithdrawn(msg.sender, amount);
    }

    /*
        Only external call
    */
    function getAvailableAmount() view external returns(uint256) {
	uint256 ts = block.timestamp;
	if(ts < online_time)
		return 0;
	uint256 time_span = ts - online_time;
	uint256 index = time_span.div(30*86400);
	uint256 amount = 0;
	for(uint256 i=0; i <= index; i++)
	{
		amount = amount.add(MONTH_TIER[i].mul(10**18));
	}
	if(amount > TOTAL_AMOUNT)
		amount = TOTAL_AMOUNT;
	if(amount < withdraw_tokens)
		amount = 0;
	else
		amount = amount.sub(withdraw_tokens);
	return amount;
    }

    function getContractInfo() view external returns(uint256 _total_amount, uint256 _withdraw_tokens,  uint256 _available_tokens, uint40 _online_time, address _user_addr) {
    	_total_amount = TOTAL_AMOUNT;
	_withdraw_tokens = withdraw_tokens;
	_available_tokens = this.getAvailableAmount();
	_online_time = online_time;
	_user_addr = user_addr;
    }
}