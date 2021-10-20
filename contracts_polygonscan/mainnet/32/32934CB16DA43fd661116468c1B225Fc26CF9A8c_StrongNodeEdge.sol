// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IMRC20 {

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);

    uint256 c = a / b;

    return c;
  }


  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }


  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract StrongNodeEdge is Context, IMRC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping(address => bool) private bots;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  address public presaleWallet = 0x87ca15a9f35c25F8adDE03Ab5176cD7f5b819A5e;
  address public stakingWallet = 0x6CFaF90A077cFF2d25586d756EF0826Af5b0BF44;
  address public operationsWallet = 0x4A6Ef7eCD34ffAb671feaC44E3A62B6Db3F83829; 
  address public teamWallet = 0x9d1Dccd20F334E2e7a80Fb67f01975A581Fc2C20;
  address public treasuryWallet = 0x568153dd1BeD99F55ef9D623732f52cF39F4A976;
  address public marketingWallet = 0x9A967fF7dA3916bEb6BAc084990f2549315DE715;
  address public advisorWallet = 0xAAB4107f0c0E95c871B781Be9A33D41966866Db2;
  address public publicsaleWallet = 0x6712D6A3ED575a7F41bB545Ea92D3D0E451EfaC3;

  constructor() {
    _name = "StrongNodeEdge Token";
    _symbol = "SNE";
    _decimals = 18;
    _totalSupply = 10**10 * 10**18; 


    uint256 presaleTokens = _totalSupply.mul(19).div(100);

    uint256 stakingTokens = _totalSupply.mul(15).div(100);

    uint256 operationTokens = _totalSupply.mul(15).div(100);

    uint256 teamTokens = _totalSupply.mul(14).div(100);

    uint256 treasuryTokens = _totalSupply.mul(10).div(100);

    uint256 marketingTokens = _totalSupply.mul(7).div(100);

    uint256 advisorTokens = _totalSupply.mul(4).div(100);

    uint256 publicsaleTokens = _totalSupply.mul(2).div(100);

    uint256 liquidityTokens = _totalSupply.sub(presaleTokens).sub(stakingTokens).sub(operationTokens).sub(teamTokens);
                          
    liquidityTokens = liquidityTokens.sub(treasuryTokens).sub(marketingTokens).sub(advisorTokens).sub(publicsaleTokens);
    
    _balances[presaleWallet] = presaleTokens;
    _balances[stakingWallet] = stakingTokens;
    _balances[operationsWallet] = operationTokens;
    _balances[teamWallet] = teamTokens;
    _balances[treasuryWallet] = treasuryTokens;
    _balances[marketingWallet] = marketingTokens;
    _balances[advisorWallet] = advisorTokens;
    _balances[publicsaleWallet] = publicsaleTokens;
    _balances[_msgSender()] = liquidityTokens;
    
    emit Transfer(
      address(0),
      presaleWallet,
      presaleTokens
    );

    emit Transfer(
      address(0),
      stakingWallet,
      stakingTokens
    );

    emit Transfer(
      address(0),
      operationsWallet,
      operationTokens
    );

    emit Transfer(
      address(0),
      teamWallet,
      teamTokens
    );

    emit Transfer(
      address(0),
      treasuryWallet,
      treasuryTokens
    );

    emit Transfer(
      address(0),
      marketingWallet,
      marketingTokens
    );

    emit Transfer(
      address(0),
      advisorWallet,
      advisorTokens
    );

    emit Transfer(
      address(0),
      publicsaleWallet,
      publicsaleTokens
    );

    emit Transfer(
      address(0),
      _msgSender(),
      liquidityTokens
    );
  }

  function getOwner() external override view returns (address) {
    return owner();
  }

  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  function name() external override view returns (string memory) {
    return _name;
  }

  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "MRC20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "MRC20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(!bots[sender] && !bots[recipient], "ERR: banned transfer");
    require(sender != address(0), "MRC20: transfer from the zero address");
    require(recipient != address(0), "MRC20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "MRC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

 
  function setBotAddress(address _botAddress, bool isBot) public onlyOwner {
      bots[_botAddress] = isBot;
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "MRC20: approve from the zero address");
    require(spender != address(0), "MRC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}