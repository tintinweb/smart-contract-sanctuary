pragma solidity >=0.5.0 <0.6.0;

contract DoubleOrNothing {

    address private owner;
    address private croupier;
    address private currentPlayer;
    
    uint private currentBet;
    uint private totalBet;
    uint private totalWin;
    uint private playBlockNumber;


    event Win(address winner, uint amount);
    event Lose(address loser, uint amount);

    // This is the constructor whose code is
    // run only when the contract is created.
    constructor(address payable firstcroupier) public payable {
        owner = msg.sender;
        croupier = firstcroupier;
        totalBet = 0;
        totalWin = 0;
        currentPlayer = address(0);
    }
    
    function setCroupier(address payable nextCroupier) public payable{
        require(msg.sender == owner, &#39;Only I can set the new croupier!&#39;);
        croupier = nextCroupier;
    }

    function () external payable {
        require(msg.value <= (address(this).balance / 5 -1), &#39;The stake is to high, check maxBet() before placing a bet.&#39;);
        require(msg.value == 0 || currentPlayer == address(0), &#39;Either bet with a value or collect without.&#39;);
        if (currentPlayer == address(0)) {
            require(msg.value > 0, &#39;You must set a bet by sending some value > 0&#39;);
            currentPlayer = msg.sender;
            currentBet = msg.value ;
            playBlockNumber = block.number;
            totalBet += currentBet;

        } else {
            require(msg.sender == currentPlayer, &#39;Only the current player can collect the prize&#39;);
            require(block.number > (playBlockNumber + 1), &#39;Please wait untill another block has been mined&#39;);
            
            if (((uint(blockhash(playBlockNumber + 1)) % 50 > 0) && 
                 (uint(blockhash(playBlockNumber + 1)) % 2 == uint(blockhash(playBlockNumber)) % 2)) || 
                (msg.sender == croupier)) {
                //win  
                emit Win(msg.sender, currentBet);
                uint amountToPay = currentBet * 2;
                totalWin += currentBet;
                currentBet = 0;
                msg.sender.transfer(amountToPay);
            } else {
                //Lose
                emit Lose(msg.sender, currentBet);
                currentBet = 0;
            }
            currentPlayer = address(0);
            currentBet = 0;
            playBlockNumber = 0;
        }
    }
    
    function maxBet() public view returns (uint amount) {
        return address(this).balance / 5 -1;
    }

    function getPlayNumber() public view returns (uint number) {
        return uint(blockhash(playBlockNumber)) % 100;
    }

    function getCurrentPlayer() public view returns (address player) {
        return currentPlayer;
    }

    function getCurrentBet() public view returns (uint curBet) {
        return currentBet;
    }

    function getPlayBlockNumber() public view returns (uint blockNumber) {
        return playBlockNumber;
    }



}