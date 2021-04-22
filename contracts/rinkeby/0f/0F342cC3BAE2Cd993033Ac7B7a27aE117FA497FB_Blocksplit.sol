/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity ^0.4.20;

contract Blocksplit {
    
    address[] public players;
    mapping (address => bool) public uniquePlayers;
    address[] public winners;
    
    address public charity = 0xc39eA9DB33F510407D2C77b06157c3Ae57247c2A;
    
    uint256 drawnBlock = 0;
    
    function() external payable {
        play(msg.sender);
    }
    
    function play(address _participant) payable public {
        require (winners.length < 2);        
        require (msg.value >= 1000000000000000 && msg.value <= 100000000000000000);
        require (uniquePlayers[_participant] == false);
        
        players.push(_participant);
        uniquePlayers[_participant] = true;
    }
    
    function draw() external {
        require (now > 1522908000);
        require (block.number != drawnBlock);
        require (winners.length < 2);
        
        drawnBlock = block.number;
        
        uint256 winningIndex = randomGen();
        address winner = players[winningIndex];
        winners.push(winner);
        
        players[winningIndex] = players[players.length - 1];
        players.length--;
        
        if (winners.length == 2) {
            charity.transfer(address(this).balance);
        }
    }
    
    function randomGen() constant internal returns (uint256 randomNumber) {
        uint256 seed = uint256(block.blockhash(block.number - 200));
        return(uint256(keccak256(block.blockhash(block.number-1), seed )) % players.length);
    }
    
}