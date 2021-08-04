//SourceUnit: 普通的波场合约.sol

pragma solidity 0.4.25;

contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  
}

contract ACI is SafeMath{
    string public name="Agricultural integral";
    string public symbol="ACI";
    uint8 public decimals=9;
    uint256 public totalSupply= 86000000 * 10**uint256(decimals);
    mapping(address=>uint256)public balanceOf;
    address private owner;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approveal(address indexed _owner, address indexed _spender, uint _value);
    
    constructor()public{
        balanceOf[address(0x41B0ED360C407B3C2488E9C6C701D2E3D4B621A798)]=totalSupply;
        owner=address(0x41B0ED360C407B3C2488E9C6C701D2E3D4B621A798);
    }
    
    
    function transfer(address _to, uint256 _value)public returns(bool) {
        _transfer(msg.sender,_to,_value);
        return true;
    }
    
     function _transfer(address _from,address _to, uint256 _value)private returns(bool) {
        require(_to != 0x0,"err:");
		require(_value > 0,"err:");
        require (balanceOf[_from]>= _value);  
        require(balanceOf[_to] + _value > balanceOf[_to]); 
      
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                    
        
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                           
        emit Transfer(_from, _to, _value);                  
     }
      
     function transferFrom(address _from, address _to, uint256 _value)public  returns (bool success) {
        require (_value <= allowance[_from][msg.sender]);     // Check allowance
        _transfer(_from,_to,_value);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value)public returns (bool success) {
		require (_value > 0) ; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function() payable {
        
    }
    
    // transfer balance to owner
	function withdrawEther(uint256 amount) {
		require(owner==msg.sender);
		owner.transfer(amount);
	}
}