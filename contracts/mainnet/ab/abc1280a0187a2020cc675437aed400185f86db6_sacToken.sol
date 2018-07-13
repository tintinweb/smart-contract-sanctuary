pragma solidity ^0.4.20;

//---------------------------------------------------------
//  增强版的代币合约 V 0.9
//                                       WangYi 2018-05-07
//---------------------------------------------------------
contract ERC20ext
{
  // stand
  function totalSupply() public constant returns (uint supply);
  function balanceOf( address who ) public constant returns (uint value);
  function allowance( address owner, address spender ) public constant returns (uint _allowance);

  function transfer( address to, uint value) public returns (bool ok);
  function transferFrom( address from, address to, uint value) public returns (bool ok);
  function approve( address spender, uint value ) public returns (bool ok);

  event Transfer( address indexed from, address indexed to, uint value);
  event Approval( address indexed owner, address indexed spender, uint value);

  // extand
  function postMessage(address dst, uint wad,string data) public returns (bool ok);
  function appointNewCFO(address newCFO) public returns (bool ok);

  function melt(address dst, uint256 wad) public returns (bool ok);
  function mint(address dst, uint256 wad) public returns (bool ok);
  function freeze(address dst, bool flag) public returns (bool ok);

  event MeltEvent(address indexed dst, uint256 wad);
  event MintEvent(address indexed dst, uint256 wad);
  event FreezeEvent(address indexed dst, bool flag);
}

//---------------------------------------------------------
// SafeMath 是一个安全数字运算的合约
//---------------------------------------------------------
contract SafeMath 
{
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) 
  {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) 
  {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) 
  {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

//---------------------------------------------------------
// sacToken 是一个增强版ERC20合约
//---------------------------------------------------------
contract sacToken is ERC20ext,SafeMath
{
  string public name;
  string public symbol;
  uint8  public decimals = 18;

  address _cfo;
  uint256 _supply;

  //帐户的余额列表
  mapping (address => uint256) _balances;

  //帐户的转账限额
  mapping (address => mapping (address => uint256)) _allowance;

  //帐户的资金冻结
  mapping (address => bool) public _frozen;

  //-----------------------------------------------
  // 初始化合约，并把所有代币都给CFO
  //-----------------------------------------------
  //   @param initialSupply 发行总量
  //   @param tokenName     代币名称
  //   @param tokenSymbol   代币符号
  //-----------------------------------------------
  function sacToken(uint256 initialSupply,string tokenName,string tokenSymbol) public
  {
    _cfo    = msg.sender;
    _supply = initialSupply * 10 ** uint256(decimals);
    _balances[_cfo] = _supply;

    name   = tokenName;
    symbol = tokenSymbol;
  }

  //-----------------------------------------------
  // 判断合约调用者是否 CFO
  //-----------------------------------------------
  modifier onlyCFO()
  {
    require(msg.sender == _cfo);
    _;
  }


  //-----------------------------------------------
  // 获取货币供应量
  //-----------------------------------------------
  function totalSupply() public constant returns (uint256)
  {
    return _supply;
  }

  //-----------------------------------------------
  // 查询账户余额
  //-----------------------------------------------
  // @param  src 帐户地址
  //-----------------------------------------------
  function balanceOf(address src) public constant returns (uint256)
  {
    return _balances[src];
  }

  //-----------------------------------------------
  // 查询账户转账限额
  //-----------------------------------------------
  // @param  src 来源帐户地址
  // @param  dst 目标帐户地址
  //-----------------------------------------------
  function allowance(address src, address dst) public constant returns (uint256)
  {
    return _allowance[src][dst];
  }

  //-----------------------------------------------
  // 账户转账
  //-----------------------------------------------
  // @param  dst 目标帐户地址
  // @param  wad 转账金额
  //-----------------------------------------------
  function transfer(address dst, uint wad) public returns (bool)
  {
    //检查冻结帐户
    require(!_frozen[msg.sender]);
    require(!_frozen[dst]);

    //检查帐户余额
    require(_balances[msg.sender] >= wad);

    _balances[msg.sender] = sub(_balances[msg.sender],wad);
    _balances[dst]        = add(_balances[dst], wad);

    Transfer(msg.sender, dst, wad);

    return true;
  }

  //-----------------------------------------------
  // 账户转账带检查限额
  //-----------------------------------------------
  // @param  src 来源帐户地址
  // @param  dst 目标帐户地址
  // @param  wad 转账金额
  //-----------------------------------------------
  function transferFrom(address src, address dst, uint wad) public returns (bool)
  {
    //检查冻结帐户
    require(!_frozen[msg.sender]);
    require(!_frozen[dst]);

    //检查帐户余额
    require(_balances[src] >= wad);

    //检查帐户限额
    require(_allowance[src][msg.sender] >= wad);

    _allowance[src][msg.sender] = sub(_allowance[src][msg.sender],wad);

    _balances[src] = sub(_balances[src],wad);
    _balances[dst] = add(_balances[dst],wad);

    //转账事件
    Transfer(src, dst, wad);

    return true;
  }

  //-----------------------------------------------
  // 设置转账限额
  //-----------------------------------------------
  // @param  dst 目标帐户地址
  // @param  wad 限制金额
  //-----------------------------------------------
  function approve(address dst, uint256 wad) public returns (bool)
  {
    _allowance[msg.sender][dst] = wad;

    //设置事件
    Approval(msg.sender, dst, wad);
    return true;
  }

  //-----------------------------------------------
  // 账户转账带附加数据
  //-----------------------------------------------
  // @param  dst  目标帐户地址
  // @param  wad  限制金额
  // @param  data 附加数据
  //-----------------------------------------------
  function postMessage(address dst, uint wad,string data) public returns (bool)
  {
    return transfer(dst,wad);
  }

  //-----------------------------------------------
  // 任命新的CFO
  //-----------------------------------------------
  // @param  newCFO 新的CFO帐户地址
  //-----------------------------------------------
  function appointNewCFO(address newCFO) onlyCFO public returns (bool)
  {
    if (newCFO != _cfo)
    {
      _cfo = newCFO;
      return true;
    }
    else
    {
      return false;
    }
  }

  //-----------------------------------------------
  // 冻结帐户
  //-----------------------------------------------
  // @param  dst  目标帐户地址
  // @param  flag 冻结
  //-----------------------------------------------
  function freeze(address dst, bool flag) onlyCFO public returns (bool)
  {
    _frozen[dst] = flag;

    //冻结帐户事件
    FreezeEvent(dst, flag);
    return true;
  }

  //-----------------------------------------------
  // 铸造代币
  //-----------------------------------------------
  // @param  dst  目标帐户地址
  // @param  wad  铸造金额
  //-----------------------------------------------
  function mint(address dst, uint256 wad) onlyCFO public returns (bool)
  {
    //目标帐户地址铸造代币,同时更新总量
    _balances[dst] = add(_balances[dst],wad);
    _supply        = add(_supply,wad);

    //铸造代币事件
    MintEvent(dst, wad);
    return true;
  }

  //-----------------------------------------------
  // 销毁代币
  //-----------------------------------------------
  // @param  dst  目标帐户地址
  // @param  wad  销毁金额
  //-----------------------------------------------
  function melt(address dst, uint256 wad) onlyCFO public returns (bool)
  {
    //检查帐户余额
    require(_balances[dst] >= wad);

    //销毁目标帐户地址代币,同时更新总量
    _balances[dst] = sub(_balances[dst],wad);
    _supply        = sub(_supply,wad);

    //销毁代币事件
    MeltEvent(dst, wad);
    return true;
  }
}