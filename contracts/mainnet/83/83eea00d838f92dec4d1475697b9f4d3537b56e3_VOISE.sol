pragma solidity ^0.4.6;
 
contract SafeMath {
  //internals
 
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
 
  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
 
  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}
 
contract VOISE is SafeMath {
    /* Public variables of the token */
    string public standard = &#39;ERC20&#39;;
    string public name = &#39;VOISE&#39;;
    string public symbol = &#39;VOISE&#39;;
    uint8  public decimals = 8;
    uint256 public totalSupply;
    address public owner;
    uint256 public startTime = 1492560000;
    /* tells if tokens have been burned already */
    bool burned;
 
    /* This creates an array with all the balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
 
 
    /* This generates a public event on the blockchain that will notify all clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burned(uint amount);
 
    /* Initializes contract with initial supply tokens and gives them to the voise team adress */
    function VOISE() {
        
        owner = msg.sender;
        
        balanceOf[owner] = 82557800000000000;   // All of them are stored in the voise team adress until they are bought
        totalSupply = 82557800000000000; // total supply of tokens
    }
 
    /* Send some of your tokens to a given address (Press bounties) */
    function transfer(address _to, uint256 _value) returns (bool success){
        if (now < startTime) throw; //check if the crowdsale is already over
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender],_value);                     // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }
 
    /* Allow another contract or person to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
 
 
    /* A contract or  person attempts to get the tokens of somebody else. */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (now < startTime && _from!=owner) throw; //check if the crowdsale is already over
        var _allowance = allowance[_from][msg.sender];
        balanceOf[_from] = safeSub(balanceOf[_from],_value); // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);     // Add the same to the recipient
        allowance[_from][msg.sender] = safeSub(_allowance,_value);
        Transfer(_from, _to, _value);
        return true;
    }
 
}