/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender;
        
    }
    
    function enter() public payable {
        require(msg.value == .1 ether);
        
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        //create the pseudo random numbers
       return uint(keccak256(block.difficulty, now, players)); 
    }
    
    function pickWinner() public restricted{
        
        uint index = random() % players.length;
        players[index].transfer(this.balance); // 0x109483hhfd8y334352fdf4 is similar to an object with certain aspects
        players = new address[](0); // dynamic array with an initial of length of 0
        
    }
    
    modifier restricted(){
        require(msg.sender == manager);
        _;
        
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}