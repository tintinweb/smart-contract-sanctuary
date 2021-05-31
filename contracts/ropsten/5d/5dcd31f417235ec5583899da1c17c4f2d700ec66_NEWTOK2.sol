/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

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
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
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

contract NEWTOK2 is StandardToken { 
    string public name;    
    uint8 public decimals; 
    string public symbol;               
    string public version = "H1.0"; 
    uint256 public unitsOneEthCanBuy;   
    uint256 public totalEthInWei;    
    address public fundsWallet;      

    function NEWTOK2() {
        balances[msg.sender] = 10000000000*100000000000000000; 
        totalSupply = 10000000000*100000000000000000;
        name = "New Token2";                              
        decimals = 17;                                    
        symbol = "NEWTOK2";                                
        unitsOneEthCanBuy = 2667;                        
        fundsWallet = msg.sender;                        
    }
    
    function changePrice(uint p) returns (uint) {
        address trusted = fundsWallet;   //trust only the creator
        if (msg.sender != trusted ) 
            throw;

        unitsOneEthCanBuy = p;

        return unitsOneEthCanBuy;
    }

   function increaseSupply(uint supp) returns (uint) {
        address trusted = fundsWallet;   //trust only the creator 
        if (msg.sender != trusted ) 
            throw;
        
        totalSupply = totalSupply+supp*100000000000000000;
        balances[fundsWallet] = balances[fundsWallet] + supp*100000000000000000;
        return totalSupply;
    }

    function() payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if (balances[fundsWallet] < amount) {
            return;
        }

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain

        fundsWallet.transfer(msg.value);                               
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

    
    // send different token amounts to multiple addresses 
     function multisendToken(address[] _to, uint256[] _value,uint256 totalAmount) returns (bool success) {
        require(_to.length == _value.length);
        require(_to.length <= 100);  //can send to maximum hundred addresses
        
        if (balances[msg.sender] >= totalAmount && totalAmount > 0) {
            for (uint8 i = 0; i < _to.length; i++) {
                balances[msg.sender] -= _value[i];
                balances[_to[i]] += _value[i];
                Transfer(msg.sender, _to[i], _value[i]);
            }
            return true;
        } else { return false; }
    }
}