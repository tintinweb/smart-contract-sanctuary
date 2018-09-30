pragma solidity ^0.4.21;


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
  public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
  public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}
/**
 * @title SafeMath
 * @dev Math   with safety checks that throw on error
 */
library SafeMath {
    /**
     * mul
     * @dev Safe math multiply function
     */
  function mul(uint256 a, uint256 b) internal pure returns (uint256){
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  /**
   * add
   * @dev Safe math addition function
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

    /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

}

/**
 * @title Ownable
 * @dev Ownable has an owner address to simplify "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * Ownable
   * @dev Ownable constructor sets the `owner` of the contract to sender
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * ownerOnly
   * @dev Throws an error if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * transferOwnership
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/**
 * @title LavevelICO
 * @dev LavevelICO contract is Ownable
 **/
contract AFDTICO is Ownable {
  using SafeERC20 for ERC20Basic;
  // ERC20 basic token contract being held
  ERC20Basic public token;
  using SafeMath for uint256;
  
  mapping(address => uint) bal;  //存储众筹账号和以太金额
  mapping(address => uint) token_balance; //存储众筹账号和AFDT金额
  
  uint256 public RATE = 2188; // 以太兑换AFDT比例
  uint256 public minimum = 10000000000000000;   //0.01ETH
//   uint256 public constant initialTokens = 1000000 * 10**8; // Initial number of tokens available
  address public constant FAVOREE = 0x57f3495D0eb2257F1B0Dbbc77a8A49E4AcAC82f5; //受益人账号
  uint256 public raisedAmount = 0; //合约以太数量
  
  /**
   * BoughtTokens
   * @dev Log tokens bought onto the blockchain
   */
  event BoughtTokens(address indexed to, uint256 value, uint256 tokens);

  constructor(ERC20Basic _token) public {
      token = _token;
  }

  /**
   * @dev Fallback function if ether is sent to address insted of buyTokens function
   **/
  function () public payable {

    buyTokens();
  }

  /**
   * buyTokens
   * @dev function that sells available tokens
   **/
  function buyTokens() public payable {
    require(msg.value >= minimum);
    uint256 weiAmount = msg.value; // 以太坊数量
    uint256 tokens = msg.value.mul(RATE).div(10**10);  //应得AFDT数量
    
    uint256 balance = token.balanceOf(this);     //合约拥有AFDT数量
    if (tokens > balance){                       //如果应得数量大于合约拥有数量返还ETH
        msg.sender.transfer(weiAmount);
        
    }
    
    else{
        if (bal[msg.sender] == 0){
            token.transfer(msg.sender, tokens); // Send tokens to buyer
            
            // log event onto the blockchain
            emit BoughtTokens(msg.sender, msg.value, tokens);
            
            token_balance[msg.sender] = tokens;
            bal[msg.sender] = msg.value;
            
            raisedAmount = raisedAmount.add(weiAmount);
            //owner.transfer(weiAmount);// Send money to owner
        }
         else{
             uint256 b = bal[msg.sender];
             uint256 c = token_balance[msg.sender];
             token.transfer(msg.sender, tokens); // Send tokens to buyer
             emit BoughtTokens(msg.sender, msg.value, tokens); // log event onto the blockchain
             
             bal[msg.sender] = b.add(msg.value);
             token_balance[msg.sender] = c.add(tokens);
             
             raisedAmount = raisedAmount.add(weiAmount);
             
             //owner.transfer(weiAmount);// Send money to owner
         }
    }
 }

  /**
   * tokensAvailable
   * @dev returns the number of tokens allocated to this contract
   **/
  function tokensAvailable() public constant returns (uint256) {
    return token.balanceOf(this);
  }

  function ratio(uint256 _RATE) onlyOwner public {
      RATE = _RATE;
  }
  
  function withdrawals() onlyOwner public {
      FAVOREE.transfer(raisedAmount);
      raisedAmount = 0;
  }
  
  function adjust_eth(uint256 _minimum) onlyOwner  public {
      minimum = _minimum;
  }
  /**
   * destroy
   * @notice Terminate contract and refund to owner
   **/
  function destroy() onlyOwner public {
    // Transfer tokens back to owner
    uint256 balance = token.balanceOf(this);
    assert(balance > 0);
    token.transfer(FAVOREE, balance);
    // There should be no ether in the contract but just in case
    selfdestruct(FAVOREE); 
  }
}