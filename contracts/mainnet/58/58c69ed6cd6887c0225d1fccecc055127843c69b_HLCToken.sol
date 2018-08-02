/**
 * ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  // token总量
  uint public totalSupply;
  // 获取账户_owner拥有token的数量
  function balanceOf(address _owner) constant returns (uint);
  //获取账户_spender可以从账户_owner中转出token的数量
  function allowance(address _owner, address _spender) constant returns (uint);
  // 从发送者账户中往_to账户转数量为_value的token
  function transfer(address _to, uint _value) returns (bool ok);
  //从账户_from中往账户_to转数量为_value的token，与approve方法配合使用
  function transferFrom(address _from, address _to, uint _value) returns (bool ok);
  // 消息发送账户设置账户_spender能从发送账户中转出数量为_value的token
  function approve(address _spender, uint _value) returns (bool ok);
  //发生转账时必须要触发的事件, 由transfer函数的最后一行代码触发。
  event Transfer(address indexed _from, address indexed _to, uint _value);
  //当函数approve(address spender, uint value)成功执行时必须触发的事件
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}



/**
 * 带安全检查的数学运算符
 */
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}



/**
 * 修复了ERC20 short address attack问题的标准ERC20 Token.
 *
 * Based on:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, SafeMath {

  //创建一个状态变量，该类型将一些address映射到无符号整数uint256。
  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  /**
   *
   * 修复ERC20 short address attack
   *
   * http://vessenes.com/the-erc20-short-address-attack-explained/
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
    //从消息发送者账户中减去token数量_value
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    //往接收账户增加token数量_value
    balances[_to] = safeAdd(balances[_to], _value);
    //触发转币交易事件
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value)  returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    //接收账户增加token数量_value
    balances[_to] = safeAdd(balances[_to], _value);
    //支出账户_from减去token数量_value
    balances[_from] = safeSub(balances[_from], _value);
    //消息发送者可以从账户_from中转出的数量减少_value
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    //触发转币交易事件
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    //允许_spender从_owner中转出的token数
    return allowed[_owner][_spender];
  }

}


/**
 * 允许token拥有者减少token总量
 * 加Burned事件使其区别于正常的transfers
 */
contract BurnableToken is StandardToken {

  address public constant BURN_ADDRESS = 0;

  event Burned(address burner, uint burnedAmount);

  /**
   * 销毁Token
   *
   */
  function burn(uint burnAmount) {
    address burner = msg.sender;
    balances[burner] = safeSub(balances[burner], burnAmount);
    totalSupply = safeSub(totalSupply, burnAmount);
    Burned(burner, burnAmount);
    Transfer(burner, BURN_ADDRESS, burnAmount);
  }
}




/**
 * 发行Ethereum token.
 *
 * 创建token总量并分配给owner.
 * owner之后可以把token分配给其他人
 * owner可以销毁token
 *
 */
contract HLCToken is BurnableToken {

  string public name;  // Token名称，例如：Halal chain token
  string public symbol;  // Token标识，例如：HLC
  uint8 public decimals = 18;  // 最多的小数位数 18 是建议的默认值
  uint256 public totalSupply;
  function HLCToken(address _owner, string _name, string _symbol, uint _totalSupply, uint8 _decimals) {
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply * 10 ** uint256(_decimals);
    decimals = _decimals;

    // 把创建token的总量分配给owner
    balances[_owner] = totalSupply;
  }
}