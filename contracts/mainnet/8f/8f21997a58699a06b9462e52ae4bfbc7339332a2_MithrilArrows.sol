pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

interface IERC20 {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MithrilArrows is IERC20 {
    /* Public variables of the token */
    string public standard = &#39;Token 0.1&#39;;
    string public constant name = "Mithril Arrows";
    string public constant symbol = "MROW";
    uint8 public constant decimals = 2;
    uint256 public initialSupply;
    uint256 public totalSupply;

    using SafeMath for uint256;
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

  
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MithrilArrows() {

         initialSupply = 3050000;
        
        
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
                                   
    }

    function totalSupply() constant returns (uint256 totalSupply){
        return totalSupply;
    } 
    function balanceOf(address _owner) constant returns (uint256 balance){
        return balanceOf[_owner];
    }
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        require(balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
	    balanceOf[_to] = balanceOf[_to].add(_value);
	    Transfer(msg.sender, _to, _value);
	    return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
        require(
            allowance [_from][msg.sender] >= _value
            && balanceOf[_from] >= _value
            && _value > 0
            );
        balanceOf[_from] = balanceOf[_from].sub(_value);
	    balanceOf[_to] = balanceOf[_to].add(_value);
	    allowance[_from][msg.sender] -= _value;
	    Transfer (_from, _to, _value);
	    return true;
    }
    function approve(address _spender, uint256 _value) returns (bool success){
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining){
        return allowance[_owner][_spender];
}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}