/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

pragma solidity ^0.4.16;


contract Token{
    
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns   (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
自定义的GAVC代币
 */
contract GavinToken is Token {

    /**
    代币名称，例如"Gavin token"
     */
    string public name;  
    /**
    返回token使用的小数点后几位。比如如果设置为3，就是支持0.001表示.
    */                 
    uint8 public decimals; 
    /**
    token简称, GAVC
    */              
    string public symbol;               

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    /**
    构造方法
     */
    function GavinToken(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {
        // 设置初始总量
        totalSupply = _initialAmount * 10 ** uint256(_decimalUnits); 
        /**
        初始token数量给予消息发送者，因为是构造函数，所以这里也是合约的创建者        
        */
        balances[msg.sender] = totalSupply; 
        name = _tokenName;                   
        decimals = _decimalUnits;          
        symbol = _tokenSymbol;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        //从消息发送者账户中减去token数量_value
        balances[msg.sender] -= _value;
        //往接收账户增加token数量_value
        balances[_to] += _value;
        //触发转币交易事件
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        //接收账户增加token数量_value
        balances[_to] += _value;
        //支出账户_from减去token数量_value
        balances[_from] -= _value; 
        //消息发送者可以从账户_from中转出的数量减少_value
        allowed[_from][msg.sender] -= _value;
        //触发转币交易事件
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) { 
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        //允许_spender从_owner中转出的token数
        return allowed[_owner][_spender];
    }

    
}