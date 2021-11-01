/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

pragma solidity 0.5.16;

interface IBEP20 {
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

contract Context {
  constructor () internal { }
  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }
  function _msgData() internal view returns (bytes memory) {
    this;
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
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

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
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



library Integer {
    function percent(uint256 a, uint256 b) internal pure returns (uint256) {
        return (b * a) / 100;
    }
}

contract OOF1OOBEP20Token is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  using Integer for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  address private _taxWallet;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  uint256 private _valueTax;
  address private _matrixAddress = address(0);
  address private _taxAddress = address(0);

  constructor() public {
    _name = "00F100 Coin";
    _symbol = "00F100";
    _decimals = 2;
    _totalSupply = 34000000;
    _valueTax = 0;
    _balances[msg.sender] = _totalSupply;
    emit Transfer(_matrixAddress, msg.sender, _totalSupply);
  }

  function getOwner() external view returns (address) {
    return owner();
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function balanceOfOwner() external view returns (uint256) {
    return _balances[owner()];
  }
  
  function valueTax() external view returns(uint256) {
      return _valueTax;
  }
  
  function taxAddress() external view returns(address) {
      return _taxAddress;
  }
  
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }
  
  function setValueTax(uint8 value) external onlyOwner returns (bool) {
      _valueTax = value;
      return true;
  }
  
  function setTaxAddress(address tax) external onlyOwner returns (bool) {
      _taxAddress = tax;
      return true;
  }
  
  function setTaxAddress() external onlyOwner returns (bool) {
      _taxAddress = _matrixAddress;
      return true;
  }
  
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }
  
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }
  
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    _transfer(sender, recipient, amount);
    return true;
  }

  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  function burn(uint256 amount) public onlyOwner returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }

  function burnFrom(address account, uint256 amount) public onlyOwner returns (bool) {
    _burnFrom(account, amount);
    return true;
  }
  
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != _matrixAddress, "BEP20: transfer from the zero address");
    require(recipient != _matrixAddress, "BEP20: transfer to the zero address");
    
    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");

    if (_valueTax > 0) {
        uint256 tax = amount.percent(_valueTax);
        amount = amount.sub(tax, "BEP20: Tax exceeds amount");
        if (_taxAddress == _matrixAddress) {
            _totalSupply = _totalSupply.sub(tax, "BEP20: tax amount exceeds total supply");
        } else {
            _balances[_taxAddress] = _balances[_taxAddress].add(tax);
        }
        emit Transfer(sender, _taxAddress, amount);
    }

    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }
  
  function _mint(address account, uint256 amount) internal {
    require(account != _matrixAddress, "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(_matrixAddress, account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != _matrixAddress, "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount, "BEP20: burn amount exceeds total supply");
    emit Transfer(account, _matrixAddress, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != _matrixAddress, "BEP20: approve from the zero address");
    require(spender != _matrixAddress, "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
}