pragma solidity ^0.4.20;

interface ERC20 {
    
    function totalsupply() constant returns(uint totalsupply);
    function balanceof(address owner) constant returns (uint balance);
    function transfer(address to, uint value) returns (bool success);
    function transferfrom(address from , address to , uint value) returns(bool success);
    function approve(address spender , uint value) returns(bool success);
    function allowance(address owner, address spender) constant returns(uint remaining);
}

contract Myfirsttoken {
    
    event Transfer(address indexed from , address indexed to , uint value);
    event Approval(address indexed owner , address indexed spender , uint value);
    
    uint public totalsupply;
    
    //maps addresses to balances
    mapping(address => uint) public _balanceof;
    
    //specifies how much of our token an address can withdraw from another address
    mapping(address => mapping(address => uint)) allowed;
    
    function totalsupply() constant returns(uint){
        return totalsupply;
    }
    
    function balanceof(address owner) constant returns(uint){
        return _balanceof[owner];
    }
    
    function transfer(address to , uint value) constant returns(bool){
        if(value >=0 && value <= _balanceof[msg.sender]){
            _balanceof[msg.sender] -= value;
            _balanceof[to] += value;
            Transfer(msg.sender , to , value);
            return true;
        }
        
        return false;
    }
    
    function transferfrom(address from , address to , uint value) returns(bool){
        if(_balanceof[from] >= value && value >= 0 && allowed[from][msg.sender] >= value){
            _balanceof[from] -= value;
            _balanceof[to] += value;
            Transfer(from , to , value);
            return true;
        }
        
        return false;
    }
    
    function approve(address spender , uint value) returns(bool){
        
        allowed[msg.sender][spender] = value;
        Approval(msg.sender , spender , value);
        return true;
    }
    
    function allowance(address owner , address spender) constant returns(uint){
        return allowed[owner][spender];
    }
}

contract MFTcreator is Myfirsttoken {
    
    function() {
        //if ether is sent to this address send it back
        throw;
    }
    
    //as BTC is for bitcoin and ETH is for ether MFT is for Myfirsttoken
    string public symbol;
    string public name;
    
    // something like wei to ether
    uint public decimals;
    
    function MFTcreator(){
        name = &quot;MyFirstToken&quot;;
        symbol = &quot;MFT&quot;;
        decimals = 10;
        totalsupply = 1000;
        _balanceof[msg.sender] = 1000; //creator gets all initial tokens
    }
    
    function approveansCall(address _spender, uint _value, bytes _extraData) returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3(&quot;receiveApproval(address,uint256,address,bytes)&quot;))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}