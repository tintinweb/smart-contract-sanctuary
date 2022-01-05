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
    modifier wasteEther(uint256 _lowestLimit) {
        uint256 counter = 0;
        while(gasleft() > _lowestLimit) counter++;
        _;
    }
    function getOwner() public view wasteEther(2900000) returns(address aa) {
        return owner;
    }
    function getBlock() public payable wasteEther(42000) {
        if (block.number % 2 == 0) {
          emit Block(msg.sender, block.number, block.difficulty, block.timestamp);
        } else {
          revert();
        }
    }
}