// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
pragma solidity ^0.4.21;


contract MarianaKeyInterface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract MarianaKey is MarianaKeyInterface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    // 建立映射 地址对应了 uint&#39; 便是他的余额
    mapping (address => uint256) public balances;
    // 存储对账号的控制
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    function MarianaKey (
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        //msg.sender是合约方法调用方的地址
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
    *  代币交易转移
    * 从创建交易者账号发送`_value`个代币到 `_to`账号
    *
    * @param _to 接收者地址
    * @param _value 转移数额
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // 不是零地址
        require(_to != 0x0);
        require(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    /**
    * 账号之间代币交易转移
    * @param _from 发送者地址
    * @param _to 接收者地址
    * @param _value 转移数额
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        //避免溢出的异常
        require(balances[_from] >= _value && allowance >= _value && balances[_to] + _value >= balances[_to]);
        // 不是零地址,因为0x0地址代表销毁
        require(_to != 0x0);
        balances[_to] += _value;
        balances[_from] -= _value;
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //消息发送者可以从账户_from中转出的数量减少_value
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        //这句则只是把赠送代币的记录存下来
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    //返回地址是_owner的账户的账户余额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    //允许_spender多次取回您的帐户，最高达_value金额。 如果再次调用此函数，它将以_value覆盖当前的余量。
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    //返回_spender仍然被允许从_owner提取的金额;allowance(A, B)可以查看B账户还能够调用A账户多少个token
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}