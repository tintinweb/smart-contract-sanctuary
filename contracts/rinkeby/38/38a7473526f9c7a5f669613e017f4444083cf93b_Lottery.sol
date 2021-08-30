/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

pragma solidity ^0.4.17;

contract Lottery{

    
    function addPlayer(uint8 side, uint stake, address id)  private {
        if(side == SideGreen){
            if(greenStakes[id] == 0){
                greenPlayers.push(id);
            }
            totalGreen += stake;
            greenStakes[id] += stake;
        }
        if(side == SideRed){
            if(redStakes[id] == 0){
                redPlayers.push(id);
            }
            totalRed += stake;
            redStakes[id] += stake;
        }
    }
    function resetPlayers() private {
        totalGreen = 0;
        totalRed = 0;
        uint i = 0;
        for(i = 0; i<greenPlayers.length; i++){
            delete greenStakes[greenPlayers[i]];
        }
        for(i = 0; i<redPlayers.length; i++){
            delete redStakes[redPlayers[i]];
        }
        greenPlayers =  new address[](0);
        redPlayers =  new address[](0);
    }
    
    uint public totalGreen;
    uint public totalRed;
    mapping(address => uint) private greenStakes;
    mapping(address => uint) private redStakes;
    
    address[] public greenPlayers;
    address[] public redPlayers;
    address public owner;

    
    

    uint public prizePool;
    uint8 private SideGreen = 1;
    uint8 private SideRed = 2;
    
    function Lottery() public payable {
        owner = msg.sender;
        prizePool  += msg.value;
    }
    
    function enter(uint8 side) public payable {
        require(msg.value >= .01 ether);
        require(side<3 && side>0);
        if(side == SideGreen){
            addPlayer(SideGreen, msg.value, msg.sender);
        }
        else{
            addPlayer(SideRed, msg.value, msg.sender);
        }
    }
    
    function random() private view returns(uint) {
        return uint(keccak256(block.difficulty, now, greenPlayers, redPlayers));
    }
    
    function settleWiner() public {
        require(msg.sender == owner);
        uint prize = 0;
        uint i = 0;
        uint stake = 0;
        if(totalRed > totalGreen){
            //red won
            prize  = (prizePool + totalRed + totalGreen);
            prizePool = prize;
            for(i = 0; i < redPlayers.length; i++){
                stake = ((redStakes[redPlayers[i]] * 10000 / totalRed) * prize)/10000;
                redPlayers[i].transfer(stake);
                prizePool -= stake;
            }
            resetState();
        } else if(totalGreen > totalRed) {
            //green won
            prize  = (prizePool + totalRed + totalGreen);
            prizePool = prize;
            for(i = 0; i < greenPlayers.length; i++){
                stake = ((greenStakes[greenPlayers[i]] * 10000 / totalGreen) * prize)/10000;
                greenPlayers[i].transfer(stake);
                prizePool -= stake;
            }
            resetState();
        } else if (totalGreen == totalRed){
            //tie
        }
        
        
    }
    

    
    function resetState() private {
        resetPlayers();
    }
}