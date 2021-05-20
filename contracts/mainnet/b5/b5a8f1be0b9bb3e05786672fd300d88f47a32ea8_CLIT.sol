/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.4.19;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

  contract ERC20 {
  function totalSupply()public view returns (uint total_Supply);
  function balanceOf(address _owner)public view returns (uint256 balance);
  function allowance(address _owner, address _spender)public view returns (uint remaining);
  function transferFrom(address _from, address _to, uint _amount)public returns (bool ok);
  function approve(address _spender, uint _amount)public returns (bool ok);
  function transfer(address _to, uint _amount)public returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint _amount);
  event Approval(address indexed _owner, address indexed _spender, uint _amount);
}

contract CLIT is ERC20
{using SafeMath for uint256;
   string public constant symbol = "CLIT";
     string public constant name = "CLIT";
     uint public constant decimals = 10;
     uint256 _totalSupply = 1000000000000000 * 10 ** 10;
     
     address public owner;
     
     bool public burnTokenStatus;
     mapping(address => uint256) balances;
  
     mapping(address => mapping (address => uint256)) allowed;
  
     modifier onlyOwner() {
         require (msg.sender == owner);
         _;
     }
  
     function CLIT () public {
         owner = msg.sender;
         balances[owner] = _totalSupply;
         emit Transfer(0, owner, _totalSupply);
     }
   
    function burntokens(uint256 tokens) external onlyOwner {
         require(!burnTokenStatus);
         require( tokens <= balances[owner]);
         burnTokenStatus = true;
         _totalSupply = (_totalSupply).sub(tokens);
         balances[owner] = balances[owner].sub(tokens);
         emit Transfer(owner, 0, tokens);
     }
  
     function totalSupply() public view returns (uint256 total_Supply) {
         total_Supply = _totalSupply;
     }

     function balanceOf(address _owner)public view returns (uint256 balance) {
         return balances[_owner];
     }
  
     function transfer(address _to, uint256 _amount)public returns (bool ok) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(msg.sender, _to, _amount);
             return true;
         }

     function transferFrom( address _from, address _to, uint256 _amount )public returns (bool ok) {
     require( _to != 0x0);
     require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
     balances[_from] = (balances[_from]).sub(_amount);
     allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
     balances[_to] = (balances[_to]).add(_amount);
     emit Transfer(_from, _to, _amount);
     return true;
         }
 
     function approve(address _spender, uint256 _amount)public returns (bool ok) {
         require( _spender != 0x0);
         allowed[msg.sender][_spender] = _amount;
         emit Approval(msg.sender, _spender, _amount);
         return true;
         }
  
     function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
         require( _owner != 0x0 && _spender !=0x0);
         return allowed[_owner][_spender];
         }
        
	function transferOwnership(address newOwner) external onlyOwner
	{
	    require( newOwner != 0x0);
	    balances[newOwner] = (balances[newOwner]).add(balances[owner]);
	    balances[owner] = 0;
	    owner = newOwner;
	    emit Transfer(msg.sender, newOwner, balances[newOwner]);
	}
}