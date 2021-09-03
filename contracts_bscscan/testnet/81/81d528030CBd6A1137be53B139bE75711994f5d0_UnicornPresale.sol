/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

/**
 *Submitted for verification at polygonscan.com on 2021-07-31
*/

/**
 *Submitted for verification at polygonscan.com on 2021-07-27
*/

// SPDX-License-Identifier: MIT 


pragma solidity ^0.6.12;

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

contract UnicornPresale{
    using SafeMath for uint256;






    address public owner;
    IERC20 public token;
    uint256 public _price;

    uint256 public presaleTimeEnds;
    uint256 public totalTokenSold;
    uint256 public presaleStarts;

    uint256 public MAX_BUY_LIMIT = 1000*1e18;


    



    uint256 public normalSaleSold = 0;








    constructor(address _token , uint256 price, uint256 endTime,uint256 _presaleStarts) public{
        owner = msg.sender;
        token = IERC20(_token);
        presaleTimeEnds = endTime;
        _price = price;
        presaleStarts = _presaleStarts;
       
    }
    


    function  setPresaleStarts(uint256 time) public IsOwner {
        presaleStarts = time;
    }
    
    modifier IsOwner{
        require(msg.sender == owner);
        _;
    }
 
    
    
    
    function changeOwner (address addr) public {
        require(msg.sender == owner,"You are not authorized");

        owner = addr;
    }
    function changePrice(uint256 price) public {
        require(msg.sender == owner,"You are not authorized");
        _price = price;
    }
    




    
    
  
    
   
    
    function safeTransferTokens(uint256 noOfTokens)internal{
        require(getTokenBalance()>= noOfTokens,"Contract has no balance");

        token.transfer(msg.sender,noOfTokens);
        totalTokenSold = totalTokenSold.add(noOfTokens);
    }
    
    
    
    
    
    function setMaxLimit(uint256 maxL) public {
        require(msg.sender == owner,"You are not authorized");

        MAX_BUY_LIMIT =  maxL;
    }
     
    function buyToken() public payable {
        require(presaleTimeEnds > block.timestamp,"Presale Finished");
        
        require(presaleStarts < block.timestamp,"Presale not started");
        
        
        
    
        uint256 noOfTokens = calculateTokens(msg.value);
        uint256 preBalance = token.balanceOf(msg.sender);

        require(noOfTokens.add(preBalance)<= MAX_BUY_LIMIT,"You can't have more than 2000 tokens");
        require(noOfTokens<= MAX_BUY_LIMIT,"You can't buy more than 2000 tokens");
      
        safeTransferTokens(noOfTokens);
    }
    
    

    
    function calculateTokens (uint256 amount ) public view returns(uint256){
        return amount.mul(10**18).div(_price);
    }




    
    
    
    // this fucntion is used to check how many fokitos are remaining in the contract
    function getTokenBalance() public view returns(uint256){
        return  token.balanceOf(address(this));
    }
    
    
        // this fucntion is used to check how many ethers are there in the contract

    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    
    
    
    // use this fuction for withdrawing all the unsold tokens

    function withdrawTokens( ) public{
        require(msg.sender == owner,"You are not the owner");
        token.transfer(owner,getTokenBalance());
        
    }
    
    
    
    // use this fuction for withdrawing all the ethers
    function withdrawBalance( ) public{
        require(msg.sender == owner,"You are not the owner");
        payable(msg.sender).transfer(getContractBalance());
    }
    
    
    // you can extend or shrink the presale time 

    function changePresaleEndTime(uint256 time) public{
        require(msg.sender == owner,"You are not the owner");
        presaleTimeEnds = time;
        
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}