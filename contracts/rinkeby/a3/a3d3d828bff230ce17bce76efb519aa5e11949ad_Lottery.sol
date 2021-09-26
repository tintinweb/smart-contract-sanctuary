/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;  
    
    function Lottery() public{
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether);
        players.push(msg.sender);
    }
    
    function random() private view  returns (uint){
        return uint(keccak256(block.difficulty, now, players));
        //sha3() same thing
    }
    
    function pickWinner() public restricted {
        require(msg.sender == manager);
        
        uint index = random() % players.length;
        players[index].transfer(this.balance); 
        players = new address[](0);//0 initial length demek
    }
    
    modifier restricted(){
        require(msg.sender == manager);
        _; //restricted kullanılan functiondaki bütün içeriği alıp buraya koyar :) DRY problem çözümü yani
    }
    
    function getPlayers() public view returns (address[]){
        return players;
    }
}