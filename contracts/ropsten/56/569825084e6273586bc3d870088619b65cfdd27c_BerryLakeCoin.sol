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

contract BerryLake is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb] >= _value && _value > 0) {
            balances[0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb] -= _value;
            balances[_to] += _value;
            Transfer(0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb][_spender] = _value;
        Approval(0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract BerryLakeCoin is BerryLake { 

    string public name;                  
    uint8 public decimals;                
    string public symbol;                 
    string public version = &#39;H1.0&#39;; 
    uint256 public unitsOneEthCanBuy;     
    uint256 public totalEthInWei;           
    address public fundsWallet;           

    function BerryLakeCoin() {
        balances[0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb] = 65536000000000000000000;               
        totalSupply = 65536000000000000000000;                       
        name = "Weirdo Test Coin";                                   
        decimals = 18;                                               
        symbol = "WTC";                                             
        unitsOneEthCanBuy = 100;                                      
        fundsWallet = 0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb;                                   
    }

    function() payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb] = balances[0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb] + amount;

        Transfer(fundsWallet, 0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb, amount); 

        fundsWallet.transfer(msg.value);                               
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb][_spender] = _value;
        Approval(0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), 0xf6D619EeF600a7C4cD2356934457cBf8009fD6eb, _value, this, _extraData)) { throw; }
        return true;
    }
}