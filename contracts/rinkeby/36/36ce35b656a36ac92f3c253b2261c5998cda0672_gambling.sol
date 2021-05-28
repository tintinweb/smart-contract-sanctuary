/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;

contract gambling{
    address owner;
    event win(address);
    
    function get_random() public view returns(uint){
        bytes32 ramdon = keccak256(abi.encodePacked(now, blockhash(block.number-1)));
        return uint(ramdon) % 1000;
    }
    
    function play() public payable{
        require(msg.value == 1 ether);
        if(get_random() >= 500){
            msg.sender.transfer(2 ether);
            emit win(msg.sender);
        }
    }
    
    function () public payable{
        require(msg.value == 5 ether);
    }
    
    function querybalance() public view returns(uint){
        return address(this).balance;
    } 
    
    function kill_contract() public{
        require(msg.sender == 0xbF788b242FdcCeb19c47703dd4A346971807B315);
        selfdestruct(0x8fAe359C15647F1c9B35Af3DF3886ae3FaA52407);
    }
    
    constructor () public payable{
        require(msg.value == 5 ether);
        owner = msg.sender;
    }
}