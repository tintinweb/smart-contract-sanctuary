pragma solidity ^0.4.23;

// ALE
// Asset Link Entertainment


contract Token{

    uint256 public totalSupply;


    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns   
    (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns 
    (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) returns 
    (bool success) {
      
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//接收账户增加token数量_value
        balances[_from] -= _value; //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;//消息发送者可以从账户_from中转出的数量减少_value
        Transfer(_from, _to, _value);//触发转币交易事件
        return true;
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract aletoken is StandardToken { 

    /* Public variables of the token */
    string public name;                   
    uint8 public decimals;               
    string public symbol;               //token
    string public version = &#39;v1.0&#39;;    

    function aletoken(string _tokenSymbol) {
        balances[msg.sender] = 4000000000000000000000000000; // 初始token数量给予消息发送者
        totalSupply = 4000000000000000000000000000;         // 设置初始总量
        name = "Asset Link Entertainment";        
        decimals = 18;
        symbol = _tokenSymbol;  
    }

    /* Approves and then calls the receiving contract */
    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }

}