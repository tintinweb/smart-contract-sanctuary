pragma solidity ^0.4.12;
 

contract IMigrationContract {
    function migrate(address addr, uint256 nas) returns (bool success);
}


contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }
 
    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }
 
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
 
}
 

contract Token {
    uint256 public totalSupply; //代币总量
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
 
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
 
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
 
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
 

//JGO代币合约
contract JGOToken is StandardToken, SafeMath {
    string  public constant name = "Artificial Intelligence Coin";   //名称
    string  public constant symbol = "AIC"; //符号
    uint256 public constant decimals = 6;  //小数位
    string  public version = "1.0";         //版本
 
    address public ethFundDeposit;          //ETH存放地址
    address public newContractAddr;         //代币更新地址
 
    bool    public isFunding;               
    uint256 public fundingStartBlock;
    uint256 public fundingStopBlock;
 
    uint256 public currentSupply;            //代币供应量
    uint256 public tokenRaised = 0;          //总售卖数量
    uint256 public tokenMigrated = 0;        //已经交易量
    uint256 public tokenExchangeRate = 100;  //自动兑换比例：1ETH = 100JGO
 
    event IncreaseSupply(uint256 _value);
    event DecreaseSupply(uint256 _value);
    event Migrate(address indexed _to, uint256 _value);
    event IssueToken(address indexed _to, uint256 _value);      //公开发行售卖的token;
    event AllocateToken(address indexed _to, uint256 _value);   //分配的私有交易token;

    modifier isOwner()  { require(msg.sender == ethFundDeposit); _; }

    function formatDecimals(uint256 _value) internal returns (uint256 ) {
        return _value * 10 ** decimals;
    }

 
 	//JGO合约初始化函数(合约所有人地址, 当前供应量, 代币总量)
    function JGOToken(address _ethFundDeposit, uint256 _currentSupply, uint256 _totalSupply) {
        ethFundDeposit = _ethFundDeposit;
 
        isFunding = false;                         
        fundingStartBlock = 0;
        fundingStopBlock = 0;
 
        currentSupply = formatDecimals(_currentSupply); //当前供应量
        totalSupply = formatDecimals(_totalSupply);     //代币总量
        balances[msg.sender] = totalSupply;
        if(currentSupply > totalSupply) throw;
    }
 

 
    //设置token汇率
    function setTokenExchangeRate(uint256 _tokenExchangeRate) isOwner external {
        if (_tokenExchangeRate == 0) throw;
        if (_tokenExchangeRate == tokenExchangeRate) throw;
 
        tokenExchangeRate = _tokenExchangeRate;
    }
 

    //增发处理(供应量，代币总量)
    function increaseSupply (uint256 _supplyValue, uint256 _totalValue) isOwner external {
        uint256 supplyValue = formatDecimals(_supplyValue);
        uint256 totalValue  = formatDecimals(_totalValue);

        totalSupply = safeAdd(totalSupply, totalValue);       //增加代币总量
        if(supplyValue + currentSupply > totalSupply) throw;  //数量检查
        currentSupply = safeAdd(currentSupply, supplyValue);  //增加供应量
        IncreaseSupply(supplyValue);
    }
 

    //被盗处理
    function decreaseSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        if (value + tokenRaised > currentSupply) throw;
 
        currentSupply = safeSubtract(currentSupply, value);
        DecreaseSupply(value);
    }
 

    //启动区块检测 异常的处理
    function startFunding (uint256 _fundingStartBlock, uint256 _fundingStopBlock) isOwner external {
        if (isFunding) throw;
        if (_fundingStartBlock >= _fundingStopBlock) throw;
        if (block.number >= _fundingStartBlock) throw;
 
        fundingStartBlock = _fundingStartBlock;
        fundingStopBlock = _fundingStopBlock;
        isFunding = true;
    }
 

    //关闭区块异常处理
    function stopFunding() isOwner external {
        if (!isFunding) throw;
        isFunding = false;
    }
 

    //开发新合约来接收代币
    function setMigrateContract(address _newContractAddr) isOwner external {
        if (_newContractAddr == newContractAddr) throw;
        newContractAddr = _newContractAddr;
    }
 

    //修改合约所有者
    function changeOwner(address _newFundDeposit) isOwner() external {
        if (_newFundDeposit == address(0x0)) throw;
        ethFundDeposit = _newFundDeposit;
    }
 

    //转移代币到新合约
    function migrate() external {
        if(isFunding) throw;
        if(newContractAddr == address(0x0)) throw;
 
        uint256 tokens = balances[msg.sender];
        if (tokens == 0) throw;
 
        balances[msg.sender] = 0;
        tokenMigrated = safeAdd(tokenMigrated, tokens);
 
        IMigrationContract newContract = IMigrationContract(newContractAddr);
        if (!newContract.migrate(msg.sender, tokens)) throw;
 
        Migrate(msg.sender, tokens);
    }

 
    //转账ETH到JGO团队
    function transferETH() isOwner external {
        if (this.balance == 0) throw;
        if (!ethFundDeposit.send(this.balance)) throw;
    }

 
    //将JGOToken分配到预处理地址
    function allocateToken (address _addr, uint256 _eth) isOwner external {
        if (_eth == 0) throw;
        if (_addr == address(0x0)) throw;
 
        uint256 tokens = safeMult(formatDecimals(_eth), tokenExchangeRate);
        if (tokens + tokenRaised > currentSupply) throw;
 
        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[_addr] += tokens;
 
        AllocateToken(_addr, tokens);
    }
 
 
    //购买代币
    function () payable {
        if (!isFunding) throw;
        if (msg.value == 0) throw;
 
        if (block.number < fundingStartBlock) throw;
        if (block.number > fundingStopBlock) throw;
 
        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        if (tokens + tokenRaised > currentSupply) throw;
 
        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[msg.sender] += tokens;
 
        IssueToken(msg.sender, tokens);
    }
}