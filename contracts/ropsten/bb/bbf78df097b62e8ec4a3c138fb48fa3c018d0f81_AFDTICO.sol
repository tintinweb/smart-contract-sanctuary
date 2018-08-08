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
 * @title Token
 * @dev API interface for interacting with the WILD Token contract 
 */
// interface Token {
//   function transfer(address _to, uint256 _value) external returns (bool);
//   function balanceOf(address _owner) external constant returns (uint256 balance);
// }



/**
 * @title LavevelICO
 * @dev LavevelICO contract is Ownable
 **/
contract AFDTICO is Ownable {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;
    
    
  using SafeMath for uint256;
  
  mapping(address => uint) bal;  //存储众筹账号和金额
  mapping(uint => address) index; //存储众筹账号索引和地址
  mapping(address => uint) Tokenamount; //存储众筹账号地址及应得代币
  
  uint256 public number;
  
  
  uint256 public constant RATE = 3000; // Number of tokens per Ether
  uint256 public constant CAP = 30; // Cap in Ether
  uint256 public constant softtop = 10; // soft top
  uint256 public constant START = 1532433620; // 开始时间
  uint256 public constant DAYS = 1; // 45 Day
  uint256 public constant ENDTIME = START+DAYS * 1 days;  //结束时间
  uint256 public minContribution = 1* 10**18;    //单人最小wei
  uint256 public maxContribution = 10 * 10**18;    //单人最大wei
  
  
  uint256 public constant initialTokens = 90000 * 10**18; // Initial number of tokens available
  bool public initialized = false;
  uint256 public raisedAmount = 0;
  
  /**
   * BoughtTokens
   * @dev Log tokens bought onto the blockchain
   */
  event BoughtTokens(address indexed to, uint256 value);

  /**
   * whenSaleIsActive
   * @dev ensures that the contract is still active
   **/
  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());
    _;
  }
  
  modifier defeated() { 
      if (now >= ENDTIME && raisedAmount <= softtop * 1 ether)
      _; 
      
  }
  
  modifier succeed() { 
   if (now >= ENDTIME && raisedAmount >= softtop * 1 ether)
   _; 
  
  }
  /**
   * LavevelICO
   * @dev LavevelICO constructor
   **/
  constructor(ERC20Basic _token) public {
      token = _token;
  }
  
  /**
   * initialize
   * @dev Initialize the contract
   **/
  function initialize() public onlyOwner {
      require(initialized == false); // Can only be initialized once
      require(tokensAvailable() == initialTokens); // Must have enough tokens allocated
      initialized = true;
  }

  /**
   * isActive
   * @dev Determins if the contract is still active
   **/
  function isActive() public view returns (bool) {
    return (
        initialized == true &&
        now >= START && // Must be after the START date
        now <= ENDTIME && // Must be before the end date
        goalReached() == false // Goal must not already be reached
    );
  }

  /**
   * goalReached
   * @dev Function to determin is goal has been reached
   **/
  function goalReached() public view returns (bool) {
    return (raisedAmount >= CAP * 1 ether);
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
  function buyTokens() public payable whenSaleIsActive {
    require(msg.value > 0);
    uint256 weiAmount = msg.value; // Calculate tokens to sell
    uint256 tokens = msg.value.mul(RATE);
    if (weiAmount <= minContribution || weiAmount >= maxContribution){
        //owner.transfer(msg.value);
        msg.sender.transfer(weiAmount);
        
    }
    else{
        if (bal[msg.sender] == 0){
            bal[msg.sender] = msg.value;
            Tokenamount[msg.sender] = tokens;
            number  = number.add(1);
            index[number] = msg.sender;
            
            emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
            raisedAmount = raisedAmount.add(weiAmount); // Increment raised amount
            //token.transfer(msg.sender, tokens); // Send tokens to buyer
            //owner.transfer(weiAmount);// Send money to owner
        }
         else{
             uint b = bal[msg.sender];
             b = b.add(msg.value);
             bal[msg.sender] =b;
             uint c = Tokenamount[msg.sender];
             Tokenamount[msg.sender] = tokens.add(c);
             emit BoughtTokens(msg.sender, tokens); // log event onto the blockchain
             raisedAmount = raisedAmount.add(weiAmount); // Increment raised amount
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


  function refund() public onlyOwner defeated {
      uint256 balance = token.balanceOf(this);
      assert(balance > 0);
      token.transfer(owner, balance);
      for (uint i;number>=i;i++){
           address add = index[i];
           uint256 a = bal[add];
           add.transfer(a);
        }
  }
 
  function remit() public onlyOwner succeed {
    //   uint256 balance = token.balanceOf(this);
    //   assert(balance > 0);
      owner.transfer(raisedAmount);
      for (uint i;number>=i;i++){
           address add = index[i];
           uint256 a = Tokenamount[add];
           token.transfer(add, a);
           //add.transfer(a);
        }
  }

  /**
   * destroy
   * @notice Terminate contract and refund to owner
   **/
  function destroy() onlyOwner public {
    // Transfer tokens back to owner
    uint256 balance = token.balanceOf(this);
    assert(balance > 0);
    token.transfer(owner, balance);
    // There should be no ether in the contract but just in case
    selfdestruct(owner);
  }
}