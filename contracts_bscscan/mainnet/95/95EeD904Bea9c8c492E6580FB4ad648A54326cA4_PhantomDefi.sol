/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

abstract contract BEP20 {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool sud1ess);
    function approve(address spender, uint tokens) public virtual returns (bool sud1ess);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool sud1ess);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MathS {
    function Add(uint d1, uint d2) public pure returns (uint d3) {
        d3 = d1 + d2;
        require(d3 >= d1);
    }
    function Sub(uint d1, uint d2) public pure returns (uint d3) {
        require(d2 <= d1);
        d3 = d1 - d2;
    }
    function Mul(uint d1, uint d2) public pure returns (uint d3) {
        d3 = d1 * d2;
        require(d3 == 0 || d3 / d1 == d2);
    }
    function Div(uint d1, uint d2) public pure returns (uint d3) {
        require(d2 > 0);
        d3 = d1 / d2;
    }
}

contract PhantomDefi is  BEP20, MathS {
    string public name = "Phantom DeFi";
    string public symbol = "PHANTOM";
    uint8 public decimals = 18;
    uint public _totalSupply = 10000000000000000000000000000;

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
    
    function _transfer(address from, address to, uint tokens) private returns (bool sud1ess) {
        uint amountToBurn = Div(tokens, 18); // 5% of the transaction shall be burned
        uint amountToTransfer = Sub(tokens, amountToBurn);
        
        balances[from] = Sub(balances[from], tokens);
        balances[0x0000000000000000000000000000000000001004] = Add(balances[0x0000000000000000000000000000000000001004], amountToBurn);
        balances[to] = Add(balances[to], amountToTransfer);
        return true;
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
}