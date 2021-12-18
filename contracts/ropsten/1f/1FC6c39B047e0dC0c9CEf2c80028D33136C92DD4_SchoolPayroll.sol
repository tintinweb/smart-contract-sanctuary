// SPDX-License-Identifier: MIT 
 pragma solidity ^0.8.0;

interface Q3TokenInterface{
    
    function transfer( address from, address to, uint256 amount) external returns(bool);
    function mint(uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SchoolPayroll{
    
    Q3TokenInterface public token;
    address public owner;
    
    constructor(Q3TokenInterface Q3Token){
        owner = msg.sender;
        token = Q3Token;
    }
    
    function payFees(uint256 amount) external {

        // student msg.sender..
        token.transfer(msg.sender, owner, amount);      
    
}
    
    function paySalary(address teacher, uint256 amount) external {
        token.transfer(owner, teacher, amount);
    }
}