pragma solidity ^0.4.4;

contract TPP2018TOKEN  {
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
	function transfer(address _to, uint256 _value)public returns (bool success) {
        if (balances[msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function  transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {
        if (balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    mapping (address =&gt; uint256) balances;
    mapping (address =&gt; mapping (address =&gt; uint256)) allowed;
    uint256 public totalSupply;

    function () {
        
        throw;
    }

    string public name;                  
    uint8 public decimals;               
    string public symbol;                
    string public version = &#39;H1.0&#39;;       

    function TPP2018TOKEN () public{
        balances[msg.sender] = 8600000000;               // Give the creator all initial tokens 
        totalSupply = 8600000000;  
        name = &quot;TPP TOKEN&quot;;      
        decimals = 2;           
        symbol = &quot;TPPT&quot;; 
    }
}