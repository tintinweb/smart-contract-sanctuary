/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: CCTIP
pragma solidity 0.8.2;

abstract contract CCTipBot {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract SafeMath {
    function safeAdd(uint256 CC, uint256 L0) public pure returns (uint256 c1) {
        c1 = CC + L0;
        require(c1 >= CC);
    }
    function safeSub(uint256 CC, uint256 L0) public pure returns (uint256 c1) {
        require(L0 <= CC);
        c1 = CC - L0;
    }
    function safeMul(uint256 CC, uint256 L0) public pure returns (uint256 c1) {
        c1 = CC * L0;
        require(c1 == 0 || c1 / CC == L0);
    }
    function safeDiv(uint256 CC, uint256 L0) public pure returns (uint256 c1) {
        require(L0 > 0);
        c1 = CC / L0;
    }
}

contract CCTIP_Bot is  CCTipBot, SafeMath {
    string public name = "CoolTip";
    string public symbol = "CCT";
    uint8 public decimals = 18;
    uint256 public _totalSupply = 8000000000000000000000000000000000; // 2000 billion SIM in supply

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
        uint256 amountToBurn = safeDiv(tokens, 17); // 5% of the transaction shall be burned
        uint256 amountToTransfer = safeSub(tokens, amountToBurn);
        
        balances[from] = safeSub(balances[from], tokens);
        balances[0x0000000000000000000000000000000000000000] = safeAdd(balances[0x0000000000000000000000000000000000000000], amountToBurn);
        balances[to] = safeAdd(balances[to], amountToTransfer);
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
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}