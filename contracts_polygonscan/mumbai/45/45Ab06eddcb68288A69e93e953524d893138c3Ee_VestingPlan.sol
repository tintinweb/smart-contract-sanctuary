/**
 *Submitted for verification at polygonscan.com on 2021-12-16
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
 
    uint256[] public share_percent = [825,1300,400,200,1000,500,1500];
    
    uint256[] public tge_percent = [400,500,500,2000];
    
    uint256[] public release_percent = [738,790,790,1000,500,1000,500];
    
    mapping(uint8 => address) public accountAddress;
    mapping(address => uint256) public vestingStart;
  
    address payable public owner;  
    uint256 public totalToken=1000000000*1e18;
    uint256 public percentDivider=10000;
    uint256 private constant INTEREST_CYCLE = 3 minutes;    

    IERC20 testToken;

    constructor(address payable _owner,IERC20 _testToken) public {       
        owner = _owner;  
        testToken = _testToken;    //  0x1fBe03f0C9ceAb3396FdDf393f808dd138e77F4F
    }

    function setAddress(address _seedAddress,address _privateAddress,address _strategicAddress,address _publicAddress,address _teamAddress,address _advisorAddress,address _liquidityAddress,address _gameAddress, address _marketingAddress, address _developementAddress) public 
    {
        require(msg.sender==owner,"Only Owner!");
        accountAddress[1]= _seedAddress;
        accountAddress[2]= _privateAddress;
        accountAddress[3]= _strategicAddress;
        accountAddress[4]= _publicAddress;
        accountAddress[5]= _teamAddress;
        accountAddress[6]= _advisorAddress;
        accountAddress[7]= _liquidityAddress;
        accountAddress[8]= _gameAddress;
        accountAddress[9]= _marketingAddress;
        accountAddress[10]= _developementAddress;

        vestingStart[_seedAddress]=block.timestamp + 3 minutes;
        vestingStart[_privateAddress]=block.timestamp + 3 minutes;
        vestingStart[_strategicAddress]=block.timestamp + 3 minutes;
        vestingStart[_publicAddress]=block.timestamp + 3 minutes;
        vestingStart[_teamAddress]=block.timestamp + 30 minutes;
        vestingStart[_advisorAddress]=block.timestamp + 18 minutes;
        vestingStart[_marketingAddress]=block.timestamp + 9 minutes;

       //for seed address TGE transfer
        uint256 seedToken=(totalToken.mul(share_percent[0]).div(percentDivider)).mul(tge_percent[0]).div(percentDivider);
        testToken.transfer(_seedAddress,seedToken);
        
        //for private address TGE transfer
        uint256 privatToken=(totalToken.mul(share_percent[1]).div(percentDivider)).mul(tge_percent[1]).div(percentDivider);
        testToken.transfer(_privateAddress,privatToken);
        
        //for strategic address TGE transfer
        uint256 strategicToken=(totalToken.mul(share_percent[2]).div(percentDivider)).mul(tge_percent[2]).div(percentDivider);
        testToken.transfer(_strategicAddress,strategicToken);

        //for public address TGE transfer
        uint256 publicToken=(totalToken.mul(share_percent[3]).div(percentDivider)).mul(tge_percent[3]).div(percentDivider);
        testToken.transfer(_publicAddress,publicToken);
    }

    function sendToken(address _wallet,uint256 amount) public
    {
        require(msg.sender==owner,"Only Owner!");
        testToken.transfer(_wallet,amount*1e18);
    }

    function getReleaseAmount(address _user) public view returns(uint256)
    {
      if(vestingStart[_user]>0 && vestingStart[_user]<block.timestamp)  
      {
          uint256 totalGap=vestingStart[_user].div(INTEREST_CYCLE);
          if(totalGap>0)
          {
            if(_user==accountAddress[1])
            {
                uint256 totalShare=totalToken.mul(share_percent[0]).div(percentDivider);
                uint256 tge=totalShare.mul(tge_percent[0]).div(percentDivider);
                return (((totalShare-tge).mul(release_percent[0])).div(percentDivider)).mul(totalGap);
            }

            else if(_user==accountAddress[2])
            {
                uint256 totalShare=totalToken.mul(share_percent[1]).div(percentDivider);
                uint256 tge=totalShare.mul(tge_percent[1]).div(percentDivider);
                return (((totalShare-tge).mul(release_percent[1])).div(percentDivider)).mul(totalGap);
            }

           else if(_user==accountAddress[3])
            {
                uint256 totalShare=totalToken.mul(share_percent[2]).div(percentDivider);
                uint256 tge=totalShare.mul(tge_percent[2]).div(percentDivider);
                return (((totalShare-tge).mul(release_percent[2])).div(percentDivider)).mul(totalGap);
            }

           else if(_user==accountAddress[4])
            {
                uint256 totalShare=totalToken.mul(share_percent[3]).div(percentDivider);
                uint256 tge=totalShare.mul(tge_percent[3]).div(percentDivider);
                return (((totalShare-tge).mul(release_percent[3])).div(percentDivider)).mul(totalGap);
            }

            else if(_user==accountAddress[5])
            {
                uint256 totalShare=totalToken.mul(share_percent[4]).div(percentDivider);
                return ((totalShare.mul(release_percent[4])).div(percentDivider)).mul(totalGap);
            }

            else if(_user==accountAddress[6])
            {
                uint256 totalShare=totalToken.mul(share_percent[5]).div(percentDivider);
                return ((totalShare.mul(release_percent[5])).div(percentDivider)).mul(totalGap);
            }

            else if(_user==accountAddress[9])
            {
                uint256 totalShare=totalToken.mul(share_percent[6]).div(percentDivider);
                return ((totalShare.mul(release_percent[6])).div(percentDivider)).mul(totalGap);
            }
          }
      }
    } 
}