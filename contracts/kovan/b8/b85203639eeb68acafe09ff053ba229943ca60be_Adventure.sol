/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-22
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

/*
*  Adventure.sol
*  TWA V1 deflationary community token smart contract
*  2020-09-29
**/

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

abstract contract ERC20Detailed is IERC20 {

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

contract Adventure is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant TOKEN_NAME = "Adventure";
  string constant TOKEN_SYMBOL = "TWA";
  uint8  constant TOKEN_DECIMALS = 18;
  address public twaFoundation;
  address constant public TWA_COMMUNITY = 0x74d5c993a2e9be15bc739168a23106A407860030;
  address constant public TWA_MARKETING_DEV_LIQ = 0x74d5c993a2e9be15bc739168a23106A407860030;
  uint public immutable twaFoundationLockedUntil;
  uint256 _totalSupply = 101000000000000000000000000;
  uint256 constant BASE_PERCENT = 100;

  constructor() public payable ERC20Detailed(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS) {
    twaFoundation = msg.sender;

    _issue(twaFoundation, 30000000000000000000000000);
    _issue(TWA_COMMUNITY, 55000000000000000000000000);
    _issue(TWA_MARKETING_DEV_LIQ, 16000000000000000000000000);
    
    // 24 months is 63115200 seconds
    twaFoundationLockedUntil = now + 10000;
  }

  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) external override view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowed[owner][spender];
  }

  function cut(uint256 value) public pure returns (uint256)  {
    uint256 roundValue = value.ceil(BASE_PERCENT);
    uint256 cutValue = roundValue.mul(BASE_PERCENT).div(10000);
    return cutValue;
  }

  function transfer(address to, uint256 value) external override returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    require(canTransact(msg.sender));

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
  }


  function approve(address spender, uint256 value) external override returns (bool) {
    require(spender != address(0));
    require(canTransact(msg.sender));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
    require(canTransact(from));

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
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
   
  function canTransact(address account) public view returns (bool) {
    if (account != twaFoundation) {
      return true;
    }
    
    if (now < twaFoundationLockedUntil) {
      return false;
    }
    
    return true;
  }
}