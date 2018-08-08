/// @title Store lederboards in the Blockchain
/// @author Marcel Scherello blockscores@scherello.de
/// @notice Create a custom leaderboard and start counting the scores
/// @dev All function calls are currently implement without side effects
/// @dev v1.1.0
contract BlockScores {
    struct Player {
        bytes32  playerName;
        address playerAddress;
        uint  score;
        uint  score_unconfirmed;
        uint   isActive;
    }
    struct Board {
        bytes32  boardName;
        string  boardDescription;
        uint   numPlayers;
        address boardOwner;
        mapping (uint => Player) players;
    }
    mapping (bytes32 => Board) boards;
    uint public numBoards;
    address owner = msg.sender;

    uint public balance;
    uint public boardCost = 1000000000000000;
    uint public playerCost = 1000000000000000;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    /**
    Funding Functions
    */

    /// @notice withdraw all funds to contract owner
    /// @return true
    function withdraw() isOwner public returns(bool) {
        uint _amount = address(this).balance;
        emit Withdrawal(owner, _amount);
        owner.transfer(_amount);
        balance -= _amount;
        return true;
    }

    /// @notice change the costs for using the contract
    /// @param costBoard costs for a new board
    /// @param costPlayer costs for a new player
    /// @return true
    function setCosts (uint costBoard, uint costPlayer) isOwner public returns(bool) {
        boardCost = costBoard;
        playerCost = costPlayer;
        return true;
    }

    /// @notice split the revenue of a new player between boardOwner and contract owner
    /// @param boardOwner of the leaderboard
    /// @param _amount amount to be split
    /// @return true
    function split(address boardOwner, uint _amount) internal returns(bool) {
        emit Withdrawal(owner, _amount/2);
        owner.transfer(_amount/2);
        //emit Withdrawal(boardOwner, _amount/2);
        boardOwner.transfer(_amount/2);
        return true;
    }

    /// @notice Event for Withdrawal
    event Withdrawal(address indexed _from, uint _value);

    /**
    Board Functions
    */

    /// @notice Add a new leaderboard. Board hash will be created by name and creator
    /// @notice a funding is required to create a new leaderboard
    /// @param name The name of the leaderboard
    /// @param boardDescription A subtitle for the leaderboard
    /// @return The hash of the newly created leaderboard
    function addNewBoard(bytes32 name, string boardDescription) public payable returns(bytes32 boardHash){
        require(msg.value >= boardCost);
        balance += msg.value;
        boardHash = keccak256(abi.encodePacked(name, msg.sender));
        numBoards++;
        boards[boardHash] = Board(name, boardDescription, 0, msg.sender);
        emit newBoardCreated(boardHash);
    }

    /// @notice Simulate the creation of a leaderboard hash
    /// @param name The name of the leaderboard
    /// @param admin The address of the admin address
    /// @return The possible hash of the leaderboard
    function createBoardHash(bytes32 name, address admin) pure public returns (bytes32){
        return keccak256(abi.encodePacked(name, admin));
    }

    /// @notice Get the metadata of a leaderboard
    /// @param boardHash The hash of the leaderboard
    /// @return Leaderboard name, description and number of players
    function getBoardByHash(bytes32 boardHash) constant public returns(bytes32,string,uint){
        return (boards[boardHash].boardName, boards[boardHash].boardDescription, boards[boardHash].numPlayers);
    }

    /// @notice Overwrite leaderboard name and desctiption as owner only
    /// @param boardHash The hash of the leaderboard to be modified
    /// @param name The new name of the leaderboard
    /// @param boardDescription The new subtitle for the leaderboard
    /// @return true
    function changeBoardMetadata(bytes32 boardHash, bytes32 name, string boardDescription) public returns(bool) {
        require(boards[boardHash].boardOwner == msg.sender);
        boards[boardHash].boardName = name;
        boards[boardHash].boardDescription = boardDescription;
    }

    /// @notice event for newly created leaderboard
    event newBoardCreated(bytes32 boardHash);


    /**
    Player Functions
    */

    /// @notice Add a new player to an existing leaderboard
    /// @param boardHash The hash of the leaderboard
    /// @param playerName The name of the player
    /// @return Player ID
    function addPlayerToBoard(bytes32 boardHash, bytes32 playerName) public payable returns (bool) {
        require(msg.value >= playerCost);
        Board storage g = boards[boardHash];
        split (g.boardOwner, msg.value);
        uint newPlayerID = g.numPlayers++;
        g.players[newPlayerID] = Player(playerName, msg.sender,0,0,1);
        return true;
    }

    /// @notice Get player data by leaderboard hash and player id/index
    /// @param boardHash The hash of the leaderboard
    /// @param playerID Index number of the player
    /// @return Player name, confirmed score, unconfirmed score
    function getPlayerByBoard(bytes32 boardHash, uint8 playerID) constant public returns (bytes32, uint, uint){
        Player storage p = boards[boardHash].players[playerID];
        require(p.isActive == 1);
        return (p.playerName, p.score, p.score_unconfirmed);
    }

    /// @notice The leaderboard owner can remove a player
    /// @param boardHash The hash of the leaderboard
    /// @param playerName The name of the player to be removed
    /// @return true/false
    function removePlayerFromBoard(bytes32 boardHash, bytes32 playerName) public returns (bool){
        Board storage g = boards[boardHash];
        require(g.boardOwner == msg.sender);
        uint8 playerID = getPlayerId (boardHash, playerName, 0);
        require(playerID < 255 );
        g.players[playerID].isActive = 0;
        return true;
    }

    /// @notice Get the player id either by player Name or address
    /// @param boardHash The hash of the leaderboard
    /// @param playerName The name of the player
    /// @param playerAddress The player address
    /// @return ID or 999 in case of false
    function getPlayerId (bytes32 boardHash, bytes32 playerName, address playerAddress) constant internal returns (uint8) {
        Board storage g = boards[boardHash];
        for (uint8 i = 0; i <= g.numPlayers; i++) {
            if ((keccak256(abi.encodePacked(g.players[i].playerName)) == keccak256(abi.encodePacked(playerName)) || playerAddress == g.players[i].playerAddress) && g.players[i].isActive == 1) {
                return i;
                break;
            }
        }
        return 255;
    }

    /**
    Score Functions
    */

    /// @notice Add a unconfirmed score to leaderboard/player. Overwrites an existing unconfirmed score
    /// @param boardHash The hash of the leaderboard
    /// @param playerName The name of the player
    /// @param score Integer
    /// @return true/false
    function addBoardScore(bytes32 boardHash, bytes32 playerName, uint score) public returns (bool){
        uint8 playerID = getPlayerId (boardHash, playerName, 0);
        require(playerID < 255 );
        boards[boardHash].players[playerID].score_unconfirmed = score;
        return true;
    }

    /// @notice Confirm an unconfirmed score to leaderboard/player. Adds unconfirmed to existing score. Player can not confirm his own score
    /// @param boardHash The hash of the leaderboard
    /// @param playerName The name of the player who&#39;s score should be confirmed
    /// @return true/false
    function confirmBoardScore(bytes32 boardHash, bytes32 playerName) public returns (bool){
        uint8 playerID = getPlayerId (boardHash, playerName, 0);
        uint8 confirmerID = getPlayerId (boardHash, "", msg.sender);
        require(playerID < 255); // player needs to be active
        require(confirmerID < 255); // confirmer needs to be active
        require(boards[boardHash].players[playerID].playerAddress != msg.sender); //confirm only other players
        boards[boardHash].players[playerID].score += boards[boardHash].players[playerID].score_unconfirmed;
        boards[boardHash].players[playerID].score_unconfirmed = 0;
        return true;
    }

    /**
    Migration Functions
    */
    /// @notice Read board metadata for migration as contract owner only
    /// @param boardHash The hash of the leaderboard
    /// @return Bord metadata
    function migrationGetBoard(bytes32 boardHash) constant isOwner public returns(bytes32,string,uint,address) {
        return (boards[boardHash].boardName, boards[boardHash].boardDescription, boards[boardHash].numPlayers, boards[boardHash].boardOwner);
    }

    /// @notice Write board metadata for migration as contract owner only
    /// @param boardHash The hash of the leaderboard to be modified
    /// @param name The new name of the leaderboard
    /// @param boardDescription The new subtitle for the leaderboard
    /// @param boardOwner The address for the boardowner
    /// @return true
    function migrationSetBoard(bytes32 boardHash, bytes32 name, string boardDescription, uint8 numPlayers, address boardOwner) isOwner public returns(bool) {
        boards[boardHash].boardName = name;
        boards[boardHash].boardDescription = boardDescription;
        boards[boardHash].numPlayers = numPlayers;
        boards[boardHash].boardOwner = boardOwner;
        return true;
    }

    /// @notice Read player metadata for migration as contract owner
    /// @param boardHash The hash of the leaderboard
    /// @param playerID Index number of the player
    /// @return Player metadata
    function migrationGetPlayer(bytes32 boardHash, uint8 playerID) constant isOwner public returns (uint, bytes32, address, uint, uint, uint){
        Player storage p = boards[boardHash].players[playerID];
        return (playerID, p.playerName, p.playerAddress, p.score, p.score_unconfirmed, p.isActive);
    }

    /// @notice Write player metadata for migration as contract owner only
    /// @param boardHash The hash of the leaderboard
    /// @param playerID Player ID
    /// @param playerName Player name
    /// @param playerAddress Player address
    /// @param score Player score
    /// @param score_unconfirmed Player unconfirmed score
    /// @param isActive Player isActive
    /// @return true
    function migrationSetPlayer(bytes32 boardHash, uint playerID, bytes32 playerName, address playerAddress, uint score, uint score_unconfirmed, uint isActive) isOwner public returns (bool) {
        Board storage g = boards[boardHash];
        g.players[playerID] = Player(playerName, playerAddress, score, score_unconfirmed, isActive);
        return true;
    }

}