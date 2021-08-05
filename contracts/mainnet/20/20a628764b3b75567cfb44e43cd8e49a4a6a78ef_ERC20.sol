/**
 *Submitted for verification at Etherscan.io on 2021-01-09
*/

pragma solidity >=0.6.0 <0.8.0;
  
// SPDX-License-Identifier: MIT
// @title ERC20 Token
// @created_by_ken

library Math { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a, "Subtraction overflow");
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a, "Addition overflow");
      return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }
}


abstract contract Ownable {
    address private _owner;
    address private _newOwner;
    
    event OwnerShipTransferred(address indexed oldOwner, address indexed newOwner);
    
    constructor() {
        _owner = msg.sender;
        _newOwner = msg.sender;
        emit OwnerShipTransferred(address(0), _owner);
    }
    
    function owner() public view returns(address){
        return _owner;
    }
    
    modifier onlyOwner(){
        require(msg.sender == _owner, 'You are not the owner');
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0), 'Invalid address');
        _newOwner = newOwner;
    }
    
    function acceptOwnerShip()public{
        require(msg.sender == _newOwner, 'You are not the new owner');
        _transferOwnership(_newOwner);
    }
    
    function _transferOwnership(address newOwner) internal{
        emit OwnerShipTransferred(_owner,newOwner);
        _owner = newOwner;
    }
}
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


contract ERC20 is IERC20, Ownable{
    using Math for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    
    constructor (string memory name_, string memory symbol_, uint256 totalSupply_, uint8 decimals_)  {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_.mul(10 ** decimals_);
        _decimals = decimals_;
        _balances[msg.sender] = _balances[msg.sender].add(_totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
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
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowed[owner][spender];
    }
    
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(value));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(value));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal{
        require(sender != address(0), "Sender Invalid address");
        require(recipient != address(0), "Recipient Invalid Address");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal{
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function burn(uint256 value) public onlyOwner {
        require(msg.sender != address(0), 'Invalid account address');
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(msg.sender, address(0), value);
    }

    
}