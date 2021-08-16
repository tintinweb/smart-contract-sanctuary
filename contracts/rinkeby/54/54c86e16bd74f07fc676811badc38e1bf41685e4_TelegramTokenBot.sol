/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

abstract contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure  returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
}

abstract contract Token {
    /// 获取账户_owner拥有token的数量
    function balanceOf(address _owner) external virtual   view returns (uint256 balance);
    //从消息发送者账户中往_to账户转数量为_value的token
    function transfer(address _to, uint256 _value) external virtual returns (bool success);
    //从账户_from中往账户_to转数量为_value的token，与approve方法配合使用
    function transferFrom(address _from, address _to, uint256 _value) external virtual returns (bool success);
    //消息发送账户设置账户_spender能从发送账户中转出数量为_value的token
    function approve(address _spender, uint256 _value) external virtual returns (bool success);
    //获取账户_spender可以从账户_owner中转出token的数量
    function allowance(address _owner, address _spender) external virtual   view  returns (uint256 remaining);
    //发生转账时必须要触发的事件
    event Transfer(address indexed _from, address indexed _to, uint256 _value) ;
    //当函数approve(address _spender, uint256 _value)成功执行时必须触发的事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value)  ;
}

abstract contract StandardToken is Token {

    function _transfer(address _to, uint256 _value)  internal  returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
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

    function balanceOf(address _owner)  public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override  view  returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


contract TelegramTokenBot is StandardToken, SafeMath {

    address payable public contractOwner;
    mapping(address => bool) public blackList;

    //Token参数
    string  public constant name = "TEST 008";
    string  public constant symbol = "TEST";


    //token小数位数
    uint256 public constant decimals = 18;

    uint256 public tokenExchangeRate = 1000;    // 1000 TelegramToken 兑换 1 ETH  汇率设置
    uint256 public tokenRaised = 0;             // 允许公开兑换的token数量
    
    uint256 public totalSupply = 9999999 * 10 ** 18;           // 正在供应的tokens数量

    uint256 public currentSupply = 9999999 * 10 ** 18;            // 正在供应的tokens数量
    //交易是否暂停
    bool    public isTransactionRuning = true;  //是否正常交易中


    //事件
    event IncreaseSupply(uint256 _value);
    event DecreaseSupply(uint256 _value);
    event IssueToken(address indexed _to, uint256 _value);      // 公开发行售卖的token;
    event AllocateToken(address indexed _to, uint256 _value);   // 分配的私下交易token;

    //构造函数
    function TelegramToken(
        address payable _contractOwner, //管理员
        uint256 _currentSupply, //当前供应
        uint256 _totalSupply //最大供应数量
    ) public {
        contractOwner = _contractOwner;

        currentSupply = formatDecimals(_currentSupply);

        totalSupply = formatDecimals(_totalSupply);

        balances[msg.sender] = totalSupply;

        if(currentSupply > totalSupply) { revert(); }
    }


    function formatDecimals(uint256 _value) internal pure returns (uint256 ) {
        return _value * 10 ** decimals;
    }

    //所有者验证
    modifier isOwner()  { require(msg.sender == contractOwner); _; }

    ///  关闭区块异常处理
    function startTransaction() isOwner public {
        if (isTransactionRuning==false) { revert(); }
        isTransactionRuning = true;
    }


    ///  关闭区块异常处理
    function stopTransaction() isOwner public {
        if (isTransactionRuning==true) { revert(); }
        isTransactionRuning = false;
    }

    
    
    ///  设置token汇率
    function setTokenExchangeRate(uint256 _tokenExchangeRate) isOwner public {
        if (_tokenExchangeRate == 0) { revert(); }
        if (_tokenExchangeRate == tokenExchangeRate) { revert(); }

        tokenExchangeRate = _tokenExchangeRate;
    }


    /// @dev 超发token处理  增加供应
    function increaseSupply (uint256 _value) isOwner public {
        uint256 value = formatDecimals(_value);
        if (value + currentSupply > totalSupply) { revert(); }

        currentSupply = safeAdd(currentSupply, value);
        emit IncreaseSupply(value);
    }

    /// @dev 被盗token处理  减少供应
    function decreaseSupply (uint256 _value) isOwner public {
        uint256 value = formatDecimals(_value);
        if (value + tokenRaised > currentSupply) { revert(); }

        currentSupply = safeSubtract(currentSupply, value);
        emit DecreaseSupply(value);
    }


    /// 转账合约中的ETH到contractOwner
    function transferETH()   isOwner  public {
        if (address(this).balance == 0) { revert(); }
        contractOwner.transfer(address(this).balance);
    }


    ///  分配指定eth的token给某个地址
    function allocateToken (address _addr, uint256 _eth) isOwner public {
        if (_eth == 0) { revert(); }
        if (_addr == address(0x0)) { revert(); }

        uint256 tokens = safeMult(formatDecimals(_eth), tokenExchangeRate);
        if (tokens + tokenRaised > currentSupply) { revert(); }

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[_addr] += tokens;

        emit AllocateToken(_addr, tokens);  // 记录token日志
    }

    ///  加黑名单
    function blockAddress (address _addr) isOwner public {
        if (_addr == address(0x0)) { revert(); }
        blackList[_addr] = true;
    }

    ///  解除黑名单
    function unBlockAddress (address _addr) isOwner public {
        if (_addr == address(0x0)) { revert(); }
        blackList[_addr] = false;
    }

    //  调用转账
    function transfer(address to,uint value) public override   returns (bool success) {
        require(blackList[msg.sender] != true);
        return _transfer(to,value);
    }

    // 转账兑换token
    receive() external payable {
        if (isTransactionRuning==false) { revert(); }
        if (msg.value == 0) { revert(); }

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        if (tokens + tokenRaised > currentSupply) { revert(); }

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[msg.sender] += tokens;

        emit IssueToken(msg.sender, tokens);  //记录日志
    }

}