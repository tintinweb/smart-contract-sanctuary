pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {  owner = msg.sender;  }
    modifier onlyOwner {  require (msg.sender == owner);    _;   }
    function transferOwnership(address newOwner) onlyOwner public{  owner = newOwner;  }
}

contract RLLToken is owned {
    string public name; 
    string public symbol; 
    uint8 public decimals = 18;
    uint256 public totalSupply; 

    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public lockOf;
	mapping (address => bool) public frozenAccount; 
	
    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Burn(address indexed from, uint256 value); 
    
    function RLLToken(uint256 initialSupply, string tokenName, string tokenSymbol, address centralMinter) public {
        if(centralMinter != 0 ) 
			owner = centralMinter; 
		else
			owner = msg.sender;
		
        totalSupply = initialSupply * 10 ** uint256(decimals); 
        balanceOf[owner] = totalSupply; 

        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0); 
        require (balanceOf[_from] > _value); 
        require (balanceOf[_to] + _value > balanceOf[_to]);
		require( balanceOf[_from] - _value >= lockOf[_from] );
        require(!frozenAccount[_from]); 
        require(!frozenAccount[_to]);

		uint256 previousBalances = balanceOf[_from] +balanceOf[_to]; 
        
        balanceOf[_from] -= _value; 
        balanceOf[_to] +=  _value; 
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances); 
		emit Transfer(_from, _to, _value); 
    }
	
    function transfer(address _to, uint256 _value) public {   _transfer(msg.sender, _to, _value);   }

    function lockAccount(address _spender, uint256 _value) public onlyOwner returns (bool success) {
        lockOf[_spender] = _value*10 ** uint256(decimals);
        return true;
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
    }

    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   

		balanceOf[msg.sender] -= _value; 
        totalSupply -= _value; 
        emit Burn(msg.sender, _value);
        return true;
    }
	
}