/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

pragma solidity 0.8.2;
// SPDX-License-Identifier: MIT


contract Math {
    function safeAdd(uint x, uint b) public pure returns (uint y) {
        y = x + b;
        require(y >= x);
    }
    function safeSub(uint x, uint b) public pure returns (uint y) {
        require(b <= x);
        y = x - b;
    }
    function safeMul(uint x, uint b) public pure returns (uint y) {
        y = x * b;
        require(x == 0 || y / x == b);
    }
    function safeDiv(uint x, uint b) public pure returns (uint y) {
        require(b > 0);
        y = x / b;
    }
}

abstract contract Bep20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address ownermacego) public virtual view returns (uint balance);
    function allowance(address ownermacego, address spendermacego) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spendermacego, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed ownermacego, address indexed spendermacego, uint tokens);
}

contract Macego is Bep20Interface, Math {
    string public tokenNamemacego = "Macego";
    string public tokenSymbolmacego = "Macego";
    uint public _tokenSupplymacego = 1*10**11 * 10**9;

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        _balances[msg.sender] = _tokenSupplymacego;
        emit Transfer(address(0), msg.sender, _tokenSupplymacego);
    }
    
     function name() public view virtual returns (string memory) {
        return tokenNamemacego;
    }


    function symbol() public view virtual returns (string memory) {
        return tokenSymbolmacego;
    }


    function decimals() public view virtual returns (uint8) {
        return 9;
    }

    function totalSupply() public override view returns (uint) {
        return _tokenSupplymacego;
    }

    function balanceOf(address ownermacego) public override view returns (uint balance) {
        return _balances[ownermacego];
    }

    function allowance(address ownermacego, address spendermacego) public override view returns (uint remaining) {
        return allowed[ownermacego][spendermacego];
    }
    
   function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Bep20: transfer from the zero address");
        require(recipient != address(0), "Bep20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Bep20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spendermacego, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spendermacego] = tokens;
        emit Approval(msg.sender, spendermacego, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}