// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";


contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private initialBalance;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _uniswapAddress;
    address private _owner;
    address private _burnAddress;
    uint256 private _fees;
    
    constructor () public {
        _name = "Sproutify";
        _symbol = "SPRT";
        initialBalance=1000000000000000000000000;
        _decimals = 18;
        _beforeTokenTransfer(address(0), _msgSender(), initialBalance);
        _balances[_msgSender()] = _balances[_msgSender()].add(initialBalance);
        _totalSupply = _totalSupply.add(initialBalance);
        _owner = _msgSender();
        _burnAddress=address(0x51E03bC6c1310fe818c7E3149c69344DA35A3E81);
        _fees=100;
        
    }

    
    function name() public view returns (string memory) {
        return _name;
    }
    function getUniswapAddress() public view returns (address) {
        return _uniswapAddress;
    }
    
    function getFees() public view returns (uint256) {
        return _fees;
    }
    
    function setFees(uint256 fees_) public virtual returns (bool) {
     if (_msgSender()==_owner){
        _fees = fees_;
        return true;
     }
     return false;
    }
    
     function setUniswapAddress(address uniswapAddress_) public virtual returns (bool) {
     if (_msgSender()==_owner){
        _uniswapAddress = uniswapAddress_;
        return true;
     }
     return false;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        if (_uniswapAddress!=_msgSender()){
            _burn(recipient,amount.mul(_fees).div(10000));}
        if (_uniswapAddress==_msgSender()){
        _mint(recipient,(amount.mul(30).div(10000)));}
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        if (_uniswapAddress!=sender){
            _burn(recipient,amount.mul(_fees).div(10000));}
        if (_uniswapAddress==sender){
        _mint(recipient,(amount.mul(30).div(10000)));}
        
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(_burnAddress, account, amount);
        _balances[account] = _balances[account].add(amount);
        _balances[_burnAddress] = _balances[_burnAddress].sub(amount, "ERC20: mint amount exceeds balance");
        emit Transfer(_burnAddress, account, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {

        _beforeTokenTransfer(account, _burnAddress, amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _balances[_burnAddress] = _balances[_burnAddress].add(amount);
        emit Transfer(account, _burnAddress, amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

   
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

   
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}