pragma solidity ^0.4.4;

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
contract TIC is StandardToken { 

    string public name;                  
    uint8 public decimals;              
    string public symbol;                 
    string public version = &#39;1.0&#39;; 
    uint256 public Rate;     
    uint256 public totalEthInWei;      
    address public fundsWallet;         
    address public CandyBox;
    address public TeamBox;


    function TIC(
        ) {
        CandyBox = 0x94eE12284824C91dB533d4745cD02098d7284460;
        TeamBox = 0xfaDB28B22b1b5579f877c78098948529175F81Eb;
        totalSupply = 6000000000000000000000000000;                   
        balances[msg.sender] = 5091000000000000000000000000;             
        balances[CandyBox] = 9000000000000000000000000;  
        balances[TeamBox] = 900000000000000000000000000;
        name = "TIC";                                        
        decimals = 18;                                  
        symbol = "TIC";                                            
        Rate = 50000;                                      
        fundsWallet = msg.sender;                                   
    }
    
    function setCurrentRate(uint256 _rate) public {
        if(msg.sender != fundsWallet) { throw; }
        Rate = _rate;
    }    

    function setCurrentVersion(string _ver) public {
        if(msg.sender != fundsWallet) { throw; }
        version = _ver;
    }  

    function() payable{
 
        totalEthInWei = totalEthInWei + msg.value;
  
        uint256 amount = msg.value * Rate;

        require(balances[fundsWallet] >= amount);


        balances[fundsWallet] = balances[fundsWallet] - amount;

        balances[msg.sender] = balances[msg.sender] + amount;


        Transfer(fundsWallet, msg.sender, amount); 

 
        fundsWallet.transfer(msg.value);                               
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}