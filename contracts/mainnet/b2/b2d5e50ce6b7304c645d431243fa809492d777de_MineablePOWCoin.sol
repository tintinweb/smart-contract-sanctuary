pragma solidity ^0.4.14;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 

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

contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
 function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
 

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
 
}
 
contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;
 
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];
 

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
 
  function approve(address _spender, uint256 _value) returns (bool) {
 
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
 
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
 
}
 
contract Ownable {
    
  address public owner;
 
 
  function Ownable() {
    owner = msg.sender;
  }
 
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }
 
}
 
contract TheLiquidToken is StandardToken, Ownable {
bytes32 public currentChallenge;                         // The coin starts with a challenge
uint public timeOfLastProof;                             // Variable to keep track of when rewards were given
uint public difficulty = 10**1;                         // Difficulty starts reasonably low

function proofOfWork(uint nonce){
    bytes8 n = bytes8(sha3(nonce, currentChallenge));    // Generate a random hash based on input
    if (n < bytes8(difficulty)) throw;                   // Check if it&#39;s under the difficulty

    uint timeSinceLastProof = (now - timeOfLastProof);  // Calculate time since last reward was given
    if (timeSinceLastProof <  30 seconds) throw;         // Rewards cannot be given too quickly
    balances[msg.sender] += timeSinceLastProof / 60 seconds;  // The reward to the winner grows by the minute

    difficulty = difficulty * 10 minutes / timeSinceLastProof + 1;  // Adjusts the difficulty

    timeOfLastProof = now;                              // Reset the counter
    currentChallenge = sha3(nonce, currentChallenge, block.blockhash(block.number-1));  // Save a hash that will be used as the next proof
}

  
}
    
contract MineablePOWCoin is TheLiquidToken {
  string public constant name = "POWCoin";
  string public constant symbol = "POW";
  uint public constant decimals = 1;
  uint256 public initialSupply;
    
  function MineablePOWCoin () { 
     totalSupply = 1 * 10 ** decimals;
      balances[msg.sender] = totalSupply;
      initialSupply = totalSupply; 
        Transfer(0, this, totalSupply);
        Transfer(this, msg.sender, totalSupply);
  }
}