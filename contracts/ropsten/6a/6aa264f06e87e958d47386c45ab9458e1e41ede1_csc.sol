/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

pragma solidity ^0.4.11;

contract IMigrationContract {
    function migrate(address addr, uint256 nas) returns (bool success);
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

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }
}

contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) returns (bool success);

    function approve(address _spender, uint256 _value) returns (bool success);

    function allowance(address _owner, address _spender)
        constant
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

/*  ERC 20 token */
contract StandardToken is Token {
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

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) returns (bool success) {
        if (
            balances[_from] >= _value &&
            allowed[_from][msg.sender] >= _value &&
            _value > 0
        ) {
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

    function allowance(address _owner, address _spender)
        constant
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
}

contract csc is StandardToken, SafeMath {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    // metadata
    string public constant name = "LLLToken";
    string public constant symbol = "LLLcoin";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public ethFundDeposit; // ETH存放地址
    address public newContractAddr; // token更新地址

    // crowdsale parameters
    bool public isFunding; // 状态切换到true
    uint256 public fundingStartBlock;
    uint256 public fundingStopBlock;

    uint256 public currentSupply; // 正在售卖中的tokens数量
    uint256 public tokenRaised = 0; // 总的售卖数量token
    uint256 public tokenMigrated = 0; // 总的已经交易的 token
    uint256 public tokenExchangeRate = 900; // 625 BILIBILI 兑换 1 ETH

    // events
    event AllocateToken(address indexed _to, uint256 _value); // 分配的私有交易token;
    event IssueToken(address indexed _to, uint256 _value); // 公开发行售卖的token;
    event IncreaseSupply(uint256 _value);
    event DecreaseSupply(uint256 _value);
    event Migrate(address indexed _to, uint256 _value);

    // 转换
    function formatDecimals(uint256 _value) internal returns (uint256) {
        return _value * 10**decimals;
    }

    // constructor
    function csc(address _ethFundDeposit, uint256 _currentSupply) {
        ethFundDeposit = _ethFundDeposit;

        isFunding = false; //通过控制预CrowdS ale状态
        fundingStartBlock = 0;
        fundingStopBlock = 0;

        currentSupply = formatDecimals(_currentSupply);
        totalSupply = formatDecimals(9999999);
        balances[msg.sender] = totalSupply;
        if (currentSupply > totalSupply) throw;
    }

    modifier isOwner() {
        require(msg.sender == ethFundDeposit);
        _;
    }

    /**
     * @dev 销毁
     */
    // function _burn(address account, uint256 value) internal {
    //     require(account != 0);
    //     require(value <= _balances[account]);

    //     _totalSupply = _totalSupply.sub(value);
    //     _balances[account] = _balances[account].sub(value);
    //     emit Transfer(account, address(0), value);
    // }

    ///  设置token汇率
    function setTokenExchangeRate(uint256 _tokenExchangeRate) external isOwner {
        if (_tokenExchangeRate == 0) throw;
        if (_tokenExchangeRate == tokenExchangeRate) throw;

        tokenExchangeRate = _tokenExchangeRate;
    }

    /// @dev 超发token处理
    function increaseSupply(uint256 _value) external isOwner {
        uint256 value = formatDecimals(_value);
        if (value + currentSupply > totalSupply) throw;
        currentSupply = safeAdd(currentSupply, value);
        IncreaseSupply(value);
    }

    /// @dev 被盗token处理
    function decreaseSupply(uint256 _value) external isOwner {
        uint256 value = formatDecimals(_value);
        if (value + tokenRaised > currentSupply) throw;

        currentSupply = safeSubtract(currentSupply, value);
        DecreaseSupply(value);
    }

    ///  启动区块检测 异常的处理
    function startFunding(uint256 _fundingStartBlock, uint256 _fundingStopBlock)
        external
        isOwner
    {
        if (isFunding) throw;
        if (_fundingStartBlock >= _fundingStopBlock) throw;
        if (block.number >= _fundingStartBlock) throw;

        fundingStartBlock = _fundingStartBlock;
        fundingStopBlock = _fundingStopBlock;
        isFunding = true;
    }

    ///  关闭区块异常处理
    function stopFunding() external isOwner {
        if (!isFunding) throw;
        isFunding = false;
    }

    /// 开发了一个新的合同来接收token（或者更新token）
    function setMigrateContract(address _newContractAddr) external isOwner {
        if (_newContractAddr == newContractAddr) throw;
        newContractAddr = _newContractAddr;
    }

    /// 设置新的所有者地址
    function changeOwner(address _newFundDeposit) external isOwner {
        if (_newFundDeposit == address(0x0)) throw;
        ethFundDeposit = _newFundDeposit;
    }

    ///转移token到新的合约
    function migrate() external {
        if (isFunding) throw;
        if (newContractAddr == address(0x0)) throw;

        uint256 tokens = balances[msg.sender];
        if (tokens == 0) throw;

        balances[msg.sender] = 0;
        tokenMigrated = safeAdd(tokenMigrated, tokens);

        IMigrationContract newContract = IMigrationContract(newContractAddr);
        if (!newContract.migrate(msg.sender, tokens)) throw;

        Migrate(msg.sender, tokens); // log it
    }

    /// 转账ETH 到BILIBILI团队
    function transferETH() external isOwner {
        if (this.balance == 0) throw;
        if (!ethFundDeposit.send(this.balance)) throw;
    }

    ///  将BILIBILI token分配到预处理地址。
    function allocateToken(address _addr, uint256 _eth) external isOwner {
        if (_eth == 0) throw;
        if (_addr == address(0x0)) throw;

        uint256 tokens = safeMult(formatDecimals(_eth), tokenExchangeRate);
        if (tokens + tokenRaised > currentSupply) throw;

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[_addr] += tokens;

        AllocateToken(_addr, tokens); // 记录token日志
    }

    /// 购买token
    function() payable {
        if (!isFunding) throw;
        if (msg.value == 0) throw;

        if (block.number < fundingStartBlock) throw;
        if (block.number > fundingStopBlock) throw;

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        if (tokens + tokenRaised > currentSupply) throw;

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[msg.sender] += tokens;

        IssueToken(msg.sender, tokens); //记录日志
    }
}