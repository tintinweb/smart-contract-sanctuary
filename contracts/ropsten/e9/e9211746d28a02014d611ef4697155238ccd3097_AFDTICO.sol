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
  mapping(address => uint) bal;  //存储众筹账号和金额
  mapping(address => uint) token_balance; //存储众筹账号索引和地址
  
  uint256 public RATE = 8000; // Number of tokens per Ether
  uint256 public constant initialTokens = 4000000 * 10**8; // Initial number of tokens available
  address public constant FAVOREE = 0xac9c5da8c6df61e4cd6e93a1ade8d0715b6fa363; //受益人账号
  
  bool public initialized = false;


  /**
   * BoughtTokens
   * @dev Log tokens bought onto the blockchain
   */
  event BoughtTokens(address indexed to, uint256 value, uint tokens);

  /**
   * whenSaleIsActive
   * @dev ensures that the contract is still active
   **/
  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());
    _;
  }

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
        initialized == true

    );
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
    
    uint256 tokens = msg.value.mul(RATE).div(10**10);
    uint256 balance = token.balanceOf(this);
    if (tokens > balance){
        msg.sender.transfer(weiAmount);
    }

    else{
        if (bal[msg.sender] == 0){

            token.transfer(msg.sender, tokens); // Send tokens to buyer

            // log event onto the blockchain
            emit BoughtTokens(msg.sender, msg.value, tokens);
            token_balance[msg.sender] = tokens;
            bal[msg.sender] = msg.value;
            //owner.transfer(weiAmount);// Send money to owner
        }
         else{
             uint256 b = bal[msg.sender];
             uint256 c = token_balance[msg.sender];
             token.transfer(msg.sender, tokens); // Send tokens to buyer
             emit BoughtTokens(msg.sender, msg.value, tokens); // log event onto the blockchain
             bal[msg.sender] = b.add(msg.value);
             token_balance[msg.sender] = c.add(tokens);
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