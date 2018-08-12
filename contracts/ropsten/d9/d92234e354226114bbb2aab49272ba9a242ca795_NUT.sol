pragma solidity ^ 0.4.16;
contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns(uint256 balance);
    function transfer(address _to, uint256 _value) public returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);
    function approve(address _spender, uint256 _value) public returns(bool success);
    function allowance(address _owner, address _spender) public constant returns(uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract NUT is Token {

    string public name; //全称
    uint256 public decimals; //小数长度
    string public symbol; //简称
    uint public startTime; //约部署时间
    address public Short; //短期锁仓
    address public Long; //长期锁仓
    address public Team; //团队
    address public Reward; //奖励
    address public Investment; //募资
    address public Foundation; //基金会
    constructor(string _tokenName, string _tokenSymbol, address tempTeam, address tempReward, address tempInvestment, address tempFoundation) public {
        name = _tokenName;
        decimals = 18;
        symbol = _tokenSymbol;
        totalSupply = 1000000000 * 10 **uint256(decimals); // 设置初始总量
        startTime = now; //记录部署合约时间
        Team = tempTeam;
        Reward = tempReward;
        Investment = tempInvestment;
        Foundation = tempFoundation;

        balances[Team] = totalSupply * 2 / 10; //团队发放
        balances[Reward] = totalSupply * 3 / 10; //奖励发放
        balances[Investment] = totalSupply * 3 / 10; //募资发放
        balances[Foundation] = totalSupply * 2 / 10; //基金会发放
        emit Transfer(0x0, Team, 200000000 * 10 **uint256(decimals));
        emit Transfer(0x0, Reward, 300000000 * 10 **uint256(decimals));
        emit Transfer(0x0, Investment, 300000000 * 10 **uint256(decimals));
        emit Transfer(0x0, Foundation, 200000000 * 10 **uint256(decimals));
    }

    //设置短期锁仓销售账户
    function setShort(address addr) public {
        require(msg.sender == Investment);
        Short = addr;
    }

    //设置长期锁仓销售账户
    function setLong(address addr) public {
        require(msg.sender == Investment);
        Long = addr;
    }

    function transfer(address _to, uint256 _value) public returns(bool success) {
        if (msg.sender == Team) {
            uint timeTemp = (now - startTime) / 60 / 60 / 24 / 100; //100天
            if (timeTemp > 10) {
                timeTemp = 10;
            }
            require(balances[msg.sender] - _value >= (totalSupply / 5 - totalSupply * timeTemp / 50));
            record(_to, _value); //记录团队组员账户的收币时间与额度数组
        }

        if (msg.sender == Short) {
            require(balances[msg.sender] >= _value);
            record(_to, _value); //记录短期账户的收币时间与额度数组
        }

        if (msg.sender == Long) {
            require(balances[msg.sender] >= _value);
            longRecord(_to, _value); //记录长期账户的收币时间与额度数组
        }

        if (number[msg.sender] != 0) { //判断发起交易的账户类型（团队成员/短期锁仓）
            judge(_value, msg.sender); //判断发起的交易是否满足时间额度限制
        }

        if (longNumber[msg.sender] != 0) { //判断发起交易的账户类型（长期锁仓）
            longJudge(_value, msg.sender); //判断发起的交易是否满足时间额度限制
        }
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        balances[msg.sender] -= _value; //从消息发送者账户中减去token数量_value
        balances[_to] += _value; //往接收账户增加token数量_value
        emit Transfer(msg.sender, _to, _value); //触发转币交易事件
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value; //接收账户增加token数量_value
        balances[_from] -= _value; //支出账户_from减去token数量_value
        allowed[_from][msg.sender] -= _value; //消息发送者可以从账户_from中转出的数量减少_value
        emit Transfer(_from, _to, _value); //触发转币交易事件
        return true;
    }

    //短期锁仓和团队成员记录
    function record(address iniadr, uint256 account) private {
        uint256[] storage T = time[iniadr]; //记录账户的收款时间的数组集.
        T.push(now);
        time[iniadr] = T;
        uint256[] storage A = init[iniadr]; //记录账户的额度数组集.
        A.push(account);
        init[iniadr] = A;
        number[iniadr] = 1; //ֻ只用来作为判断条件时用。
    }

    //长期锁仓记录
    function longRecord(address iniadr, uint256 account) private {
        uint256[] storage T = longTime[iniadr]; //记录账户的收款时间的数组集.
        T.push(now);
        longTime[iniadr] = T;
        uint256[] storage A = longInit[iniadr]; //记录账户的额度数组集.
        A.push(account);
        longInit[iniadr] = A;
        longNumber[iniadr] = 1; //ֻ只用来作为判断条件时用。
    }
    //判断交易是否合法
    function judge(uint256 _value, address addr) private {
        uint256[] storage T = time[addr];
        uint256[] storage A = init[addr];
        number[addr] = 0; //每次交易前都要重新计算它，所以要先将上一次的重置
        for (uint i = 0; i < T.length; i++) {
            if (now < (T[i] + 100 days)) { //如果发币时间距离当前交易时间小于100天，则往冻结额度里添加对应发币时间的额度。
                number[addr] += A[i];
            }
        }
        require(balances[addr] - _value >= number[addr]); //账户余额必须大于冻结余额
    }
    //判断交易是否合法
    function longJudge(uint256 _value, address addr) private { //长期锁仓代币权限
        uint256[] storage T = longTime[addr];
        uint256[] storage A = longInit[addr];
        longNumber[addr] = 0; //每次交易前都要重新计算它，所以要先将上一次的重置
        for (uint i = 0; i < T.length; i++) {
            if (now < (T[i] + 1000 days)) { //如果发币时间距离当前交易时间小于100天，则往冻结额度里添加对应发币时间的额度。
                longNumber[addr] += A[i];
            }
        }
        require(balances[addr] - _value >= longNumber[addr]); //账户余额必须大于冻结余额
    }

    function balanceOf(address _owner) public constant returns(uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns(bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns(uint256 remaining) {
        return allowed[_owner][_spender]; //允许_spender从_owner中转出的token数
    }

    function benchTransfer(address[] addr, uint256[] num) public {
        require(addr.length == num.length);
        for (uint i = 0; i < num.length; i++) {

            transfer(addr[i], num[i] * 10 **uint256(decimals));
        }
    }

    mapping(address =>uint256) balances;
    mapping(address =>mapping(address =>uint256)) allowed;

    mapping(address =>uint256[]) time; //账户收款时间
    mapping(address =>uint256[]) init; //账户转入额度
    mapping(address =>uint256) number; //冻结额度
    mapping(address =>uint256[]) longTime; //账户收款时间
    mapping(address =>uint256[]) longInit; //账户转入额度
    mapping(address =>uint256) longNumber; //长期锁仓冻结额度
}