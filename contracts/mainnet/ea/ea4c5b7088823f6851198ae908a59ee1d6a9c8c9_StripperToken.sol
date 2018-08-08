pragma solidity ^0.4.11;

interface ERC20 {
function totalSupply() constant returns (uint256 totalSupply);
function balanceOf(address _owner) constant returns (uint256 balance);
function transfer(address _to, uint256 _value) returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
function approve(address _spender, uint256 _value) returns (bool success);
function allowance(address _owner, address _spender) constant returns (uint256 remaining);
event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract StripperToken is ERC20 {
    
    using SafeMath for uint256;
    
    uint public constant _totalSupply = 1000000000000000000000000;
    
    string public constant symbol = "STRP";
    string public constant name = "Stripper Token";
    uint8 public constant decimals = 18;
    
    // 1 ether = 100 STRP
    uint256 public constant RATE = 100;
    
    address public owner;
    
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    function ( ) payable {
        createTokens( );
    }
    
    
    function StripperToken( ) {
        owner = msg.sender;
    }
    
    function createTokens( ) payable {
        require(msg.value > 0);
        
        uint256 tokens = msg.value.mul(RATE);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        
        owner.transfer(msg.value);
    }
    
    function totalSupply( ) constant returns (uint256 totalSupply) {
       return _totalSupply;
    }
   
   function balanceOf(address _owner) constant returns (uint256 balance) {
       return balances[_owner];
   }
   
   function transfer(address _to, uint256 _value) returns (bool success) {
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
        Transfer(_from, _to, _value);
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