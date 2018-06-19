pragma solidity ^0.4.16;

contract Utils {
    function Utils() public {    }
    modifier greaterThanZero(uint256 _amount) { require(_amount > 0);    _;   }
    modifier validAddress(address _address) { require(_address != 0x0);  _;   }
    modifier notThis(address _address) { require(_address != address(this));  _; }
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) { uint256 z = _x + _y;  assert(z >= _x);  return z;  }
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) { assert(_x >= _y);  return _x - _y;   }
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) { uint256 z = _x * _y; assert(_x == 0 || z / _x == _y); return z; }
}

contract owned {
    address public owner;

    function owned() public {  owner = msg.sender;  }
    modifier onlyOwner {  require (msg.sender == owner);    _;   }
    function transferOwnership(address newOwner) onlyOwner public{  owner = newOwner;  }
}

contract MyUserToken is owned, Utils {
    string public name; 
    string public symbol; 
    uint8 public decimals = 18;
    uint256 public totalSupply; 

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value); 
    
    function MyUserToken(uint256 initialSupply, string tokenName, string tokenSymbol) public {

        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply; 

        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {

      require(_to != 0x0); 
      require(balanceOf[_from] >= _value); 
      require(balanceOf[_to] + _value > balanceOf[_to]); 
      
      uint256 previousBalances = safeAdd(balanceOf[_from], balanceOf[_to]); 
      balanceOf[_from] = safeSub(balanceOf[_from], _value); 
      balanceOf[_to] = safeAdd(balanceOf[_to], _value); 
      emit Transfer(_from, _to, _value);
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances); 
    }

    function transfer(address _to, uint256 _value) public {   _transfer(msg.sender, _to, _value);   }
}