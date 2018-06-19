pragma solidity ^0.4.0;

contract owned {

  address public owner;
  address public candidate;
  
  function owned() public payable {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(owner == msg.sender);
    _;
  }

  function changeOwner(address _owner) onlyOwner public {
    candidate = _owner;
  }
  
  function confirmOwner() public {
    require(candidate == msg.sender);
    owner = candidate;
  }  
}

contract TelegramOpenNetwork is owned {

  uint256 public totalSupply;
  mapping (address => uint256) public balanceOf;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  function TelegramOpenNetwork() public payable owned() {
    totalSupply = 5000000000;
    balanceOf[this] = 4150000000;
    balanceOf[owner] = totalSupply - balanceOf[this];
    Transfer(this, owner, balanceOf[owner]);
  }

  function () public payable {
    require(balanceOf[this] > 0);
    uint256 tokens = 700 * msg.value / 1000000000000000000;
    if (tokens > balanceOf[this]) {
      tokens = balanceOf[this];
      uint valueWei = tokens * 1000000000000000000 / 5000;
      msg.sender.transfer(msg.value - valueWei);
    }
    require(tokens > 0);
    balanceOf[msg.sender] += tokens;
    balanceOf[this] -= tokens;
    Transfer(this, msg.sender, tokens);
  }
}

contract TonToken is TelegramOpenNetwork {
    
  string public standard    = &#39;ERC 20&#39;;
  string public name      = &#39;TelegramOpenNetwork&#39;;
  string public symbol    = &#39;TON&#39;;
  uint8  public decimals    = 0;
  
  function TonToken() public payable TelegramOpenNetwork() {}
  
  function transfer(address _to, uint256 _value) public {
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    Transfer(msg.sender, _to, _value);
  }
}

contract TelegramOpenNetworkContract is TonToken {

  function TelegramOpenNetworkContract() public payable TonToken() {}

  function withdraw() public onlyOwner {
    owner.transfer(this.balance);
  } 
}