pragma solidity 0.4.19;
contract MiningDifFutures {
    uint public initDifficulty = block.difficulty;
    address public participantOne;
    address public participantTwo;
    address public winner;
    uint public difficulty; uint deposits;
    function () payable {
        if (deposits>=2) {
            difficulty = block.difficulty;
            winner = difficulty>initDifficulty ? participantOne : participantTwo;
            address(winner).transfer(this.balance); 
        } else { 
            if(deposits==0){ participantOne = msg.sender; } else { participantTwo = msg.sender; }
            deposits = deposits+1;
        }
    }
    function balEth() view returns(uint) { return this.balance / 1 ether; }
    function bal() view returns(uint) { return this.balance; }
}