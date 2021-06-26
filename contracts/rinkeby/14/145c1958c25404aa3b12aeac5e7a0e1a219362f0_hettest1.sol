/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.9.0;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns(bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract hettest1 is ERC20 {
 
    string public name = "heettest1";
    string public symbol = "HETT1";
    uint public decimals = 6;
    uint public override totalSupply;

    address public founder;

    mapping (address=>uint) balances;
    mapping (address=>mapping(address=>uint)) allowed;

    constructor(){
        totalSupply =  1000000000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner) external view override returns (uint balance){
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) external override returns (bool success){
        require(balances[msg.sender]>= tokens);

        balances[msg.sender] -= tokens;
        balances[to] += tokens;

        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    function approve(address spender, uint tokens) external override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);
        return true;

    }

    function allowance(address tokenOwner, address spender) external view override returns (uint remaining){
        return allowed[tokenOwner][spender];
    }

    function transferFrom(address from, address to, uint tokens) external override returns(bool success){
        require(balances[from] >= tokens);
        require(allowed[from][to] >= tokens);

        balances[from] -= tokens;
        balances[to] += tokens;

        allowed[from][to] -= tokens;

        return true;

    }


}