pragma solidity ^0.5.16;

import './IERC20.sol';
import './SafeMath.sol';
import './owned.sol';

contract DotcMain is owned{
    using SafeMath for uint256;

    uint256 public constant FROZEN_SPAN = 30*86400;

    struct Order{
	uint256 order_id; //唯一订单ID
	address buyer;
	address seller;
	address token;	//这里需要确认是USDT还是USDC还是DAI
	uint256 token_amount; //稳定币数量
	uint256 token_price; //单价
	uint256 fiat_amount; //法币数量
	uint status; //订单状态：0-新订单，不能撮合，1-有效订单，可以交易， 2-买家已付款，3-结束，4-仲裁
	uint256 place_time; //订单开始时间
	uint256 close_time; //订单结束时间 
	uint256 buyer_frozen;//买方冻结数额
	uint256 seller_frozen; //卖方冻结数额
    }

    mapping (address => uint256) userOrderNum; //用户的订单数
    mapping (address => uint256) user_frozen_time_span; //用户的保证金冻结时间，默认是填FROZEN_SPAN, owner可以改
    mapping (address => uint256) user_order_id_done; //用户已经处理过的ID，则遍历则从该ID开始向后遍历，以节省循环次数
    mapping (address => mapping(uint256 => Order)) userOrders; //用户的订单

    uint256 public penaltyRatioMantissa; //1e18
    IERC20 usdt;
    IERC20 usdc;
    IERC20 dai;

    //事件
    event NewSellOrder(address indexed token, address indexed account, uint256 token_amount);
    event NewBuyOrder(address indexed token, address indexed account, uint256 token_amount);
    event TokenDeposited(address indexed token, address indexed account, uint256 amount);
    event TokenWithdrawn(address indexed token, address indexed account, uint256 amount);

    constructor(address usdtAddress, address usdcAddress, address daiAddress) public {

    	usdt = IERC20(usdtAddress);

    	usdc = IERC20(usdcAddress);

    	dai = IERC20(daiAddress);

	penaltyRatioMantissa = 0.05e18;
    }

    //设置罚没比例
    function _setPenaltyRatioMantissa(uint256 ratio) onlyOwner public {

	penaltyRatioMantissa = ratio;
    }

    //用户把资产从合约提取到钱包
    function withdraw(address token) public {
	uint256 amount = 0;
	emit TokenWithdrawn(token, msg.sender, amount);
    }

    /*
        Only external call
    */
    function getTokenAvailableAmount(address token, address account) view external returns(uint256) {
	uint256 amount = 0;
	uint256 orderNum = userOrderNum[account];
	if(orderNum > 0)
	{
		uint256 initial_id = user_order_id_done[account];
		for(uint i=initial_id; i<orderNum; i++)
		{
			Order memory order = userOrders[account][i];
			if(order.token != token)
				continue;
			if(account == order.buyer)
			{
				if(!isReleasable(account, i))
					continue;
				amount = amount.add(order.buyer_frozen);
			}
			if(account == order.seller)
			{
				if(!isReleasable(account, i))
					continue;
				amount = amount.add(order.seller_frozen);
			}
		}	
	}else
	{
		return 0;
	}
	return amount;
    }

    function isReleasable(address account, uint256 order_id) view internal returns (bool)
    {
	Order memory order = userOrders[account][order_id];
	uint256 frozen_span = user_frozen_time_span[account];
	if((order.close_time !=0)&&(block.timestamp.sub(order.close_time) >= frozen_span))
		return true;
	return false;
    }

}

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