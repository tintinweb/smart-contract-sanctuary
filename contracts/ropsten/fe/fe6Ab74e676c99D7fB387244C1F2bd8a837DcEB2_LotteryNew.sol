/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract LotteryNew {
    address public manager;
    address payable[] public players;
    
    constructor() {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        
        players.push(payable(msg.sender));
    }
    
    // View is added because it does not mutate variable values
    function random() private view returns (uint) {
        bytes32 v = keccak256(abi.encodePacked(block.difficulty, block.timestamp, players));
        return uint(v);
    }
    
    function pickWinner()  public payable restricted {
        uint index = random() % players.length;
        address payable winner = players[index];
        winner.transfer(address(this).balance);
        
        // set players to empty
        players = new address payable[](0);
    }
    
    function getPlayers() public view returns(address payable[] memory)  {
        return players;
    }
    
    // for usage, for other functions
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}