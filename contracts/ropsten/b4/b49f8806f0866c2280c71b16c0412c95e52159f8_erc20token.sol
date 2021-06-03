/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity ^0.4.21;


contract EIP20Interface {
    string public name;
    string public symbol;
    uint public decimal;
    uint public totalSupply;
    

    /// @param _owner 获取余额的地址
    /// @return 余额
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice 发送 '_value' 代币到 '_to' 地址从 'msg.sender'打出
    /// @param _to 发达目标的地址
    /// @param _value 转账token的数量
    /// @return 传输是否成功
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice 在 '_from'批准的情况下,将 '_value'数量代币从 '_from' 发送给 '_to'
    /// @param _from 发送者地址
    /// @param _to 目标地址
    /// @param _value 传递token的数量
    /// @return 传输是否成功
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice 'msg.sender' 合约管理者批准 '_spender' 使用 '_value' 数量代币
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _spender 允许转移代币的账户地址
    /// @param _value 允许转移的token数量
    /// @return 授权是否成功
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner 拥有token的账户地址
    /// @param _spender 允许转移token的账户地址
    /// @return 剩余允许使用的token数量
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract erc20token is EIP20Interface {
    
    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    constructor (string _name,string _symbol) public {
        name = _name;
        symbol = _symbol;
        decimal = 0;
        totalSupply = 100000;
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }

    /// @notice 发送 '_value' 代币到 '_to' 地址从 'msg.sender'打出
    /// @param _to 发达目标的地址
    /// @param _value 转账token的数量
    /// @return 传输是否成功
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= _value);
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice 在 '_from'批准的情况下,将 '_value'数量代币从 '_from' 发送给 '_to'
    /// @param _from 发送者地址
    /// @param _to 目标地址
    /// @param _value 传递token的数量
    /// @return 传输是否成功
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_to != address(0));
        require(balances[_to] + _value >= _value);
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        
        emit Transfer(_from,_to,_value);
        return true;
    }

    /// @notice 'msg.sender' 合约管理者批准 '_spender' 使用 '_value' 数量代币
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _spender 允许转移代币的账户地址
    /// @param _value 允许转移的token数量
    /// @return 授权是否成功
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @param _owner 拥有token的账户地址
    /// @param _spender 允许转移token的账户地址
    /// @return 剩余允许使用的token数量
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
}