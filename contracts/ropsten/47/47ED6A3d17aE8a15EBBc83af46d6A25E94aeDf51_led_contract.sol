/**
 *Submitted for verification at Etherscan.io on 2021-02-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.5;


contract led_contract{
    
    address payable owner;
    int8 ledState;
    
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner can call this."
        );
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function setLed (int8 newOn) external payable {
        ledState = newOn;
    }

    function readLed() external view returns (int8 actOn) {
        return ledState;
    }

    function retrieveEther() external onlyOwner{
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function kill() external onlyOwner{
        selfdestruct(owner);
    }
    
}