pragma solidity ^0.5.0;

// This is a test token for Tornado Currency, please do not buy or interact with this token.
// REAL TORNADO token goes by ticker TORN and will be listed after the presale. Join our Telegram to participate in the presale.
// TORNADO TELEGRAM: https://t.me/TornadoCurrency
// TORNADO WEBSITE: https://tornadocurrency.com/
// TORNADO TWITTER: https://twitter.com/TornadoCurrency

interface IERC20 {
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

contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
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

contract TornadoTest is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName     = "Tornadocurrency.com";
  string constant tokenSymbol   = "TORNTEST";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply          = 1000000000000000000000000;
  uint256 constant noFee        = 10000000000000000001;

  //2254066
  //uint256 constant startBlock            = 10814854; //2%
  uint256 constant heightEnd20Percent    = 13068920; //1%
  uint256 constant heightEnd10Percent    = 15322986; //0.5%
  uint256 constant heightEnd05Percent    = 17577052; //0.25%

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
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

    function findPercent(uint256 value) public view returns (uint256)  {
        //uint256 roundValue = value.ceil(basePercent);
        uint256 currentRate = returnRate();
        uint256 onePercent  = value.div(currentRate);
        return onePercent;
    }

    function returnRate() public view returns(uint256) {
        if                                       ( block.number < heightEnd20Percent)  return 50;
        if (block.number >= heightEnd20Percent  && block.number < heightEnd10Percent)  return 100;
        if (block.number >= heightEnd10Percent  && block.number < heightEnd05Percent)  return 200;
        if (block.number >= heightEnd05Percent)                                        return 400;
    }



  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    if (value < noFee) {
        _transferBurnNo(to,value);
    } else {
        _transferBurnYes(to,value);
    }

    return true;
  }


  function _transferBurnYes(address to, uint256 value) internal {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    require(value >= noFee);

    uint256 tokensToBurn = findPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
  }

  function _transferBurnNo(address to, uint256 value) internal {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    require(value < noFee);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);

    emit Transfer(msg.sender, to, value);
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

    if (value < noFee) {
        _transferFromBurnNo(from, to, value);
    } else {
        _transferFromBurnYes(from, to, value);
    }

    return true;
  }

function _transferFromBurnYes(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
    require(value >= noFee);

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = findPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);

  }

function _transferFromBurnNo(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
    require(value < noFee);


    _balances[from] = _balances[from].sub(value);
    _balances[to]   = _balances[to].add(value);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, value);

  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}