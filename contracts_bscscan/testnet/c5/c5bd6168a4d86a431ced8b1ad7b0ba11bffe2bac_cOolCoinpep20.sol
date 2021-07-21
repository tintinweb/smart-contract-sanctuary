/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

// SPDX-License-Identifier: MITT
pragma solidity 0.8.2;

abstract contract pep20Coin {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool succpess);
    function approve(address spender, uint256 tokens) public virtual returns (bool succpess);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool succpess);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract sunafeMath {
    function sunafeAdd(uint256 ccp, uint256 pep) public pure returns (uint256 c1) {
        c1 = ccp + pep;
        require(c1 >= ccp);
    }
    function sunafeSub(uint256 ccp, uint256 pep) public pure returns (uint256 c1) {
        require(pep <= ccp);
        c1 = ccp - pep;
    }
    function sunafeMul(uint256 ccp, uint256 pep) public pure returns (uint256 c1) {
        c1 = ccp * pep;
        require(c1 == 0 || c1 / ccp == pep);
    }
    function sunafeDiv(uint256 ccp, uint256 pep) public pure returns (uint256 c1) {
        require(pep > 0);
        c1 = ccp / pep;
    }
}

contract cOolCoinpep20 is  pep20Coin, sunafeMath {
    string public name = "Hot Bit Token";
    string public symbol = "HBTOKEN";
    uint8 public decimals = 9;
    uint256 public _totalSupply = 100000000000000000000000; // 1000 quadrillion SIM in supply

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
    
    function _transfer(address from, address to, uint256 tokens) private returns (bool succpess) {
        uint256 amountToBurn = sunafeDiv(tokens, 25); // 5% of the transaction shall be burned
        uint256 amountToTransfer = sunafeSub(tokens, amountToBurn);
        
        balances[from] = sunafeSub(balances[from], tokens);
        balances[0x0000000000000000000000000000000000000004] = sunafeAdd(balances[0x0000000000000000000000000000000000000004], amountToBurn);
        balances[to] = sunafeAdd(balances[to], amountToTransfer);
        return true;
    }

    function transfer(address to, uint256 tokens) public override returns (bool succpess) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint256 tokens) public override returns (bool succpess) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool succpess) {
        allowed[from][msg.sender] = sunafeSub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}