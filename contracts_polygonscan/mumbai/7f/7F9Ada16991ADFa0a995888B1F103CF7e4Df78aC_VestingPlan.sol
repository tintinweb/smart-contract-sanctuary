/**
 *Submitted for verification at polygonscan.com on 2021-12-17
*/

pragma solidity 0.5.4;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
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

contract VestingPlan{
    using SafeMath for *;

    struct Account{
        uint256 id;
        uint256 tge;
        uint256 cycleToken;
        uint256 cycleStarted;
        uint256 cycleEnd;
        uint256 cycleClaimed; 
    } 

    mapping(address => Account) public accounts;
    mapping(uint => address) public idToAddress;
    uint256 public lastUserId = 1;

    address payable public owner;  
    uint256 private constant INTEREST_CYCLE = 3 minutes;    

    IERC20 testToken;

    constructor(address payable _owner,IERC20 _testToken) public {       
        owner = _owner;  
        testToken = _testToken;    //  0x1fBe03f0C9ceAb3396FdDf393f808dd138e77F4F
    }

    function setAddress(address []  memory  _address, uint256[] memory _tge, uint256[] memory monthlyToken, uint256[] memory startTime, uint256[] memory endTime) public 
    {
      require(msg.sender==owner,"Only Owner");    
      require(_address.length>0,"Invalid Input!");
      uint256 i;
      for(i=0;i<_address.length;i++)
      {
        Account memory user = Account({
          id:lastUserId,
          tge:_tge[i],
          cycleToken:monthlyToken[i],
          cycleStarted:startTime[i],
          cycleEnd:endTime[i],
          cycleClaimed:startTime[i]               
        });
        accounts[_address[i]] = user;

        if(_tge[i]>0)
        testToken.transfer(_address[i],_tge[i]);
        idToAddress[lastUserId]=_address[i];
        lastUserId++;
      }
    }
    
    function claim() public 
    {
      require(accounts[msg.sender].id>0);
      uint256 amount=getReleaseAmount(msg.sender);
      if(amount>0)
      testToken.transfer(msg.sender,amount);
    }


    function getReleaseAmount(address _user) public view returns(uint256)
    {
        if(accounts[_user].id>0 && accounts[_user].cycleClaimed<accounts[_user].cycleEnd)
        {
          uint256 _gap;
          if(block.timestamp>accounts[_user].cycleEnd)
          _gap=(accounts[_user].cycleEnd.sub(accounts[_user].cycleClaimed)).div(INTEREST_CYCLE);
          else
          _gap=(block.timestamp.sub(accounts[_user].cycleClaimed)).div(INTEREST_CYCLE);
          return _gap.mul(accounts[_user].cycleToken);
        }
        else
        return 0;
    }

    function sendToken(address _wallet,uint256 amount) public
    {
        require(msg.sender==owner,"Only Owner!");
        testToken.transfer(_wallet,amount*1e18);
    }

    function timestamp() public view returns(uint256)
    {
        return block.timestamp;
    }
}