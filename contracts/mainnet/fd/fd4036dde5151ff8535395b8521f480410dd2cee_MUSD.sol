pragma solidity ^0.4.24;

contract Token{
    // token总量，默认会为public变量生成一个getter函数接口，名称为totalSupply().
    uint256 public totalSupply;

    /// 获取账户_owner拥有token的数量 
    function balanceOf(address _owner) constant public returns (uint256 balance);

    //从消息发送者账户中往_to账户转数量为_value的token
    function transfer(address _to, uint256 _value) public returns (bool success);

    //从账户_from中往账户_to转数量为_value的token，与approve方法配合使用
    function transferFrom(address _from, address _to, uint256 _value) public returns   
    (bool success);

    //消息发送账户设置账户_spender能从发送账户中转出数量为_value的token
    function approve(address _spender, uint256 _value) public returns (bool success);

    //获取账户_spender可以从账户_owner中转出token的数量
    function allowance(address _owner, address _spender) constant public returns 
    (uint256 remaining);

    //发生转账时必须要触发的事件 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //当函数approve(address _spender, uint256 _value)成功执行时必须触发的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 
    _value);
    
    event Burn(address indexed from, uint256 value);  //减去用户余额事件
}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        //require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
        emit Transfer(msg.sender, _to, _value);//触发转币交易事件
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
        emit Transfer(_from, _to, _value);//触发转币交易事件
        return true;
    }
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint256 _value) public returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];//允许_spender从_owner中转出的token数
    }
    
    
    /**
     * 减少代币调用者的余额
     *
     * 操作以后是不可逆的
     *
     * @param _value 要删除的数量
     */
    function burn(uint256 _value) public returns (bool success) {
        //检查帐户余额是否大于要减去的值
        require(balances[msg.sender] >= _value);   // Check if the sender has enough

        //给指定帐户减去余额
        balances[msg.sender] -= _value;

        //代币问题做相应扣除
        totalSupply -= _value;

        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * 删除帐户的余额（含其他帐户）
     *
     * 删除以后是不可逆的
     *
     * @param _from 要操作的帐户地址
     * @param _value 要减去的数量
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {

        //检查帐户余额是否大于要减去的值
        require(balances[_from] >= _value);

        //检查 其他帐户 的余额是否够使用
        require(_value <= allowed[_from][msg.sender]);

        //减掉代币
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        //更新总量
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

// ERC20 standard token
contract MUSD is StandardToken{
    
    address public admin; // 管理员
    string public name = "CHINA MOROCCO MERCANTILE EXCHANGE CLIENT TRUST ACCOUNT"; // 代币名称
    string public symbol = "MUSD"; // 代币符号
    uint8 public decimals = 18; // 代币精度
    uint256 public INITIAL_SUPPLY = 10000000000000000000000000; // 总量80亿 *10^18
    // 同一个账户满足任意冻结条件均被冻结
    mapping (address => bool) public frozenAccount; //无限期冻结的账户
    mapping (address => uint256) public frozenTimestamp; // 有限期冻结的账户

    bool public exchangeFlag = true; // 代币兑换开启
    // 不满足条件或募集完成多出的eth均返回给原账户
    uint256 public minWei = 1;  //最低打 1 wei  1eth = 1*10^18 wei
    uint256 public maxWei = 20000000000000000000000; // 最多一次打 20000 eth
    uint256 public maxRaiseAmount = 20000000000000000000000; // 募集上限 20000 eth
    uint256 public raisedAmount = 0; // 已募集 0 eth
    uint256 public raiseRatio = 200000; // 兑换比例 1eth = 20万token
    // event 通知
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 构造函数
    constructor() public {
        totalSupply = INITIAL_SUPPLY;
        admin = msg.sender;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    // fallback 向合约地址转账 or 调用非合约函数触发
    // 代币自动兑换eth
    function()
    public payable {
        require(msg.value > 0);
        if (exchangeFlag) {
            if (msg.value >= minWei && msg.value <= maxWei){
                if (raisedAmount < maxRaiseAmount) {
                    uint256 valueNeed = msg.value;
                    raisedAmount = raisedAmount + msg.value;
                    if (raisedAmount > maxRaiseAmount) {
                        uint256 valueLeft = raisedAmount - maxRaiseAmount;
                        valueNeed = msg.value - valueLeft;
                        msg.sender.transfer(valueLeft);
                        raisedAmount = maxRaiseAmount;
                    }
                    if (raisedAmount >= maxRaiseAmount) {
                        exchangeFlag = false;
                    }
                    // 已处理过精度 *10^18
                    uint256 _value = valueNeed * raiseRatio;

                    require(_value <= balances[admin]);
                    balances[admin] = balances[admin] - _value;
                    balances[msg.sender] = balances[msg.sender] + _value;

                    emit Transfer(admin, msg.sender, _value);

                }
            } else {
                msg.sender.transfer(msg.value);
            }
        } else {
            msg.sender.transfer(msg.value);
        }
    }

    /**
    * 修改管理员
    */
    function changeAdmin(
        address _newAdmin
    )
    public
    returns (bool)  {
        require(msg.sender == admin);
        require(_newAdmin != address(0));
        balances[_newAdmin] = balances[_newAdmin] + balances[admin];
        balances[admin] = 0;
        admin = _newAdmin;
        return true;
    }
    /**
    * 增发
    */
    function generateToken(
        address _target,
        uint256 _amount
    )
    public
    returns (bool)  {
        require(msg.sender == admin);
        require(_target != address(0));
        balances[_target] = balances[_target] + _amount;
        totalSupply = totalSupply + _amount;
        INITIAL_SUPPLY = totalSupply;
        return true;
    }

    // 从合约提现
    // 只能提给管理员
    function withdraw (
        uint256 _amount
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        msg.sender.transfer(_amount);
        return true;
    }
    /**
    * 锁定账户
    */
    function freeze(
        address _target,
        bool _freeze
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        require(_target != address(0));
        frozenAccount[_target] = _freeze;
        return true;
    }
    /**
    * 通过时间戳锁定账户
    */
    function freezeWithTimestamp(
        address _target,
        uint256 _timestamp
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        require(_target != address(0));
        frozenTimestamp[_target] = _timestamp;
        return true;
    }

    /**
        * 批量锁定账户
        */
    function multiFreeze(
        address[] _targets,
        bool[] _freezes
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        require(_targets.length == _freezes.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i += 1) {
            address _target = _targets[i];
            require(_target != address(0));
            bool _freeze = _freezes[i];
            frozenAccount[_target] = _freeze;
        }
        return true;
    }
    /**
            * 批量通过时间戳锁定账户
            */
    function multiFreezeWithTimestamp(
        address[] _targets,
        uint256[] _timestamps
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        require(_targets.length == _timestamps.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i += 1) {
            address _target = _targets[i];
            require(_target != address(0));
            uint256 _timestamp = _timestamps[i];
            frozenTimestamp[_target] = _timestamp;
        }
        return true;
    }
    /**
    * 批量转账
    */
    function multiTransfer(
        address[] _tos,
        uint256[] _values
    )
    public
    returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_tos.length == _values.length);
        uint256 len = _tos.length;
        require(len > 0);
        uint256 amount = 0;
        for (uint256 i = 0; i < len; i += 1) {
            amount = amount + _values[i];
        }
        require(amount <= balances[msg.sender]);
        for (uint256 j = 0; j < len; j += 1) {
            address _to = _tos[j];
            require(_to != address(0));
            balances[_to] = balances[_to] + _values[j];
            balances[msg.sender] = balances[msg.sender] - _values[j];
            emit Transfer(msg.sender, _to, _values[j]);
        }
        return true;
    }
    /**
    * 从调用者转账至_to
    */
    function transfer(
        address _to,
        uint256 _value
    )
    public
    returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    /*
    * 从调用者作为from代理将from账户中的token转账至to
    * 调用者在from的许可额度中必须>=value
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(!frozenAccount[_from]);
        require(now > frozenTimestamp[msg.sender]);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;

        emit Transfer(_from, _to, _value);
        return true;
    }
    /**
    * 调整转账代理方spender的代理的许可额度
    */
    function approve(
        address _spender,
        uint256 _value
    ) public
    returns (bool) {
        // 转账的时候会校验balances，该处require无意义
        // require(_value <= balances[msg.sender]);

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    /**
    * 增加转账代理方spender的代理的许可额度
    * 意义不大的function
    */
    // function increaseApproval(
    //     address _spender,
    //     uint256 _addedValue
    // )
    // public
    // returns (bool)
    // {
    //     // uint256 value_ = allowed[msg.sender][_spender].add(_addedValue);
    //     // require(value_ <= balances[msg.sender]);
    //     // allowed[msg.sender][_spender] = value_;

    //     // emit Approval(msg.sender, _spender, value_);
    //     return true;
    // }
    /**
    * 减少转账代理方spender的代理的许可额度
    * 意义不大的function
    */
    // function decreaseApproval(
    //     address _spender,
    //     uint256 _subtractedValue
    // )
    // public
    // returns (bool)
    // {
    //     // uint256 oldValue = allowed[msg.sender][_spender];
    //     // if (_subtractedValue > oldValue) {
    //     //    allowed[msg.sender][_spender] = 0;
    //     // } else {
    //     //    uint256 newValue = oldValue.sub(_subtractedValue);
    //     //    require(newValue <= balances[msg.sender]);
    //     //   allowed[msg.sender][_spender] = newValue;
    //     //}

    //     // emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    //     return true;
    // }

    //********************************************************************************
    //查询账户是否存在锁定时间戳
    function getFrozenTimestamp(
        address _target
    )
    public view
    returns (uint256) {
        require(_target != address(0));
        return frozenTimestamp[_target];
    }
    //查询账户是否被锁定
    function getFrozenAccount(
        address _target
    )
    public view
    returns (bool) {
        require(_target != address(0));
        return frozenAccount[_target];
    }
    //查询合约的余额
    function getBalance()
    public view
    returns (uint256) {
        return address(this).balance;
    }
    // 修改name
    function setName (
        string _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        name = _value;
        return true;
    }
    // 修改symbol
    function setSymbol (
        string _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        symbol = _value;
        return true;
    }

    // 修改募集flag
    function setExchangeFlag (
        bool _flag
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        exchangeFlag = _flag;
        return true;

    }
    // 修改单笔募集下限
    function setMinWei (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        minWei = _value;
        return true;

    }
    // 修改单笔募集上限
    function setMaxWei (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        maxWei = _value;
        return true;
    }
    // 修改总募集上限
    function setMaxRaiseAmount (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        maxRaiseAmount = _value;
        return true;
    }

    // 修改已募集数
    function setRaisedAmount (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        raisedAmount = _value;
        return true;
    }

    // 修改募集比例
    function setRaiseRatio (
        uint256 _value
    )
    public
    returns (bool) {
        require(msg.sender == admin);
        raiseRatio = _value;
        return true;
    }

    // 销毁合约
    function kill()
    public {
        require(msg.sender == admin);
        selfdestruct(admin);
    }

}