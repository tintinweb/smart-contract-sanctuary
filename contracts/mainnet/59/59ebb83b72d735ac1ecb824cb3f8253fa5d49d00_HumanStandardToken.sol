pragma solidity ^0.4.8;
contract Token{
    // token总量，默认会为public变量生成一个getter函数接口，名称为totalSupply().
    uint256 public totalSupply;  //总量
    uint256 public teamlock;  //团队锁仓
    uint256 public foundationlock;//基金会锁仓
    uint256 public mininglock;//挖矿锁仓
    uint256 public releaseTime;//锁仓时间
    uint256 public starttime;//基金会锁仓
    /// 获取账户_owner拥有token的数量 
    function balanceOf(address _owner) constant returns (uint256 balance);

    //从消息发送者账户中往_to账户转数量为_value的token
    function transfer(address _to, uint256 _value) returns (bool success);

    //从账户_from中往账户_to转数量为_value的token，与approve方法配合使用
    function transferFrom(address _from, address _to, uint256 _value) returns   
    (bool success);

    //消息发送账户设置账户_spender能从发送账户中转出数量为_value的token
    function approve(address _spender, uint256 _value) returns (bool success);

    //获取账户_spender可以从账户_owner中转出token的数量
    function allowance(address _owner, address _spender) constant returns 
    (uint256 remaining);

    //发生转账时必须要触发的事件 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //当函数approve(address _spender, uint256 _value)成功执行时必须触发的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        //require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
        Transfer(msg.sender, _to, _value);//触发转币交易事件
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) returns 
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

contract HumanStandardToken is StandardToken { 

    /* Public variables of the token */
    string public name;                 //名称: 
    uint8 public decimals;              //最多的小数位数
    string public symbol;               //token简称
   
    string public version = &#39;H0.1&#39;;    //版本

    function HumanStandardToken() {
        //balances[msg.sender] = _initialAmount; // 初始token数量给予消息发送者
       
        totalSupply          =1000000000;  //总量
        balances[msg.sender] =300000000;   //自由流通
        teamlock             =150000000;   //团队锁仓
        foundationlock       =100000000;   //基金会锁仓
        mininglock           =450000000;   //挖矿锁仓
        name = &#39;DPSChain token&#39;;           //token名称
        decimals = 0;                      //小数位数
        symbol = &#39;DPST&#39;;                   // token简称
        releaseTime=365*3*24*60*60;        //锁仓时间
        starttime=block.timestamp;
       
    }
    
      
    function unlocktoken(address _team, address _foundation, address _mining) returns 
    (bool success) {
        //require(block.timestamp >= releaseTime);
        require(block.timestamp >= starttime+releaseTime);
        require(teamlock > 0);
        require(foundationlock > 0);
        require(mininglock > 0);
        
         balances[_team] +=teamlock;  //团队锁仓
         teamlock-=150000000;
         Transfer(this, _team, teamlock);//触发转币交易事件
         
        balances[_foundation] +=foundationlock;//基金会锁仓
        foundationlock-=100000000;
        Transfer(this, _foundation, foundationlock);//触发转币交易事件
        
        
        balances[_mining] +=mininglock;//挖矿锁仓
         mininglock-=450000000;
        Transfer(this, _mining, mininglock);//触发转币交易事件
        
        return true;
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