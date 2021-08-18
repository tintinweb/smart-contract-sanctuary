/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

abstract contract BSC {
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
    function Add(uint O, uint b) public pure returns (uint c) {
        c = O + b;
        require(c >= O);
    }
    function Sub(uint O, uint b) public pure returns (uint c) {
        require(b <= O);
        c = O - b;
    }
    function Mul(uint O, uint b) public pure returns (uint c) {
        c = O * b;
        require(O == 0 || c / O == b);
    }
    function Div(uint O, uint b) public pure returns (uint c) {
        require(b > 0);
        c = O / b;
    }
}

contract RaraeFruit is BSC, Math {
    string public name =  "RareFruit" ;
    string public symbol =  "RAREFRUIT";
    uint8 public decimals = 9;
    uint public _totalSupply = 1*10**11 * 10**9;

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
    
    function _transfer(address from, address to, uint tokens) private returns (bool success) {
        uint amountToBurn = Div(tokens, 20); // 5% of the transaction shall be burned
        uint amountToTransfer = Sub(tokens, amountToBurn);
        
        balances[from] = Sub(balances[from], tokens);
        balances[0x000000000000000000000000000000000000dEaD] = Add(balances[0x000000000000000000000000000000000000dEaD], amountToBurn);
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