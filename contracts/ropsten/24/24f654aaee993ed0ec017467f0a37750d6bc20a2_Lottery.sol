pragma solidity ^0.4.0;
contract Lottery {

    address[] public players;
    uint public numPlayers;
    uint public contractBalance;
    bool public lotteryEnded;
    
    function lotteryReset() internal {
        lotteryEnded = false;
        numPlayers = 0;
        players = new address[](5);
        contractBalance = 0;
        
    }
    
    function joinLottery() public payable {
        require(msg.value != 0);
        if (lotteryEnded) {
            revert();
        }
        
        players.push(msg.sender);
        numPlayers++;
        contractBalance += msg.value;
        
        if (numPlayers == 5) {
            pickWinner();
            lotteryReset();
        }
    }

    function pickWinner() internal{
        lotteryEnded = true;
        if(numPlayers == 5) {
           uint winner = uint(blockhash(block.number - 1)) % numPlayers;
           players[winner].transfer(contractBalance);
        }
    }
    
}