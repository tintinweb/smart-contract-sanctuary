pragma solidity  0.4.24;

contract Token {

    /// @return 返回token的发行量
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner 查询以太坊地址token余额
    /// @return The balance 返回余额
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice msg.sender（交易发送者）发送 _value（一定数量）的 token 到 _to（接受者）  
    /// @param _to 接收者的地址
    /// @param _value 发送token的数量
    /// @return 是否成功
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice 发送者 发送 _value（一定数量）的 token 到 _to（接受者）  
    /// @param _from 发送者的地址
    /// @param _to 接收者的地址
    /// @param _value 发送的数量
    /// @return 是否成功
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice 发行方 批准 一个地址发送一定数量的token
    /// @param _spender 需要发送token的地址
    /// @param _value 发送token的数量
    /// @return 是否成功
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner 拥有token的地址
    /// @param _spender 可以发送token的地址
    /// @return 还允许发送的token的数量
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    /// 发送Token事件
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    /// 批准事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*
This implements ONLY the standard functions and NOTHING else.
For a token like you would want to deploy in something like Mist, see HumanStandardToken.sol.

If you deploy this, you won&#39;t have anything useful.

Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20

实现ERC20标准
.*/

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //默认token发行量不能超过(2^256 - 1)
        //如果你不设置发行量，并且随着时间的发型更多的token，需要确保没有超过最大值，使用下面的 if 语句
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //向上面的方法一样，如果你想确保发行量不超过最大值
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

/*
This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20) as well as the following OPTIONAL extras intended for use by humans.

In other words. This is intended for deployment in something like a Token Factory or Mist wallet, and then used by humans.
Imagine coins, currencies, shares, voting weight, etc.
Machine-based, rapid creation of many tokens would not necessarily need these extra features or will be minted in other manners.

1) Initial Finite Supply (upon creation one specifies how much is minted).
2) In the absence of a token registry: Optional Decimal, Symbol & Name.
3) Optional approveAndCall() functionality to notify a contract if an approval() has occurred.

.*/

contract MyFreeCoin is StandardToken {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //token名称: MyFreeCoin 
    uint8 public decimals;                //小数位
    string public symbol;                 //标识
    string public version = &#39;H0.1&#39;;       //版本号

    function MyFreeCoin(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;               // 合约发布者的余额是发行数量
        totalSupply = _initialAmount;                        // 发行量
        name = _tokenName;                                   // token名称
        decimals = _decimalUnits;                            // token小数位
        symbol = _tokenSymbol;                               // token标识
    }

    /* 批准然后调用接收合约 */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //调用你想要通知合约的 receiveApprovalcall 方法 ，这个方法是可以不需要包含在这个合约里的。
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //假设这么做是可以成功，不然应该调用vanilla approve。
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}