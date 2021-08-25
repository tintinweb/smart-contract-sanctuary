/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

pragma solidity ^0.4.23;

contract GAMCasino {
  address public owner;
  // The minimum bet a user has to make to participate in the game
  uint256 public minimumBet;

  // The total amount of Ether bet for this current game
  uint256 public totalBet;

  // The total number of bets the users have made
  uint256 public numberOfBets;

  // The max user of bets that cannot be exceeded to avoid excessive gas consumption
  // when distributing the prizes and restarting the game
  uint256 public maximumBetsNr = 2;

  // Save player when betting number
  address[] public players;

  // The number that won the last game
  uint public numberWinner;

  // Save player info
  struct Player {
    uint256 amountBet;
    uint256 numberSelected;
  }

  // The address of the player and => the user info
  mapping(address => Player) public playerInfo;

  // Event watch when player win
  event Won(bool _status, address _address, uint _amount);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor(uint256 _minimumBet) public payable {
    owner = msg.sender;
    if (_minimumBet != 0) 
      minimumBet = _minimumBet;
  }

  // fallback
  function() public payable {}

  function kill() public {
    if (msg.sender == owner) 
      selfdestruct(owner);
  }

  /// @notice The Bookie can withdraw money from the table
  /// @return bool Returns true if withdraw success
  function withdraw() public onlyOwner returns(bool) {
    owner.transfer(address(this).balance);
    return true;
  }

  /// @notice Check if a player exists in the current game
  /// @param player The address of the player to check
  /// @return bool Returns true is it exists or false if it doesn't
  function checkPlayerExists(address player) public constant returns(bool) {
    for (uint256 i = 0; i < players.length; i++) {
      if (players[i] == player) 
        return true;
    }
    return false;
  }

  /// @notice To bet for a number by sending Ether
  /// @param numberSelected The number that the player wants to bet for. Must be between 1 and 10 both inclusive
  function bet(uint256 numberSelected) public payable {
    // Check that the player doesn't exists
    require(!checkPlayerExists(msg.sender));
    // Check that the number to bet is within the range
    require(numberSelected <= 10 && numberSelected >= 1);
    // Check that the amount paid is bigger or equal the minimum bet
    require(msg.value >= minimumBet);

    // Set the number bet for that player
    playerInfo[msg.sender].amountBet = msg.value;
    playerInfo[msg.sender].numberSelected = numberSelected;
    numberOfBets++;
    players.push(msg.sender);
    totalBet += msg.value;
    if (numberOfBets >= maximumBetsNr)
      generateNumberWinner();
    //We need to change this in order to be secure
  }

  /// @notice Generates a random number between 1 and 10 both inclusive.
  /// Can only be executed when the game ends.
  function generateNumberWinner() public {
    uint256 numberGenerated = block.number % 10 + 1;
    numberWinner = numberGenerated;
    distributePrizes(numberGenerated);
  }

  /// @notice Sends the corresponding Ether to each winner then deletes all the
  /// players for the next game and resets the `totalBet` and `numberOfBets`
  function distributePrizes(uint256 numberWin) public {
    address[100] memory winners;
    address[100] memory losers;
    uint256 countWin = 0;
    uint256 countLose = 0;

    for (uint256 i = 0; i < players.length; i++) {
      address playerAddress = players[i];
      if (playerInfo[playerAddress].numberSelected == numberWin) {
        winners[countWin] = playerAddress;
        countWin++;
      } else {
        losers[countLose] = playerAddress;
        countLose++;
      }
      delete playerInfo[playerAddress];
    }

    if (countWin != 0) {
      uint256 winnerEtherAmount = totalBet/countWin;

      for (uint256 j = 0; j < countWin; j++){
        if (winners[j] != address(0)) {
          winners[j].transfer(winnerEtherAmount);
          emit Won(true, winners[j], winnerEtherAmount);
        }
      }
    }

    for (uint256 l = 0; l < losers.length; l++){
      if (losers[l] != address(0))
        emit Won(false, losers[l], 0);
    }

    resetData();
  }

  // Restart game
  function resetData() public {
    players.length = 0;
    totalBet = 0;
    numberOfBets = 0;
  }
}