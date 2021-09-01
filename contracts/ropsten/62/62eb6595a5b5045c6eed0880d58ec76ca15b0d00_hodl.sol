/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0 <= 0.9.0;

contract hodl {
    address payable owner;
    uint start = block.timestamp;
    mapping(address=>uint) bal;
    
    modifier check() {
        require(msg.sender == payable(owner) ,"You cna't pick up any one of money.");
        _;
    }
    
    constructor(address payable add) {
        owner = add;
    }
    
    function day_after()internal view returns(bool b){
        if(block.timestamp >= start + 365 * 1 days) {
            return(true);
        }
    }
    
    function eth_in_contract() external view returns(uint) {
        return address(this).balance;
    }
    
    receive() external payable{}
    
    fallback()external payable{}
    
    function destruct()public check returns(string memory s){
        if(day_after()) {
            selfdestruct(owner);
        }
        else {
            return("Still can't withdraw the money.");
        }
    }
}