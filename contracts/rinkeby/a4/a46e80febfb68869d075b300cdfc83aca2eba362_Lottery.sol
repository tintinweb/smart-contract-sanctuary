/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Lottery {


    address public manager;
    address [] public  players;
    constructor(){
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether );
        players.push(msg.sender);
    }
    function random() private view returns (uint){
      return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }
    
    function pickWinner() public  restricted {
      
        uint index = random() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
    }
    
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    function getPlayers() public view returns( address[] memory)
    {
        return players;
    }
}