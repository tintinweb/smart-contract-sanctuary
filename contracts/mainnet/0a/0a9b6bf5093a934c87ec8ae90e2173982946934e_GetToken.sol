pragma solidity ^0.4.15;

contract ERC20 {
  function totalSupply() constant returns (uint totalsupply);
  function balanceOf(address _owner) constant returns (uint balance);
  function transfer(address _to, uint _value) returns (bool success);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint remaining);
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Owned {
  address public owner;
  event OwnershipTransferred(address indexed _from, address indexed _to);

  function Owned() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    if (msg.sender != owner) revert();
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract GetToken is Owned {
  address public token;
  uint256 public sellPrice;
	
  event GotTokens(address indexed buyer, uint256 ethersSent, uint256 tokensBought);
	
  function GetToken (
    address _token,
    uint256 _sellPrice
  ) {
    token = _token;
    sellPrice = _sellPrice * 1 szabo;
  }
    
  function WithdrawToken(uint256 tokens) onlyOwner returns (bool ok) {
    return ERC20(token).transfer(owner, tokens);
  }
    
  function SetPrice (uint256 newprice) onlyOwner {
    sellPrice = newprice * 1 szabo;
  }
    
  function WithdrawEther(uint256 ethers) onlyOwner returns (bool ok) {
    if (this.balance >= ethers) {
      return owner.send(ethers);
    }
  }
    
  function BuyToken() payable {
    uint tokens = msg.value / sellPrice;
    uint total = ERC20(token).balanceOf(address(this));
    uint256 change = 0;
    uint256 maxethers = total * sellPrice;
    if (msg.value > maxethers) {
      change  = msg.value - maxethers;
    }
    if (change > 0) {
      if (!msg.sender.send(change)) revert();
    }
    if (tokens > 0) {
      if (!ERC20(token).transfer(msg.sender, tokens)) revert();
    }
    GotTokens(msg.sender, msg.value, tokens);
  }
    
  function () payable {
    BuyToken();
  }
}