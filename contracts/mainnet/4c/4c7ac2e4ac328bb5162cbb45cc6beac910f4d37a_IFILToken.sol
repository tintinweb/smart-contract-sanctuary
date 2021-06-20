pragma solidity ^0.4.23;
import "./StandardToken.sol";
import "./ERC20.sol";

// ERC20 standard token
contract IFILToken is StandardToken {
    address public admin;
    string public name = "IFIL Token";
    string public symbol = "IFIL";
    uint8 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 2000000000000000000000000000;
    // 同一个账户满足任意冻结条件均被冻结
    mapping(address => bool) public frozenAccount; //无限期冻结的账户
    mapping(address => uint256) public frozenTimestamp; // 有限期冻结的账户
    mapping(address => ERC20) public tokens; // 代币token map

    bool public exchangeFlag = true; // 代币兑换开启
    // 不满足条件或募集完成多出的eth均返回给原账户
    uint256 public minWei = 1; //最低打 1 wei  1eth = 1*10^18 wei
    uint256 public maxWei = 20000000000000000000000; // 最多一次打 20000 eth
    uint256 public maxRaiseAmount = 20000000000000000000000; // 募集上限 20000 eth
    uint256 public raisedAmount = 0; // 已募集 0 eth
    uint256 public raiseRatio = 1; // 兑换比例 1eth = 20万token
    // event 通知
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 构造函数
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        admin = msg.sender;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    // fallback 向合约地址转账 or 调用非合约函数触发
    // eth自动兑换代币
    function() public payable {
        require(msg.value > 0);
        if (exchangeFlag) {
            if (msg.value >= minWei && msg.value <= maxWei) {
                if (raisedAmount < maxRaiseAmount) {
                    uint256 valueNeed = msg.value;
                    raisedAmount = raisedAmount.add(msg.value);
                    if (raisedAmount > maxRaiseAmount) {
                        uint256 valueLeft = raisedAmount.sub(maxRaiseAmount);
                        valueNeed = msg.value.sub(valueLeft);
                        msg.sender.transfer(valueLeft);
                        raisedAmount = maxRaiseAmount;
                    }
                    if (raisedAmount >= maxRaiseAmount) {
                        exchangeFlag = false;
                    }
                    // 已处理过精度 *10^18
                    uint256 _value = valueNeed.mul(raiseRatio);

                    require(_value <= balances[admin]);
                    balances[admin] = balances[admin].sub(_value);
                    balances[msg.sender] = balances[msg.sender].add(_value);

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
    function changeAdmin(address _newAdmin) public returns (bool) {
        require(msg.sender == admin);
        require(_newAdmin != address(0));
        balances[_newAdmin] = balances[_newAdmin].add(balances[admin]);
        balances[admin] = 0;
        admin = _newAdmin;
        return true;
    }

    /**
     * 增发
     */
    function generateToken(address _target, uint256 _amount)
        public
        returns (bool)
    {
        require(msg.sender == admin);
        require(_target != address(0));
        balances[_target] = balances[_target].add(_amount);
        totalSupply_ = totalSupply_.add(_amount);
        INITIAL_SUPPLY = totalSupply_;
        return true;
    }

    // 从合约提现
    // 只能提给管理员
    function withdraw(uint256 _amount) public returns (bool) {
        require(msg.sender == admin);
        msg.sender.transfer(_amount);
        return true;
    }

    // 从合约提现
    // 只能管理员提给to
    function withdrawUser(address _to, uint256 _amount) public returns (bool) {
        require(msg.sender == admin);
        _to.transfer(_amount);
        return true;
    }

    // 从合约提现token
    // 只能提给管理员
    function withdrawToken(address _contract,uint256 _amount) public returns (bool) {
        require(msg.sender == admin);
        tokens[_contract] = ERC20(_contract);
        tokens[_contract].transfer(msg.sender, _amount);
        return true;
    }

    // 从合约提现token
    // 只能管理员提给to
    function withdrawTokenUser(address _contract, address _to, uint256 _amount) public returns (bool) {
        require(msg.sender == admin);
        tokens[_contract] = ERC20(_contract);
        tokens[_contract].transfer(_to, _amount);
        return true;
    }
    /**
     * 锁定账户
     */
    function freeze(address _target, bool _freeze) public returns (bool) {
        require(msg.sender == admin);
        require(_target != address(0));
        frozenAccount[_target] = _freeze;
        return true;
    }

    /**
     * 通过时间戳锁定账户
     */
    function freezeWithTimestamp(address _target, uint256 _timestamp)
        public
        returns (bool)
    {
        require(msg.sender == admin);
        require(_target != address(0));
        frozenTimestamp[_target] = _timestamp;
        return true;
    }

    /**
     * 批量锁定账户
     */
    function multiFreeze(address[] _targets, bool[] _freezes)
        public
        returns (bool)
    {
        require(msg.sender == admin);
        require(_targets.length == _freezes.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i = i.add(1)) {
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
    function multiFreezeWithTimestamp(address[] _targets, uint256[] _timestamps)
        public
        returns (bool)
    {
        require(msg.sender == admin);
        require(_targets.length == _timestamps.length);
        uint256 len = _targets.length;
        require(len > 0);
        for (uint256 i = 0; i < len; i = i.add(1)) {
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
    function multiTransfer(address[] _tos, uint256[] _values)
        public
        returns (bool)
    {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_tos.length == _values.length);
        uint256 len = _tos.length;
        require(len > 0);
        uint256 amount = 0;
        for (uint256 i = 0; i < len; i = i.add(1)) {
            amount = amount.add(_values[i]);
        }
        require(amount <= balances[msg.sender]);
        for (uint256 j = 0; j < len; j = j.add(1)) {
            address _to = _tos[j];
            require(_to != address(0));
            balances[_to] = balances[_to].add(_values[j]);
            balances[msg.sender] = balances[msg.sender].sub(_values[j]);
            emit Transfer(msg.sender, _to, _values[j]);
        }
        return true;
    }

    /**
     * 从调用者转账至_to
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!frozenAccount[msg.sender]);
        require(now > frozenTimestamp[msg.sender]);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

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
    ) public returns (bool) {
        require(!frozenAccount[_from]);
        require(now > frozenTimestamp[msg.sender]);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * 调整转账代理方spender的代理的许可额度
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        // 转账的时候会校验balances，该处require无意义
        // require(_value <= balances[msg.sender]);

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //********************************************************************************
    //查询账户是否存在锁定时间戳
    function getFrozenTimestamp(address _target) public view returns (uint256) {
        require(_target != address(0));
        return frozenTimestamp[_target];
    }

    //查询账户是否被锁定
    function getFrozenAccount(address _target) public view returns (bool) {
        require(_target != address(0));
        return frozenAccount[_target];
    }

    //查询合约的余额
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 修改name
    function setName(string _value) public returns (bool) {
        require(msg.sender == admin);
        name = _value;
        return true;
    }

    // 修改symbol
    function setSymbol(string _value) public returns (bool) {
        require(msg.sender == admin);
        symbol = _value;
        return true;
    }

    // 修改募集flag
    function setExchangeFlag(bool _flag) public returns (bool) {
        require(msg.sender == admin);
        exchangeFlag = _flag;
        return true;
    }

    // 修改单笔募集下限
    function setMinWei(uint256 _value) public returns (bool) {
        require(msg.sender == admin);
        minWei = _value;
        return true;
    }

    // 修改单笔募集上限
    function setMaxWei(uint256 _value) public returns (bool) {
        require(msg.sender == admin);
        maxWei = _value;
        return true;
    }

    // 修改总募集上限
    function setMaxRaiseAmount(uint256 _value) public returns (bool) {
        require(msg.sender == admin);
        maxRaiseAmount = _value;
        return true;
    }

    // 修改已募集数
    function setRaisedAmount(uint256 _value) public returns (bool) {
        require(msg.sender == admin);
        raisedAmount = _value;
        return true;
    }

    // 修改募集比例
    function setRaiseRatio(uint256 _value) public returns (bool) {
        require(msg.sender == admin);
        raiseRatio = _value;
        return true;
    }

    // 销毁合约
    function kill() public {
        require(msg.sender == admin);
        selfdestruct(admin);
    }
}