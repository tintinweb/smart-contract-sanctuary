pragma solidity ^0.5.17;

import './IERC20.sol';
import './SafeMath.sol';
import './owned.sol';

// Token Locker for tech team & presale
contract GFBLocker is owned{
    using SafeMath for uint256;

    uint256 constant public TECH_TOTAL_SHARE = 100000*10**18;
    uint256 constant public PRESALE_TOTAL_SHARE = 50000*10**18;

    event CoinWithdrawn(address indexed addr, uint256 amount);

    address payable tech_wallet;

    mapping (address => uint256) presale_balance;
    mapping (address => uint256) presale_withdraw_tokens;

    IERC20 gfb;

    uint256 public tech_withdraw_tokens;


    uint40 public online_time;

    constructor(address payable gfbContractAddress, address payable techAddress) public {

    	gfb = IERC20(gfbContractAddress);

	tech_wallet = techAddress;

	tech_withdraw_tokens = 0;

        online_time = uint40(block.timestamp+365*86400);
    }

    function _setOnlineTime(uint40 ts) onlyOwner public {

	online_time = ts;
    }

    function _addPresaleUser(address account, uint256 volume) onlyOwner public {

	require(account != address(0) && volume > 0, "Invalid parameters.");

	presale_balance[account] = presale_balance[account].add(volume);
    }
 

    function tech_withdraw() public {

	require(msg.sender == tech_wallet, "only authorized user.");

	uint256 amount = this.getTechAvailableAmount();
	
        require(amount > 0, "No available coins.");

	uint256 gfb_balance = gfb.balanceOf(address(this));

        require(gfb_balance >= amount, "No GFB left for withdrawing");

	gfb.transfer(msg.sender, amount);

	tech_withdraw_tokens = tech_withdraw_tokens.add(amount);

	emit CoinWithdrawn(msg.sender, amount);
    }

    function presale_withdraw() public {

	require(presale_balance[msg.sender] > 0, "only authorized user.");

	uint256 amount = this.getPresaleAvailableAmount(msg.sender);
	
        require(amount > 0, "No available coins.");

	uint256 gfb_balance = gfb.balanceOf(address(this));

        require(gfb_balance >= amount, "No GFB left for withdrawing");

	gfb.transfer(msg.sender, amount);

	presale_withdraw_tokens[msg.sender] = presale_withdraw_tokens[msg.sender].add(amount);

	emit CoinWithdrawn(msg.sender, amount);
    }

    /*
        Only external call
    */
    function getTechAvailableAmount() view external returns(uint256) {
	uint256 ts = block.timestamp;
	if(ts < online_time)
		return 0;
	uint256 time_span = ts - online_time;
	uint256 amount = time_span.div(86400).mul(TECH_TOTAL_SHARE).div(360);
	if(amount > TECH_TOTAL_SHARE)
		amount = TECH_TOTAL_SHARE;
	if(amount <= tech_withdraw_tokens)
		amount = 0;
	else
		amount = amount.sub(tech_withdraw_tokens);
	return amount;
    }

    function getPresaleAvailableAmount(address account) view external returns(uint256) {
	
	require(presale_balance[account]>0, "has been withdrawn or has no presale tokens.");

	uint256 ts = block.timestamp;
	if(ts < online_time)
		return 0;
	uint256 amount = presale_balance[account].mul(2).div(5);
	uint256 time_span = ts - online_time;
	amount = amount.add(time_span.div(86400).div(30).mul(presale_balance[account]).div(20));
	if(amount > presale_balance[account])
		amount = presale_balance[account];
	if(amount <= presale_withdraw_tokens[account])
		amount = 0;
	else
		amount = amount.sub(presale_withdraw_tokens[account]);
	return amount;
    }
}

pragma solidity ^0.5.17;

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