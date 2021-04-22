/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.4.20;

contract Blocksplit {
    
    address[] public players;
    mapping (address => bool) public uniquePlayers;
    address public winner;
    
    uint256 drawnBlock = 0;
    
    function() external payable {
        play(msg.sender);
    }
    
    function play(address _participant) payable public {
        require (msg.value >= 1000000000000000 && msg.value <= 100000000000000000);
        require (uniquePlayers[_participant] == false);
        
        players.push(_participant);
        uniquePlayers[_participant] = true;
    }
    
    function draw() external {
        require (players.length == 3);
        require (block.number != drawnBlock);
        
        drawnBlock = block.number;
        
        uint256 winningIndex = randomGen();
        winner = players[winningIndex];
        
        if (winner != 0) {
            winner.transfer(address(this).balance);
        }
    }
    
    function randomGen() constant internal returns (uint256 randomNumber) {
        uint256 seed = uint256(block.blockhash(block.number - 200));
        return(uint256(keccak256(block.blockhash(block.number-1), seed )) % players.length);
    }
    
}