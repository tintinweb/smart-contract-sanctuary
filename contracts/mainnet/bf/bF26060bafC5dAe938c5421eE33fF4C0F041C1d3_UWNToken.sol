pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {  owner = msg.sender;  }
    modifier onlyOwner {  require (msg.sender == owner);    _;   }
    function transferOwnership(address newOwner) onlyOwner public{  owner = newOwner;  }
}

contract UWNToken is owned{
    string public name; 
    string public symbol; 
    uint8 public decimals = 18; 
    uint256 public totalSupply; 

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Burn(address indexed from, uint256 value);  
    
    function UWNToken(uint256 initialSupply, string tokenName, string tokenSymbol, address owneraddr) public {
		owner = owneraddr;

        totalSupply = initialSupply * 10 ** uint256(decimals); 
        
        balanceOf[owner] = totalSupply; 

        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {

      require(_to != 0x0); 
      require(balanceOf[_from] >= _value); 
      require(balanceOf[_to] + _value > balanceOf[_to]);
      
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
      balanceOf[_from] -= _value;
      balanceOf[_to] += _value; 
      emit Transfer(_from, _to, _value);
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances); 

    }

    function transfer(address _to, uint256 _value) public {   _transfer(msg.sender, _to, _value);   }

    function burn(uint256 _value) public onlyOwner returns (bool success) {
        
        require(balanceOf[msg.sender] >= _value);  

		balanceOf[msg.sender] -= _value; 
        totalSupply -= _value; 
        emit Burn(msg.sender, _value);
        return true;
    }
}