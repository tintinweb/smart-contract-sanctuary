/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

pragma solidity ^0.7.6;

contract Lottery{
    
    address public manager;
    address payable[] public players;
    
    
    constructor(){
        manager = msg.sender;
    }
    
    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    
    function enter() public payable {
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }

    function _pseudoRandom() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
    
    function pickWinner() public restricted {
        
        require(players.length > 0);

        uint index = _pseudoRandom() % players.length;
        players[index].transfer(address(this).balance);

        players = new address payable[](0); 
    }
    
    function getPlayers() public view returns (address payable[] memory){
        return players;
    }
    
}