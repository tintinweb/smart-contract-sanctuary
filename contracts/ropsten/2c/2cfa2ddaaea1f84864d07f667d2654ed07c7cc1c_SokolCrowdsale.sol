pragma solidity ^0.4.24;

contract owned {

    address public owner;
    address public newOwner;

    constructor() public payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        newOwner = _owner;
    }

    function confirmOwner() public {
        require(newOwner == msg.sender);
        owner = newOwner;
    }
}

contract Crowdsale is owned {
    
    uint256 public totalSupply;
    string public priceOneTokenSokol = "1 token SOKOL = 0.01 ETH";
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor() public payable owned() {
        totalSupply = 50;
        balanceOf[this] = 10;
        balanceOf[owner] = totalSupply - balanceOf[this];
        emit Transfer(this, owner, balanceOf[owner]);
    }

    function () public payable {
        require(balanceOf[this] > 0);
        uint amountOfTokensForOneEther = 100;

        uint256 tokens = amountOfTokensForOneEther * msg.value / 1000000000000000000;
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint256 valueWei = tokens * 1000000000000000000 / amountOfTokensForOneEther;
            msg.sender.transfer(msg.value - valueWei);
        }
        require(tokens > 0);
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        emit Transfer(this, msg.sender, tokens);
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[this] >= _value);
        balanceOf[this] -= _value;
        totalSupply -= _value;
        emit Burn(this, _value);
        return true;
    }
}

contract Token is Crowdsale {
    
    string  public name        = "Sokol Coin 50";
    string  public symbol      = "SO50";
    uint8   public decimals    = 0;

    constructor() public payable Crowdsale() {}

    function transfer(address _to, uint256 _value) public {
	require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
}

contract SokolCrowdsale is Token {

    constructor() public payable Token() {}
    
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
}