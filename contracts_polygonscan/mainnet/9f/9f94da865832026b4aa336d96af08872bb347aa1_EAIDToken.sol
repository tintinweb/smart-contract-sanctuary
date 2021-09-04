/**
 *Submitted for verification at polygonscan.com on 2021-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract ERC20 is Context, IERC20,Ownable, IERC20Metadata {
    
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 public _burnFee = 2;
    uint256 public _previous_burnFee = _burnFee;
    uint256 public _redistributionFee = 2;
    uint256 public _previousredistributionFee = _redistributionFee;

    uint256 public _liquidityFee = 1;
    uint256 public _previousliquidityFee = _liquidityFee;
    mapping (address => bool) private _isExcluded;

    address public constant REDISTRIBUTION_USER = 0x16389FCd78423a0Ca099941EB97681d7EafB21fC;
    address public constant LIQUIDITY_USER = 0xc8E37f116980655305D0f07b53aa752BA3d3496C;
    address public constant DEAD_USER = 0x000000000000000000000000000000000000dEaD;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 TokentoDeduct =amount;
		uint256 TokentoRedistribution =0;
        uint256 TokentoBurn =0;
        uint256 TokentoLiquidity =0;
        if(!isExcludedFromFee(sender))
        {
            TokentoRedistribution=amount.mul(_redistributionFee).div(10**2);
            TokentoBurn=amount.mul(_burnFee).div(10**2);
            TokentoLiquidity=amount.mul(_liquidityFee).div(10**2);
            amount = amount.sub(TokentoRedistribution).sub(TokentoBurn).sub(TokentoLiquidity);
            emit Transfer(sender, REDISTRIBUTION_USER, TokentoRedistribution);
            emit Transfer(sender, DEAD_USER, TokentoBurn);
            emit Transfer(sender, LIQUIDITY_USER, TokentoLiquidity);
			_balances[REDISTRIBUTION_USER] += TokentoRedistribution;
			_balances[DEAD_USER] += TokentoBurn;
			_balances[LIQUIDITY_USER] += TokentoLiquidity;
        }
        _balances[sender] = senderBalance - TokentoDeduct;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcluded[account];
      }
      

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        //_totalSupply -= amount;

        emit Transfer(account, DEAD_USER, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function excludeFromFee(address account) public onlyOwner {
      _isExcluded[account] = true;
    }
    function includeInFee(address account) public onlyOwner {
      _isExcluded[account] = false;
    }
    function setRedistributionFee(uint256 redistributionFee) external onlyOwner() {
      _redistributionFee = redistributionFee;
    }
    function setBurnFee(uint256 burnFee) external onlyOwner() {
      _burnFee = burnFee;
    }
    function setLiquidityFee(uint256 liquidityFee) external onlyOwner() {
      _liquidityFee = liquidityFee;
    }
    
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

abstract contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract EAIDToken is ERC20Burnable, ReentrancyGuard {

    constructor() ERC20("Ekart Aid", "EAID") {
        _mint(owner(), (10**10) * (10**9));
		excludeFromFee(owner());
    }

    function extractLostCrypto() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function extractLostToken(address tokenToExtract) external nonReentrant onlyOwner {
        IERC20(tokenToExtract).transfer(owner(), IERC20(tokenToExtract).balanceOf(address(this)));
    }
}