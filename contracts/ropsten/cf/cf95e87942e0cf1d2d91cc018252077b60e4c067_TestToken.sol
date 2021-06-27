/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity ^0.8.0;

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

contract TestToken is IBEP20 {
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
        _name = 'TestToken';
        _symbol = 'TST';
        _decimals = 18;
        _totalSupply = 100;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function changeTokenDetails(string memory symbol_, string memory name_) public {
        _symbol = symbol_;
        _name = name_;
    }
    
    function getOwner() external view override returns (address) {
        return _owner;
    }
    

    function decimals() external view override returns (uint8) {
        return _decimals;
    }


    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    

    function name() external view override returns (string memory) {
        return _name;
    }
    

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
    
    function mint(uint256 amount) public returns (bool) {
        require(msg.sender == _owner, "BEP20: not owner");
        _mint(_owner, amount);
        return true;
    } 
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
    
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        uint256 currentAllowance = _allowances[account][msg.sender];
        require(currentAllowance >= amount, 'BEP20: burn amount exceeds allowance');
        _approve(account, msg.sender, currentAllowance - amount);
    }
}