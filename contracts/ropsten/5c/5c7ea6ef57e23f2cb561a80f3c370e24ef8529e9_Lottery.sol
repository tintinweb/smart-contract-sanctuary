/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

abstract contract StorageInterface {
    function retrieve() virtual public view returns (uint256);
}

contract Lottery {
    
    address public owner;
    address public winner = address(0);
    
    address[] public participants;
    
    uint256 lottery_ticket_price = 0.001 ether;
    
    StorageInterface storage_contract;
    
    constructor() {
        owner = msg.sender;
    }
    
    function numberOfParticipants() public view returns (uint256) {
        return participants.length;
    }
    
    function setStorageContractAddress(address new_storage_contract) public isOwner {
        storage_contract = StorageInterface(new_storage_contract);
    }
    
    function purchaseTicket() public payable {
        require(msg.sender != owner);
        require(msg.value == lottery_ticket_price);
        
        participants.push(msg.sender);
    }
    
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function readFromStorageContract() public view returns (uint256) {
        return storage_contract.retrieve();
    }
    
    function endLottery() public isOwner {
        require(winner == address(0));
        
        uint256 rand_number = uint256(keccak256(abi.encodePacked(block.timestamp, readFromStorageContract())));
        uint256 rand_index = rand_number % participants.length;
        
        winner = participants[rand_index];
    }
    
    function withdraw() external {
        require(msg.sender == winner);
        
        uint256 current_balance = address(this).balance;
        payable(winner).transfer(current_balance);
    }
}