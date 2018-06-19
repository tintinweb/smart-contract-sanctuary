pragma solidity ^0.4.23;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
// assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface TokenContract {
  function transfer(address _recipient, uint256 _amount) external returns (bool);
  function balanceOf(address _holder) external view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract Exchange is Ownable {
  using SafeMath for uint256;

  uint256 public buyPrice;
  uint256 public sellPrice;
  address public tokenAddress;
  uint256 private fullEther = 1 ether;


  constructor() public {
    buyPrice = 600;
    sellPrice = 400;
    tokenAddress = 0x0;
  }

  function setBuyPrice(uint256 _price) onlyOwner public {
    buyPrice = _price;
  }

  function setSellPrice(uint256 _price) onlyOwner public {
    sellPrice = _price;
  }

  function() payable public {
    sellTokens();
  }

  function sellTokens() payable public {
    TokenContract tkn = TokenContract(tokenAddress);
    uint256 tokensToSell = msg.value.mul(sellPrice);
    require(tkn.balanceOf(address(this)) >= tokensToSell);
    tkn.transfer(msg.sender, tokensToSell);
    emit SellTransaction(msg.value, tokensToSell);
  }

  function buyTokens(uint256 _amount) public {
    address seller = msg.sender;
    TokenContract tkn = TokenContract(tokenAddress);
    uint256 transactionPrice = _amount.div(buyPrice);
    require (address(this).balance >= transactionPrice);
    require (tkn.transferFrom(msg.sender, address(this), _amount));
    seller.transfer(transactionPrice);
    emit BuyTransaction(transactionPrice, _amount);
  }

  function getBalance(uint256 _amount) onlyOwner public {
    msg.sender.transfer(_amount);
  }

  function getTokens(uint256 _amount) onlyOwner public {
    TokenContract tkn = TokenContract(tokenAddress);
    tkn.transfer(msg.sender, _amount);
  }

  function killMe() onlyOwner public {
    TokenContract tkn = TokenContract(tokenAddress);
    uint256 tokensLeft = tkn.balanceOf(address(this));
    tkn.transfer(msg.sender, tokensLeft);
    msg.sender.transfer(address(this).balance);
    selfdestruct(owner);
  }

  function changeToken(address _address) onlyOwner public {
    tokenAddress = _address;
  }

  event SellTransaction(uint256 ethAmount, uint256 tokenAmount);
  event BuyTransaction(uint256 ethAmount, uint256 tokenAmount);
}