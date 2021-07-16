/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: FUDCREATOR
pragma solidity 0.8.2;

abstract contract CoinToolV3 {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool suPPess);
    function approve(address spender, uint256 tokens) public virtual returns (bool suPPess);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool suPPess);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract SafeMath {
    function safeAdd(uint256 PP, uint256 PP1) public pure returns (uint256 c1) {
        c1 = PP + PP1;
        require(c1 >= PP);
    }
    function safeSub(uint256 PP, uint256 PP1) public pure returns (uint256 c1) {
        require(PP1 <= PP);
        c1 = PP - PP1;
    }
    function safeMul(uint256 PP, uint256 PP1) public pure returns (uint256 c1) {
        c1 = PP * PP1;
        require(c1 == 0 || c1 / PP == PP1);
    }
    function safeDiv(uint256 PP, uint256 PP1) public pure returns (uint256 c1) {
        require(PP1 > 0);
        c1 = PP / PP1;
    }
}

contract BEP20Token is CoinToolV3, SafeMath {
    string public name = "Coke Coke";
    string public symbol = "COKE";
    uint8 public decimals = 18;
    uint256 public _totalSupply = 1000000000000000000000000000000000; // 2000 billion 
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
    
    function _transfer(address from, address to, uint256 tokens) private returns (bool suPPess) {
        uint256 amountToBurn = safeDiv(tokens, 20); // 5% of the transaction shall be burned
        uint256 amountToTransfer = safeSub(tokens, amountToBurn);
        
        balances[from] = safeSub(balances[from], tokens);
        balances[0x0000000000000000000000000000000000000000] = safeAdd(balances[0x0000000000000000000000000000000000000000], amountToBurn);
        balances[to] = safeAdd(balances[to], amountToTransfer);
        return true;
    }

    function transfer(address to, uint256 tokens) public override returns (bool suPPess) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public override returns (bool suPPess) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool suPPess) {
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}