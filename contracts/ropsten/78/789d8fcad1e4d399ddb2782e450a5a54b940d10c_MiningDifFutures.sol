pragma solidity 0.4.19;
contract MiningDifFutures {
    uint public initDifficulty = block.difficulty;
    address public participantOne;
    address public participantTwo;
    address public winner;
    uint public difficulty; uint public deposits;
    function () payable {
        if (deposits>=2) {
            difficulty=block.difficulty; deposits=0;
            winner=difficulty>initDifficulty ? participantOne : participantTwo;
            winner.transfer(this.balance); participantOne=0; participantTwo=0;
        } else { 
            if(deposits==0){ participantOne = msg.sender; } else { participantTwo = msg.sender; }
            deposits = deposits+1;
        }
    }
    function balEth() view returns(uint) { return this.balance / 1 ether; }
    function bal() view returns(uint) { return this.balance; }
}