/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// SPDX-License-Identifier: MIT 


pragma solidity 0.8.4;

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

contract FolkitoPresale{
    using SafeMath for uint256;



    enum TypeOfMember{ NORMAL,WHITELISTED, PRIVATEMEMBER }
    


    address public owner;
    IERC20 public token;
    uint256 public _price = 0.00001 ether;
    uint256 public _privatePrice = 0.000001 ether;
    uint256 public _whiteListPrice = 0.000001 ether;

    uint256 private ONE_TOKEN = 1 ether;
    uint256 public presaleTimeEnds = block.timestamp.add(10 days);
    uint256 public totalTokenSold;


    uint8 TYPE_NORMAL = 0;
    uint8 TYPE_WHITELIST = 1;
    uint8 TYPE_PRIVATEMEMBER = 2;

    

    uint256 public WHITELISTING_SHARE = 6000000*10**18;
    uint256 public whitelistingSold = 0;


    uint256 public NORMAL_SALE_SHARE = 5000000*10**18;
    uint256 public normalSaleSold = 0;



    uint256 public PRIVATE_SALE_SHARE = 5000000*10**18;
    uint256 public privateSaleSold = 0;


    mapping (address => bool) public whitelist;

    mapping (address => bool) public privateMembersList;


    constructor(address _token ){
        owner = msg.sender;
        token = IERC20(_token);
       
    }
    
    
    modifier IsOwner{
        require(msg.sender == owner);
        _;
    }
 
    
    
    
    function addOrRemoveUserFromWhitelist(address user,bool isAdd) public{
     require(msg.sender == owner,"You are not authorized");
     
     whitelist[user] = isAdd;
    }
    
    


    function addOrRemoveUserFromPrivateSale(address user,bool isAdd) public{
     require(msg.sender == owner,"You are not authorized");
     
     privateMembersList[user] = isAdd;

    }
    
    
    
    
    // user will send the amount when they will buy the tokens adn contract will automatically calcluitate  the number of tokens accordign to the amount user will send
    
    
    
    function buyToken() external payable
    {
        require(presaleTimeEnds> block.timestamp,"Presale Finished");
        
        uint8 memberType = getMemberType(msg.sender);
        uint256 noOfTokens = calculateTokens(msg.value,memberType);
        
        if(memberType == TYPE_WHITELIST){
            
            if(whitelistingSold.add(noOfTokens)<= WHITELISTING_SHARE){
                whitelistingSold = whitelistingSold.add(noOfTokens);
            }else{
                revert("Whitelist Sale Quota has finished");
            }
            
        }if(memberType == TYPE_PRIVATEMEMBER){
            if(privateSaleSold.add(noOfTokens)<= PRIVATE_SALE_SHARE){
                privateSaleSold = privateSaleSold.add(noOfTokens);
            }else{
                revert("PRIVATE Sale Quota has finished");
            }
            
        }else{

            if(normalSaleSold.add(noOfTokens)<= NORMAL_SALE_SHARE){
                normalSaleSold = normalSaleSold.add(noOfTokens);
            }else{
                revert("Normal Sale Quota has finished");
            }
            

        }
        
        require(getTokenBalance()>= noOfTokens,"Contract has no balance");

        token.transfer(msg.sender,noOfTokens);
        totalTokenSold = totalTokenSold.add(noOfTokens);
        
    }
    
    

    function getTotalPresaleAmount()  public view returns(uint256){
        return NORMAL_SALE_SHARE.add(WHITELISTING_SHARE).add(PRIVATE_SALE_SHARE);
    }
    
    
    function calculateTokens (uint256 amount,uint8 userType ) public view returns(uint256){
        if(userType == TYPE_WHITELIST){
            
            return amount.div(_whiteListPrice).mul(10**18);

        }else if(userType == TYPE_PRIVATEMEMBER){
            
            return amount.div(_privatePrice).mul(10**18);

        } else{
            return amount.div(_price).mul(10**18);

        }
    }



    function getMemberType(address user) public view returns (uint8) {
      
        uint8 userType = TYPE_NORMAL;

        if(whitelist[user] ==true){
            userType = TYPE_WHITELIST;
        }else if(privateMembersList[user] ==true){
            userType = TYPE_PRIVATEMEMBER;
        }
        return userType;


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