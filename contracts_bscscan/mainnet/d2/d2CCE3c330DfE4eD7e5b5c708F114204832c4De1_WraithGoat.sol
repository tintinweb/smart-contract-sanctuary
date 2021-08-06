/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

abstract contract IRC71Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner71) public virtual view returns (uint balance);
    function allowance(address tokenOwner71, address spender71) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender71, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner71, address indexed spender71, uint tokens);
}

pragma solidity 0.8.1;

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

pragma solidity 0.8.1;

contract WraithGoat is IRC71Interface, Math {
    string public tokenName71 = "Wraith Goat";
    string public tokenSymbol71 = "WRGO";
    uint public _tokenSupply71 = 5*10**9 * 10**9;

    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        _balances[msg.sender] = _tokenSupply71;
        emit Transfer(address(0), msg.sender, _tokenSupply71);
    }
    
     function name() public view virtual returns (string memory) {
        return tokenName71;
    }


    function symbol() public view virtual returns (string memory) {
        return tokenSymbol71;
    }


    function decimals() public view virtual returns (uint8) {
        return 9;
    }

    function totalSupply() public override view returns (uint) {
        return _tokenSupply71;
    }

    function balanceOf(address tokenOwner71) public override view returns (uint balance) {
        return _balances[tokenOwner71];
    }

    function allowance(address tokenOwner71, address spender71) public override view returns (uint remaining) {
        return allowed[tokenOwner71][spender71];
    }
    
   function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "IRC71: transfer from the zero address");
        require(recipient != address(0), "IRC71: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "IRC71: transfer amount exceeds balance");
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

    function approve(address spender71, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender71] = tokens;
        emit Approval(msg.sender, spender71, tokens);
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