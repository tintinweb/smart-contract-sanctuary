/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

pragma solidity ^0.4.17; 

contract Lottery {
    address public manager; 
    address[] public players;
    address public lastWinner;
    
    function Lottery() public {
        manager = msg.sender;
    }
    
    function enter() public payable {
         // require min .01 ether or 10000000000000000 wei
        require(msg.value > .01 ether);      
        players.push(msg.sender);
    }
    
    function random() private view returns (uint) {
        // pass block difficult, time and players into sha3. Cast hash to uint
        return uint(sha3(block.difficulty, now, players)); 
    }
    
    function pickWinner() public restricted {
        uint winnerIndex = random() % players.length;
        address winnerAddress = players[winnerIndex];
        winnerAddress.transfer(address(this).balance);
        
        players = new address[](0);
        lastWinner = winnerAddress;
    }
  
    modifier restricted() {
        //only allow the manager to call pickWinner
        require(msg.sender == manager);
        _;
    }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
}