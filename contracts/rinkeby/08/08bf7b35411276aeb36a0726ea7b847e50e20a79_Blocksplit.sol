/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.4.6;

contract Blocksplit {
    
    address[] public players;
    mapping (address => bool) public uniquePlayers;
    //address[] public winners;
    address public winner;
    uint256 public winningIndex;
    uint256 public seed1;
    
    //address public charity = 0xc39eA9DB33F510407D2C77b06157c3Ae57247c2A;
    
    uint256 public drawnBlock = 0;
    
    function() external payable {
        play(msg.sender);
    }
    
    function play(address _participant) payable public {
    //    require (winners.length < 2);        
        require (msg.value >= 1000000000000000 && msg.value <= 100000000000000000);
        require (uniquePlayers[_participant] == false);
        
        players.push(_participant);
        uniquePlayers[_participant] = true;
    }
    
    function draw() external {
    //    require (now > 1522908000);
        require (block.number != drawnBlock);
    //    require (winners.length < 2);
        
        drawnBlock = block.number;
        
        //uint256 
        winningIndex = randomGen();
        winner = players[winningIndex];
    //    winners.push(winner);
        
    //    players[winningIndex] = players[players.length - 1];
    //    players.length--;
        
    //    if (winners.length == 2) {
    //        charity.transfer(address(this).balance);
    //    }
          winner.transfer(address(this).balance);  
    }
    
    function randomGen() constant internal returns (uint256 randomNumber) {
        uint256 seed = uint256(blockhash(block.number - 200));
        return(uint256(keccak256(abi.encodePacked(blockhash(block.number-1), seed))) % players.length);
    }
    
}