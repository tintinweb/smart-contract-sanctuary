/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

abstract contract BEP20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner58) public virtual view returns (uint balance);
    function allowance(address tokenOwner58, address spender58) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender58, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner58, address indexed spender58, uint tokens);
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

contract PAKISTAN is BEP20Interface, Math {
    string public tokenName59 = "PAKISTAN";
    string public tokenSymbol59 = "PAKISTAN";
    uint public _tokenSupply59 = 1*10**14 * 10**9;

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        _balances[msg.sender] = _tokenSupply59;
        emit Transfer(address(0), msg.sender, _tokenSupply59);
    }
    
     function name() public view virtual returns (string memory) {
        return tokenName59;
    }


    function symbol() public view virtual returns (string memory) {
        return tokenSymbol59;
    }


    function decimals() public view virtual returns (uint8) {
        return 9;
    }

    function totalSupply() public override view returns (uint) {
        return _tokenSupply59;
    }

    function balanceOf(address tokenOwner58) public override view returns (uint balance) {
        return _balances[tokenOwner58];
    }

    function allowance(address tokenOwner58, address spender58) public override view returns (uint remaining) {
        return allowed[tokenOwner58][spender58];
    }
    
   function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
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

    function approve(address spender58, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender58] = tokens;
        emit Approval(msg.sender, spender58, tokens);
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