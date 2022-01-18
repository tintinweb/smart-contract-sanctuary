/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: No-License
// The following creation is the exclusive property of his creator

pragma solidity >=0.8.0 < 0.9.0;

contract RockPaperScissors {

    address private admin;
    
    address[] private winners;
    address[] private players;

    uint private roomNumber;
    uint private roundNumber;
    bool private roomOpen;
    uint private roundEndTime;
    bool private updateParametersOnNextRoom;

    uint private entryBet;
    uint private fees;
    uint private seatsNumberFactor;
    uint private timePerRound;
    bool private registrationAllowed;

    uint private newEntryBet;
    uint private newFees;
    uint private newSeatsNumberFactor;
    uint private newTimePerRound;
    bool private newRegistrationAllowed;
    
    struct Play {
        bytes32 encryptMove;
        bool played;
        bytes1 decryptMove;
        bool revealed;
    }

    mapping(address => Play) private plays;
    mapping(uint => address) public hallOfFame;

    constructor() {
        admin = msg.sender;
        roomOpen = true;
        entryBet = 1e8 gwei;
        fees = 10;
        seatsNumberFactor = 2;
        timePerRound = 3600;
        registrationAllowed = true;
        updateParametersOnNextRoom = false;
    }

    // Register player in the room
    function register() payable external onlyRegistrationAllowed onlyRoomOpen onlyNonRegisteredPlayer  {
        
        // Check player is sending the expected bet
        require(msg.value == entryBet, "You have to send the expected bet");

        players.push(msg.sender);
        plays[msg.sender] = Play('', false, '', false);

        emit PlayerRegistered(roomNumber, msg.sender);

        // If room is full Close Room and Start Game
        if(players.length == 2**seatsNumberFactor) {
            startGame();
            emit GameStarted(roomNumber, players, seatsNumberFactor);
        }
    }

    function play(bytes32 encryptMove) public onlyRegisteredPlayer onlyRoomClose {
        
        // Check player has not played yet
        require(!plays[msg.sender].played, "You already played");

        plays[msg.sender].encryptMove = encryptMove;
        plays[msg.sender].played = true;

        emit PlayerMove(roomNumber, roundNumber, msg.sender, "Player played");
        emit OpponentMove(roomNumber, roundNumber, getOpponentAddress(), "Your opponent played");
    }

    function reveal(string memory decryptMove) public onlyRegisteredPlayer onlyRoomClose returns(string memory) {

        address opponentAddress = getOpponentAddress();

        // Check player played
        require(plays[msg.sender].played, "You must play first");
        // Check opponent played
        require(plays[opponentAddress].played, "Your opponent must play first");
        // Check player has not revealed yet
        require(!plays[msg.sender].revealed, "Your move has already been revealed");
        // Check encryptMove == decryptMove
        require(plays[msg.sender].encryptMove == sha256(bytes (decryptMove)), "Your decrypted move do not match encrypted one");
        // Check Move correspond to expected value
        require(bytes(decryptMove)[0] == bytes1("1") || bytes(decryptMove)[0] == bytes1("2") || bytes(decryptMove)[0] == bytes1("3"), "Your move is not matching expected move");

        plays[msg.sender].decryptMove = bytes(decryptMove)[0];
        plays[msg.sender].revealed = true;

        // If opponent revealed => get match Winner
        if(plays[opponentAddress].revealed) { 

            winners.push(getMatchWinner(opponentAddress));

            // If everybody played => go to next round
            if(winners.length == players.length / 2) {
             return goToNextRound();
            }
        }
        emit PlayerMove(roomNumber, roundNumber, msg.sender, "Player revealed");
        emit OpponentMove(roomNumber, roundNumber, getOpponentAddress(), "Your opponent revealed");
        return "Waiting for your opponent to reveal";
    }

    // #############################################
    // ############# Player Utilities ##############
    // #############################################

    function canIReveal() external view onlyRegisteredPlayer onlyRoomClose onlyPlayerPlayed returns(bool) {
        return plays[getOpponentAddress()].played;
    }


    function getPlayers() external view returns(address[] memory) {
        return players;
    }

    function getContractValue() external view returns(uint) {
        return address(this).balance;
    }

    function getMyOpponentAddress() public view onlyRegisteredPlayer onlyRoomClose returns(address) {
        return getOpponentAddress();
    }

    function getGameParameters() public view returns(uint EntryBet, uint RoomNumber, bool RoomOpen, uint RoundNumber, uint SeatsNumber, uint TimePerRound, uint prize, bool RegistrationAllowed, bool UpdateParametersOnNextRoom) {
        return (entryBet, roomNumber, roomOpen, roundNumber, 2**seatsNumberFactor, timePerRound, entryBet * 2**seatsNumberFactor * (100 - fees) / 100,registrationAllowed, updateParametersOnNextRoom);
    }

    function forceEndRound() public onlyRoomClose {
        require(block.timestamp > roundEndTime, "There is still time to play");

        for(uint i = 0; i < players.length; i += 2) {
            if(plays[players[i]].revealed == true && plays[players[i+1]].revealed == false) {
                winners.push(players[i]);
                emit MatchResult(roomNumber, roundNumber, players[i], players[i+1], plays[players[i]].decryptMove, 0, "Default Winner - Opponent did not revealed in the alloted time");
            }
            if(plays[players[i]].revealed == false && plays[players[i+1]].revealed == true) {
                winners.push(players[i+1]);
                emit MatchResult(roomNumber, roundNumber, players[i+1], players[i], plays[players[i+1]].decryptMove, 0, "Default Winner - Opponent did not revealed in the alloted time");
            }
            if(plays[players[i]].played == true && plays[players[i+1]].played == false) {
                winners.push(players[i]);
                emit MatchResult(roomNumber, roundNumber, players[i], players[i+1], 0, 0, "Default Winner - Opponent did not played in the alloted time");
            }
            if(plays[players[i]].played == false && plays[players[i+1]].played == true) {
                winners.push(players[i+1]);
                emit MatchResult(roomNumber, roundNumber, players[i+1], players[i], 0, 0, "Default Winner - Opponent did not played in the alloted time");
            }
            // Random winner
            if(plays[players[i]].played == false && plays[players[i+1]].played == false) {
                winners.push(players[i + block.timestamp % 2]);
                emit MatchResult(roomNumber, roundNumber, players[i + block.timestamp % 2], players[i + (block.timestamp + 1) % 2], 0, 0, "Random Winner - No one played");
            }
            if(plays[players[i]].revealed == false && plays[players[i+1]].revealed == false) {
                winners.push(players[i + block.timestamp % 2]);
                emit MatchResult(roomNumber, roundNumber, players[i + block.timestamp % 2], players[i + (block.timestamp + 1) % 2], 0, 0, "Random Winner - No one revealed");
            }
            // If both revealed do nothing
        }
    }

    function leftTimeToPlay() public view onlyRoomClose returns(uint){
        if(block.timestamp > roundEndTime) {
            return 0;
        }
            return roundEndTime - block.timestamp;
    }

    // #############################################
    // ############# Admin Utilities ###############
    // #############################################

    function updateParameters(uint updatedEntryBet, uint updateFees, uint updateSeatsNumberFactor, uint updatedTimePerRound, bool updatedRegistrationAllowed) public onlyAdmin {
        require(updateFees < 100, "Fees are too high");
        require(updateSeatsNumberFactor > 0, "Cannot have 1 seats");
        require(updateSeatsNumberFactor < 21, "Cannot have more than 1 million seats");
        require(updatedTimePerRound >= 600, "Minimum time to play is 10 minutes");

        newEntryBet = updatedEntryBet;
        newFees = updateFees;
        newSeatsNumberFactor = 2**updateSeatsNumberFactor;
        newTimePerRound = updatedTimePerRound;
        newRegistrationAllowed = updatedRegistrationAllowed;
        updateParametersOnNextRoom = true;
    }

    function allowRegistration() public onlyAdmin {
        registrationAllowed = true;
        emit RegistrationIsNowAllowed(roomNumber);
    }

    function withdrawMoney(uint amount) public payable onlyAdmin {
        if(amount == 0) { amount = address(this).balance; }
        payable(msg.sender).transfer(amount);
    }

    function cancelRoom(string memory cancelReason) public onlyAdmin onlyRoomOpen {
        for(uint i = 0; i < players.length; i++) {
            payable(players[i]).transfer(entryBet);
        }
        emit RoomCanceled(roomNumber, cancelReason);
        resetRoom();
    }

    // #############################################
    // ######## Contract Utilities #################
    // #############################################

    function startGame() private {
        roomOpen = false;
        roundNumber = 1;
        shufflePlayers();
        roundEndTime = block.timestamp + timePerRound;
    }

    // Shuffle players list
    function shufflePlayers() private {
        for (uint i = 0; i < players.length; i++) {
            uint n = i + uint(keccak256(abi.encodePacked(block.timestamp))) % (players.length - i);
            address temp = players[n];
            players[n] = players[i];
            players[i] = temp;
        }
    }        
    
    function isPlayer() private view returns (bool) {
           for(uint i = 0; i < players.length; i++) {
            if(players[i] == msg.sender) {
                return true;
                }
        }
        return false;
    }

    function getOpponentAddress() private view returns(address) {
        uint playerIndex = getElementIndex(players, msg.sender);

        if(playerIndex % 2 == 0) {
            return players[playerIndex + 1];
        }
        
        return players[playerIndex - 1];
    }

    function getMatchWinner(address opponentAddress) private returns(address) {
        bytes1 playerMove = plays[msg.sender].decryptMove;
        bytes1 opponentMove = plays[opponentAddress].decryptMove;

        // Rock - Paper
        if(playerMove == bytes1("1") && opponentMove == bytes1("2")) { 
            emit MatchResult(roomNumber, roundNumber, opponentAddress, msg.sender, opponentMove, playerMove, "Fair Game");
            return opponentAddress; 
        }
        // Rock - Scissors
        if(playerMove == bytes1("1") && opponentMove == bytes1("3")) { 
            emit MatchResult(roomNumber, roundNumber, msg.sender, opponentAddress, playerMove, opponentMove, "Fair Game");
            return msg.sender; 
        }
        // Paper - Rock
        if(playerMove == bytes1("2") && opponentMove == bytes1("1")) { 
            emit MatchResult(roomNumber, roundNumber, msg.sender, opponentAddress, playerMove, opponentMove, "Fair Game");
            return msg.sender; 
        }
        // Paper - Scissors
        if(playerMove == bytes1("2") && opponentMove == bytes1("3")) { 
            emit MatchResult(roomNumber, roundNumber, opponentAddress, msg.sender, opponentMove, playerMove, "Fair Game");
            return opponentAddress; 
        }
        // Scissors - Rock
        if(playerMove == bytes1("3") && opponentMove == bytes1("1")) { 
            emit MatchResult(roomNumber, roundNumber, opponentAddress, msg.sender, opponentMove, playerMove, "Fair Game");
            return opponentAddress; 
        }
        // Scissors - Paper
        if(playerMove == bytes1("3") && opponentMove == bytes1("2")) { 
            emit MatchResult(roomNumber, roundNumber, msg.sender, opponentAddress, playerMove, opponentMove, "Fair Game");
            return msg.sender; 
        }
        // playerMove == opponentMove -> firts to reveal win
        emit MatchResult(roomNumber, roundNumber, opponentAddress, msg.sender, opponentMove, playerMove, "Equality - First to reveal won");
        return opponentAddress;
    }

    function resetMoves() private {
        for(uint i = 0; i < players.length; i++) {
            delete plays[players[i]];
        }
    }

    function resetRound() private {
        resetMoves();
        delete players;
        players = winners;
        delete winners;
        roundEndTime = block.timestamp + timePerRound;
        roundNumber++;

        emit NewRoundStarted(roomNumber, roundNumber);
    }

    function resetRoom() private {
        resetRound();
        delete players;
        roomOpen = true;
        roomNumber++;
        roundNumber = 0;
        roundEndTime = 0;
        
        if (updateParametersOnNextRoom) {
            entryBet = newEntryBet;
            fees = newFees;
            seatsNumberFactor = newSeatsNumberFactor;
            timePerRound = newTimePerRound;
            registrationAllowed = newRegistrationAllowed;
            updateParametersOnNextRoom = false;
        }

        emit NewRoomOpened(roomNumber, entryBet, 2**seatsNumberFactor, timePerRound);
    }

    function goToNextRound() private returns(string memory){
        // Check if this was final round
        if(winners.length == 1) {
            payWinner();
            hallOfFame[roomNumber] = winners[0];
            emit GameEnded(roomNumber, winners[0], entryBet * 2**seatsNumberFactor * (100 - fees) / 100);
            resetRoom();
            return "We have a winner ! New Room Opened";
        }     
        resetRound();
        return "Next Round Started";
    }

    // Pay Winner
    function payWinner() private {
        payable(winners[0]).transfer(entryBet * 2**seatsNumberFactor * (100 - fees) / 100);
    }

    // ############################################
    // ################ Modifiers #################
    // ############################################

    modifier onlyAdmin {
        require(msg.sender == admin, "Only Admin can perform this action");
        _;
    }

    modifier onlyRegisteredPlayer {
        require(isPlayer(), "Only Registerd Players can perform this action");
        _;
    }

    modifier onlyNonRegisteredPlayer {
        require(!isPlayer(), "Only Non Registered Players can perform this action");
        _;
    }

    modifier onlyRegistrationAllowed {
        require(registrationAllowed, "Registration is not allowed for the moment");
        _;
    }

    modifier onlyRoomOpen {
        require(roomOpen, "Room is closed, game has started");
        _;
    }

    modifier onlyRoomClose {
        require(!roomOpen, "Room is still open, game has not started yet");
        _;
    }

    modifier onlyPlayerPlayed {
        require(plays[msg.sender].played, "Only player who played can perform this action");
        _;
    }

    // ############################################
    // ################ Events ####################
    // ############################################

    event NewRoomOpened(uint indexed roomNumber, uint entryBet, uint seatsNumber, uint timePerRound);
    event RegistrationIsNowAllowed(uint indexed roomNumber);

    event PlayerRegistered(uint indexed roomNumber, address indexed player);
    event GameStarted(uint indexed roomNumber, address[] players, uint numberOfRounds);
    
    event PlayerMove(uint indexed roomNumber, uint roundNumber, address indexed player, string comment);
    event OpponentMove(uint indexed roomNumber, uint roundNumber, address indexed player, string comment);
    event MatchResult(uint indexed roomNumber, uint roundNumber, address indexed winner, address indexed looser, bytes1 winnerMove, bytes1 looserMove, string comment);
    
    event NewRoundStarted(uint indexed roomNumber, uint indexed roundNumber);

    event GameEnded(uint indexed roomNumber, address indexed winner, uint prize);

    event RoomCanceled(uint indexed roomNumber, string comment);
    
    // ############################################
    // ################ Other #####################
    // ############################################

    function getElementIndex(address[] memory array, address element) private pure returns(uint) {
        for(uint i = 0; i < array.length; i++) {
            if(array[i] == element) {
            return i;
            }
        }
        return 0;
    }

}