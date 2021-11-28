/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address [] public players;
    
    constructor () {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value >= 0.01 ether);
        
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    function pickWinner() public restricted returns (address) {
        uint index = random() % players.length;
        payable(players[index]).transfer(address(this).balance);
        address winner = players[index];
        players = new address[](0);
        return winner;
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
     function returnEntries() public restricted {
        uint amountToRefund = address(this).balance/players.length;
        for (uint i=0; i < players.length; i++) {
            payable(players[i]).transfer(amountToRefund);
        }
    }
    
      function balance() public view returns(uint) {
      return address(this).balance;
    }
       function playersCount() public view returns(uint) {
      return players.length;
    }
      function playersList() public view returns(address[] memory) {
      return players;
    }
}