// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./access.sol";
import "./pausable.sol";


contract Junca is IERC20, Access, Pausable {
    using SafeMath for uint256;
    
    string private _name = "junca cash";
    string private _symbol = "JCC";
    uint8 private _decimals = 18;

    uint256 private _totalSupply;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    constructor () public {
        uint256 amount = 130000000 * (uint256(10) ** decimals());
        _mint(_msgSender(), amount);
    }
    
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function balanceOf(address account) override public view returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function transfer(address recipient, uint256 amount) override public notPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) override public notPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "JCC: transfer amount exceeds allows"));
        return true;
    }
    
    function approve(address spender, uint256 amount) override public notPaused returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 sumValue) public notPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(sumValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subValue) public notPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subValue, "JCC: decreased allowance zero value"));
        return true;
    }
    
    function mint(address account, uint256 amount) public isAuthorizer returns (bool) {
        _mint(account, amount);
        return true;
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
    
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "JCC: transfer from zero address");
        require(recipient != address(0), "JCC: transfer to zero address");
        
        _balances[sender] = _balances[sender].sub(amount, "JCC: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "JCC: approve from zero address");
        require(spender != address(0), "JCC: approve to zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "JCC: mint to zero address");
        
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "JCC: burn from the zero address");
        
        _balances[account] = _balances[account].sub(amount, "JCC: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        
        emit Transfer(account, address(0), amount);
    }
    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(_msgSender(), account, amount);
    }

    function destruct() public isPaused isAuthorizer { 
        selfdestruct(msg.sender); 
    }
    
}