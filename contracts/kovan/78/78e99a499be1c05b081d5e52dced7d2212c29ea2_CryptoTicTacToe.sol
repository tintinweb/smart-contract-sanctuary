/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity ^0.8.4;

contract CryptoTicTacToe {
    
    // Structs
    struct WinningCase {
        uint firstIndex;
        uint secondIndex;
        uint thirdIndex;
    }
    
    // Public Game State Variables
    bool public isGameFinished;
    address public playerO;
    address public playerX;
    address public currentPlayer;
    address public gameOwner;
    address public lastWinner;
    
    // Constants
    int8 private constant EMPTY_MOVE = -1;
    int8 private constant O_MOVE = 0;
    int8 private constant X_MOVE = 1;
    
    // Private Variables
    int8[9] private emptyBoard = [EMPTY_MOVE, EMPTY_MOVE, EMPTY_MOVE, EMPTY_MOVE, EMPTY_MOVE, EMPTY_MOVE, EMPTY_MOVE, EMPTY_MOVE, EMPTY_MOVE];
    int8[9] private gameBoard = int8[9](emptyBoard);
    WinningCase[] private winningCases;
    WinningCase private winnerCase;
    
    // Constructor
    constructor (address _playerO, address _playerX) public{
        // Initialize game variables
        gameOwner = msg.sender;
        playerO = _playerO;
        playerX = _playerX;
        currentPlayer = playerO;
        createWinningCases();
    }

    // PUBLIC CALLABLE METHODS
    // Attempt to make a move
    function makeMove (uint8 _index) public {
        require ((_index >= 0 && _index <= 9 && msg.sender == currentPlayer && gameBoard[_index] == EMPTY_MOVE && !isGameFinished), "Error: Cannot place a move. Make sure the input is valid.");
        gameBoard[_index] = (currentPlayer == playerO ? O_MOVE : X_MOVE);
        currentPlayer = (currentPlayer == playerO ? playerX : playerO);
        if (isBoardFull()){
            isGameFinished = true;
        }
        else if (hasWinner()){
            isGameFinished = true;
            lastWinner = getWinnerAddress();
        }
    }
     // Show actual board state
    function getBoard() public view returns (int8[9] memory) {
        return gameBoard;
    }
    
    // Attempt to change players
    function changePlayers(address _playerO, address _playerX) public {
        require (msg.sender == gameOwner, "Error: Only gameOwner can call changePlayers function");
        playerO = _playerO;
        playerX = _playerX;
    }
    
    // Attempt to change ownership
    function changeOwner(address _newOwner) public {
        require (msg.sender == gameOwner, "Error: Only gameOwner can call changeOwner function.");
        gameOwner = _newOwner;
    }
    
    // Reset game state
    function resetGame() public {
        require (msg.sender == gameOwner, "Error: Only gameOwner can call resetGame function.");
        isGameFinished = false;
        gameBoard = emptyBoard;
    }
    
    // PRIVATE HELPER METHODS
    // Create and add winning cases
    function createWinningCases() private {
        WinningCase memory case1 = WinningCase(0, 1, 2);
        WinningCase memory case2 = WinningCase(3, 4, 5);
        WinningCase memory case3 = WinningCase(6, 7, 8);
        WinningCase memory case4 = WinningCase(0, 3, 6);
        WinningCase memory case5 = WinningCase(1, 4, 7);
        WinningCase memory case6 = WinningCase(2, 5, 8);
        WinningCase memory case7 = WinningCase(0, 4, 8);
        WinningCase memory case8 = WinningCase(2, 4, 6);
        winningCases.push(case1);
        winningCases.push(case2);
        winningCases.push(case3);
        winningCases.push(case4);
        winningCases.push(case5);
        winningCases.push(case6);
        winningCases.push(case7);
        winningCases.push(case8);
    }
    
    // Check for a win
    function hasWinner() private returns (bool) {
        for (uint i = 0; i < winningCases.length; i++) {
            WinningCase memory currentCase = winningCases[i];
            uint firstIndex = currentCase.firstIndex;
            uint secondIndex = currentCase.secondIndex;
            uint thirdIndex = currentCase.thirdIndex;
            if (gameBoard[firstIndex] == gameBoard[secondIndex] && gameBoard[secondIndex] == gameBoard[thirdIndex] && gameBoard[firstIndex] != EMPTY_MOVE){
                winnerCase = currentCase;
                return true;
            }
        }
        
        return false;
    }
    
    // Get winner address
    function getWinnerAddress() private view returns (address winner) {
        return winnerCase.firstIndex == 0 ? playerO : playerX;
    }
    
    // Check if board is full
    function isBoardFull() private view returns (bool) {
        for (uint i = 0; i < gameBoard.length ; i++){
            if (gameBoard[i] == EMPTY_MOVE){
                return false;
            }
        }
        return true;
    }
}