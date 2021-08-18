/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.6;

contract Lottery {
    
    address public manager;
    address payable[] public players;

    constructor(){
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        
        players.push(payable(msg.sender));
        
    }
    
    
    function random() private view returns(uint){
        return uint(keccak256(
            abi.encodePacked(block.difficulty, block.timestamp, players)
        ));
    }
    
    function pickWinner() public restricted{
        uint index = random() % players.length; 
        players[index].transfer(address(this).balance); // 0x143223432432
        players = new address payable[](0)  ;
        
    }
    
    function getPlayers() public view returns (address payable[] memory){
        return players;

    }
    
    modifier restricted(){
      require(manager == msg.sender); //checking to see if the manager is the one sending. 
      _;
    }
       
}