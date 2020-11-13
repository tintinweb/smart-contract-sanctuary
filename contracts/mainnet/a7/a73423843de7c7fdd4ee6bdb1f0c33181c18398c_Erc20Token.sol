/**
 *Submitted for verification at Etherscan.io on 2019-06-04
*/

pragma solidity ^ 0.4.21;

contract Token{
    // token总量，默认会为public变量生成一个getter函数接口，名称为totalSupply().
    uint256 public totalSupply;

    /// 获取账户_owner拥有token的数量 
    function balanceOf(address _owner) public constant returns (uint256 balance);

    //从消息发送者账户中往_to账户转数量为_value的token
    function transfer(address _to, uint256 _value) public returns(bool success);

    //从账户_from中往账户_to转数量为_value的token，与approve方法配合使用
    function transferFrom(address _from, address _to, uint256 _value) public returns
        (bool success);

    //消息发送账户设置账户_spender能从发送账户中转出数量为_value的token
    function approve(address _spender, uint256 _value) public returns(bool success);

    //获取账户_spender可以从账户_owner中转出token的数量
    function allowance(address _owner, address _spender) public constant returns 
        (uint256 remaining);

    //发生转账时必须要触发的事件 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //当函数approve(address _spender, uint256 _value)成功执行时必须触发的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract SafeMath {
    uint256 constant public MAX_UINT256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) revert();
        return x * y;
    }
}

contract StandardToken is Token, SafeMath {
    function transfer(address _to, uint256 _value) public returns(bool success) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);//从消息发送者账户中减去token数量_value
        balances[_to] = safeAdd(balances[_to], _value);//往接收账户增加token数量_value
        emit Transfer(msg.sender, _to, _value);//触发转币交易事件
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns
        (bool success) {
       
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] = safeAdd(balances[_to], _value);//接收账户增加token数量_value
        balances[_from] = safeSub(balances[_from], _value); //支出账户_from减去token数量_value
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);//消息发送者可以从账户_from中转出的数量减少_value
        emit Transfer(_from, _to, _value);//触发转币交易事件
        return true;
    }
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public returns(bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
    }
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
}

contract Erc20Token is StandardToken { 

    /* Public variables of the token */
    string public name;                   //名称
    uint8 public decimals;               //最多的小数位数
    string public symbol;               //token
    string public version = '1.0.0';    //版本

    function Erc20Token(string _tokenName, string _tokenSymbol, uint256 _initialAmount, uint8 _decimalUnits) public {
        balances[msg.sender] = _initialAmount; // 初始token数量给予消息发送者
        totalSupply = _initialAmount;         // 设置初始总量
        name = _tokenName;                   // token名称
        symbol = _tokenSymbol;             // token简称
        decimals = _decimalUnits;           // 小数位数
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        require(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
    
    /* transfer from one address to muilt address */
    function transferFromArray(address _from, address[] _to, uint256[] _value) public returns(bool success) {
        for(uint256 i = 0; i < _to.length; i++){
            transferFrom(_from, _to[i], _value[i]);
        }
        return true;
    }
    
    /* transfer from muilt address to one address */
    function transferFromArrayToOne(address[] _from, address _to, uint256[] _value) public returns(bool success) {
        for(uint256 i = 0; i < _from.length; i++){
            transferFrom(_from[i], _to, _value[i]);
        }
        return true;
    }


}