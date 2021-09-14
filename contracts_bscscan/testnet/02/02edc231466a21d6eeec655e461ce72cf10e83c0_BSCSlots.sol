/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2; // needed to return dynamic string array in Solidity

contract BSCSlots {
    event GameResult(address indexed sender);

    address payable casinoOwner; // casino owner address
    uint private casinoBalance; // Casino funds
    
    uint[] private symbols = [0, 1, 2, 3, 4, 5, 6, 7]; // 8 symbols used for slot machine
    // 0 = apple
    // 1 = refund
    // 2 = cherry
    // 3 = banana
    // 4 = grape
    // 5 = orange
    // 6 = kiwi
    // 7 = jackpot
    
    mapping(uint => uint) public symbolWorth; // int to int mapping to determine value of a symbol
    string[] private linesWon; // array will keep track of lines won in a game
    
    enum State {inProgress, Finished}
    
    struct Game {
        State state;
        address payable playerAddress;
        uint playerBetAmount;
        uint time;
        uint[3][3] slotsState;
        uint prizeMoney;
        string[] linesWon;
        string result;
        bytes32 slotsHash;
    }
    
    Game[] private Games;
    Game[] public FinishedGames;
    
    constructor() public payable {
        casinoOwner = msg.sender; 
        casinoBalance = msg.value;

        symbolWorth[0] = 10000000000000000; // apple
        symbolWorth[1] = 0; // refund
        symbolWorth[2] = 2000000000000000; // cherry
        symbolWorth[3] = 8000000000000000; // banana
        symbolWorth[4] = 12000000000000000; // grape
        symbolWorth[5] = 25000000000000000; // orange
        symbolWorth[6] = 30000000000000000; // kiwi
        symbolWorth[7] = 50000000000000000; // jackpot
    }

    modifier onlyOwner() {
        require(casinoOwner == msg.sender, "Only casino owner can call this function");
        _;
    }
    
    modifier onlyPlayer() {
        require(casinoOwner != msg.sender, "Only player can call this function");
        _;
    }
    
    // modifier that requires a certain game state before a function can be called
    modifier inState(State _state) {
        int index = getGameIndex(msg.sender);
        require(index != -1 && Games[uint(index)].state == _state, "Invalid state.");
        _;
    }
    
    // Function that allows casino owner to fund casino balance
    function fundCasino() public payable onlyOwner {
        casinoBalance += msg.value;
    }
    
    // Function to withdraw casino funds
    function withdrawCasinoFunds(uint _amount) public onlyOwner {
        require(Games.length == 0, "Cannot withdraw funds when there are active games.");
        require(_amount <= address(this).balance, "Withdraw amount exceeds casino contract funds.");
        msg.sender.transfer(_amount);
        casinoBalance -= _amount;
    }

    // Hashing function: takes in address, player bet amount, and the slots after spin
    function hash(address _addr, uint _bet, uint[3][3] memory _slotResults) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_addr, _bet, _slotResults));
    }
    
    
    // Function will calculate the total prize earned from a row
    function calculatePrize(uint _leftSymbol, uint _middleSymbol, uint _rightSymbol, uint _playerBetAmount) private returns(uint) {
        uint totalPrize = 0;
        symbolWorth[1] = _playerBetAmount; // refund
        if (_leftSymbol == symbols[2]) { // cherry logic - (symbols[2] is cherry)
            totalPrize += symbolWorth[_leftSymbol];
            if (_middleSymbol == symbols[2]) {
                totalPrize += symbolWorth[_middleSymbol];
                if (_rightSymbol == symbols[2])
                    totalPrize += symbolWorth[_rightSymbol];
            }
        }
        else if (_leftSymbol == _middleSymbol && _leftSymbol == _rightSymbol) // perfect line match
            totalPrize += symbolWorth[_leftSymbol];
        return totalPrize;
    }
    
    function playerBet(uint[3][3] memory arr) public payable onlyPlayer {
        require(getGameIndex(msg.sender) == -1, "You are already playing a casino game (1 game at a time)!");
        require(casinoBalance >= (1500 + 1500 * Games.length), "Casino contract ran out of money to play with right now."); // ensure 1500 in casino balance for each player
       // require(msg.value == 1000000000000000 wei || msg.value == 4000000000000000 wei || msg.value == 8000000000000000 wei, "You must pay 1, 2, or 3 wei to play the game!");
        Game memory newGame = Game(
            State.inProgress, // game State
            msg.sender, // player address
            msg.value, // player bet amount
            now, // time of game
            arr, // slot machine state
            0, // prize money
            linesWon, // lines won
            '',// result
            0); // Slot hash
        Games.push(newGame);
        casinoBalance += msg.value; // how much wei the player sent to this contract
        
        int index = getGameIndex(msg.sender);
        Game storage game = Games[uint(index)];

        // Hashing slots after spin
        game.slotsHash = hash(msg.sender, msg.value, game.slotsState);

        // Checking hash before calculating prize money
        require(hash(game.playerAddress, uint(game.playerBetAmount), game.slotsState) == game.slotsHash, "Slots/Player Bet have been changed illegally.");
        
        // Calculate the prize money from the slots
        uint prizeMoney = 0;
        if (game.playerBetAmount >= 1000000000000000) {
            prizeMoney = calculatePrize(game.slotsState[1][0], game.slotsState[1][1], game.slotsState[1][2], game.playerBetAmount);
            if (prizeMoney > 0) {
                game.prizeMoney += prizeMoney;
                game.linesWon.push("middle");
            }
            
            if (game.playerBetAmount >= 4000000000000000) {
                prizeMoney = calculatePrize(game.slotsState[0][0], game.slotsState[0][1], game.slotsState[0][2], game.playerBetAmount);
                if (prizeMoney > 0) {
                    game.prizeMoney += prizeMoney;
                    game.linesWon.push("top");
                }
                prizeMoney = calculatePrize(game.slotsState[2][0], game.slotsState[2][1], game.slotsState[2][2], game.playerBetAmount);
                if (prizeMoney > 0) {
                    game.prizeMoney += prizeMoney;
                    game.linesWon.push("bottom");
                }
                
                if (game.playerBetAmount == 800000000000000) {
                    prizeMoney = calculatePrize(game.slotsState[0][0], game.slotsState[1][1], game.slotsState[2][2], game.playerBetAmount);
                    if (prizeMoney > 0) {
                        game.prizeMoney += prizeMoney;
                        game.linesWon.push("majorDiagonal");
                    }
                    prizeMoney = calculatePrize(game.slotsState[2][0], game.slotsState[1][1], game.slotsState[0][2], game.playerBetAmount);
                    if (prizeMoney > 0) {
                        game.prizeMoney += prizeMoney;
                        game.linesWon.push("minorDiagonal");
                    }
                }
            }
        }
        
        if (game.prizeMoney > 0) { // if player wins subtract ether from casino balance and send to player address
            game.playerAddress.transfer(game.prizeMoney);
            casinoBalance -= game.prizeMoney;
            game.result = "Player won!";
        } 
        else
            game.result = "Player lost!";
        
        game.state = State.Finished;
        resetGame(); 
	    emit GameResult(msg.sender); // have to be after resetGame()
    }
    
    // Function that returns the index of the game that the player is in
    function getGameIndex(address _address) internal view returns(int) {
        if(Games.length == 0)
            return -1;
        for(uint i = 0; i < Games.length; i++) {
            if(Games[i].playerAddress == _address)
                return int(i);
        }
        return -1;
    }
    
     // Function that resets the game
    function resetGame() internal {
        int index = getGameIndex(msg.sender);
        require(index != -1, "Player not in any of the casino games!");
        removePlayer(uint(index));
    }
    
    // Function that removes a player's game from the game list
    function removePlayer(uint index) internal {
        if (index >= Games.length) return;
        
        FinishedGames.push(Games[index]);
        
        for (uint i = index; i < Games.length-1; i++){
            Games[i] = Games[i+1];
        }
        Games.pop();
    }
    
    // Function will return the result of the latest game that a player played
    function getResults() public view returns(Game memory) {
        Game memory lastGame;
        for (uint i = FinishedGames.length-1; i >= 0; i--) {
            if (FinishedGames[i].playerAddress == msg.sender) {
                lastGame = FinishedGames[i];
                break;
            }
        }
        return lastGame;
    }

    // Function will return the total number of games a player has played
    function getGameCount(address _address) private view returns(uint) {
        uint count = 0;
        for (uint i = 0; i < FinishedGames.length; i++) {
            if (FinishedGames[i].playerAddress == _address)
                count++;
        }
        return count;
    }
    
    // Function will return history of a player's games
    function getHistory(address _address) public view returns(Game[] memory) {
        Game[] memory gameHistory = new Game[](getGameCount(_address));
        uint counter = 0;
        for (uint i = 0; i < FinishedGames.length; i++) {
            if (FinishedGames[i].playerAddress == _address) {
                gameHistory[counter] = FinishedGames[i];
                counter++;
            }
        }
        return gameHistory;
    }

    function getGames() public view returns(Game[] memory) {
        return Games;
    }

    function getFinishedGames() public view returns(Game[] memory) {
        return FinishedGames;
    }
    
    // Function to see casino owner address
    function getOwnerAddress() public view returns(address payable) {
        return casinoOwner;
    }
    
    // Function to get casino balance
    function getCasinoBalance() public view returns(uint) {
        return casinoBalance;
    }
    
    // Function to get contract balance
    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    // Test function to see status of slot machine reels
    function getSlots() public view returns(uint[3][3] memory) {
        Game memory game = getResults();
        return game.slotsState;
    }
    function getRow1() public view returns(uint[3] memory) {
        Game memory game = getResults();
        return game.slotsState[0];
    }
    function getRow2() public view returns(uint[3] memory) {
        Game memory game = getResults();
        return game.slotsState[1];
    }
    function getRow3() public view returns(uint[3] memory) {
        Game memory game = getResults();
        return game.slotsState[2];
    }
    
    // Test function to see lines won
    function getLinesWon() public view returns(string[] memory) {
        Game memory game = getResults();
        return game.linesWon;
    }
    
    // Test function to see prize money from spin
    function getPrizeMoney() public view returns(uint) {
        Game memory game = getResults();
        return game.prizeMoney;
    }
    
    // When all games are done and the owner wants to cash out, will send all funds to casino owner
    function closeContract() public onlyOwner {
        require(Games.length == 0, "Cannot close contract when there are active games.");
        selfdestruct(casinoOwner); // sends all of the contract's current balance to casino owner
        casinoBalance = 0; 
    }
    
}