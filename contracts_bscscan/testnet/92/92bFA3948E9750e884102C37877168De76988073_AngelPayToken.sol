// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./settings.sol";
import "./balance.sol";

contract AngelPayToken is Context, IBEP20, Ownable,Balance {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  
  
  //uint8 private _devf;
  //uint8 private _markf;
  
  //address  dev = 0xDaEB888B857b0a424366b336C32A61f33d3Ee965;
  //address mark = 0x268bb15831DaAF236ACA0c150fAddB91B10627a8;
  //address char = 0xc652d594557F27249c330af236a4061a2f5020e4;

  constructor() {
    _name = "Atest4";
    _symbol = "Atest4";
    _decimals = 10;
    //_totalSupply = 100000000 * 10**_decimals;
    _totalSupply = 46000000 * 10**_decimals;
    _balances[msg.sender] = _totalSupply;
    
    //_devf=2;
    //_markf=2;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function getOwner() public override view returns (address) {
     return owner();
  }
   
  function decimals() public override view returns (uint8) {
     return _decimals;
  }

  function symbol() public override view returns (string memory) {
     return _symbol;
  }

  function name() public override view returns (string memory) {
     return _name;
  }

  function totalSupply() public override view returns (uint256) {
     return _totalSupply;
  }

  function balanceOf(address account) public override view returns (uint256) {
     return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    if (_msgSender()!=getOwner() || getWhitelist(_msgSender())){
            _burn(_msgSender(),amount.mul(getBuyBurning()).div(10**2));
            _transfer(_msgSender(), getDevAddress(), amount.mul(getDevFee()).div(10**2));
            _transfer(_msgSender(), getMarkAddress(), amount.mul(getMarkFee()).div(10**2));
            _transfer(_msgSender(), getCharityAddress(), amount.mul(getCharityFee()).div(10**2));
            _transfer(_msgSender(), recipient, amount.sub(amount.mul(getBuyBurning()+getDevFee()+getMarkFee()+getCharityFee()).div(10**2)));
            return true;
    }else{
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
  }
    
  function allowance(address owner, address spender) public override view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    if (_msgSender()!=getOwner() || getWhitelist(_msgSender())){
            _burn(sender,amount.mul(getSellBurning()).div(10**2));
            _transfer(sender, getDevAddress(), amount.mul(getDevFee()).div(10**2));
            _transfer(sender, getMarkAddress(), amount.mul(getMarkFee()).div(10**2));
            _transfer(sender, getCharityAddress(), amount.mul(getCharityFee()).div(10**2));
            _transfer(sender, recipient, amount.sub(amount.mul(getBuyBurning()+getDevFee()+getMarkFee()+getCharityFee()).div(10**2)));
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
            return true;
    }else{
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }
  
  function mint(address account, uint256 amount) public returns (bool) {
    require(depositStateTeam[msg.sender]);
    _mint(_msgSender(), amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }
  
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, 0x000000000000000000000000000000000000dEaD, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
  
}