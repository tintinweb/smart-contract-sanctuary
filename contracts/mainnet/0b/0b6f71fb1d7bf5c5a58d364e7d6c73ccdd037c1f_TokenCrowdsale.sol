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

contract TraceCrowdsale is owned {
    
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function TraceCrowdsale() payable owned() {
        totalSupply = 5000000;
        balanceOf[this] = 2500000;
        balanceOf[owner] = totalSupply - balanceOf[this];
        Transfer(this, owner, balanceOf[owner]);
    }

    function () payable {
        require(balanceOf[this] > 0);
        uint256 tokensPerOneEther = 5000;
        uint256 tokens = tokensPerOneEther * msg.value / 1000000000000000000;
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

contract TraceToken is TraceCrowdsale {
    
    string  public standard    = &#39;Token 0.1&#39;;
    string  public name        = &#39;TraceToken&#39;;
    string  public symbol      = "TACE";
    uint8   public decimals    = 0;

    function TraceToken() payable TraceCrowdsale() {}

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
}

contract TokenCrowdsale is TraceToken {

    function TokenCrowdsale() payable TraceToken() {}
    
    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }
    
    function killMe() public onlyOwner {
        selfdestruct(owner);
    }
}