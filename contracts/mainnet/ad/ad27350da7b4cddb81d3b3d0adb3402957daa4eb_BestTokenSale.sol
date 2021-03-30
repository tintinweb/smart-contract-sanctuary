/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

/**
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
░░░░░░██████╗░██╗░░░░░░░██╗░█████╗░██████╗░░░░░░░░░░░░|
░░░░░██╔════╝░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░░░░░░|
░░░░░╚█████╗░░╚██╗████╗██╔╝███████║██████╔╝░░░░░░░░░░░|
░░░░░░╚═══██╗░░████╔═████║░██╔══██║██╔═══╝░░░░░░░░░░░░|
░░░░░██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░░░░░░░░░░░░░░░|
░░░░░╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░░░░░░░░░░░░░░░|
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
░░░░░░░░░░░░░░░░TheBestSwap.org░░░░░░░░░░░░░░░░░░░░░░░|

// Token sale TheBestSwap.Org
// Contract Best: 0xf42219aa121140128a4c04bf0f7555c8d3feac94
// Price 5000 BEST = 1 ETH
// List Price: 1 ETH = 2700 BEST (Guaranteed by Shenghai fund)
// List exchange time: 1 hour after the end of Presale,
// Pre-sale start: from 4:00 PM (GMT+8) March 30, to (3 hours)
// Send ETH to the contract address of the contract Presale: 0xAd27350DA7b4CDdb81d3b3d0AdB3402957daA4eb
// Gas Limit 200,000
//Gas Price (GWEI): 140
// Min Buy: 0.1 ether
// Max Buy: 5 ether
// Token is automatically distributed, we recommend using a personal wallet, or wallets with private keys, not sending ETH from Exchange or wallets from exchanges!
// Website - https://thebesswap.org
//Trade - https://thebestswap.org/#/swap
// Dextools - https://www.dextools.io/app/uniswap/pair-explorer/0xf42219aa121140128A4C04Bf0F7555C8D3feaC94
// Telegram - https://t.me/TheBestSwap
// Github - https://github.com/TheBestSwap
*/

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

contract BestTokenSale is Ownable {
  
using SafeMath for uint256;
  IERC20 token;
  string public constant Info = "thebestswap.org";
  uint256 public constant RATE = 5000; //number of tokens per ETH
  uint256 public constant CAP = 1000;  //Number of ETH accepted until the sale ends
  bool private initialized = false; //We dont start until you call startSale()
  uint256 public raisedAmount = 0; //allow users to read the amount of funds raised
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
    require(msg.value >= 0.1 ether);
    require(msg.value <= 15 ether);
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