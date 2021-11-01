pragma solidity 0.5.16;

import "IBEP20.sol";
import "Context.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "Integer.sol";

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