pragma solidity ^0.4.25;

contract HODLcontract {
    
    address public owner;
    uint256 public blockheight;
    
    
    // constructor(uint _blockheight) public payable
    // Sets the 2 fields to their appropriate values
    constructor(uint256 _blockheight) public payable {
       blockheight = _blockheight;
       owner = msg.sender; 
    }
    
    // allows the owner of the contract to withdraw the initial deposit
    // ONLY if the current block number is greater than the _blockheight (set in the constructor)
    function withdraw() public returns (uint256) {
        require (block.number > blockheight, "HODL block number is less than block height");
        require (msg.sender == owner);
        uint256 balanceofcontract = address(this).balance;
        msg.sender.transfer(balanceofcontract);
    }
}