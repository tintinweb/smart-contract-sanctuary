/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;



contract Mytoken {
    address owner;
    uint Supply;
    string public  name;
    string public symbol;
    modifier onlyOwner (){
        require(msg.sender==owner);
        _;
    }
    event Transfer(address indexed from ,address indexed to,uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender,
 uint tokens);
    constructor(uint256 initialSupply,string memory _name,string memory _symbol)  {
        owner=msg.sender;
        Supply=initialSupply;
        balances[msg.sender]=Supply;
        name=_name;
        symbol=_symbol;
    }
    mapping(address=>uint256) balances;
    mapping(address=>mapping(address=>uint256)) allowed;

    function totalSupply() public view returns (uint256){
        return Supply;
    }
    function balanceOf(address tokenOwner) public view returns (uint){
        return balances[tokenOwner];
    }
    
    function transfer(address to, uint tokens) public returns (bool){
        require(balances[msg.sender]>=tokens);
        balances[msg.sender]=balances[msg.sender]-tokens;
        balances[to]=balances[to]+tokens;
        emit Transfer(msg.sender,to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint) {
           return allowed[tokenOwner][spender];
    }
    function approve(address spender, uint tokens)  public returns (bool){
        require(balances[msg.sender]>=tokens);
        allowed[msg.sender][spender]=tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool){
        require(balances[from]>=tokens);
        require(allowed[from][to]>=tokens);
        allowed[from][to]=allowed[from][to]-tokens;
        balances[from]=balances[from]-tokens;
        balances[to]=balances[to]+tokens;
    }
}