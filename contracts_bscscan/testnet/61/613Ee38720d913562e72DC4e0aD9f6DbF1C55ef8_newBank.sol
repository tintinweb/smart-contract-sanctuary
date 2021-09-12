/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

pragma solidity ^0.5.17;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
contract IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract newBank {

    using SafeMath for uint256;
    
    IERC20 private _supportToken =  IERC20(0x3c91B301f80cCB055e97d2405523C95e72892D30);

    struct _detail{
        uint256 startTime;
        uint256 amount;
        uint256 period;
        uint256 rate;
    }
    
    address private _owner;
    address private _cmo;
    
    uint256 private _index;
    uint256 private _balance;
    mapping(address=>mapping(uint256=>_detail)) private _user;
    mapping(uint256=>uint256) private _rate;
    
    event Deposited(address indexed user, uint256 amount ,uint256 period,uint256 index);
    event withdrawed(address indexed user, uint256 amount ,uint256 index);
    event rated(uint256 period,uint256 rate);

    constructor() public  {
        _owner  = msg.sender;
        _cmo    = msg.sender;
        _index  = 0;
    }
    
    modifier onlyCmo() {
        require(msg.sender == _cmo);
        _;
    }
    
    function setCmo(address newCmo) public {
        require(msg.sender == _owner);
        _cmo   = newCmo;
    }
    
    function getCmo() public  view returns(address) {
        return _cmo;
    }
    
    function getBalance() public  view returns(uint256) {
        return _balance;
    }
    
    function setRate(uint256 period, uint256 rate ) public onlyCmo() {
        
        require((period == 7) || (period == 30) ||  (period == 90) ||  (period == 180));
        
        _rate[period] = rate;
        emit rated(period,rate);
    }
    
    function deposit(uint256 amount,uint256 period) public {
        
        require((period == 7) || (period == 30) ||  (period == 90) ||  (period == 180));
        
        _detail memory new_detail; 
        
        new_detail.startTime = block.timestamp;
        new_detail.amount    = amount;
        new_detail.period    = period;
        new_detail.rate      = _rate[period];
        
        _index += 1;
        
        _user[msg.sender][_index] = new_detail;
        
        _balance += amount;
        
        _supportToken.transferFrom(msg.sender,address(this),amount);
        
        emit Deposited(msg.sender,amount,period,_index);
    }
    
    function withdraw(uint256 index) public {
        require(_user[msg.sender][index].startTime > 0);
        require(block.timestamp >( _user[msg.sender][index].startTime + (_user[msg.sender][index].period).mul(86400) ));
        //require(_user[msg.sender][index].amount == amount);
        
        uint256 amount = getExceptedYield(msg.sender,index);
        
        require(_balance>= amount);
        
        
        _supportToken.transferFrom(address(this),msg.sender,amount);
        
        _balance -= amount;
        delete _user[msg.sender][index];
        
        emit withdrawed(msg.sender,amount,index);
        
    }
    
    function withdrawtest(uint256 index) public {
        //require(_user[msg.sender][index].startTime > 0);
       // require(block.timestamp >( _user[msg.sender][index].startTime + (_user[msg.sender][index].period).mul(86400) ));
        //require(_user[msg.sender][index].amount == amount);
        
        uint256 amount = getExceptedYield(msg.sender,index);
        
        require(_balance>= amount);
        
        
        _supportToken.transferFrom(address(this),msg.sender,amount);
        
        _balance -= amount;
        delete _user[msg.sender][index];
        
        emit withdrawed(msg.sender,amount,index);
        
    }    
    
    function getExceptedYield(address user,uint256 index) public view returns(uint256 amount) {
        
        uint256 userAmount = _user[user][index].amount;
        uint256 rate       = _user[user][index].rate;
        uint256 period     = _user[user][index].period;
        
        amount             = userAmount + userAmount.mul(rate).mul(period).div(10000); 
        
        return amount;
        
    }
    
}