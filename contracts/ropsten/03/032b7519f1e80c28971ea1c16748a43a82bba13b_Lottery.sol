/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.5 <0.9.0;

contract Lottery {
    
    address public manager;
    address payable[] public participants;
    
    constructor(){
        manager = msg.sender;
    }
    
    modifier onlyManager{
        require( msg.sender == manager );
        _;
    }
    
    receive() external payable {
        require ( msg.sender != manager, "Manager not send");
        require ( msg.value == 1 ether);
        participants.push(payable(msg.sender));
    }
    
    function getBalance() onlyManager public view returns(uint){
        return address(this).balance;
    }
    
    function random() onlyManager public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }
    
    function Winner() onlyManager public{
        address payable winner;
        uint index = random() % participants.length;
        winner = participants[index];
        winner.transfer(getBalance());
        participants = new address payable[](0);
    }
    
    
}