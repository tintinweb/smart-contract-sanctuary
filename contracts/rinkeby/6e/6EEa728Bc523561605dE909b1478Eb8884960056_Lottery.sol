/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

pragma solidity ^0.8.10;

contract Lottery{
    address  public manager;
    address[] public players;
    
    constructor() {
        manager = msg.sender;
    }
    
    function enter() public payable{
        require(msg.value > .001 ether);
        players.push(msg.sender);
    }
    
    function getPlayers() public view returns(address[] memory) {
        return players;
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
        
    }
    
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
    
    function pickWinner() public restricted {
        require(msg.sender == manager);
        
        uint index = random() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
    }
    
    
    
}