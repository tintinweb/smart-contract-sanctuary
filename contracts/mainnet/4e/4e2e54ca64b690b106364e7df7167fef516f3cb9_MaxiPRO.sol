/*
The MaxiPRO Contract.

The MaxiPRO Contract is free software: you can redistribute it and/or
modify.
@author Ivan Fedorov 
twitter https://twitter.com/maxipro_pro
bitcointalk https://bitcointalk.org/index.php?topic=4336550
telegram https://t.me/Maxipro_pro
medium https://medium.com/@maxipro_pro
contact e-mail: info@maxipro.pro
*/




 pragma solidity ^0.4.16; 
    contract owned {
        address public owner;

        function owned() {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner {
            owner = newOwner;
        }
    }
		
	contract Crowdsale is owned {
    
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
	  mapping (address => bool) public frozenAccount;
      event Transfer(address indexed from, address indexed to, uint256 value);

    function Crowdsale() payable owned() {
        totalSupply = 1000000000;
        balanceOf[this] = 400000000; // public sale
		balanceOf[0x552e7F467CAF7FaBCEcaFdF3e986d093F85c5762] = 300000000; // team
		balanceOf[0x8Caa69e596CCE4A5EbaE0Efe44765573EDCa70CE] = 200000000; // for development and support of investment instrument
		balanceOf[0x4d989F62Dc0133d82Dbe8378a9d6542F3b0ABee5] = 8750000; // closed sale 
		balanceOf[0xA81A580813c3b187a8A2B6b67c555b10C73614fa] = 2500000; // closed sale 
		balanceOf[0x08c68BB69532EaaAF5d62B3732A2b7b7ABd74394] = 10000000; // closed sale 
		balanceOf[0x829ac84591641639A7b8C7150b7CF3e753778cd8] = 6250000; // closed sale 
		balanceOf[0xae8b76e01EBcd0e2E8b190922F08639D42abc0c9] = 3250000; // closed sale 
		balanceOf[0x78C2bd83Fd47ea35C6B4750AeFEc1a7CF1a2Ad0a] = 2000000; // closed sale 
		balanceOf[0x24e7d49CBF4108473dBC1c7A4ADF0De28CaF4148] = 4125000; // closed sale 
		balanceOf[0x322D5BA67bdc48ECC675546C302DB6B5d7a0C610] = 5250000; // closed sale 
		balanceOf[0x2e43daE28DF4ef8952096721eE22602344638979] = 8750000; // closed sale 
		balanceOf[0x3C36A7F610C777641fcD2f12B0D82917575AB7dd] = 3750000; // closed sale 
		balanceOf[0xDCE1d58c47b28dfe22F6B334E5517a49bF7B229a] = 7500000; // closed sale 
		balanceOf[0x36Cbb77588E5a59124e530dEc08a3C5433cCD820] = 6750000; // closed sale 
		balanceOf[0x3887FCB4BC96E66076B213963FbE277Ed808345A] = 12500000; // closed sale 
		balanceOf[0x6658E430bBD2b97c421A8BBA13361cC83D48609C] = 6250000; // closed sale 
		balanceOf[0xb137178106ade0506393d2041BDf90AF542F35ED] = 2500000; // closed sale 
		balanceOf[0x8F551F0B6144235cB89F000BA87fDd3A6B425F2E] = 7500000; // closed sale 
		balanceOf[0xfC1F805de2C30af99B72B02B60ED9877660C5194] = 2375000; // closed sale 
	
    }

    function () payable {
        require(balanceOf[this] > 0);
        uint256 tokens = 200000 * msg.value / 1000000000000000000;
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint valueWei = tokens * 1000000000000000000 / 200000;
            msg.sender.transfer(msg.value - valueWei);
        }
        require(balanceOf[msg.sender] + tokens > balanceOf[msg.sender]); 
        require(tokens > 0);
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        Transfer(this, msg.sender, tokens);
    }
}
contract Token is Crowdsale {
    
   
    string  public name        = &#39;MaxiPRO&#39;;
    string  public symbol      = "MPR";
    uint8   public decimals    = 0;

    mapping (address => mapping (address => uint256)) public allowed;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burned(address indexed owner, uint256 value);

    function Token() payable Crowdsale() {}

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
		require(!frozenAccount[msg.sender]);
		
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowed[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant
        returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burned(msg.sender, _value);
    }
}
contract MaxiPRO is Token {
    
    
    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }
     function killMe() public onlyOwner {
        require(totalSupply == 0);
        selfdestruct(owner);
    }
}