/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

    abstract contract BP20 {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Math {
    function Add(uint fi1, uint fi2) public pure returns (uint fi3) {
        fi3 = fi1 + fi2;
        require(fi3 >= fi1);
    }
    function Sub(uint fi1, uint fi2) public pure returns (uint fi3) {
        require(fi2 <= fi1);
        fi3 = fi1 - fi2;
    }
    function Mul(uint fi1, uint fi2) public pure returns (uint fi3) {
        fi3 = fi1 * fi2;
        require(fi1 == 0 || fi3 / fi1 == fi2);
    }
    function Div(uint fi1, uint fi2) public pure returns (uint fi3) {
        require(fi2 > 0);
        fi3 = fi1 / fi2;
    }
   function safeAdd(uint fi1, uint fi2) public pure returns (uint fi3) {
        fi3 = fi1 + fi2;
        require(fi3 >= fi1);
    }
    function safeSub(uint fi1, uint fi2) public pure returns (uint fi3) {
        require(fi2 <= fi1);
        fi3 = fi1 - fi2;
    }
    function safeMul(uint fi1, uint fi2) public pure returns (uint fi3) {
        fi3 = fi1 * fi2;
        require(fi1 == 0 || fi3 / fi1 == fi2);
    }
    function safeDiv(uint fi1, uint fi2) public pure returns (uint fi3) {
        require(fi2 > 0);
        fi3 = fi1 / fi2;
    }
   
}

contract IronBar is BP20, Math {
    string public name =  "Iron Bar";
    string public symbol =  "IRON";
    uint8 public decimals = 9;
    uint public _totalSupply = 1*10**13 * 10**9;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    


    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEfi20: transfer from the zero address");
        require(recipient != address(0), "BEfi20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "BEfi20: transfer amount exceeds balance");
        unchecked {
            balances[sender] = senderBalance - amount;
        }
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        allowed[from][msg.sender] = Sub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


}