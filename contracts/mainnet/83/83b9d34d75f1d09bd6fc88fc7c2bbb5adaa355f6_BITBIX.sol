pragma solidity ^0.4.11;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

//import &#39;./SafeMath.sol&#39;;

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract BITBIX is ERC20Basic {
    
    using SafeMath for uint256;
    
    //                                  30,000,000.00000000
    uint public  _totalSupply = 3000000000000000; 
    
    // name and branding
    string public constant name = "BITBIX";
    string public constant symbol = "BBX";
    uint8 public constant decimals = 8;
    
    
    address public owner;
    
    mapping(address => uint256) balances; 
    mapping(address => mapping(address => uint256)) allowed;
    
   
    function BITBIX() 
    { 
        balances[msg.sender] = _totalSupply; 
        owner = msg.sender;
        
    } 
    
  
    function totalSupply() constant returns (uint256 totalSupply) 
    {
        return _totalSupply; 
    } 
    
    function balanceOf(address _owner) constant returns (uint256 balance) 
    {
        return balances[_owner]; 
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) 
    {
        require(
            balances[msg.sender] >= _value 
            && _value > 0 
            ); 
            
        balances[msg.sender] = balances[msg.sender].sub(_value); 
        balances[_to] = balances[_to].add(_value); 
        
        Transfer(msg.sender, _to, _value); 
        return true; 
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(
            allowed[_from][msg.sender] >= _value
            && balances[_from] >= _value
            && _value > 0
            );
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            Transfer(_from,_to,_value);
            return true;
    }
    
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}