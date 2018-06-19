pragma solidity ^0.4.4;

contract Token {

    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
	
        if (balances[msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
		
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;

        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
	
        if (balances[_from] &gt;= _value &amp;&amp; allowed[_from][msg.sender] &gt;= _value &amp;&amp; _value &gt; 0) {
		
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
			
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
	
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
	
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
		
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
	
      return allowed[_owner][_spender];
	  
    }

    mapping (address =&gt; uint256) balances;
    mapping (address =&gt; mapping (address =&gt; uint256)) allowed;
    uint256 public totalSupply;
}

contract DazzioCoin is StandardToken {

    /* Public variables of the token */

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = &#39;H1.0&#39;; 
    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;
    address public fundsWallet;

    function DazzioCoin() {
	
        balances[msg.sender] = 5000000000000000000000000;        // Total supply goes to the contract creator
        totalSupply = 5000000000000000000000000;                 // Total token supply
        name = &quot;DazzioCoin&quot;;                                     // Token display name
        decimals = 18;
        symbol = &quot;DAZZ&quot;;                                         // Token symbol
        unitsOneEthCanBuy = 1000;                                // Tokens per ETH
        fundsWallet = msg.sender;                                // ETH goes to the contract address
		
    }

    function() payable{
        
		totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] &gt;= amount);
        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;
        Transfer(fundsWallet, msg.sender, amount);
        fundsWallet.transfer(msg.value);
		
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
	
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3(&quot;receiveApproval(address,uint256,address,bytes)&quot;))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}