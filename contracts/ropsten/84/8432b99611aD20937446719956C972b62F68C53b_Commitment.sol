pragma solidity ^0.4.11;

contract Commitment {
    address owner;
    
    mapping (address => string) public commitments;
    
    function Commitment() {
        owner = msg.sender;
    }
    
    function addGoal(string commitmentDesc) external payable {
        commitments[msg.sender] = commitmentDesc;
    }
}