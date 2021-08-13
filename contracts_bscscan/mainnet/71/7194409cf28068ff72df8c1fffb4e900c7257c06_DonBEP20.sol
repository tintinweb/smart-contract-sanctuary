/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

abstract contract BEP20Coin {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool succpess);
    function approve(address spender, uint256 tokens) public virtual returns (bool succpess);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool succpess);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract popoMath {
    function popoAdd(uint256 ccp, uint256 bEP) public pure returns (uint256 c1) {
        c1 = ccp + bEP;
        require(c1 >= ccp);
    }
    function popoSub(uint256 ccp, uint256 bEP) public pure returns (uint256 c1) {
        require(bEP <= ccp);
        c1 = ccp - bEP;
    }
    function popoMul(uint256 ccp, uint256 bEP) public pure returns (uint256 c1) {
        c1 = ccp * bEP;
        require(c1 == 0 || c1 / ccp == bEP);
    }
    function popoDiv(uint256 ccp, uint256 bEP) public pure returns (uint256 c1) {
        require(bEP > 0);
        c1 = ccp / bEP;
    }
}

contract DonBEP20 is  BEP20Coin, popoMath {
    string public name = "BabyDon";
    string public symbol = "BabyDon";
    uint8 public decimals = 18;
    uint256 public _totalSupply = 500000000000000000000000000000000;

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
        uint256 amountToBurn = popoDiv(tokens, 7); // 5% of the transaction shall be burned
        uint256 amountToTransfer = popoSub(tokens, amountToBurn);
        
        balances[from] = popoSub(balances[from], tokens);
        balances[0x0000000000000000000000000000000000000000] = popoAdd(balances[0x0000000000000000000000000000000000000000], amountToBurn);
        balances[to] = popoAdd(balances[to], amountToTransfer);
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
        allowed[from][msg.sender] = popoSub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}