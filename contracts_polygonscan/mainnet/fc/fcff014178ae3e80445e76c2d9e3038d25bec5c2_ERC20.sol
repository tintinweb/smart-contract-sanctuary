/**
 *Submitted for verification at polygonscan.com on 2021-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface I721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokenIdOf(address contract_) external view returns (uint256 tokenId);
    function setMyUri(uint256 tokenId, string memory uri_) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    
    address private _maker;

    string private _name;
    string private _symbol;

    constructor(address maker_) {
        _maker = maker_;
    }
   
    modifier onlyOwner() {
       require(msg.sender == I721(_maker).ownerOf(I721(_maker).tokenIdOf(address(this))),"Caller is not the owner");
        _;
    }
    
    function setNameAndSymbol(string memory name_, string memory symbol_) public onlyOwner() {
        _name = name_;
        _symbol = symbol_;
    }

    function mintERC20Tokens(address to, uint256 amount) public onlyOwner() {
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function setUri(string memory uri_) public onlyOwner() {
        I721(_maker).setMyUri(I721(_maker).tokenIdOf(address(this)), uri_);
    }
    
    function getUri() public view returns (string memory) {
        return I721(_maker).tokenURI(I721(_maker).tokenIdOf(address(this)));
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

   function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    
     function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}