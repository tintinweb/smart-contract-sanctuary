pragma solidity ^0.4.0;

contract owned {

    address public owner;

    function owned() payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        owner = _owner;
    }
}

contract Crowdsale is owned {
    
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function Crowdsale() payable owned() {
        totalSupply = 10000000 * 1 ether;
        balanceOf[this] = 5500000 * 1 ether;
        balanceOf[owner] = totalSupply - balanceOf[this];
        Transfer(this, owner, balanceOf[owner]);
    }

    function () payable {
        require(balanceOf[this] > 0);
        uint256 tokensPerOneEther = 1000;
        //uint256 tokens = tokensPerOneEther * msg.value / 1000000000000000000;
        uint256 tokens = tokensPerOneEther * msg.value ;
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint valueWei = tokens * 1000000000000000000 / tokensPerOneEther;
            msg.sender.transfer(msg.value - valueWei);
        }
        require(tokens > 0);
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        Transfer(this, msg.sender, tokens);
    }
}

contract EnterRentToken is Crowdsale {
    
    string  public standard    = &#39;Token 1.3&#39;;
    string  public name        = &#39;Enter Rent Token&#39;;
    string  public symbol      = "ERT";
    uint8   public decimals    = 18;

    function EnterRentToken() payable Crowdsale() {}

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
    
}


contract EnterRentCrowdsale is EnterRentToken {

    function EnterRentCrowdsale() payable EnterRentToken() {}
    
   function withdraw() public onlyOwner {
    msg.sender.transfer(this.balance);
  }
    

    function killMe() public onlyOwner {
        selfdestruct(owner);
    }
}