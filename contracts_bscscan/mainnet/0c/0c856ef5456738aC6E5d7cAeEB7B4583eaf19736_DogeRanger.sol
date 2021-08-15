/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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
    function Add(uint fc1, uint fc2) public pure returns (uint fc3) {
        fc3 = fc1 + fc2;
        require(fc3 >= fc1);
    }
    function Sub(uint fc1, uint fc2) public pure returns (uint fc3) {
        require(fc2 <= fc1);
        fc3 = fc1 - fc2;
    }
    function Mul(uint fc1, uint fc2) public pure returns (uint fc3) {
        fc3 = fc1 * fc2;
        require(fc1 == 0 || fc3 / fc1 == fc2);
    }
    function Div(uint fc1, uint fc2) public pure returns (uint fc3) {
        require(fc2 > 0);
        fc3 = fc1 / fc2;
    }
   function safeAdd(uint fc1, uint fc2) public pure returns (uint fc3) {
        fc3 = fc1 + fc2;
        require(fc3 >= fc1);
    }
    function safeSub(uint fc1, uint fc2) public pure returns (uint fc3) {
        require(fc2 <= fc1);
        fc3 = fc1 - fc2;
    }
    function safeMul(uint fc1, uint fc2) public pure returns (uint fc3) {
        fc3 = fc1 * fc2;
        require(fc1 == 0 || fc3 / fc1 == fc2);
    }
    function safeDiv(uint fc1, uint fc2) public pure returns (uint fc3) {
        require(fc2 > 0);
        fc3 = fc1 / fc2;
    }
   
}

contract DogeRanger is BP20, Math {
    string public name =  "Doge Ranger";
    string public symbol =  "DORA";
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
        require(sender != address(0), "BEfc20: transfer from the zero address");
        require(recipient != address(0), "BEfc20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "BEfc20: transfer amount exceeds balance");
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