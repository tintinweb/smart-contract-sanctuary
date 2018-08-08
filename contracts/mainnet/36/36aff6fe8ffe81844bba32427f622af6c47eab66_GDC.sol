pragma solidity ^0.4.13;

contract SafeMath {
    //SafeAdd 是安全加法，这是ERC20标准function
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    //SafeSubtract 是安全减法，这是ERC20标准function
    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    //SafeMult 是安全乘法，这是ERC20标准function
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

// Token合约，这里定义了合约需要用到的方法
contract Token {
    //totalSupply: 总供应量
    uint256 public totalSupply;
    //balanceOf: 获取每个地址的GDC余额
    function balanceOf(address _owner) constant returns (uint256 balance);
    //transfer: GDC合约的转账功能
    function transfer(address _to, uint256 _value) returns (bool success);
    //transferFrom: 将GDC从一个地址转向另一个地址
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    //approve: 允许从A地址向B地址转账，需要先approve, 然后才能transferFrom
    function approve(address _spender, uint256 _value) returns (bool success);
    //allowance，保留Approve方法的结果
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    //Transfer事件，在调用转账方法之后，会记录下转账事件
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //Approval事件，在调用approve方法之后，会记录下Approval事件
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {
    //转账功能，实现向某个账户转账的功能
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

    // 实现从A账户向B账户转账功能，但必须要A账户先允许向B账户的转账金额才可
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
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
    //获取当前账户的代币数量
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    //允许向某个账户转账多少金额
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    // 记录下向某个账户转账的代币数量
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    // 代币余额表，记录下某个地址有多少代币数量
    mapping (address => uint256) balances;
    // 允许转账金额，记录下A地址允许向B地址，转账多少代币
    mapping (address => mapping (address => uint256)) allowed;
}

// GDC合约，继承自ERC20的标准合约
contract GDC is StandardToken, SafeMath {
    string public constant name = "GDC"; //合约名字为GDC
    string public constant symbol = "GDC"; //合约标示为GDC
    uint256 public constant decimals = 18; //合约小数点后18位
    string public version = "1.0"; //合约版本 1.0

    address  public GDCAcc01;  //GDC合约的账号1
    address  public GDCAcc02;  //GDC合约的账号2
    address  public GDCAcc03;  //GDC合约的账号3
    address  public GDCAcc04;  //GDC合约的账号4
    address  public GDCAcc05;  //GDC合约的账号5

    uint256 public constant factorial = 6; //用于定义每个账户多少GDC数量所用。
    uint256 public constant GDCNumber1 = 200 * (10**factorial) * 10**decimals; //GDCAcc1代币数量为200M，即2亿代币
    uint256 public constant GDCNumber2 = 200 * (10**factorial) * 10**decimals; //GDCAcc2代币数量为200M，即2亿代币
    uint256 public constant GDCNumber3 = 200 * (10**factorial) * 10**decimals; //GDCAcc3代币数量为200M，即2亿代币
    uint256 public constant GDCNumber4 = 200 * (10**factorial) * 10**decimals; //GDCAcc4代币数量为200M，即2亿代币
    uint256 public constant GDCNumber5 = 200 * (10**factorial) * 10**decimals; //GDCAcc5代币数量为200M，即2亿代币


    // 构造函数，需要输入五个地址，然后分别给五个地址分配2亿GDC代币
    function GDC(
      address _GDCAcc01,
      address _GDCAcc02,
      address _GDCAcc03,
      address _GDCAcc04,
      address _GDCAcc05
    )
    {
      totalSupply = 1000 * (10**factorial) * 10**decimals; // 设置总供应量为10亿
      GDCAcc01 = _GDCAcc01;
      GDCAcc02 = _GDCAcc02;
      GDCAcc03 = _GDCAcc03;
      GDCAcc04 = _GDCAcc04;
      GDCAcc05 = _GDCAcc05;

      balances[GDCAcc01] = GDCNumber1;
      balances[GDCAcc02] = GDCNumber2;
      balances[GDCAcc03] = GDCNumber3;
      balances[GDCAcc04] = GDCNumber4;
      balances[GDCAcc05] = GDCNumber5;

    }

    // transferLock 代表必须要输入的flag为true的时候，转账才可能生效，否则都会失效
    function transferLock(address _to, uint256 _value, bool flag) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0 && flag) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }
}