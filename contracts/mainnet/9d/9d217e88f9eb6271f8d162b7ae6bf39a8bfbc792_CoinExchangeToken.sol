pragma solidity ^0.4.19;

contract Token {

    /// @return total amount of tokens
    /// @return 返回token的发行量
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    /// @param _owner 查询以太坊地址token余额
    /// @return The balance 返回余额
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    /// @notice msg.sender（交易发送者）发送 _value（一定数量）的 token 到 _to（接受者）  
    /// @param _to 接收者的地址
    /// @param _value 发送token的数量
    /// @return 是否成功
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    /// @notice 发送者 发送 _value（一定数量）的 token 到 _to（接受者）  
    /// @param _from 发送者的地址
    /// @param _to 接收者的地址
    /// @param _value 发送的数量
    /// @return 是否成功
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    /// @notice 发行方 批准 一个地址发送一定数量的token
    /// @param _spender 需要发送token的地址
    /// @param _value 发送token的数量
    /// @return 是否成功
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    /// @param _owner 拥有token的地址
    /// @param _spender 可以发送token的地址
    /// @return 还允许发送的token的数量
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    /// 发送Token事件
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    /// 批准事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
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
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
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

contract CoinExchangeToken is StandardToken {

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
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //小数位How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H0.1&#39;;       //版本号human 0.1 standard. Just an arbitrary versioning scheme.

    function CoinExchangeToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;               // 把合约的发布者的余额设置为发行量的数量,Give the creator all initial tokens
        totalSupply = _initialAmount;                        // 发行量Update total supply
        name = _tokenName;                                   // token名称Set the name for display purposes
        decimals = _decimalUnits;                            // token小数位Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // token标识Set the symbol for display purposes
    }

    /* Approves and then calls the receiving contract */
    /* 批准然后调用接收合约 */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //调用你想要通知合约的 receiveApprovalcall 方法 ，这个方法是可以不需要包含在这个合约里的。
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        //假设这么做是可以成功，不然应该调用vanilla approve。
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}