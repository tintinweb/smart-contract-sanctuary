/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

pragma solidity ^ 0.5.16;
//————————————————————————————————————————————————————————
//基本功能「转账」「查询地址余额」「选择委托人」「委托转账」
//特别功能「更改合约所有者」「销毁代币」「信任支付」
//代币安全「安全计算」「冻结交易」「地址黑名单」
//使用指南：把代币名字改成自己喜欢的名字
//遇到问题联系作者，作者是将要大二的学生，足够亲近。
//————————————————————————————————————————————————————————
//保证合约做计算时的安全，如下
library SafeMath {
  function add(uint a, uint b) internal pure returns(uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns(uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns(uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns(uint c) {
    require(b > 0);
    c = a / b;
  }
}
//使用ERC20标准，如下
contract ERC20Interface {
  function totalSupply() public view returns(uint);
  function balanceOf(address tokenOwner) public view returns(uint balance);
  function allowance(address tokenOwner, address spender) public view returns(uint remaining);
  function transfer(address to, uint tokens) public returns(bool success);
  function approve(address spender, uint tokens) public returns(bool success);
  function transferFrom(address from, address to, uint tokens) public returns(bool success);
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
//该操作介绍
contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}
//合约owner，以及退位让贤设置newowner
contract Owned {
  address public owner;
  event OwnershipTransferred(address indexed _from, address indexed _to);
  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
  }
}
//冻结所有SUIBE交易功能
contract Tokenlock is Owned {
  uint8 isLocked = 0;
  event Freezed();
  event UnFreezed();
  modifier validLock {
    require(isLocked == 0);
    _;
  }
  function freeze() public onlyOwner {
    isLocked = 1;
    emit Freezed();
  }
  function unfreeze() public onlyOwner {
    isLocked = 0;
    emit UnFreezed();
  }
}
//用户黑名单功能
contract UserLock is Owned {
  mapping(address => bool) blacklist;
  event LockUser(address indexed who);
  event UnlockUser(address indexed who);
  modifier permissionCheck {
    require(!blacklist[msg.sender]);
    _;
  }
  function lockUser(address who) public onlyOwner {
    blacklist[who] = true;
    emit LockUser(who);
  }
  function unlockUser(address who) public onlyOwner {
    blacklist[who] = false;
    emit UnlockUser(who);
  }
}
//「需要部署」，创建代币合约，功能已写在function前
contract WZGLToken is ERC20Interface, Tokenlock, UserLock {
  using SafeMath for uint;
  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  mapping(address => uint) balances;
  mapping(address => mapping(address => uint256)) public allowed;
  constructor() public {
    symbol = "WZGL";
    name = "WZGL";//代币名
    decimals = 18;//小数位数
    _totalSupply = 100000000000000000000000000;//发行总量
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }
  //查询目前WZGL存量（减去销毁）
  function totalSupply() public view returns(uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  //输入地址，查询余额
  function balanceOf(address tokenOwner) public view returns(uint balance) {
    return balances[tokenOwner];
  }
  //输入目标地址，金额，进行转账
  function transfer(address to, uint tokens) public validLock permissionCheck returns(bool success) {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  //输入委托人地址，输入委托金额，进行委托操作
  //「委托人可以自由的动用你的账户中被委托的金额」
  function approve(address spender, uint tokens) public validLock permissionCheck returns(bool success) 
  {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  //「委托人特权」输入托付者地址，转账地址，转账金额。进行委托转账
  //「信任保证」
  function transferFrom(address _from, address to, uint tokens) public validLock permissionCheck 
  returns(bool success) {
    balances[_from] = balances[_from].sub(tokens);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(_from, to, tokens);
    return true;
  }
  //输入托付人地址，委托人地址，查询剩余委托金额
  function allowance(address tokenOwner, address spender) public view returns(uint remaining) {
    return allowed[tokenOwner][spender];
  }
  //「销毁操作」销毁自己拥有的WZGL，WZGL总量也会减少
  function burn(uint256 value) public validLock permissionCheck returns(bool success) {
    require(msg.sender != address(0));
    _totalSupply = _totalSupply.sub(value);
    balances[msg.sender] = balances[msg.sender].sub(value);
    emit Transfer(msg.sender, address(0), value);
    return true;
  }
  //信任支付
  function approveAndCall(address spender, uint tokens, bytes memory data) public validLock 
  permissionCheck returns(bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  //错误转账回调
  function () external payable {
    revert();
  }
  //owner地址支持接受其他ERC20代币
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns(bool 
success) {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }
}