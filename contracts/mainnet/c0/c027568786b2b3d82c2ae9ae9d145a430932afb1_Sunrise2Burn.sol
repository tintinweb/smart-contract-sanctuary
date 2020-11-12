/*
  _________                  .__                             __   
 /   _____/__ __  ___________|__| ______ ____   ____   _____/  |_ 
 \_____  \|  |  \/    \_  __ \  |/  ___// __ \ /    \_/ __ \   __\
 /        \  |  /   |  \  | \/  |\___ \\  ___/|   |  \  ___/|  |  
/_______  /____/|___|  /__|  |__/____  >\___  >___|  /\___  >__|  
        \/           \/              \/     \/     \/     \/      
https://Sunrisenet.finance
SPDX-License-Identifier: MIT
*/

pragma solidity ^0.5.0;

//====================================
//Sunrisenet.finance
//=====================================
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

//====================================
//Sunrisenet.finance
//=====================================

contract ERC20Detailed is IERC20 {

  uint8 public _Tokendecimals;
  string public _Tokenname;
  string public _Tokensymbol;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
   
    _Tokendecimals = decimals;
    _Tokenname = name;
    _Tokensymbol = symbol;
    
  }

  function name() public view returns(string memory) {
    return _Tokenname;
  }

  function symbol() public view returns(string memory) {
    return _Tokensymbol;
  }

  function decimals() public view returns(uint8) {
    return _Tokendecimals;
  }
}


//====================================
//Sunrisenet.finance
//=====================================

contract Sunrise2Burn is ERC20Detailed {

  uint256 _totalSupply = 100000000000000000000000;
  
  using SafeMath for uint256;
  mapping (address => uint256) public _Burn2MoonTokenBalances;
  mapping (address => mapping (address => uint256)) public _allowed;
  string constant tokenName = "Sunrisenet finance";
  string constant tokenSymbol = "SRN";
  uint8  constant tokenDecimals = 18;
  
  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _start(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _Burn2MoonTokenBalances[owner];
  }


  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _Burn2MoonTokenBalances[msg.sender]);
    require(to != address(0));

    uint256 Burn2MoonTokenDecay = value.div(10);
    uint256 tokensToTransfer = value.sub(Burn2MoonTokenDecay);

    _Burn2MoonTokenBalances[msg.sender] = _Burn2MoonTokenBalances[msg.sender].sub(value);
    _Burn2MoonTokenBalances[to] = _Burn2MoonTokenBalances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(Burn2MoonTokenDecay);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), Burn2MoonTokenDecay);
    return true;
  } 

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _Burn2MoonTokenBalances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _Burn2MoonTokenBalances[from] = _Burn2MoonTokenBalances[from].sub(value);

    uint256 Burn2MoonTokenDecay = value.div(10);
    uint256 tokensToTransfer = value.sub(Burn2MoonTokenDecay);

    _Burn2MoonTokenBalances[to] = _Burn2MoonTokenBalances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(Burn2MoonTokenDecay);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), Burn2MoonTokenDecay);

    return true;
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

  function _start(address account, uint256 amount) internal {
    require(amount != 0);
    _Burn2MoonTokenBalances[account] = _Burn2MoonTokenBalances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _Burn2MoonTokenBalances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _Burn2MoonTokenBalances[account] = _Burn2MoonTokenBalances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
  
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}