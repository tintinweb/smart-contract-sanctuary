pragma solidity ^0.4.23;

// 定义智能合约---TokenDemo
contract TokenDemo{
    string public name;         // 代币名称
    string public symbol;       // 代币代号
    uint8 public decimals;      // 代币位数
    uint256 public totalSupply; // 代币提供总量
    
    mapping (address => uint256) public balanceOf;   // 账户余额
    
    // 事件
    event Transfer(address from, address to, uint256 value);
    
    // 代币构造函数
    function TokenDemo(string tokenName, string tokenSymbol, uint8 tokenDecimals, uint256 tokenTotalSupply) public{
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        totalSupply = tokenTotalSupply;
    }
    
    // 交易函数
    function _transfer(address _from, address _to, uint256 _value) internal{
        // 检查输出地址不为空
        require(_to != 0x0);
        
        // 检查发送方余额大于要交易的金额
        require(balanceOf[_from] >= _value);
        
        // 接收方余额检查
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        // 交易前余额(余额平衡检查)
        uint previousBalances;
        previousBalances = balanceOf[_from] + balanceOf[_to];
        
        // 发送方转出金额
        balanceOf[_from] -= _value;
        
        // 接收方转入金额
        balanceOf[_to] += _value;
        
        Transfer(_from, _to, _value);
        
        // 余额平衡检查
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    // 公开对外交易函数
    function transfer(address _to, uint256 _value) public{
        _transfer(msg.sender, _to, _value);
    }
    
    
    // 返回代币名称---name
    function name() view public returns (string tokenName){
        return name;
    }
    
    // 返回代币代号
    function symbol() view public returns (string tokenSymbol){
        return symbol;
    }
    
    // 返回代币位数
    function decimals() view public returns (uint8 tokenDecimals){
        return decimals;
    }
    
    // 返回代币总发行量
    function totalSupply() view public returns (uint256 tokenTotalSupply){
        return totalSupply;
    }
}