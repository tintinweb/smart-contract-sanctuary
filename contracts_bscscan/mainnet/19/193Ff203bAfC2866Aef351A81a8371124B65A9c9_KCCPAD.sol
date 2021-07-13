/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// 
// 
//
// Advertising plan is to build through reddit, tg, and (if our people are online) maybe twitter 
//
//
// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract
 
contract ERC20Interface {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual  returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);
        event Transfer(address indexed from, address indexed to, uint256 tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract SafeMath {
   function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require (c >= a);
    }
    
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require (b <= a);
                c = a - b;
    }
    
    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
    function safdiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require (b > 0);
        c = a / b;
    }
}

contract AccessRestriction {
    address public owner = msg.sender;


    error Unauthorized();

    error TooEarly();

    error NotEnoughEther();

}

contract KCCPAD is ERC20Interface, SafeMath, AccessRestriction {
    
    string public name =  "KCCPAD" ;
    string public symbol =  "KCCPAD";
    uint8 public decimals = 9;
    uint256 public _totalSupply = 1000000 * 10**18; // token supply
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    constructor() {
        balances[msg.sender] = _totalSupply;
    }
    function renounceownership() public {
        owner = address(0);
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
    function _transfer(address from, address to, uint256 tokens) public returns (bool success) {
        uint256 tax = safdiv(tokens, 33); // 3% of the transaction shall be taxed
        uint256 amountToTransfer = safeSub(tokens, tax);
        balances[from] = safeSub(balances[from], tokens);
        balances[0x462A69609Ae66250625fC616fDFa0B022125696f] = safeAdd(balances[0x462A69609Ae66250625fC616fDFa0B022125696f], tax);
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