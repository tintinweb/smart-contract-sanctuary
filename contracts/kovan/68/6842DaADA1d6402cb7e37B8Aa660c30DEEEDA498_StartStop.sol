/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

contract StartStop {
    address public owener;
    bool public paused;
    
    constructor() {
        owener = msg.sender;
    }
    
    function setPaused(bool _paused) public {
        require(owener == msg.sender, "your are not the owner!");
        
        paused = _paused;
    }
    
    function getBalance() view public returns (uint256) {
        return address(this).balance;
    }
    
    function depositToken() public payable {

    }

    function withdrawToken() public {
        require(owener == msg.sender, "your are not the owner!");
        require(!paused,"smart contract is paused");
        
        address payable _reciver = msg.sender;
        _reciver.transfer(address(this).balance);
    }
    
    function distroy() public {
        require(owener == msg.sender, "your are not the owner!");
        
        selfdestruct(msg.sender);
    }
}