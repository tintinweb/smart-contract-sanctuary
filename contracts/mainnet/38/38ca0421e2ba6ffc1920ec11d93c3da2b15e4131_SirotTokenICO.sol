/**
 *Submitted for verification at Etherscan.io on 2020-07-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
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
contract SirotTokenICO is Ownable {
  using SafeMath for uint256;
  Token token;
  string public constant Info = "Do not call buyTokens directly. Use sale.sirottoken.com";
  uint256 public constant RATE = 125000;
  uint256 public constant CAP = 500;
  uint256 public constant START = 1593705081; // July 2nd
  uint256 public constant DAYS = 92;
  uint256 public constant initialTokens = 50000000 * 10**18;
  bool public initialized = false;
  uint256 public raisedAmount = 0;
  event BoughtTokens(address indexed to, uint256 value);
  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());
    _;
  }
  constructor() public {
      address _tokenAddr = 0x5eA0F26b81DC67d2463020614650d9325C8adbE7;
      token = Token(_tokenAddr);
  }
  function initialize() public onlyOwner {
      require(initialized == false);
      require(tokensAvailable() == initialTokens);
      initialized = true;
  }
  function isActive() public view returns (bool) {
    return (
        initialized == true &&
        now >= START &&
        now <= START.add(DAYS * 1 days) &&
        goalReached() == false
    );
  }
  function goalReached() public view returns (bool) {
    return (raisedAmount >= CAP * 1 ether);
  }
  fallback () external payable {
    buyTokens();
  }
  receive() external payable {
    buyTokens();
  }
  function buyTokens() public payable whenSaleIsActive {
    require(msg.value > 0);
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(RATE);
    
    emit BoughtTokens(msg.sender, tokens);
    raisedAmount = raisedAmount.add(msg.value);
    token.transfer(msg.sender, tokens);
    ownerpayable.transfer(msg.value);
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
}