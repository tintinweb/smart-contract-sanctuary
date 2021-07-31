/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

pragma solidity 0.4.26;

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

contract WG is SafeMath{
    string public name="World Green Chain";
    string public symbol="WG";
    uint8 public decimals=9;
    uint256 public totalSupply= 500000000000 * 10**uint256(decimals);
    mapping(address=>uint256)public balanceOf;
    address private owner=0xDC88EC2A5DEbeca75c152dE9Cf3FF26ebB18aE17;
    
    
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    
    event Approveal(address indexed _owner, address indexed _spender, uint _value);
    
    constructor()public{
        balanceOf[owner]=totalSupply;
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
        
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                     // Subtract from the sender
       
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(_from, _to, _value);                   // Notify anyone listening that this transfer took place
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