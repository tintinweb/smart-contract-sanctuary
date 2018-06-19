pragma solidity ^0.4.18;

/*PTT final suggested version*/

contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
       require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 is SafeMath {

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);



    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals); 
        balanceOf[msg.sender] = totalSupply;                
        name = tokenName;                                   
        symbol = tokenSymbol;  
    }                             


    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0); 
        require(balanceOf[_from] >= _value); 
        require(balanceOf[_to] + _value > balanceOf[_to]); 
        uint previousBalances = SafeMath.safeAdd(balanceOf[_from],balanceOf[_to]); 
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value); 
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value); 
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances); 
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender],_value);
        _transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

}

contract MyToken is owned, TokenERC20 {

 
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public freezeOf;

    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed from, uint256 value);
    

    function MyToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               
        require (balanceOf[_from] >= _value);              
        require (balanceOf[_to] + _value > balanceOf[_to]); 
        require(!frozenAccount[_from]);                     
        require(!frozenAccount[_to]);                       
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                         
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                           
        Transfer(_from, _to, _value);
    }
    
        function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);    
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);         
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);   
        totalSupply = SafeMath.safeSub(totalSupply, _value);                             
        Burn(_from, _value);
        return true;
    }
    
        function burn(uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);  
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);          
        totalSupply = SafeMath.safeSub(totalSupply, _value);                     
        Burn(msg.sender, _value);
        return true;
    }
 
       function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    	// in case someone transfer ether to smart contract, delete if no one do this
	    function() payable public{}
	    
        // transfer ether balance to owner
	    function withdrawEther(uint256 amount) onlyOwner public {
		msg.sender.transfer(amount);
	}
	
	    // transfer token to owner
        function withdrawMytoken(uint256 amount) onlyOwner public {
        _transfer(this, msg.sender, amount); 
        }
        
}