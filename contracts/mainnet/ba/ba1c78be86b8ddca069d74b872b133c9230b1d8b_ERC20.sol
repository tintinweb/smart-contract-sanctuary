pragma solidity ^0.4.8;

library BobbySafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a==0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BobbyERC20Base {

  //可以执行暂停操作的权限
  address public ceoAddress;

  //是否暂停智能合约的运行
  bool public paused = false;

  constructor()  {
    ceoAddress = msg.sender;
  }

  modifier onlyCEO() {
     require(msg.sender == ceoAddress);
    _;
  }

 function setCEO(address _newCEO) public onlyCEO {
      require(_newCEO != address(0));
      ceoAddress = _newCEO;
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused {
    require(paused);
    _;
  }

  function pause() external onlyCEO whenNotPaused {
    paused = true;
  }

  function unpause() public onlyCEO whenPaused {
    paused = false;
  }
}

contract ERC20Interface {

  //ERC20指定接口
  event Approval(address indexed src, address indexed guy, uint wad);
  event Transfer(address indexed src, address indexed dst, uint wad);

  function name() public view returns (string name);
  function symbol() public view returns (string symbol);
  function decimals() public view returns (uint8 decimals);
  function totalSupply() public view returns (uint256 totalSupply);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  //扩展接口
  function getBalanceAddr(uint256 _index) public view returns(address addr);
  function getBalance(uint256 _index) public view returns(uint256 tokens);
  function getBalanceSize() public view returns(uint256 size);
}

//Erc智能合约
contract ERC20 is ERC20Interface, BobbyERC20Base {

  using BobbySafeMath for uint256;

  //常量定义
  uint private  _Wei = 1;
  uint private  _Kwei = 1000 * _Wei;
  uint private  _Mwei = 1000 * _Kwei;
  uint private  _Gwei = 1000 * _Mwei;
  uint private  _Bobby = 1000 * 1000 * 1000 * _Gwei;
  uint private  _CurrentBob = 165442393 * _Mwei;

  uint private _Hundred = 100;
  uint private _Thousand = 1000;
  uint private _Billion = _Thousand * _Thousand * _Thousand;

  //代币基本信息
  string private _name = "BOBBY";     //代币名称
  string private _symbol = "BOBBY";   //代币标识
  uint8 private _decimals = 9;        //小数点后位数
  uint256 private _totalSupply = 10 * _Billion * (10 ** uint256(_decimals));

  //解封用户代币结构
  struct userToken {
    uint _index;             //放在数组中的下标
    address _addr;          //用户账号
    uint256 _tokens;        //通证数量
  }
  mapping(address=>userToken) private _balancesMap;           //用户可用代币映射
  address[] _balancesArray;                                   //用户禁封代币数组,from 1

  struct logEntry {
    uint time;
    address from;
    address to;
    uint256 value;
  }
  logEntry[] _logs;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);       //代币转移事件
  event Approval(address indexed _owner, address indexed _spender, uint256 _value); //配额许可事件

  //构造方法，将代币的初始总供给都分配给合约的部署账户。合约的构造方法只在合约部署时执行一次
  constructor() {
    _balancesArray.push(address(0));

    //此处需要注意，请使用CEO的地址,因为初始化后，将会使用这个地址作为CEO地址
    //注意，一定要使用memory类型，否则，后面的赋值会影响其它成员变量
    userToken memory userCEO;
    userCEO._index = _balancesArray.length;
    userCEO._addr = msg.sender;
    userCEO._tokens = _totalSupply;
    _balancesArray.push(msg.sender);
    _balancesMap[msg.sender] = userCEO;
  }

  //返回合约名称。view关键子表示函数只查询状态变量，而不写入
  function name() public view returns (string name){
    name = _name;
  }

  //返回合约标识符
  function symbol() public view returns (string symbol){
    symbol = _symbol;
  }

  //返回合约小数位
  function decimals() public view returns (uint8 decimals){
    decimals = _decimals;
  }

  //返回合约总供给额
  function totalSupply() public view returns (uint256 totalSupply){
    totalSupply = _totalSupply;
  }

  function getBalanceAddr(uint256 _index) public view returns(address addr){
    require(_index < _balancesArray.length);
    require(_index >= 0);
    addr = _balancesArray[_index];
  }

  function getBalance(uint256 _index) public view returns(uint256 tokens){
    require(_index < _balancesArray.length);
    require(_index >= 0);
    tokens = _balancesMap[_balancesArray[_index]]._tokens;
  }

  function getBalanceSize() public view returns(uint256 size){
    size = _balancesArray.length;
  }

  function log(address from, address to, uint256 value) public {
    logEntry memory entry;
    entry.time = now;
    entry.from = from;
    entry.to = to;
    entry.value = value;
    _logs.push(entry);
  }

  function getLogSize() public view returns(uint256 size){
    size = _logs.length;
  }

  function getLog(uint256 _index) public view returns(uint time, address from, address to, uint256 value){
    require(_index < _logs.length);
    require(_index >= 0);
    logEntry entry = _logs[_index];
    time = entry.time;
    from = entry.from;
    to = entry.to;
    value = entry.value;
  }

  //查询账户_owner的账户余额
  function balanceOf(address _owner) public view returns (uint256 balance){
    balance = _balancesMap[_owner]._tokens;
  }

  function addBalance(address _addr, uint256 _value) private{
    _balancesMap[_addr]._tokens = _balancesMap[_addr]._tokens.add(_value);
  }

  function subBalance(address _addr, uint256 _value) private{
    _balancesMap[_addr]._tokens = _balancesMap[_addr]._tokens.sub(_value);
  }

  //从代币合约的调用者地址上转移_value的数量token到的地址_to，并且必须触发Transfer事件
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success){
    require(_balancesMap[msg.sender]._tokens >= _value);
    subBalance(msg.sender, _value);

    uint index = _balancesMap[_to]._index;
    if(index == 0){
      userToken memory user;
      user._index = _balancesArray.length;
      user._addr = _to;
      user._tokens = _value;
      _balancesMap[_to] = user;
      _balancesArray.push(_to);
    }
    else{
      addBalance(_to, _value);
    }

    Transfer(msg.sender, _to, _value);
    log(msg.sender, _to, _value);
    success = true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success){
    success = true;
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success){
    success = true;
  }

  function allowance(address _owner, address _spender) public view whenNotPaused returns (uint256 remaining){
    remaining = 0;
  }
}