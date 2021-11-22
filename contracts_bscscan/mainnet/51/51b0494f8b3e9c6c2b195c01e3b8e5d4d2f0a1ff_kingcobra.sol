/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

/**
 *

██╗░░██╗██╗███╗░░██╗░██████╗░  ░█████╗░░█████╗░██████╗░██████╗░░█████╗░
██║░██╔╝██║████╗░██║██╔════╝░  ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗
█████═╝░██║██╔██╗██║██║░░██╗░  ██║░░╚═╝██║░░██║██████╦╝██████╔╝███████║
██╔═██╗░██║██║╚████║██║░░╚██╗  ██║░░██╗██║░░██║██╔══██╗██╔══██╗██╔══██║
██║░╚██╗██║██║░╚███║╚██████╔╝  ╚█████╔╝╚█████╔╝██████╦╝██║░░██║██║░░██║
╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░  ░╚════╝░░╚════╝░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝
╚═════╝░░╚═════╝░╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚══╝
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract babyMath {
    function babyAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function babySub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function babyMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function babyDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract kingcobra is ERC20Interface, babyMath {
    string public name = "KING COBRA";
    string public symbol = "KINGCOBRA";
    uint8 public decimals = 18;
    uint256 public _totalSupply = 10000000000000000000000; // 2 billion SIM in supply

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address from, address to, uint256 tokens) private returns (bool success) {
        uint256 amountToBurn = babyDiv(tokens, 40); // 5% of the transaction shall be burned
        uint256 amountToTransfer = babySub(tokens, amountToBurn);
        
        balances[from] = babySub(balances[from], tokens);
        balances[0x0000000000000000000000000000000000000000] = babyAdd(balances[0x0000000000000000000000000000000000000000], amountToBurn);
        balances[to] = babyAdd(balances[to], amountToTransfer);
        return true;
    }

    function transfer(address to, uint256 tokens) public override returns (bool success) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
        allowed[from][msg.sender] = babySub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}