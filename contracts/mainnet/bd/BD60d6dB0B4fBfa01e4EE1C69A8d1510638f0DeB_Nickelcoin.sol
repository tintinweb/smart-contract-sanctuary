pragma solidity ^0.4.18;

interface IERC20 {

function totalSupply() public constant returns (uint256 totalSupply);
//Get the total token supply
function balanceOf(address _owner) public constant returns (uint256 balance);
//Get the account balance of another account with address _owner
function transfer(address _to, uint256 _value) public returns (bool success);
//Send _value amount of tokens to address _to
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
//Send _value amount of tokens from address _from to address _to
/*The transferFrom method is used for a withdraw workflow, allowing contracts to send 
tokens on your behalf, for example to "deposit" to a contract address and/or to charge
fees in sub-currencies; the command should fail unless the _from account has deliberately
authorized the sender of the message via some mechanism; we propose these standardized APIs for approval: */
function approve(address _spender, uint256 _value) public returns (bool success);
/* Allow _spender to withdraw from your account, multiple times, up to the _value amount. 
If this function is called again it overwrites the current allowance with _value. */
function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
//Returns the amount which _spender is still allowed to withdraw from _owner
event Transfer(address indexed _from, address indexed _to, uint256 _value);
//Triggered when tokens are transferred.
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
//Triggered whenever approve(address _spender, uint256 _value) is called.

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Nickelcoin is IERC20 {
    
    using SafeMath for uint256;
    
    string public constant name = "Nickelcoin";  
    string public constant symbol = "NKL"; 
    uint8 public constant decimals = 8;  
    uint public  _totalSupply = 4000000000000000; 
    
   
    mapping (address => uint256) public funds; 
    mapping(address => mapping(address => uint256)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);  
    
    function Nickelcoin() public {
    funds[0xa33c5838B8169A488344a9ba656420de1db3dc51] = _totalSupply; 
    }
     
    function totalSupply() public constant returns (uint256 totalsupply) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return funds[_owner];  
    }
        
    function transfer(address _to, uint256 _value) public returns (bool success) {
   
    require(funds[msg.sender] >= _value && funds[_to].add(_value) >= funds[_to]);

    
    funds[msg.sender] = funds[msg.sender].sub(_value); 
    funds[_to] = funds[_to].add(_value);       
  
    Transfer(msg.sender, _to, _value); 
    return true;
    }
	
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require (allowed[_from][msg.sender] >= _value);   
        require (_to != 0x0);                            
        require (funds[_from] >= _value);               
        require (funds[_to].add(_value) > funds[_to]); 
        funds[_from] = funds[_from].sub(_value);   
        funds[_to] = funds[_to].add(_value);        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);                 
        return true;                                      
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
         allowed[msg.sender][_spender] = _value;    
         Approval (msg.sender, _spender, _value);   
         return true;                               
     }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];   
    } 
    

}