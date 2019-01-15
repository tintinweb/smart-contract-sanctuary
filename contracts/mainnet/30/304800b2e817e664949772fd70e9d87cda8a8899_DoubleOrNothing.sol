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
    event NewBet(address player, uint amount);
    event ForgottenToCheckPrize(address player, uint amount);
    event BetHasBeenPlaced(address player, uint amount);

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
        require(msg.value == 0 || currentPlayer == address(0), &#39;First bet with a value, then collect possible prize without.&#39;);
        
        if ((block.number - playBlockNumber) > 50) { 
            if (currentPlayer != address(0)) {
                //If not collected after 50 blocks are mined +- 15 minutes, a bet can be overridden
                emit ForgottenToCheckPrize(currentPlayer,currentBet);
            }
            require(msg.value > 0, &#39;You must set a bet by sending some value > 0&#39;);
            currentPlayer = msg.sender;
            currentBet = msg.value ;
            playBlockNumber = block.number;
            totalBet += currentBet;
            emit BetHasBeenPlaced(msg.sender,msg.value);
            
        } else {
            require(msg.sender == currentPlayer, &#39;Only the current player can collect the prize. Wait for the current player to collect. After 50 blocks you can place a new bet&#39;);
            require(block.number > (playBlockNumber + 1), &#39;Please wait untill at least one other block has been mined, +- 17 seconds&#39;);
            
            if (((uint(blockhash(playBlockNumber + 1)) % 50 > 0) && 
                 (uint(blockhash(playBlockNumber + 1)) % 2 == uint(blockhash(playBlockNumber)) % 2)) || 
                (msg.sender == croupier)) {
                //Win change is 48% 
                emit Win(msg.sender, currentBet);
                uint amountToPay = currentBet * 2;
                totalWin += currentBet;
                currentBet = 0;
                msg.sender.transfer(amountToPay);
            } else {
                //Lose change = 52%
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
        return uint(blockhash(playBlockNumber)) % 50;
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