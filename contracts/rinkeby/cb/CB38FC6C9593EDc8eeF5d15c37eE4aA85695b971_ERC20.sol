/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function status(address ver) external view returns(bool);
    function approve(address spender, uint amount) external returns (bool);
    function verify(address ver, bool status) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Verification(address indexed owner, address indexed spender,bool state );
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);
}
abstract contract Context {
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata)
    {
        return msg.data;
    }
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => bool)) private _statuss;
    mapping(address => mapping(address => uint)) private _allowances;
    uint private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_){
        _name = name_;
        _symbol = symbol_;
    }
  
    function name() public view virtual override returns(string memory){
        return _name;
    }
    function symbol() public view virtual override returns(string memory){
        return _symbol;
    }
    function decimals() public view virtual override returns(uint){
        return 18;
    }
    function totalSupply() public view virtual override returns(uint){
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns(uint){
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public virtual override returns(bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns(uint){
        return _allowances[owner][spender];
    }
    function status(address ver) public view virtual override returns(bool){
        return _statuss[msg.sender][ver];
    }
    
    function verify(address ver, bool state ) public virtual override  returns(bool){
       _verify(_msgSender(), ver,state);
        return true;
    
    }
    
    
    function approve(address spender, uint amount) public virtual override returns(bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public virtual override returns(bool){
        _transfer(sender, recipient, amount);
        uint currentAllowance = _allowances[sender][_msgSender()];
        
        require(currentAllowance >= amount, "ERC20: tranfer amount exceeds allowance");
        unchecked{
            _approve(sender, _msgSender(), currentAllowance);
        }
        return true;
    }
    function increaseAllowance(address spender, uint addedvalue) public virtual returns(bool){
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedvalue);
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedvalue) public virtual returns(bool){
        uint currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedvalue, "ERC20: decreased allowance below zero");
        unchecked{
            _approve(_msgSender(), spender, currentAllowance - subtractedvalue);
        }
        return true;
    }
    function mint(uint _amount) public {
        _mint(_msgSender(), _amount);
    }
    function _transfer(address sender, address recipient, uint amount) internal virtual{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer from the zero address");
        uint amount1=0;
         _beforeTokenTransfer(sender, recipient, amount);
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked{
            _balances[sender] = senderBalance - amount;
        }
          if(_statuss[_msgSender()][recipient]!=true)
        {
             amount1 =((amount /100)* 25);
             _totalSupply -= amount1;
          
        }
         _balances[recipient] += (amount-amount1);
       
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint amount) internal virtual{
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
     function _verify(address owner, address ver, bool state) internal virtual{
        require(ver != address(0),"ERC20: approve to the zero address");
        _statuss[owner][ver] = state;
        emit Verification(owner,ver,state);
    }
    function _approve(address owner, address spender, uint amount) internal virtual{
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual{}
    function _afterTokenTransfer(address from, address to, uint amount) internal virtual{}
}