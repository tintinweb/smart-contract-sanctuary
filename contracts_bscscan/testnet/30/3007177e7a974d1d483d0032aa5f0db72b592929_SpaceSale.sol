/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.0 <0.8.0;


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

pragma solidity ^0.7.5;

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
  address payable public ownerPayable;
  constructor()  {
    owner = address(msg.sender);
    ownerPayable = address(uint160(owner));
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner; 
    ownerPayable = address(uint160(owner));

  }
}

contract SpaceSale is Ownable {
    
  using SafeMath for uint256;
  IERC20 token;
  string public constant Info = "Set Gas Limits 200,000";
  uint256 public constant RATE = 1; 
  uint256 public constant CAP = 2000;  
  bool private initialized = false; //We dont start until you call startSale()
  uint256 public raisedAmount = 0; 
  modifier whenSaleIsActive() {
    // Check if sale is active
    assert(isActive());
    _;
  }
  
  constructor() {}
  
  function startSale(address _tokenAddr) public onlyOwner { 
      require(initialized == false); //Call when you are ready to start the sale
      token = IERC20(_tokenAddr);
      token.approve(address(this), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
      initialized = true;
  }
  function isActive() public view returns (bool) {
    return (
        initialized == true //Lets the public know if we're live
    );
  }
  function goalReached() public view returns (bool) {
    return (raisedAmount >= CAP * 1 ether);
  }
  fallback() external payable {
    buyTokens();
  } //Fallbacks so if someone sends ether directly to the contract it will function as a purchase
  receive() external payable {
    buyTokens();
  }
  function buyTokens() public payable whenSaleIsActive {
    require(msg.value >= 1 ether);
    require(msg.value <= 75 ether);
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(RATE);
    raisedAmount = raisedAmount.add(msg.value);
    ownerPayable.transfer(msg.value);
    token.transferFrom(address(this), msg.sender, tokens);
  }
  function tokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this));
  }
  function endSale() onlyOwner public {
    uint256 tokenBalance = token.balanceOf(address(this));
    token.transferFrom(address(this), owner, tokenBalance); //Tokens returned to owner wallet
    selfdestruct(ownerPayable);
  }
}