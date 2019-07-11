/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.5.1;

contract Token{
    /// token总量，默认会为public变量生成一个getter函数接口，名称为totalSupply()
    uint256 public totalSupply;
    
    /// 获取账户_owner拥有token的数量
    function balanceOf(address _owner) public view returns (uint256 balance);
    
    //从消息发送者账户中往_to账户转数量为_value的token
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
    //从账户_from中往账户_to转数量为_value的token，与approve方法配合使用
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    //消息发送账户设置账户_spender能从发送账户中转出数量为_value的token
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    //获取账户_spender可以从账户_owner中转出token的数量
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
     //发生转账时必须要触发的事件 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    //当函数approve(address _spender, uint256 _value)成功执行时必须触发的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    //查询余额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        //require(balances[msg.sender] >= _value && balances[_to] + _value >balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
        emit Transfer(msg.sender, _to, _value);//触发转币交易事件
        return true;
    }
    //授权账户_spender可以从消息发送者账户转出数量为_value的token
    function approve(address _spender, uint256 _value) public returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//接收账户增加token数量_value
        balances[_from] -= _value; //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;//消息发送者可以从账户_from中转出的数量减少_value
        emit Transfer(_from, _to, _value);//触发转币交易事件
        return true;
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract TestToken is StandardToken { 

    string public name;                   
    uint8 public decimals;               
    string public symbol;             

    function BitCloud() public {
        balances[msg.sender] = 1000000000000000000; 
        totalSupply = 1000000000000000000;         
        name = "BitCloud Token";                  
        decimals = 8;          
        symbol = "BPRO";            
    }
}