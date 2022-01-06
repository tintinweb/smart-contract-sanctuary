/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

pragma solidity  ^0.8.6;
contract SillyContract {
    address private owner;
    event Block(address indexed _from, uint indexed blockNumber, uint blockDifficulty, uint blockTimestamp);
    constructor() public {
        owner = msg.sender;
    }
    
    function getBlock() public payable {
          emit Block(msg.sender, block.number, block.difficulty, block.timestamp);
    }
}