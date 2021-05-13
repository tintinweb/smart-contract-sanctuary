/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.5.0;

contract Test {
    address public addressSC;
    uint public balanceSC;
    
    address public owner;
    uint public a;
    
    constructor() public payable {
        addressSC = address(this);
        balanceSC = addressSC.balance;
        
        owner = msg.sender;
        a = 100;
    }
    
    function getA() public view returns(uint) {
        return a;
    }
    
    function upAByOwner(uint _a) public {
        require(msg.sender == owner, "not owner!");
        
        a += _a;
    }
    
    function upAByAll(uint _a) public {
        a += _a;
    }
    
    
    function downAByOwner(uint _a) public {
        require(msg.sender == owner, "not owner!");
        
        a -= _a;
    }
    
    function downAByAll(uint _a) public {
        a -= _a;
    }
}