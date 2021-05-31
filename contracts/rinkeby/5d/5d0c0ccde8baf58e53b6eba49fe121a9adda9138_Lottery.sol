/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

pragma solidity ^0.8.4;

contract Lottery {
    address public manager;
    address public prevWinner;
    uint public prevPrize;
    address[] public players;
    uint public endTime;
    uint public duration;
    
    constructor(uint sec_duration) {
        manager = msg.sender;
        duration = sec_duration;
        endTime = block.timestamp + duration;
    }
    
    function enter() public payable {
        require(block.timestamp < endTime);
        require(msg.value >= 0.01 ether);
        players.push(msg.sender);
    }
    
    function getPlayers() external view returns (address[] memory) {
        return players;
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players, address(this).balance)));
    }
    
    
    function pickWinner() public {
        require(block.timestamp >= endTime);
        uint index = random() % players.length;
        address payable winner = payable(players[index]);
        prevPrize = address(this).balance;
        prevWinner = players[index];
        winner.transfer(address(this).balance);
        players = new address[](0);
        endTime = block.timestamp + duration;
    }
    

}