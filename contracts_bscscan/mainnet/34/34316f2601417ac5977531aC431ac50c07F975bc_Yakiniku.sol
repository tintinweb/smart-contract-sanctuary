/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

abstract contract IRC65Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner65) public virtual view returns (uint balance);
    function allowance(address tokenOwner65, address spender65) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender65, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner65, address indexed spender65, uint tokens);
}

pragma solidity 0.8.2;

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

pragma solidity 0.8.2;

contract Yakiniku is IRC65Interface, Math {
    string public tokenName65 = "Yakiniku";
    string public tokenSymbol65 = "Yakiniku";
    uint public _tokenSupply65 = 3*10**12 * 10**9;

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        _balances[msg.sender] = _tokenSupply65;
        emit Transfer(address(0), msg.sender, _tokenSupply65);
    }
    
     function name() public view virtual returns (string memory) {
        return tokenName65;
    }


    function symbol() public view virtual returns (string memory) {
        return tokenSymbol65;
    }


    function decimals() public view virtual returns (uint8) {
        return 9;
    }

    function totalSupply() public override view returns (uint) {
        return _tokenSupply65;
    }

    function balanceOf(address tokenOwner65) public override view returns (uint balance) {
        return _balances[tokenOwner65];
    }

    function allowance(address tokenOwner65, address spender65) public override view returns (uint remaining) {
        return allowed[tokenOwner65][spender65];
    }
    
   function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "IRC65: transfer from the zero address");
        require(recipient != address(0), "IRC65: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "IRC65: transfer amount exceeds balance");
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

    function approve(address spender65, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender65] = tokens;
        emit Approval(msg.sender, spender65, tokens);
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