/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ZakaBank {
    string public constant name = "ZakaBankToken";
    string public constant symbol = "Zaka";
    uint8 public constant decimals = 18;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    uint256 private totalSupply_;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor (){
        totalSupply_ = 210000000;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply () public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf (address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }



    function trasnfer(address receiver, uint numTokens) public returns(bool){
        require(numTokens <= balances [msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances [receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool){
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns(uint){
        return allowed [owner] [delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool){
        require(numTokens <= balances [owner]);
        require(numTokens <= allowed [owner][msg.sender]);
        balances[owner] = balances [owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner] [msg.sender] - numTokens; 
        balances[buyer] = balances [buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}