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

contract OsmiumCrowdsale is owned {
    
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function OsmiumCrowdsale() payable owned() {
        totalSupply = 21000000;
        balanceOf[this] = 20000000;
        balanceOf[owner] = totalSupply - balanceOf[this];
        Transfer(this, owner, balanceOf[owner]);
    }

    function () payable {
        require(balanceOf[this] > 0);
        uint256 tokensPerOneEther = 3000;
        uint256 tokens = tokensPerOneEther * msg.value / 1000000000000000000;
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

contract Osmium is OsmiumCrowdsale {
    
    string  public standard    = &#39;Token 0.1&#39;;
    string  public name        = &#39;Osmium&#39;;
    string  public symbol      = "OSM";
    uint8   public decimals    = 0;

    function Osmium() payable OsmiumCrowdsale() {}

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
}

contract EasyOsmiumCrowdsale is Osmium {

    function EasyOsmiumCrowdsale() payable Osmium() {}
    
    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }
    
    function killMe() public onlyOwner {
        selfdestruct(owner);
    }
}