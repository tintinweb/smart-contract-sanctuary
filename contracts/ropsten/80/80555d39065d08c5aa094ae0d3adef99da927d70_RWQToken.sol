pragma solidity ^0.4.25;
contract Token{
    // token总量，默认会为public变量生成一个getter函数接口，名称为totalSupply().
    uint256 public totalSupply;

    // 获取账户_owner拥有token的数量 
    function balanceOf(address _owner) public  returns (uint256 balance);

    //从消息发送者账户中往_to账户转数量为_value的token
    function transfer(address _to, uint256 _value)  public  returns (bool success);

    //从账户_from中往账户_to转数量为_value的token，与approve方法配合使用
    function transferFrom(address _from, address _to, uint256 _value)  public  returns   
    (bool success);

    //消息发送账户设置账户_spender能从发送账户中转出数量为_value的token
    function approve(address _spender, uint256 _value)  public  returns (bool success);

    //获取账户_spender可以从账户_owner中转出token的数量
    function allowance(address _owner, address _spender) public  returns 
    (uint256 remaining);

    //发生转账时必须要触发的事件 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //当函数approve(address _spender, uint256 _value)成功执行时必须触发的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        //require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
        Transfer(msg.sender, _to, _value);//触发转币交易事件
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool success) {
        //require(balances[_from] >= _value && allowed[_from][msg.sender] >= 
        // _value && balances[_to] + _value > balances[_to]);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;//接收账户增加token数量_value
        balances[_from] -= _value; //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value;//消息发送者可以从账户_from中转出的数量减少_value
        Transfer(_from, _to, _value);//触发转币交易事件
        return true;
    }
    function balanceOf(address _owner) public  returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public  returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public  returns (uint256 remaining) {
        return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract RWQToken is StandardToken { 
    string public name = "RWQToken";       //名称
    uint8 public decimals = 18;            //最多的小数位数
    string public symbol = "RWQ";          //token简称
    string public version = &#39;0.1&#39;;         //版本

    function RWQToken(uint256 _initialAmount)  {
        balances[msg.sender] = _initialAmount*10**uint256(decimals); // 初始token数量给予消息发送者
        totalSupply = _initialAmount;         // 设置初始总量
    }
  

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
    
		//结构体-锁定数据
        struct lockParam
        {
            uint startTime; //开始时间
            uint amount;  //锁定数量
            uint lockTime;   //单位秒
        }
     mapping(address => lockParam) public lockParams;
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        //check lock  --rongwq
        lockParam param = lockParams[msg.sender];
        if (now-param.startTime<param.lockTime){//锁定中，未过期，校验锁定数量是否足够
			uint remainderVal = balances[msg.sender] -  _value;
			require(remainderVal>=param.amount,&#39;交易失败，账户可交易数量不足&#39;);
        }    
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
        Transfer(msg.sender, _to, _value);//触发转币交易事件
        return true;
    }
    

    function lock(address belocked,uint amount,uint locktime) public returns(bool success){
        require(locktime > 0 && amount > 0);
        lockParams[belocked].startTime = now;
        lockParams[belocked].lockTime = locktime;
        lockParams[belocked].amount = amount*10**uint256(decimals);
        return true;
    }
	
}