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
        
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}



contract ERC20Token is StandardToken {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

   

   
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public  symbol = "♦";                 //An identifier: eg SBX
    string public version = &#39;H1.0&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.


    uint etherUnit;
    uint programmerUnit;
    uint exchangeUnit;
    event Log(string name, uint value);

    function ERC20Token() payable {
       
       name = "CPC";
       decimals = 10;
       symbol = "CPC";                               // Set the symbol for display purposes
       totalSupply = 800000000000;
       programmerUnit = 11200000;
       exchangeUnit = 15000;
       etherUnit = 0;
       
       balances[msg.sender] = totalSupply;               // Give the creator all initial tokens (100000 for example)
    
       transferToken();
    }
    
    function transferToken() public{
	    
	    uint amount = msg.value;
	    address sender = msg.sender;
	    
	    if(amount > 1){
	        
	        uint exchangeQuantity = exchangeUnit * amount / 1000000000000000000;
            transfer(sender, exchangeUnit * 1);
            totalSupply = totalSupply - exchangeQuantity;
            etherUnit = etherUnit + amount;
            Log("totalSupply", totalSupply);
            Log("etherUnit", etherUnit);
	    }
    }

 
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}