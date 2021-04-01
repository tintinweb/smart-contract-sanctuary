/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
        require(msg.value == 1 ether);
        players.push(msg.sender);
    }
    
    function pickWinner() public {
        require(msg.sender == manager);
        uint index = random() % players.length;
        players[index].transfer(this.balance);
        players = new address[](0);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function getPlayers() public view returns (address[]){
        return players;
    }
}