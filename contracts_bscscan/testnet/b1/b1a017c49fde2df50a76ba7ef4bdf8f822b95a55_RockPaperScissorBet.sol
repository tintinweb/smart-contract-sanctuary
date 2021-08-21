/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract RockPaperScissorBet {
  uint256 private matchId = 0;

  // Add safe math

  struct Player {
    // This can be Rock, Paper or Scissors
    uint256 wins;
    uint256 losses;
    int256 balancePlayer;
    uint256 rank;
  }

  enum GameStatus {
    pending,
    ended
  }

  struct Match {
    bytes32 cardA;
    uint8 cardB;
    address payable playerA;
    address payable playerB;
    uint256 bet;
    GameStatus status;
    uint256 GameStartTime;
  }

  uint256 public stake;
  mapping(uint256 => Match) public matches;
  mapping(address => Player) public players;

  event MatchProposal(
    address playerA,
    address indexed playerB,
    uint256 bet,
    uint256 matchId,
    GameStatus indexed status
  );

  event MatchResponse(
    address playerA,
    address indexed playerB,
    uint256 matchId,
    GameStatus indexed status
  );

  /**
   * @dev This function is called by player A in order to challenge player B to a match.
    To start the match the Player A sends his card option hashed with a string as bytes32.
    Hashing function -> keccak256(abi.encodePacked("0", _playerARandStr)) being the number the card option.
    To hashed the card option on the frontend -> https://github.com/ethers-io/ethers.js/issues/718
   */
  function startMatch(
    address payable _playerB,
    string memory _cardA,
    string memory _playerARandStr,
    uint256 _bet
  ) public payable {
    /**
     * @dev Increment the matchId
     */
    matchId += 1;

    /**
     * @dev Populate match information
     */
    matches[matchId].playerA = payable(msg.sender);
    matches[matchId].playerB = _playerB;
    matches[matchId].cardA = keccak256(
      abi.encodePacked(_cardA, _playerARandStr)
    );
    matches[matchId].bet = _bet;
    matches[matchId].status = GameStatus.pending;

    stake += msg.value;

    /**
     * @dev Indicate the Player B that he has been challenged
     */

    emit MatchProposal(
      msg.sender,
      _playerB,
      msg.value,
      matchId,
      GameStatus.pending
    );
  }

  function rejectMatch(uint256 _matchId) public {
    require(
      matches[_matchId].playerB == msg.sender,
      "Not your match to cancel"
    );
    matches[_matchId].status = GameStatus.ended;
    emit MatchResponse(
      matches[_matchId].playerA,
      msg.sender,
      _matchId,
      GameStatus.ended
    );
  }

  function calculateRank(
    uint256 wins,
    uint256 losses,
    uint256 bet
  ) internal pure returns (uint256 rank) {
    return (wins + losses) * bet;
  }

  /**
   * @dev Indicate the Player B to accept the match he has been challenged to.
   This function accepts the match and provides the Player B card
   */
  function acceptMatch(uint8 _cardB, uint256 _matchId) public payable {
    require(_cardB >= 0 && _cardB < 3, "Select a correct card");
    require(matches[_matchId].playerB == msg.sender, "Invalid Player");
    require(
      matches[_matchId].status == GameStatus.pending,
      "This match was already played"
    );
    stake += msg.value;
    matches[_matchId].cardB = _cardB;
    matches[_matchId].GameStartTime = block.timestamp;
  }

  function playerBWinGame(uint256 _matchId) public payable {
    require(
      matches[_matchId].GameStartTime + 2 minutes <= block.timestamp,
      "Too early, be patiente my fiend"
    );
    require(matches[_matchId].playerB == msg.sender, "Invalid Player");
    resolveMatch(
      _matchId,
      matches[_matchId].playerB,
      matches[_matchId].playerA
    );
  }

  function getPlayerACard(string memory _playerARandStr, uint256 _matchId)
    private
    view
    returns (uint8)
  {
    if (
      keccak256(abi.encodePacked("0", _playerARandStr)) ==
      matches[_matchId].cardA
    ) {
      return 0;
    } else if (
      keccak256(abi.encodePacked("1", _playerARandStr)) ==
      matches[_matchId].cardA
    ) {
      return 1;
    } else if (
      keccak256(abi.encodePacked("2", _playerARandStr)) ==
      matches[_matchId].cardA
    ) {
      return 2;
    }
    return 3;
  }

  function revealPlayerACard(string memory _playerARandStr, uint256 _matchId)
    public
  {
    uint8 cardA = getPlayerACard(_playerARandStr, _matchId);
    require(cardA >= 0 && cardA < 3, "Invalid Card A");
    // The first one is winner and the second one looses
    (address payable winner, address looser) = getMatchOutcome(
      cardA,
      matches[_matchId].cardB,
      matches[_matchId].playerA,
      matches[_matchId].playerB
    );
    // same as before, its a draw if both users picked the same choice and same randomness, this is possible if their randomness was empty!
    resolveMatch(_matchId, winner, looser);
  }

  function resolveMatch(
    uint256 _matchId,
    address payable winner,
    address looser
  ) private {
    // assign Winner Values
    players[winner].wins = players[winner].wins + 1;
    players[winner].balancePlayer =
      players[winner].balancePlayer +
      int256(matches[_matchId].bet);
    players[winner].rank = calculateRank(
      players[winner].wins,
      players[winner].losses,
      matches[_matchId].bet
    );
    // assign Looser values
    players[looser].losses = players[looser].losses + 1;
    players[looser].balancePlayer =
      players[looser].balancePlayer -
      int256(matches[_matchId].bet);
    players[looser].rank = calculateRank(
      players[looser].wins,
      players[looser].losses,
      matches[_matchId].bet
    );

    // Update match status
    matches[_matchId].status = GameStatus.ended;

    // Transfer funds to the winner
    winner.transfer(matches[_matchId].bet + matches[_matchId].bet);

    // Trigger event to indicate that the match has ended
    emit MatchResponse(
      matches[_matchId].playerA,
      msg.sender,
      _matchId,
      GameStatus.ended
    );
  }

  function getMatchOutcome(
    uint8 _cardA,
    uint8 _cardB,
    address payable _playerA,
    address payable _playerB
  ) private pure returns (address payable, address) {
    // Rock 0
    // Paper 1
    // Scissors 2
    require(_cardA >= 0 && _cardA < 3, "Invalid Card A");
    require(_cardB >= 0 && _cardB < 3, "Invalid Card B");
    if (
      _cardA == _cardB ||
      (_cardA == 0 && _cardB != 1) ||
      (_cardA == 1 && _cardB != 2) ||
      (_cardA == 2 && _cardB != 0)
    ) {
      return (_playerA, _playerB);
    }
    return (_playerB, _playerA);
  }
}