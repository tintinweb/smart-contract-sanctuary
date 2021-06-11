/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    
    constructor() public {
        manager = msg.sender;
    }
    
    modifier onlyManager() {
        require(manager == msg.sender, "YOU ARE NOT THE OWNER!");
        _;
    }
    
    function enter() public payable {
        require(msg.value > .01 ether, "To enter the lottery you'll need to send more than 0.01 ether!");
        
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public onlyManager {
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address[](0);
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}