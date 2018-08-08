pragma solidity ^0.4.21;

contract KKToken {
  
  //地址 -> 余额 的映射
  mapping (address => uint256) balances;
  //地址 -> 允许代币转移的地址及数量 的映射
  mapping (address => mapping (address => uint256)) allowed;
  
  //这4个状态变量会自动创建对应public函数
  string public name = " Kunkun Token";
  string public symbol = "KKT";
  uint8 public decimals = 18;  //建议的默认值
  uint256 public totalSupply;

  uint256 public initialSupply = 100000000;

  //如果ETH被发送到这个合约，会被发送回去
  function (){
    throw;
  }

  //构造函数，只在合约创建时执行一次
  function KKToken(){
    //实际总供应量 = 代币数量*10^精度
    totalSupply = initialSupply * (10 ** uint256(decimals));
    //把所有代币分配给合约创建者
    balances[msg.sender] = totalSupply;
  }

  //查询某账户（_owner）的余额
  function balanceOf(address _owner) view returns (uint256 balance){
    return balances[_owner];
  }

  //向某个地址（_to）发送（_value）个代币
  //发送者调用
  function transfer(address _to, uint256 _value) returns (bool success){
    //检查发送者是否有足够的代币
    if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { 
      return false; 
    }
  }

  //从某个地址（_from）向某个地址（_to）发送（_value）个代币
  //接收者调用
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
    //检查发送者是否有足够的代币
    //检查接收者是否发送者的允许发送范围内，且发送数量也在对应的允许范围内
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

  //允许某个地址（_spender）从你的账户转移（_value）个代币
  function approve(address _spender, uint256 _value) returns (bool success){
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  //获取（_owner）允许某个地址（_spender）还可以转移多少代币
  function allowance(address _owner, address _spender) view returns (uint256 remaining){
    return allowed[_owner][_spender];
  }

  //transfer 被调用时的通知事件
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  //approve 被调用时的通知事件
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  
}