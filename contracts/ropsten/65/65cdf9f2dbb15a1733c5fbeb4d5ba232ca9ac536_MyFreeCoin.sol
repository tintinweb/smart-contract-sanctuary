pragma solidity ^0.4.4;

contract Token {
    
    // return the total token selled
    function totalSupply() view returns(uint256 supply){}
    
    // @param _owner 查询以太坊地址token余额
    function balanceOf(address _owner) view returns (uint balance){}
    
    // @notice msg.sender（交易发送者）发送 _value（一定数量）的 token 到 _to（接受者）  
    // @param _to 接收者的地址
    // @param _value 发送token的数量
    // @return 是否成功
    function transfer(address _to, uint _value) returns(bool success){}
    
    /// @notice 发送者 发送 _value（一定数量）的 token 到 _to（接受者）  
    /// @param _from 发送者的地址
    /// @param _to 接收者的地址
    /// @param _value 发送的数量
    /// @return 是否成
    function teansferFrom(address _from, address _to, uint _value) returns (bool success){}
    
     /// @notice 发行方 批准 一个地址发送一定数量的token
    /// @param _spender 需要发送token的地址
    /// @param _value 发送token的数量
    /// @return 是否成功
    function approve(address _spender, uint _value) returns (bool success){}
    
    /// @param _owner 拥有token的地址
    /// @param _spender 可以发送token的地址
    /// @return 还允许发送的token的数量
    function allowance(address _owner, address _spender) view returns(uint remaining){}
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
}

contract StandardToken is Token{
    
    mapping (address => uint)balances;
    
    mapping(address => mapping(address => uint)) allowed;
    
    uint public totalSupply;
    
    function transfer(address _to, uint _value) returns(bool success){
        if(balances[msg.sender] >= _value && _value >0){
            balances[msg.sender] -=_value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }else{
            return false;
        }
        
    }
    
    
    function teansferFrom(address _from, address _to, uint _value) returns (bool success){
        if(balances[_from] >=_value && allowed[_from][msg.sender] >= _value && _value >0){
            balances[_from] -= _value;
            balances[_to] += _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }else{
            return false;
        }
    }
    
    
    function balanceOf(address _owner) view returns (uint balance){
        return balances[_owner];
    }
    
    function approve(address _spender, uint _value) returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) view returns(uint remaining){
        return allowed[_owner][_spender];
    }
}

contract MyFreeCoin is StandardToken{
    
    // 回退函数
    function (){
        throw;
    }

    string public name;
    
    uint8 public decimal;
    
    string public symbol;
    
    string public version = "H0.1";
    
    constructor(uint _initAmount, string _tokenName, uint8 _decimal, string _tokenSymbol) public {
        balances[msg.sender] = _initAmount;
        
        totalSupply = _initAmount;
        
        name = _tokenName;
        decimal = _decimal;
        symbol = _tokenSymbol;
    }
    
    function approveAndCall(address _spender, uint _value, bytes _extraData) returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        
        //调用你想要通知合约的 receiveApprovalcall 方法 ，这个方法是可以不需要包含在这个合约里的。
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //假设这么做是可以成功，不然应该调用vanilla approve。
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;

    }
    
}