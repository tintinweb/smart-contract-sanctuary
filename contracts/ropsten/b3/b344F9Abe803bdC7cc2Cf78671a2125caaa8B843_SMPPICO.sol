/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity ^0.4.21;

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

  function Ownable() public {
    owner = msg.sender;
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
  function balanceOf(address _owner) external constant returns (uint256 balance);
}

contract SMPPICO is Ownable {
  using SafeMath for uint256;
  Token token;

  uint256 public constant RATE = 200;
  uint256 public constant CAP = 4000;
  uint256 public constant START = 10960990;
  uint256 public constant DAYS = 360;

  uint256 public constant initialTokens = 800000 * 10**18;
  bool public initialized = false;
  uint256 public raisedAmount = 0;

  event BoughtTokens(address indexed to, uint256 value);

  modifier whenSaleIsActive() {
    assert(isActive());
    _;
  }

  function SMPPICO(address _tokenAddr) public {
      require(_tokenAddr != 0);
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

  function () public payable {
    buyTokens();
  }

  function buyTokens() public payable whenSaleIsActive {
    uint256 weiAmount = msg.value; 
    uint256 tokens = weiAmount.mul(RATE);

    emit BoughtTokens(msg.sender, tokens); 
    raisedAmount = raisedAmount.add(msg.value); 
    token.transfer(msg.sender, tokens); 

    owner.transfer(msg.value);
  }

  function tokensAvailable() public constant returns (uint256) {
    return token.balanceOf(this);
  }

  function destroy() onlyOwner public {
    uint256 balance = token.balanceOf(this);
    assert(balance > 0);
    token.transfer(owner, balance);
    selfdestruct(owner);
  }
}