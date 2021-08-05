/**
 *Submitted for verification at Etherscan.io on 2020-12-25
*/

pragma solidity ^0.7.0;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address public owner;
  address payable public ownerpayable;
  constructor() public {
    owner = msg.sender;
    ownerpayable = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner; 
  }
}
interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) external view returns (uint256 balance);
}
contract DUSTSALE is Ownable {
  using SafeMath for uint256;
  Token token;
  string public constant Info = "Official Public Sale Contract for DUST Token";
  uint256 public constant RATE = 250000; //number of tokens per ether
  uint256 public constant CAP = 400;  //Number of ether accepted until the sale ends
  uint256 public constant START = 1608892200; // Date and time (GMT): Friday, December 25, 2020 10:30:00 AM
  uint256 public constant DAYS = 7; //time duration of sale
  uint256 public constant initialTokens = 100000000 * 10**18; //Number of tokens at start of the sale. This exact amount must be sent to the contract to call initialize() !
  bool public initialized = false; //We dont start until you call initialize()
  uint256 public raisedAmount = 0; //allow users to read the amount of funds raised
  event BoughtTokens(address indexed to, uint256 value);
  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());
    _;
  }
  constructor() public {
      address _tokenAddr = 0xd9EAE2f204D7506Dd2C22394ad57FcE47675B111;
      token = Token(_tokenAddr);
  }
  function initialize() public onlyOwner { //Make sure you send the tokens specified above before calling this or it will fail!
      require(initialized == false); //Call when you are ready to start the sale
      require(tokensAvailable() == initialTokens);
      initialized = true;
  }
  function isActive() public view returns (bool) {
    return (
        initialized == true && //Lets the public know if we're live
        block.timestamp >= START &&
        block.timestamp <= START.add(DAYS * 1 days) &&
        goalReached() == false
    );
  }
  function goalReached() public view returns (bool) {
    return (raisedAmount >= CAP * 1 ether);
  }
  fallback () external payable {
    buyTokens();
  } //Fallbacks so if someone sends ether directly to the contract it will function as a purchase
  receive() external payable {
    buyTokens();
  }
  function buyTokens() public payable whenSaleIsActive {
    require(msg.value > 0);
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(RATE);

    emit BoughtTokens(msg.sender, tokens);
    raisedAmount = raisedAmount.add(msg.value);
    ownerpayable.transfer(msg.value);
    token.transfer(msg.sender, tokens);
  }
  function tokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this));
  }
  function destroy() onlyOwner public {
    uint256 balance = token.balanceOf(address(this));
    assert(balance > 0);
    token.transfer(owner, balance); //Tokens returned to owner wallet; will be subsequently burned.
    selfdestruct(ownerpayable);
  }
}  //Development credit to MCP Capital, LLC. Visit Solidity.finance for more!