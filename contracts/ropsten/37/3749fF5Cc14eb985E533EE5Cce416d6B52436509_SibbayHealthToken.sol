pragma solidity ^0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fd999c8b98bd9c9692909f9cd39e9290">[email&#160;protected]</a>
// released under Apache 2.0 licence
// input  /home/henry/learning/git/smartContract/truffle/022-sht/contracts-bak/SibbayHealthToken.sol
// flattened :  Saturday, 17-Nov-18 06:24:45 UTC
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Management is Ownable {

  /**
   * 暂停和取消暂停事件
   * */
  event Pause();
  event Unpause();

  /**
   * 打开锁定期自动释放事件
   * 关闭锁定期自动释放事件
   * 打开强制锁定期自动释放事件
   * */
  event OpenAutoFree(address indexed admin, address indexed who);
  event CloseAutoFree(address indexed admin, address indexed who);
  event OpenForceAutoFree(address indexed admin, address indexed who);

  /**
   * 增加和删除管理员事件
   * */
  event AddAdministrator(address indexed admin);
  event DelAdministrator(address indexed admin);

  /**
   * 合约暂停标志, True 暂停，false 未暂停
   * 锁定余额自动释放开关
   * 强制锁定余额自动释放开关
   * 合约管理员
   * */
  bool public paused = false;
  mapping(address => bool) public autoFreeLockBalance;          // false(default) for auto frce, true for not free
  mapping(address => bool) public forceAutoFreeLockBalance;     // false(default) for not force free, true for froce free
  mapping(address => bool) public adminList;

  /**
   * 构造函数
   * */
  constructor() public {
  }

  /**
   * modifier 要求合约正在运行状态
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * modifier 要求合约暂停状态
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * 要求是管理员
   * */
  modifier whenAdministrator(address who) {
    require(adminList[who]);
    _;
  }

  /**
   * 要求不是管理员
   * */
  modifier whenNotAdministrator(address who) {
    require(!adminList[who]);
    _;
  }

  /**
   * * 暂停合约
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * 取消暂停合约
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

  /**
   * 打开锁定期自动释放开关
   * */
  function openAutoFree(address who) whenAdministrator(msg.sender) public {
    delete autoFreeLockBalance[who];
    emit OpenAutoFree(msg.sender, who);
  }

  /**
   * 关闭锁定期自动释放开关
   * */
  function closeAutoFree(address who) whenAdministrator(msg.sender) public {
    autoFreeLockBalance[who] = true;
    emit CloseAutoFree(msg.sender, who);
  }

  /**
   * 打开强制锁定期自动释放开关
   * 该开关只能打开，不能关闭
   * */
  function openForceAutoFree(address who) onlyOwner public {
    forceAutoFreeLockBalance[who] = true;
    emit OpenForceAutoFree(msg.sender, who);
  }

  /**
   * 添加管理员
   * */
  function addAdministrator(address who) onlyOwner public {
    adminList[who] = true;
    emit AddAdministrator(who);
  }

  /**
   * 删除管理员
   * */
  function delAdministrator(address who) onlyOwner public {
    delete adminList[who];
    emit DelAdministrator(who);
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  /**
   * 账户总余额
   * */
  mapping(address => uint256) balances;

  /**
   * 总供应量
   * */
  uint256 totalSupply_;

  /**
   * 获取总供应量
   * */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {

  // 记录代理账户
  // 第一个address是token的所有者，即被代理账户
  // 第二个address是token的使用者，即代理账户
  mapping (address => mapping (address => uint256)) internal allowed;

  // 代理转账事件
  // spender: 代理
  // from: token所有者
  // to: token接收账户
  // value: token的转账数量
  event TransferFrom(address indexed spender,
                     address indexed from,
                     address indexed to,
                     uint256 value);


  /**
   * 设置代理
   * _spender 代理账户
   * _value 代理额度
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * 查询代理额度
   * _owner token拥有者账户
   * _spender 代理账户
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * 提高代理额度
   * _spender 代理账户
   * _addValue 需要提高的代理额度
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * 降低代理额度
   * _spender 代理账户
   * _subtractedValue 降低的代理额度
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract SibbayHealthToken is StandardToken, Management {

  string public constant name = "Sibbay Health Token"; // solium-disable-line uppercase
  string public constant symbol = "SHT"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase

  /**
   * 常量
   * 单位量, 即1个token有多少wei(假定token的最小单位为wei)
   * */
  uint256 constant internal MAGNITUDE = 10 ** uint256(decimals);

  uint256 public constant INITIAL_SUPPLY = 1000000000 * MAGNITUDE;

  // 设置赎回价格事件
  event SetSellPrice(address indexed admin, uint256 price);
  // 锁定期转账事件
  event TransferByDate(address indexed from, address indexed to, uint256[] values, uint256[] dates);
  event TransferFromByDate(address indexed spender, address indexed from, address indexed to, uint256[] values, uint256[] dates);
  // 关闭赎回事件
  event CloseSell(address indexed who);
  // 赎回事件
  event Sell(address indexed from, address indexed to, uint256 tokenValue, uint256 etherValue);
  // withdraw 事件
  event Withdraw(address indexed who, uint256 etherValue);
  // 添加token到fundAccount账户
  event AddTokenToFund(address indexed who, address indexed from, uint256 value);
  // refresh 事件
  event Refresh(address indexed from, address indexed who);

  /**
   * 将锁定期的map做成一个list
   * value 锁定的余额
   * _next 下个锁定期的到期时间
   * */
  struct Element {
    uint256 value;
    uint256 next;
  }

  /**
   * 账户
   * lockedBalances 锁定余额
   * lockedElement 锁定期余额
   * start_date 锁定期最早到期时间
   * end_date 锁定期最晚到期时间
   * */
  struct Account {
    uint256 lockedBalances;
    mapping(uint256 => Element) lockedElement;
    uint256 start_date;
    uint256 end_date;
  }

  /**
   * 所有账户
   * */
  mapping(address => Account) public accounts;

  /**
   * sellPrice: token 赎回价格, 即1 token的赎回价格是多少wei(wei为以太币最小单位)
   * fundAccount: 特殊资金账户，赎回token，接收购买token资金
   * sellFlag: 赎回标记
   * */
  uint256 public sellPrice;
  address public fundAccount;
  bool public sellFlag;

  /**
   * 需求：owner 每年释放的金额不得超过年初余额的10%
   * curYear:  当前年初时间
   * YEAR:  一年365天的时间
   * vault: owner限制额度
   * VAULT_FLOOR_VALUE: vault 最低限值
   * */
  uint256 public curYear;
  uint256 constant internal YEAR = 365 * 24 * 3600;
  uint256 public vault;
  uint256 constant internal VAULT_FLOOR_VALUE = 10000000 * MAGNITUDE;

  /**
   * 合约构造函数
   * 初始化合约的总供应量
   */
  constructor(address _owner, address _fund) public {
    // 要求_owner, _fund不为0
    require(_owner != address(0));
    require(_fund != address(0));

    // 设置owner, fund
    owner = _owner;
    fundAccount = _fund;

    // 初始化owner是管理员
    adminList[owner] = true;

    // 初始化发行量
    totalSupply_ = INITIAL_SUPPLY;
    balances[owner] = INITIAL_SUPPLY;
    emit Transfer(0x0, owner, INITIAL_SUPPLY);

    /**
     * 初始化合约属性
     * 赎回价格
     * 赎回标记为false
     * */
    sellPrice = 0;
    sellFlag = true;

    /**
     * 初始化owner限制额度
     * 2018/01/01 00:00:00
     * */
    vault = totalSupply_.mul(10).div(100);
    curYear = 1514736000;
  }

  /**
   * fallback函数
   * */
  function () external payable {
  }

  /**
   * modifier 要求开启赎回token
   * */
  modifier whenOpenSell()
  {
    require(sellFlag);
    _;
  }

  /**
   * modifier 要求关闭赎回token
   * */
  modifier whenCloseSell()
  {
    require(!sellFlag);
    _;
  }

  /**
   * 刷新owner限制余额vault
   * */
  function refreshVault(address _who, uint256 _value) internal
  {
    uint256 balance;

    // 只对owner操作
    if (_who != owner)
      return ;
    // 记录balance of owner
    balance = balances[owner];
    // 如果是新的一年, 则计算vault为当前余额的10%
    if (now >= (curYear + YEAR))
    {
      if (balance <= VAULT_FLOOR_VALUE)
        vault = balance;
      else
        vault = balance.mul(10).div(100);
      curYear = curYear.add(YEAR);
    }

    // vault 必须大于等于 _value
    require(vault >= _value);
    vault = vault.sub(_value);
    return ;
  }

  /**
   * 重新计算到期的锁定期余额, 内部接口
   * _who: 账户地址
   * */
  function refreshlockedBalances(address _who, bool _update) internal returns (uint256)
  {
    uint256 tmp_date = accounts[_who].start_date;
    uint256 tmp_value = accounts[_who].lockedElement[tmp_date].value;
    uint256 tmp_balances = 0;
    uint256 tmp_var;

    // 强制自动释放打开则跳过判断，直接释放锁定期余额
    if (!forceAutoFreeLockBalance[_who])
    {
      // 强制自动释放未打开，则判断自动释放开关
      if(autoFreeLockBalance[_who])
      {
        // 自动释放开关未打开(true), 直接返回0
        return 0;
      }
    }

    // 锁定期到期
    while(tmp_date != 0 &&
          tmp_date <= now)
    {
      // 记录到期余额
      tmp_balances = tmp_balances.add(tmp_value);

      // 记录 tmp_date
      tmp_var = tmp_date;

      // 跳到下一个锁定期
      tmp_date = accounts[_who].lockedElement[tmp_date].next;
      tmp_value = accounts[_who].lockedElement[tmp_date].value;

      // delete 锁定期余额
      if (_update)
        delete accounts[_who].lockedElement[tmp_var];
    }

    // return expired balance
    if(!_update)
      return tmp_balances;

    // 修改锁定期数据
    accounts[_who].start_date = tmp_date;
    accounts[_who].lockedBalances = accounts[_who].lockedBalances.sub(tmp_balances);
    balances[_who] = balances[_who].add(tmp_balances);

    // 将最早和最晚时间的标志，都置0，即最初状态
    if (accounts[_who].start_date == 0)
        accounts[_who].end_date = 0;

    return tmp_balances;
  }

  /**
   * 可用余额转账，内部接口
   * _from token的拥有者
   * _to token的接收者
   * _value token的数量
   * */
  function transferAvailableBalances(
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    // 检查可用余额
    require(_value <= balances[_from]);

    // 修改可用余额
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);

    // 触发转账事件
    if(_from == msg.sender)
      emit Transfer(_from, _to, _value);
    else
      emit TransferFrom(msg.sender, _from, _to, _value);
  }

  /**
   * 锁定余额转账，内部接口
   * _from token的拥有者
   * _to token的接收者
   * _value token的数量
   * */
  function transferLockedBalances(
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    // 检查可用余额
    require(_value <= balances[_from]);

    // 修改可用余额和锁定余额
    balances[_from] = balances[_from].sub(_value);
    accounts[_to].lockedBalances = accounts[_to].lockedBalances.add(_value);
  }

  /**
   * 回传以太币, 内部接口
   * _from token来源账户
   * _to token目标账户
   * _value 为token数目
   * */
  function transferEther(
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    /**
     * 要求 _to 账户接收地址为特殊账户地址
     * 这里只能为return，不能为revert
     * 普通转账在这里返回, 不赎回ether
     * */
    if (_to != fundAccount)
        return ;

    /**
     * 没有打开赎回功能，不能向fundAccount转账
     * */
    require(sellFlag);

    /**
     * 赎回价格必须大于0
     * 赎回的token必须大于0
     * */
    require(_value > 0);

    // 赎回的以太币必须小于账户余额, evalue 单位是wei，即以太币的最小单位
    uint256 evalue = _value.mul(sellPrice).div(MAGNITUDE);
    require(evalue <= address(this).balance);

    // 回传以太币
    if (evalue > 0)
    {
      _from.transfer(evalue);
      emit Sell(_from, _to, _value, evalue);
    }
  }

  /**
   * 取回合约上所有的以太币
   * 只有owner才能取回
   * */
  function withdraw() public onlyOwner {
    uint256 value = address(this).balance;
    owner.transfer(value);
    emit Withdraw(msg.sender, value);
  }

  /**
   * 从from账户向fundAccount添加token
   * */
  function addTokenToFund(address _from, uint256 _value) 
    whenNotPaused
    public
  {
    if (_from != msg.sender)
    {
      // 检查代理额度
      require(_value <= allowed[_from][msg.sender]);

      // 修改代理额度
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    }

    // 刷新vault余额
    refreshVault(_from, _value);

    // 修改可用账户余额
    transferAvailableBalances(_from, fundAccount, _value);
    emit AddTokenToFund(msg.sender, _from, _value);
  }

  /**
   * 转账
   * */
  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    // 不能给地址0转账
    require(_to != address(0));

    /**
     * 获取到期的锁定期余额
     * */
    refreshlockedBalances(msg.sender, true);
    refreshlockedBalances(_to, true);

    // 刷新vault余额
    refreshVault(msg.sender, _value);

    // 修改可用账户余额
    transferAvailableBalances(msg.sender, _to, _value);

    // 回传以太币
    transferEther(msg.sender, _to, _value);

    return true;
  }

  /**
   * 代理转账
   * 代理从 _from 转账 _value 到 _to
   * */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    // 不能向赎回地址发送token
    require(_to != fundAccount);

    // 不能向0地址转账
    require(_to != address(0));

    /**
     * 获取到期的锁定期余额
     * */
    refreshlockedBalances(_from, true);
    refreshlockedBalances(_to, true);

    // 检查代理额度
    require(_value <= allowed[_from][msg.sender]);

    // 修改代理额度
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    // 刷新vault余额
    refreshVault(_from, _value);

    // 修改可用账户余额
    transferAvailableBalances(_from, _to, _value);

    return true;
  }

  /**
   * 设定代理和代理额度
   * 设定代理为 _spender 额度为 _value
   * */
  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  /**
   * 提高代理的代理额度
   * 提高代理 _spender 的代理额度 _addedValue
   * */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  /**
   * 降低代理的代理额度
   * 降低代理 _spender 的代理额度 _subtractedValue
   * */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

  /**
   * 批量转账 token
   * 批量用户 _receivers
   * 对应的转账数量 _values
   * */
  function batchTransfer(
    address[] _receivers,
    uint256[] _values
  )
    public
    whenNotPaused
  {
    // 判断接收账号和token数量为一一对应
    require(_receivers.length > 0 && _receivers.length == _values.length);

    /**
     * 获取到期的锁定期余额
     * */
    refreshlockedBalances(msg.sender, true);

    // 判断可用余额足够
    uint32 i = 0;
    uint256 total = 0;
    for (i = 0; i < _values.length; i ++)
    {
      total = total.add(_values[i]);
    }
    require(total <= balances[msg.sender]);

    // 刷新vault余额
    refreshVault(msg.sender, total);

    // 一一 转账
    for (i = 0; i < _receivers.length; i ++)
    {
      // 不能向赎回地址发送token
      require(_receivers[i] != fundAccount);

      // 不能向0地址转账
      require(_receivers[i] != address(0));

      refreshlockedBalances(_receivers[i], true);
      // 修改可用账户余额
      transferAvailableBalances(msg.sender, _receivers[i], _values[i]);
    }
  }

  /**
   * 代理批量转账 token
   * 被代理人 _from
   * 批量用户 _receivers
   * 对应的转账数量 _values
   * */
  function batchTransferFrom(
    address _from,
    address[] _receivers,
    uint256[] _values
  )
    public
    whenNotPaused
  {
    // 判断接收账号和token数量为一一对应
    require(_receivers.length > 0 && _receivers.length == _values.length);

    /**
     * 获取到期的锁定期余额
     * */
    refreshlockedBalances(_from, true);

    // 判断可用余额足够
    uint32 i = 0;
    uint256 total = 0;
    for (i = 0; i < _values.length; i ++)
    {
      total = total.add(_values[i]);
    }
    require(total <= balances[_from]);

    // 判断代理额度足够
    require(total <= allowed[_from][msg.sender]);

    // 修改代理额度
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(total);

    // 刷新vault余额
    refreshVault(_from, total);

    // 一一 转账
    for (i = 0; i < _receivers.length; i ++)
    {
      // 不能向赎回地址发送token
      require(_receivers[i] != fundAccount);

      // 不能向0地址转账
      require(_receivers[i] != address(0));

      refreshlockedBalances(_receivers[i], true);
      // 修改可用账户余额
      transferAvailableBalances(_from, _receivers[i], _values[i]);
    }
  }

  /**
   * 带有锁定期的转账, 当锁定期到期之后，锁定token数量将转入可用余额
   * _receiver 转账接收账户
   * _values 转账数量
   * _dates 锁定期，即到期时间
   *        格式：UTC时间，单位秒，即从1970年1月1日开始到指定时间所经历的秒
   * */
  function transferByDate(
    address _receiver,
    uint256[] _values,
    uint256[] _dates
  )
    public
    whenNotPaused
  {
    // 判断接收账号和token数量为一一对应
    require(_values.length > 0 &&
        _values.length == _dates.length);

    // 不能向赎回地址发送token
    require(_receiver != fundAccount);

    // 不能向0地址转账
    require(_receiver != address(0));

    /**
     * 获取到期的锁定期余额
     * */
    refreshlockedBalances(msg.sender, true);
    refreshlockedBalances(_receiver, true);

    // 判断可用余额足够
    uint32 i = 0;
    uint256 total = 0;
    for (i = 0; i < _values.length; i ++)
    {
      total = total.add(_values[i]);
    }
    require(total <= balances[msg.sender]);

    // 刷新vault余额
    refreshVault(msg.sender, total);

    // 转账
    for(i = 0; i < _values.length; i ++)
    {
      transferByDateSingle(msg.sender, _receiver, _values[i], _dates[i]);
    }

    emit TransferByDate(msg.sender, _receiver, _values, _dates);
  }

  /**
   * 代理带有锁定期的转账, 当锁定期到期之后，锁定token数量将转入可用余额
   * _from 被代理账户
   * _receiver 转账接收账户
   * _values 转账数量
   * _dates 锁定期，即到期时间
   *        格式：UTC时间，单位秒，即从1970年1月1日开始到指定时间所经历的秒
   * */
  function transferFromByDate(
    address _from,
    address _receiver,
    uint256[] _values,
    uint256[] _dates
  )
    public
    whenNotPaused
  {
    // 判断接收账号和token数量为一一对应
    require(_values.length > 0 &&
        _values.length == _dates.length);

    // 不能向赎回地址发送token
    require(_receiver != fundAccount);

    // 不能向0地址转账
    require(_receiver != address(0));

    /**
     * 获取到期的锁定期余额
     * */
    refreshlockedBalances(_from, true);
    refreshlockedBalances(_receiver, true);

    // 判断可用余额足够
    uint32 i = 0;
    uint256 total = 0;
    for (i = 0; i < _values.length; i ++)
    {
      total = total.add(_values[i]);
    }
    require(total <= balances[_from]);

    // 判断代理额度足够
    require(total <= allowed[_from][msg.sender]);

    // 修改代理额度
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(total);

    // 刷新vault余额
    refreshVault(_from, total);

    // 转账
    for(i = 0; i < _values.length; i ++)
    {
      transferByDateSingle(_from, _receiver, _values[i], _dates[i]);
    }

    emit TransferFromByDate(msg.sender, _from, _receiver, _values, _dates);
  }

  /**
   * _from token拥有者
   * _to 转账接收账户
   * _value 转账数量
   * _date 锁定期，即到期时间
   *       格式：UTC时间，单位秒，即从1970年1月1日开始到指定时间所经历的秒
   * */
  function transferByDateSingle(
    address _from,
    address _to,
    uint256 _value,
    uint256 _date
  )
    internal
  {
    uint256 start_date = accounts[_to].start_date;
    uint256 end_date = accounts[_to].end_date;
    uint256 tmp_var = accounts[_to].lockedElement[_date].value;
    uint256 tmp_date;

    if (_value == 0)
    {
        // 不做任何处理
        return ;
    }

    if (_date <= now)
    {
      // 到期时间比当前早，直接转入可用余额
      // 修改可用账户余额
      transferAvailableBalances(_from, _to, _value);

      return ;
    }

    if (start_date == 0)
    {
      // 还没有收到过锁定期转账
      // 最早时间和最晚时间一样
      accounts[_to].start_date = _date;
      accounts[_to].end_date = _date;
      accounts[_to].lockedElement[_date].value = _value;
    }
    else if (tmp_var > 0)
    {
      // 收到过相同的锁定期
      accounts[_to].lockedElement[_date].value = tmp_var.add(_value);
    }
    else if (_date < start_date)
    {
      // 锁定期比最早到期的还早
      // 添加锁定期，并加入到锁定期列表
      accounts[_to].lockedElement[_date].value = _value;
      accounts[_to].lockedElement[_date].next = start_date;
      accounts[_to].start_date = _date;
    }
    else if (_date > end_date)
    {
      // 锁定期比最晚到期还晚
      // 添加锁定期，并加入到锁定期列表
      accounts[_to].lockedElement[_date].value = _value;
      accounts[_to].lockedElement[end_date].next = _date;
      accounts[_to].end_date = _date;
    }
    else
    {
      /**
       * 锁定期在 最早和最晚之间
       * 首先找到插入的位置
       * 然后在插入的位置插入数据
       * tmp_var 即 tmp_next
       * */
      tmp_date = start_date;
      tmp_var = accounts[_to].lockedElement[tmp_date].next;
      while(tmp_var < _date)
      {
        tmp_date = tmp_var;
        tmp_var = accounts[_to].lockedElement[tmp_date].next;
      }

      // 记录锁定期并加入列表
      accounts[_to].lockedElement[_date].value = _value;
      accounts[_to].lockedElement[_date].next = tmp_var;
      accounts[_to].lockedElement[tmp_date].next = _date;
    }

    // 锁定期转账
    transferLockedBalances(_from, _to, _value);

    return ;
  }

  /**
   * sell tokens
   * */
  function sell(uint256 _value) public whenOpenSell whenNotPaused {
    transfer(fundAccount, _value);
  }

  /**
   * 设置token赎回价格
   * */
  function setSellPrice(uint256 price) public whenAdministrator(msg.sender) {
    require(price > 0);
    sellPrice = price;

    emit SetSellPrice(msg.sender, price);
  }

  /**
   * 关闭购买赎回token
   * */
  function closeSell() public whenOpenSell onlyOwner {
    sellFlag = false;
    emit CloseSell(msg.sender);
  }

  /**
   * 重新计算账号的lockbalance
   * */
  function refresh(address _who) public whenNotPaused {
    refreshlockedBalances(_who, true);
    emit Refresh(msg.sender, _who);
  }

  /**
   * 查询账户可用余额
   * */
  function availableBalanceOf(address _owner) public view returns (uint256) {
    return (balances[_owner] + refreshlockedBalances(_owner, false));
  }

  /**
   * 查询账户总余额
   * */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner] + accounts[_owner].lockedBalances;
  }

  /**
   * 获取锁定余额
   * */
  function lockedBalanceOf(address _who) public view returns (uint256) {
    return (accounts[_who].lockedBalances - refreshlockedBalances(_who, false));
  }

  /**
   * 根据日期获取锁定余额
   * 返回：锁定余额，下一个锁定期
   * */
  function lockedBalanceOfByDate(address _who, uint256 date) public view returns (uint256, uint256) {
    return (accounts[_who].lockedElement[date].value, accounts[_who].lockedElement[date].next);
  }

}