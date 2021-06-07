/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

contract BlockPaperScissors {

    enum Move { None, Block, Paper, Scissors}
    enum GameState { None, Started, Played, Evaluated}
    enum GameResult { None, FirstPlayerWin, SecondPlayerWin, Draw }
    struct Game {
        GameState state;
        string title;
        address firstPlayer;
        address secondPlayer;
        bytes32 firstMoveEncrypted;
        bytes32 firstMoveSecret;
        Move firstMove;
        Move secondMove;
        GameResult result;
    }
    
    uint256 gameCount;

    mapping(bytes32 => Game) games;
    mapping(address => bytes32[]) public playerGames;

    event GameStarted(address firstPlayer, address secondPlayer, bytes32 gameId);
    event SecondMovePlayed(address firstPlayer, address secondPlayer, bytes32 gameId, Move move);
    event GameEvaluated(address firstPlayer, address secondPlayer, bytes32 gameId, GameResult result);

    function encryptMove(uint8 move, bytes32 secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(move, secret));
    }

    function decryptMove(bytes32 encryptedMove, bytes32 secret) public pure returns (uint8) {
        bytes32 currentHash;
        for(uint8 i = 1; i<4; i++){
            currentHash = encryptMove(i, secret);
            if(currentHash == encryptedMove){
                return(i);
            }
        }
        return 0;
    }

    function startGame(string memory title, address opponent, bytes32 encryptedMove) public returns(bytes32 gameId) {
        gameId = keccak256(abi.encodePacked(gameCount, title, msg.sender, opponent));
        gameCount++;

        games[gameId].title = title;
        games[gameId].state = GameState.Started;
        games[gameId].firstPlayer = msg.sender;
        games[gameId].secondPlayer = opponent;

        playerGames[msg.sender].push(gameId);
        playerGames[opponent].push(gameId);


        games[gameId].firstMoveEncrypted = encryptedMove;
        emit GameStarted(msg.sender, opponent, gameId);
    }

    function makeMove(bytes32 gameId, uint8 move) public {
        require(move <= 3, "Invalid Move: Out of range");
        require(move > 0, "Invalid Move: Zero");
        require(msg.sender == games[gameId].secondPlayer, "Sender is not the second player");
        require(games[gameId].state == GameState.Started, "Can't move in current game state");

        games[gameId].secondMove = Move(move);
        games[gameId].state = GameState.Played;

        emit SecondMovePlayed(games[gameId].firstPlayer, msg.sender, gameId, Move(move));
    }


    function evaluateGame(bytes32 gameId, bytes32 secret) public {
        require(msg.sender == games[gameId].firstPlayer, "Sender is not the first player");
        require(games[gameId].state == GameState.Played, "Can't reveal move in current game state");

        // Decrypt move using given secret
        bytes32 encryptedMove = games[gameId].firstMoveEncrypted;
        uint8 decryptedMove = decryptMove(encryptedMove, secret);
        require(decryptedMove > 0, "No valid move could be decrypted for given secret");
        games[gameId].firstMoveSecret = secret;

        // Evaluate Game
        games[gameId].firstMove = Move(decryptedMove);
        games[gameId].result = _calculateGameResult(games[gameId].firstMove, games[gameId].secondMove);
        games[gameId].state = GameState.Evaluated;
        emit GameEvaluated(msg.sender, games[gameId].secondPlayer, gameId, games[gameId].result);
    }

    function _calculateGameResult(Move firstMove, Move secondMove) internal returns(GameResult){
        if(firstMove == secondMove){
            return GameResult.Draw;
        }
        bool firstPlayerWon = (firstMove == Move.Block && secondMove == Move.Scissors) ||
            (firstMove == Move.Paper && secondMove == Move.Block) ||
            (firstMove == Move.Scissors && secondMove == Move.Paper);
        if(firstPlayerWon){
            return GameResult.FirstPlayerWin;
        }
        return GameResult.SecondPlayerWin;
    }

    function getGameResult(bytes32 gameId) public view returns(uint8){
        return uint8(games[gameId].result);
    }
    
    function getPlayerGames(address player) public view returns(bytes32[] memory){
        return playerGames[player];
    }

    function getGameData(bytes32 gameId) public view returns(uint8, address, address, bytes32, bytes32, uint8, uint8, uint8, string memory){
        Game storage game = games[gameId];
        return (uint8(game.state), game.firstPlayer, game.secondPlayer,
                game.firstMoveEncrypted, game.firstMoveSecret,
                uint8(game.firstMove), uint8(game.secondMove),
                uint8(game.result), game.title);
    }

}