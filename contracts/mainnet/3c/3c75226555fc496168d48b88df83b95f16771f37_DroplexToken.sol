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

contract DroplexToken is SafeMath {
    /* Public variables of the token */
    string public standard = &#39;ERC20&#39;;
    string public name = &#39;Droplex Token&#39;;
    string public symbol = &#39;DROP&#39;;
    uint8 public decimals = 0;
    uint256 public totalSupply = 30000000;
    address public owner = 0xaBE3d12e5518BF8266bB91B56913962ce1F77CF4;
    /* from this time on tokens may be transfered (after ICO)*/

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function DroplexToken() {
        owner = 0xaBE3d12e5518BF8266bB91B56913962ce1F77CF4;
        balanceOf[owner] = 30000000;              // Give the owner all initial tokens
        totalSupply = 30000000;                   // Update total supply
    }

    /* Send some of your tokens to a given address */
    function transfer(address _to, uint256 _value) returns (bool success){
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


    /* A contract or  person attempts to get the tokens of somebody else.
    *  This is only allowed if the token holder approved. */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        var _allowance = allowance[_from][msg.sender];
        balanceOf[_from] = safeSub(balanceOf[_from],_value); // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);     // Add the same to the recipient
        allowance[_from][msg.sender] = safeSub(_allowance,_value);
        Transfer(_from, _to, _value);
        return true;
    }

}