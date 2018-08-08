pragma solidity ^0.4.12;


contract IMigrationContract {
    function migrate(address addr, uint256 nas) public returns (bool success) ;
}

/* 创建一个父类， 账户管理员 */
contract owned {

    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    /* modifier是修改标志 */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /* 修改管理员账户， onlyOwner代表只能是用户管理员来修改 */
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


/* 灵感来自于NAS  coin*/
contract SafeMath {


    function safeAdd(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }

    function safeDiv(uint256 x, uint256 y) internal returns (uint256) {
        assert(y != 0);
        uint256 z = x / y;
        return z;
    }
}


contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {

    // 销毁金额通知事件
    event Burn(address indexed from, uint256 value);

    /* 冻结账户 */
    mapping(address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);


    function transfer(address _to, uint256 _value) public returns (bool success) {
        // 防止转移到0x0， 用burn代替这个功能
        require(_to != 0x0);
        // 检测发送者是否有足够的资金
        require(balances[msg.sender] >= _value);
        require(_value >= 0);
        // 检查是否溢出（数据类型的溢出）
        require(balances[_to] + _value > balances[_to]);

        require(!frozenAccount[msg.sender]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen

        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // 防止转移到0x0， 用burn代替这个功能
        require(_to != 0x0);
        // 检测发送者是否有足够的资金
        require(balances[_from] >= _value);
        require(_value >= 0);
        // 检查是否溢出（数据类型的溢出）
        require(balances[_to] + _value > balances[_to]);
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);

        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
    * 销毁代币
    */
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
    * 从其他账户销毁代币
    */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowed[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowed[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
}


contract RunningCoinToken is StandardToken, SafeMath, owned {

    // metadata
    string  public constant name = "RunningCoin";
    string  public constant symbol = "RNC";
    uint256 public constant decimals = 18;
    string  public version = "1.0";

    // contracts
    address public ethFundDeposit;          // ETH存放地址
    address public newContractAddr;         // token更新地址

    // crowdsale parameters
    bool    public isFunding;                // 状态切换到true
    uint256 public fundingStartBlock;
    uint256 public fundingStopBlock;

    uint256 public currentSupply;           // 正在售卖中的tokens数量
    uint256 public tokenRaised = 0;         // 总的售卖数量token
    uint256 public tokenMigrated = 0;     // 总的已经交易的 token
    uint256 public tokenExchangeRate = 5000;             // 500 RunningCoin 兑换 1 ETH

    // events
    event AllocateToken(address indexed _to, uint256 _value);   // 分配的私有交易token;
    event IssueToken(address indexed _to, uint256 _value);      // 公开发行售卖的token;
    event IncreaseSupply(uint256 _value);
    event DecreaseSupply(uint256 _value);
    event Migrate(address indexed _to, uint256 _value);

    // constructor
    constructor (
        address _ethFundDeposit,
        uint256 _currentSupply) public
    {
        ethFundDeposit = _ethFundDeposit;

        isFunding = false;
        //通过控制预CrowdS ale状态
        fundingStartBlock = 0;
        fundingStopBlock = 0;

        currentSupply = formatDecimals(_currentSupply);
        totalSupply = formatDecimals(1000000000);
        balances[msg.sender] = totalSupply;
        if (currentSupply > totalSupply) revert();
    }

    // 转换
    function formatDecimals(uint256 _value) internal returns (uint256) {
        return _value * 10 ** decimals;
    }

    ///  设置token汇率
    function setTokenExchangeRate(uint256 _tokenExchangeRate) onlyOwner external {
        if (_tokenExchangeRate == 0) revert();
        if (_tokenExchangeRate == tokenExchangeRate) revert();

        tokenExchangeRate = _tokenExchangeRate;
    }

    /// @dev 超发token处理
    function increaseSupply(uint256 _value) onlyOwner external {
        uint256 value = formatDecimals(_value);
        if (value + currentSupply > totalSupply) revert();
        currentSupply = safeAdd(currentSupply, value);
        emit IncreaseSupply(value);
    }

    /// @dev 被盗token处理
    function decreaseSupply(uint256 _value) onlyOwner external {
        uint256 value = formatDecimals(_value);
        if (value + tokenRaised > currentSupply) revert();

        currentSupply = safeSubtract(currentSupply, value);
        emit DecreaseSupply(value);
    }

    ///  启动区块检测 异常的处理
    function startFunding(uint256 _fundingStartBlock, uint256 _fundingStopBlock) onlyOwner external {
        if (isFunding) revert();
        if (_fundingStartBlock >= _fundingStopBlock) revert();
        if (block.number >= _fundingStartBlock) revert();

        fundingStartBlock = _fundingStartBlock;
        fundingStopBlock = _fundingStopBlock;
        isFunding = true;
    }

    ///  关闭区块异常处理
    function stopFunding() onlyOwner external {
        if (!isFunding) revert();
        isFunding = false;
    }

    /// 开发了一个新的合同来接收token（或者更新token）
    function setMigrateContract(address _newContractAddr) onlyOwner external {
        if (_newContractAddr == newContractAddr) revert();
        newContractAddr = _newContractAddr;
    }

    /// 设置新的所有者地址
    function changeOwner(address _newFundDeposit) onlyOwner external {
        if (_newFundDeposit == address(0x0)) revert();
        ethFundDeposit = _newFundDeposit;
    }

    ///转移token到新的合约
    function migrate() external {
        if (isFunding) revert();
        if (newContractAddr == address(0x0)) revert();

        uint256 tokens = balances[msg.sender];
        if (tokens == 0) revert();

        balances[msg.sender] = 0;
        tokenMigrated = safeAdd(tokenMigrated, tokens);

        IMigrationContract newContract = IMigrationContract(newContractAddr);
        if (!newContract.migrate(msg.sender, tokens)) revert();

        emit Migrate(msg.sender, tokens);
        // log it
    }


    /// 向指定账户增发资金
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        currentSupply = safeAdd(currentSupply, mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);

    }

    /// 冻结 or 解冻账户
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }


    ///  Running Token分配到预处理地址。
    function allocateToken(address _addr, uint256 _eth) onlyOwner external {
        if (_eth == 0) revert();
        if (_addr == address(0x0)) revert();

        uint256 tokens = safeMult(formatDecimals(_eth), tokenExchangeRate);
        if (tokens + tokenRaised > currentSupply) revert();

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[_addr] += tokens;

        emit AllocateToken(_addr, tokens);
        // 记录token日志
    }

    /// 购买token
    function() payable public{
        if (!isFunding) revert();
        if (msg.value == 0) revert();

        if (block.number < fundingStartBlock) revert();
        if (block.number > fundingStopBlock) revert();

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        if (tokens + tokenRaised > currentSupply) revert();

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[msg.sender] += tokens;

        emit IssueToken(msg.sender, tokens);
        //记录日志
    }

    //出售代币
    function sell(uint amount) public returns (uint revenue){
        require(balances[msg.sender] >= amount);         // checks if the sender has enough to sell
        balances[this] += amount;                        // adds the amount to owner&#39;s balance
        balances[msg.sender] -= amount;                  // subtracts the amount from seller&#39;s balance
        //        revenue = amount * sellPrice;
        revenue = safeDiv(amount, tokenExchangeRate);
        msg.sender.transfer(revenue);                     // sends ether to the seller: it&#39;s important to do this last to prevent recursion attacks
        emit Transfer(msg.sender, this, amount);               // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }
}