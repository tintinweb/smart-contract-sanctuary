// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);

    }


    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {

            if (b > a) return (false, 0);
            return (true, a - b);

    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {

            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
        
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
 
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {

            if (b == 0) return (false, 0);
            return (true, a / b);
   
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
       
            if (b == 0) return (false, 0);
            return (true, a % b);
        
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
 
            require(b <= a, errorMessage);
            return a - b;
        
    }


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {

            require(b > 0, errorMessage);
            return a / b;
        
    }


    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
     
            require(b > 0, errorMessage);
            return a % b;
        
    }
}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimal() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract ERC20 is IERC20{
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private owner;
    
    constructor(string memory name_, string memory symbol_, uint256 totsupply_, uint8 decimals_) public{
        _name = name_;
        _symbol = symbol_;
        _balances[msg.sender] = totsupply_;
        _totalSupply = totsupply_;
        _decimals = decimals_;
        owner=msg.sender;
    }
    
    modifier onlyOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
     }

    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    
    function symbol() public view virtual override returns (string memory){
        return _symbol;
    }
    
    function decimal() public view virtual override returns (uint8){
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256){
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256){
        return _balances[account];
    }
    
    function transfer(address recipient,uint256 amount) public virtual override returns (bool){
        require(amount <= _balances[msg.sender]);
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function mint(uint256 qnty) public virtual returns (uint256){
        // require(address[msg.sender] != address(0), "ERC20: mint to the zero address");
        _totalSupply +=qnty;
        _balances[msg.sender] += qnty;
        return _totalSupply;
    }
        
    function burn(uint256 qnty) public virtual returns (uint256){
        require(_balances[msg.sender] >= qnty);
        _totalSupply -= qnty;
        _balances[msg.sender] -= qnty;
        return _totalSupply;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256){
        return _allowances[owner][spender];
    }
    
    
    function approve(address spender, uint256 amount) public virtual override returns (bool){
         _approve(msg.sender, spender, amount);
         return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool){
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(_balances[sender] >= amount && currentAllowance >= amount);
        _balances[recipient] += amount;
        _balances[sender] -= amount;
        // unchecked{
        //     _approve(sender, msg.sender, currentAllowance-amount);
        // }
        _allowances[sender][msg.sender] -= amount; 
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    
    
}