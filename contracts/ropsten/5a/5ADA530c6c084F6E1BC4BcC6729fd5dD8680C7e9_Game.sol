/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.4;

contract Game {
  /*
  Game is responsible for maintaining the internal state of the game along with its validity.
  */

  // UTILITIES

  event printInt(int val);
  event printString(string val);

  // GAME STATE

  // Note: To save space, we only ever keep track of where P and E are individually.
  // Note: There is therefore no actual game board, but game board boundaries and a set of rules restricting movement.

  // for quick access to an 'imaginary' game board (rows: A-J, cols: 0-9)
  // we have index from 0 to 99 (a total of 100)
  // each row has 10, so A: 0-9, B: 10-19, ... J: 90-99
  // To get an index, we use rowIncrement + colNum
  mapping (string => int) private rowIncrements;
  mapping (string => int) private validRow;
  mapping (string => int) private playerPositions;
  int totalMovesByPAndE; // turn no. = totalMovesByPAndE/2 (since we always increase totalMovesByPAndE by pairs i.e. 1 for P, 1 for E)
  string winner;
  int MAXIMUM_TURN_ROUNDS = 10;

  // GAME INITIALIZATION AND RESTART

  /*
  Starts the initial instance of the Game object, which refreshes at a new game
  */
  constructor() {
    newGame();
  }

  /*
  Refreshes the Game to the start condition
  API: This is used by the auction manager to restart games
  */
  function newGame() public {
      initializeRowDetails();
      resetGameBoard();
      totalMovesByPAndE = 0;
      winner = "E";
  }

  /*
  Determines if game has ended
  API: The auction manager may use this function to check for the current game's end, which then to restart game, call the function newGame
  */
  function hasGameEnded() public view returns (bool) {
      return (totalMovesByPAndE >= MAXIMUM_TURN_ROUNDS) || (getCurrentPursuerIndex() == getCurrentEvaderIndex()) || (keccak256(abi.encodePacked(winner)) == keccak256(abi.encodePacked("P")));
  }

  /*
  Determines the winner of the current game round
  API: This should be used with hasGameEnded to determine the winner
  Note: Recommended to call hasGameEnded at the end of each turn after submitting the 'correct' P and E next moves, and call getGameWinner if hasGameEnded is true
  */
  function getGameWinner() public view returns (string memory) {
      return winner;
  }

  function getTurnNumber() public view returns (int) {
      return totalMovesByPAndE/2 + 1;
  }

  /*
  Sets both rowIncrements and validRow
  */
  function initializeRowDetails() private {
    // Index = rowIncrement[rowLetter] + col
    rowIncrements['A'] = 0;
    rowIncrements['B'] = 10;
    rowIncrements['C'] = 20;
    rowIncrements['D'] = 30;
    rowIncrements['E'] = 40;
    rowIncrements['F'] = 50;
    rowIncrements['G'] = 60;
    rowIncrements['H'] = 70;
    rowIncrements['I'] = 80;
    rowIncrements['J'] = 90;

    // Valid if validRow[rowLetter] > 0
    validRow['A'] = 1;
    validRow['B'] = 1;
    validRow['C'] = 1;
    validRow['D'] = 1;
    validRow['E'] = 1;
    validRow['F'] = 1;
    validRow['G'] = 1;
    validRow['H'] = 1;
    validRow['I'] = 1;
    validRow['J'] = 1;
  }

  /*
  Helper function to refresh gameBoard, with Pursuer at bottom left corner (0,0) and Evader E at 5th row, 5th col (4, 4)
  Note: (4,4) is used from (5-1, 5-1) due to 0 indexing
  */
  function resetGameBoard() private {
    setCurrentPursuerIndex(0);
    setCurrentEvaderIndex(44);
  }

  // GAME BOARD INDEX

  /*
  Converts the user input for positions into its corresponding gameBoard index (0-99) for direct access on gameBoard
  */
  function getIndexFromRowCol(string memory row, int col) private view returns (int) {
      return rowIncrements[row] + col;
  }

  /*
  Similar to isValidInput, except this uses the resultant value (0-99) converted by getIndexFromRowCol from input (row, col) from user
  */
  function isValidIndex(int idx) private pure returns (bool) {
      return ((idx >= 0) && (idx < 100));
  }

  /*
  Checks for valid row and col entered by the user
  API: This is used by the auction manager to check if the user input (row: string, col: int) is valid
  */
  function isValidInput(string memory row, int col) public view returns (bool) {
      return (isValidRow(row) && isValidCol(col));
  }

  function isValidRow(string memory row) private view returns (bool) {
      return (validRow[row] > 0);
  }

  function isValidCol(int col) private pure returns (bool) {
      return ((col >= 0) && (col < 10));
  }


  /*
  Identifies the index the pursuer P is currently at in the gameBoard
  API: This is used to provide data for the visual on where P is
  */
  function getCurrentPursuerIndex() public view returns (int) {
      return playerPositions["P"];
  }

  /*
  Identifies the index the evader E is currently at in the gameBoard
  API: This is used to provide data for the visual on where E is
  */
  function getCurrentEvaderIndex() public view returns (int) {
      return playerPositions["E"];
  }

  function setCurrentPursuerIndex(int newPursuerIdx) private {
      playerPositions["P"] = newPursuerIdx;
  }

  function setCurrentEvaderIndex(int newEvaderIdx) private {
      playerPositions["E"] = newEvaderIdx;
  }

  // PURSUER MOVEMENT
  
  function isValidMovePursuerUpRight() public view returns (bool) {
      int currentIdx = getCurrentPursuerIndex();
      return (currentIdx == playerPositions["P"]) && ((currentIdx % 10) < 9) && ((currentIdx+10) < 100);
  }

  function movePursuerUpRight() public {
      int currentIdx = getCurrentPursuerIndex();
      require((currentIdx == playerPositions["P"]), "Move Failed: Only Pursuer (P) can perform this movement");
      require(((currentIdx % 10) < 9), "Move Failed: Attemped to move diagonally out of the allowed right barrier");
      require(((currentIdx+10) < 100), "Move Failed: Attemped to move diagonally out of the allowed top barrier");

      moveFromTo(currentIdx, currentIdx+11);
  }

  function isValidMovePursuerUpLeft() public view returns (bool) {
      int currentIdx = getCurrentPursuerIndex();
      return (currentIdx == playerPositions["P"]) && ((currentIdx % 10) > 0) && ((currentIdx+10) < 100);
  }

  function movePursuerUpLeft() public {
      int currentIdx = getCurrentPursuerIndex();
      require((currentIdx == playerPositions["P"]), "Move Failed: Only Pursuer (P) can perform this movement");
      require(((currentIdx % 10) > 0), "Move Failed: Attemped to move diagonally out of the allowed left barrier");
      require(((currentIdx+10) < 100), "Move Failed: Attemped to move diagonally out of the allowed top barrier");

      moveFromTo(currentIdx, currentIdx+9);
  }

  function isValidMovePursuerDownRight() public view returns (bool) {
      int currentIdx = getCurrentPursuerIndex();
      return (currentIdx == playerPositions["P"]) && ((currentIdx % 10) < 9) && ((currentIdx-10) >= 0);
  }

  function movePursuerDownRight() public {
      int currentIdx = getCurrentPursuerIndex();
      require((currentIdx == playerPositions["P"]), "Move Failed: Only Pursuer (P) can perform this movement");
      require(((currentIdx % 10) < 9), "Move Failed: Attemped to move diagonally out of the allowed right barrier");
      require(((currentIdx-10) >= 0), "Move Failed: Attemped to move diagonally out of the allowed bottom barrier");

      moveFromTo(currentIdx, currentIdx-9);
  }

  function isValidMovePursuerDownLeft() public view returns (bool) {
      int currentIdx = getCurrentPursuerIndex();
      return (currentIdx == playerPositions["P"]) && ((currentIdx % 10) > 0) && ((currentIdx-10) >= 0);
  }

  function movePursuerDownLeft() public {
      int currentIdx = getCurrentPursuerIndex();
      require((currentIdx == playerPositions["P"]), "Move Failed: Only Pursuer (P) can perform this movement");
      require(((currentIdx % 10) > 0), "Move Failed: Attemped to move diagonally out of the allowed left barrier");
      require(((currentIdx-10) >= 0), "Move Failed: Attemped to move diagonally out of the allowed bottom barrier");

      moveFromTo(currentIdx, currentIdx-11);
  }
  
  function isValidMovePursuerUp() public view returns (bool) {
      int currentIdx = getCurrentPursuerIndex();
      return (currentIdx == playerPositions["P"]) && ((currentIdx+10) < 100);
  }

  function movePursuerUp() public {
      int currentIdx = getCurrentPursuerIndex();
      require((currentIdx == playerPositions["P"]), "Move Failed: Only Pursuer (P) can perform this movement");
      require(((currentIdx+10) < 100), "Move Failed: Attemped to move out of the allowed top barrier");

      moveUp(currentIdx);
  }

  function isValidMovePursuerDown() public view returns (bool) {
      int currentIdx = getCurrentPursuerIndex();
      return (currentIdx == playerPositions["P"]) && ((currentIdx-10) >= 0);
  }

  function movePursuerDown() public {
      int currentIdx = getCurrentPursuerIndex();
      require((currentIdx == playerPositions["P"]), "Move Failed: Only Pursuer (P) can perform this movement");
      require(((currentIdx-10) >= 0), "Move Failed: Attemped to move out of the allowed bottom barrier");

      moveDown(currentIdx);
  }

  function isValidMovePursuerLeft() public view returns (bool) {
      int currentIdx = getCurrentPursuerIndex();
      return (currentIdx == playerPositions["P"]) && ((currentIdx % 10) > 0);
  }

  function movePursuerLeft() public {
      int currentIdx = getCurrentPursuerIndex();
      require((currentIdx == playerPositions["P"]), "Move Failed: Only Pursuer (P) can perform this movement");
      require(((currentIdx % 10) > 0), "Move Failed: Attemped to move out of the allowed left barrier");

      moveLeft(currentIdx);
  }

  function isValidMovePursuerRight() public view returns (bool) {
      int currentIdx = getCurrentPursuerIndex();
      return (currentIdx == playerPositions["P"]) && ((currentIdx % 10) < 9);
  }

  function movePursuerRight() public {
      int currentIdx = getCurrentPursuerIndex();
      require((currentIdx == playerPositions["P"]), "Move Failed: Only Pursuer (P) can perform this movement");
      require(((currentIdx % 10) < 9), "Move Failed: Attemped to move out of the allowed right barrier");

      moveRight(currentIdx);
  }

  // EVADER MOVEMENT

  function isValidMoveEvaderUp() public view returns (bool) {
      int currentIdx = getCurrentEvaderIndex();
      return (currentIdx == playerPositions["E"]) && ((currentIdx+10) < 100);
  }

  function moveEvaderUp() public {
      int currentIdx = getCurrentEvaderIndex();
      require((currentIdx == playerPositions["E"]), "Move Failed: Only Evader (E) can perform this movement");
      require(((currentIdx+10) < 100), "Move Failed: Attemped to move out of the allowed top barrier");

      moveUp(currentIdx);
  }

  function isValidMoveEvaderDown() public view returns (bool) {
      int currentIdx = getCurrentEvaderIndex();
      return (currentIdx == playerPositions["E"]) && ((currentIdx-10) >= 0);
  }
  
  function moveEvaderDown() public {
      int currentIdx = getCurrentEvaderIndex();
      require((currentIdx == playerPositions["E"]), "Move Failed: Only Evader (E) can perform this movement");
      require(((currentIdx-10) >= 0), "Move Failed: Attemped to move out of the allowed bottom barrier");

      moveDown(currentIdx);
  }

  function isValidMoveEvaderLeft() public view returns (bool) {
      int currentIdx = getCurrentEvaderIndex();
      return (currentIdx == playerPositions["E"]) && ((currentIdx % 10) > 0);
  }

  function moveEvaderLeft() public {
      int currentIdx = getCurrentEvaderIndex();
      require((currentIdx == playerPositions["E"]), "Move Failed: Only Evader (E) can perform this movement");
      require(((currentIdx % 10) > 0), "Move Failed: Attemped to move out of the allowed left barrier");

      moveLeft(currentIdx);
  }

  function isValidMoveEvaderRight() public view returns (bool) {
      int currentIdx = getCurrentEvaderIndex();
      return (currentIdx == playerPositions["E"]) && ((currentIdx % 10) < 9);
  }

  function moveEvaderRight() public {
      int currentIdx = getCurrentEvaderIndex();
      require((currentIdx == playerPositions["E"]), "Move Failed: Only Evader (E) can perform this movement");
      require(((currentIdx % 10) < 9), "Move Failed: Attemped to move out of the allowed right barrier");

      moveRight(currentIdx);
  }

  // BASIC MOVEMENT HELPER FUNCTIONS

  function moveUp(int currentIdx) private {
      require(((currentIdx+10) < 100), "Move Failed: Attempted to move out of the allowed top grid");
      moveFromTo(currentIdx, currentIdx+10);
  }

  function moveDown(int currentIdx) private {
      require(((currentIdx-10) >= 0), "Move Failed: Attempted to move out of the allowed bottom grid");
      moveFromTo(currentIdx, currentIdx-10);
  }

  function moveLeft(int currentIdx) private {
      require(((currentIdx % 10) > 0), "Move Failed: Attemped to move out of the allowed left barrier");
      moveFromTo(currentIdx, currentIdx-1);
  }

  function moveRight(int currentIdx) private {
      require(((currentIdx % 10) < 9), "Move Failed: Attemped to move out of the allowed right barrier");
      moveFromTo(currentIdx, currentIdx+1);
  }

  /*
  Moves the previousIdx presence to the newIdx position on gameBoard via a swap mechanic
  */
  function moveFromTo(int previousIdx, int newIdx) private {
      require((previousIdx == playerPositions["P"]) || (previousIdx == playerPositions["E"]), "Move Failed: Only Pursuer (P) and Evader (E) can be moved");
      require(isValidIndex(previousIdx), "Move Failed: The starting position of the move is invalid");
      require(((newIdx < 100) && (newIdx >= 0)), "Move Failed: Attempted to move out of the allowed top/bottom grid");

      // identify P or E to move
      if (previousIdx == getCurrentPursuerIndex()) {
          setCurrentPursuerIndex(newIdx);
      } else if (previousIdx == getCurrentEvaderIndex()) {
          setCurrentEvaderIndex(newIdx);
      }

      // update game total moves for current round
      totalMovesByPAndE = totalMovesByPAndE + 1;

      // if P catches E, P wins and game should end
      if (getCurrentPursuerIndex() == getCurrentEvaderIndex()) {
          winner = "P";
      }
      
  }

}