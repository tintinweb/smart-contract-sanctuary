/**
 *Submitted for verification at polygonscan.com on 2021-12-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner() {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner() {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  function geUnlockTime() public view returns (uint256) {
    return _lockTime;
  }

  function lock(uint256 time) public virtual onlyOwner() {
    _previousOwner = _owner;
    _owner = address(0);
    _lockTime = block.timestamp + time;
    emit OwnershipTransferred(_owner, address(0));
  }

  function unlock() public virtual {
    require(_previousOwner == msg.sender, "You don't have permission to unlock");
    require(block.timestamp > _lockTime, "Contract is locked until 7 days");
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = _previousOwner;
  }
}

contract ChessBettor is Ownable {

  using SafeMath for uint256;

  // 0 => No Explicit Winner
  // 1 => Black
  // 2 => White
  struct Vote {
    uint8 voteFor;
    uint256 amount;
    uint256 voteTimestamp;
    bool claimed;
  }

  struct Game {
    string gameId;
    bool gameExists;

    uint8 winner;
    uint256 gameEndTimestamp;
    bool isOn;

    uint256 totalAmount;
    uint256 amountWhite;
    uint256 amountBlack;

    uint256 validTotalAmount;
    uint256 validAmountWhite;
    uint256 validAmountBlack;

    uint256 numberBets;
    uint256 whiteBets;
    uint256 blackBets;

    uint256 aI; // Accepted Index
    mapping(uint256 => mapping(address => uint256)) voteIndex;
    mapping(uint256 => address[]) bettors;
    mapping(uint256 => Vote[]) voteList;
  }

  struct UserData {
    uint256 totalGames;
    uint256 wins;       // Only takes claimed games into consideration
    uint256 draws;      // Only takes claimed games into consideration
    uint256 losses;     // Only takes claimed games into consideration
    uint256 undetermined;

    string[] allGamesPlayed;
    string[] gamesWithUnclaimedBalance;
  }

  struct ReturnableGameData {
    string gameId;

    uint8 winner;
    uint256 gameEndTimestamp;
    bool isOn;

    uint256 totalAmount;
    uint256 amountWhite;
    uint256 amountBlack;

    uint256 numberBets;
    uint256 whiteBets;
    uint256 blackBets;
  }

  struct ReturnableGameSpecificUserData {
    ReturnableGameData gameData;
    Vote voteData;
    int8 result;
  }

  struct ReturnableUserData {
    uint256 totalGames;
    uint256 wins;
    uint256 draws;
    uint256 losses;
    uint256 undetermined;
    uint256 claimableRewardAmount;

    ReturnableGameSpecificUserData[] allGameData;
  }

  uint256 public minBetAmount = 1 ether;

  string[] private activeGameIds;
  string[] private existingGameIds;
  mapping(string => Game) private existingGames;
  mapping(address => UserData) private allPlayerData;

  uint256 public feePercent = 0;
  uint256 public totalFeeGenerated = 0;
  uint256 public remainingFeeBalance = 0;
  uint256 public maxBettorsPerGame = 50;
  uint256 public maxAllowedUnclaimedGames = 10;

  event gameCreated(string _gameId, address _voter, uint256 _amount);
  event votePlaced(string _gameId, address _voter, uint256 _amount, uint8 _side);
  event gameEnded(string _gameId, uint8 winner);
  event rewardWithdraw(address _benificiary, uint256 _amount);

  function createGame(string memory _gameId, uint256 _amount) internal {
    Game storage newGame = existingGames[_gameId];
    newGame.gameId = _gameId;
    newGame.gameExists = true;
    newGame.isOn = true;
    newGame.gameEndTimestamp = 0;

    newGame.voteList[newGame.aI].push(Vote(0, 0, block.timestamp, true));
    // This implies that player has not placed bet yet.
    newGame.bettors[newGame.aI].push(address(0));
    existingGameIds.push(_gameId);

    activeGameIds.push(_gameId);
    emit gameCreated(_gameId, msg.sender, _amount);
  }

  function placeBet(string memory _gameId, uint8 _vote, uint256 _amount) public payable {
    require(existingGames[_gameId].winner < 3, "Cannot place bet for this gameId");
    require(_amount <= msg.value, "Mismatch in sent amount");
    require(msg.value >= minBetAmount, "Betting amount cannot be less than minBetAmount");
    require(_vote == 1 || _vote == 2, "Vote can be either 1 or 2 only");

    if (gameExists(_gameId)) {
      require(existingGames[_gameId].isOn, "Cannot place bet on a game that has already ended...");
    } else {
      createGame(_gameId, _amount);
    }

    Game storage game = existingGames[_gameId];
    require(game.voteIndex[game.aI][msg.sender] == 0, "Player has already placed bet in this game");
    require(game.bettors[game.aI].length <= maxBettorsPerGame, "Maximum number of bettors have placed bets for this game.");

    if (allPlayerData[msg.sender].gamesWithUnclaimedBalance.length >= maxAllowedUnclaimedGames) {
      claimRewardsFor(msg.sender);
    }

    allPlayerData[msg.sender].totalGames = allPlayerData[msg.sender].totalGames.add(1);
    allPlayerData[msg.sender].undetermined = allPlayerData[msg.sender].undetermined.add(1);
    allPlayerData[msg.sender].allGamesPlayed.push(_gameId);
    allPlayerData[msg.sender].gamesWithUnclaimedBalance.push(_gameId);
    // TODO : Add AutoClaim System.

    if (_vote == 1) {
      game.amountBlack = game.amountBlack.add(_amount);
      game.blackBets += 1;
    } else {
      game.amountWhite = game.amountWhite.add(_amount);
      game.whiteBets += 1;
    }

    game.totalAmount = game.totalAmount.add(_amount);
    game.numberBets = game.numberBets.add(1);

    game.voteIndex[game.aI][msg.sender] = game.numberBets;
    game.voteList[game.aI].push(Vote(_vote, _amount, block.timestamp, false));
    game.bettors[game.aI].push(msg.sender);

    emit votePlaced(_gameId, msg.sender, _amount, _vote);
  }

  function endGame(uint256 _gameIndex, string memory _gameId, uint8 _winner, uint256 _gameEndTimestamp) public onlyOwner() {
    require(areStringsEqual(activeGameIds[_gameIndex], _gameId), "Game Id and Game Index Mismatch");
    require(_winner >= 0 && _winner <= 3, "Invalid Winner");
    require(existingGames[_gameId].isOn, "Game has already ended");

    Game storage game = existingGames[_gameId];
    game.isOn = false;
    game.winner = _winner;
    game.gameEndTimestamp = _gameEndTimestamp;

    if (_winner >= 3) {
      takeFee(game.totalAmount);
      game.gameExists = false;
      game.winner = 0;
      game.totalAmount = 0;
      game.amountWhite = 0;
      game.amountBlack = 0;
      game.numberBets = 0;
      game.whiteBets = 0;
      game.blackBets = 0;
      game.aI += 1;
    } else if (_winner == 2 || _winner == 1) {
      (game.validTotalAmount, game.validAmountWhite, game.validAmountBlack) = getValidAmounts(existingGames[_gameId]);
    } else if (_winner == 0) {
      (game.validTotalAmount, game.validAmountWhite, game.validAmountBlack) = (game.totalAmount, game.amountWhite, game.amountBlack);
    }

    activeGameIds[_gameIndex] = activeGameIds[activeGameIds.length - 1];
    activeGameIds.pop();

    emit gameEnded(_gameId, _winner);
  }

  function takeFee(uint256 _amount) internal {
    remainingFeeBalance = remainingFeeBalance.add(_amount);
    totalFeeGenerated += _amount;
  }

  function claimRewards() external {
    claimRewardsFor(msg.sender);
  }

  function claimRewardsFor(address _address) internal {

    (uint256 reward, uint256 fees, string[] memory claimedGames, int8[] memory results) = calculateRewards(_address);

    updateAllClaimedVotesAndListOfUnclaimedVotes(_address, claimedGames, results);
    takeFee(fees);
    payable(_address).transfer(reward);

    emit rewardWithdraw(_address, reward);
  }

  function updateAllClaimedVotesAndListOfUnclaimedVotes(address _address, string[] memory toBeClaimedGames, int8[] memory results) internal {
    uint256 currentIndex = 0;
    uint256 max = toBeClaimedGames.length;
    string[] storage unclaimedGames = allPlayerData[_address].gamesWithUnclaimedBalance;
    UserData storage userData = allPlayerData[_address];

    for (uint256 i = 0; i < unclaimedGames.length; i++) {
      unclaimedGames[i - currentIndex] = unclaimedGames[i];

      if ((currentIndex < max) && (areStringsEqual(unclaimedGames[i], toBeClaimedGames[currentIndex]))) {
        Game storage game = existingGames[toBeClaimedGames[currentIndex]];
        game.voteList[game.aI][game.voteIndex[game.aI][_address]].claimed = true;

        userData.undetermined -= 1;
        if (results[currentIndex] == 0) {
          userData.draws = userData.draws.add(1);
        } else if (results[currentIndex] == 1) {
          userData.wins = userData.wins.add(1);
        } else if (results[currentIndex] == - 1) {
          userData.losses = userData.losses.add(1);
        }

        currentIndex++;
      }
    }

    for (uint256 i = 0; i < max; i++) {
      unclaimedGames.pop();
    }
  }

  function setMinBetAmount(uint256 amount) external onlyOwner() {
    require(amount > 0, "minBetAmount has to be greater than 0");
    minBetAmount = amount;
  }

  function setFeePercent(uint256 _feePercent) external onlyOwner() {
    require(_feePercent <= 100, "Fee percent cannot be greater than 100");
    feePercent = _feePercent;
  }

  function setMaxBettorsPerGame(uint256 noOfBettors) external onlyOwner() {
    maxBettorsPerGame = noOfBettors;
  }

  function setMaxAllowedUnclaimedGames(uint256 amount) external onlyOwner() {
    maxAllowedUnclaimedGames = amount;
  }

  function withdrawFees(uint256 amount, address payable to) external onlyOwner() {
    require(amount <= remainingFeeBalance, "Cannot withdraw more than remaining fee balance");
    to.transfer(amount);
    remainingFeeBalance = remainingFeeBalance.sub(amount);
  }



  // ----------------------------- //
  // Internal View Functions Below //
  // ----------------------------- //

  function areStringsEqual(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(bytes(a)) == keccak256(bytes(b));
  }

  function getValidAmounts(Game storage game) internal view returns (uint256 totalAmount, uint256 amountWhite, uint256 amountBlack) {
    Vote[] storage voteList = game.voteList[game.aI];

    for (uint256 i = 1; i < voteList.length; i++) {
      Vote storage vote = voteList[i];

      if (vote.voteTimestamp > game.gameEndTimestamp) {
        continue;
      } else if (vote.voteFor == 2) {
        totalAmount = totalAmount.add(vote.amount);
        amountWhite = amountWhite.add(vote.amount);
      } else if (vote.voteFor == 1) {
        totalAmount = totalAmount.add(vote.amount);
        amountBlack = amountBlack.add(vote.amount);
      }
    }
  }

  function getRewardAmountForPlayerForGame(Vote storage vote, Game storage game) internal view returns (uint256) {
    require(vote.voteFor == game.winner, "Voter has to be winner to calculate rewards");

    uint256 numerator = vote.amount.mul(game.validTotalAmount);
    uint256 denominator = (game.winner == 1) ? game.validAmountBlack : game.validAmountWhite;

    return numerator.div(denominator);
  }

  function getCountOfClaimableGamesForAddress(address _address, string[] storage unclaimedGameIds) internal view returns (uint256) {
    uint256 count = 0;

    for (uint i = 0; i < unclaimedGameIds.length; i++) {
      Game storage game = existingGames[unclaimedGameIds[i]];
      Vote storage vote = game.voteList[game.aI][game.voteIndex[game.aI][_address]];

      if (!(game.isOn || vote.claimed)) {
        count++;
      }
    }

    return count;
  }

  function formatData(
    address _address,
    string[] memory gameList,
    uint256 minIndex,
    uint256 maxIndex,
    bool modifyWinsAndLosses
  ) internal view returns (ReturnableUserData memory fullPlayerData) {
    require(minIndex >= 0 && minIndex <= maxIndex && maxIndex < gameList.length, "Invalid Indices");
    fullPlayerData.totalGames = allPlayerData[_address].totalGames;
    fullPlayerData.wins = allPlayerData[_address].wins;
    fullPlayerData.draws = allPlayerData[_address].draws;
    fullPlayerData.losses = allPlayerData[_address].losses;
    fullPlayerData.undetermined = allPlayerData[_address].undetermined;
    (fullPlayerData.claimableRewardAmount,,,) = calculateRewards(_address);

    fullPlayerData.allGameData = new ReturnableGameSpecificUserData[](maxIndex + 1 - minIndex);
    uint256 index = 0;

    for (uint256 i = minIndex; i <= maxIndex; i++) {
      string memory gameId = gameList[i];
      (ReturnableGameData memory returnableGameData,) = getGameDetails(gameId);

      Game storage game = existingGames[gameId];
      Vote storage vote = game.voteList[game.aI][game.voteIndex[game.aI][_address]];
      int8 result;

      if (game.isOn) {
        result = - 2;
      } else if (vote.voteTimestamp > game.gameEndTimestamp || game.winner == 0) {
        result = 0;
        if (modifyWinsAndLosses && !vote.claimed) {
          fullPlayerData.draws += 1;
        }
      } else if (vote.voteFor == game.winner) {
        result = 1;
        if (modifyWinsAndLosses && !vote.claimed) {
          fullPlayerData.wins += 1;
        }
      } else {
        result = - 1;
        if (modifyWinsAndLosses && !vote.claimed) {
          fullPlayerData.losses += 1;
        }
      }

      fullPlayerData.allGameData[index] = ReturnableGameSpecificUserData(returnableGameData, Vote(vote.voteFor, vote.amount, vote.voteTimestamp, vote.claimed), result);
      index += 1;
    }

    return fullPlayerData;
  }



  // ----------------------------- //
  //  Public View Functions Below  //
  // ----------------------------- //

  function gameExists(string memory _gameId) public view returns (bool) {
    return existingGames[_gameId].gameExists;
  }

  function getGameDetails(string memory _gameId) public view returns (ReturnableGameData memory, Vote[] memory) {
    Game storage _game = existingGames[_gameId];

    ReturnableGameData memory returnableGameData = ReturnableGameData(
      _game.gameId,
      _game.winner,
      _game.gameEndTimestamp,
      _game.isOn,
      _game.totalAmount,
      _game.amountWhite,
      _game.amountBlack,
      _game.numberBets,
      _game.whiteBets,
      _game.blackBets
    );
    require(_game.gameExists, "No game exists for the given game id.");

    return (returnableGameData, _game.voteList[_game.aI]);
  }

  function calculateRewards(address _address) public view returns (uint256 claimableReward, uint256 fees, string[] memory removableGames, int8[] memory results) {
    uint256 nonTaxableReward = 0;
    uint256 index = 0;
    string[] storage unclaimedGameIds = allPlayerData[_address].gamesWithUnclaimedBalance;

    // Get all the gameIds in which player has participated.
    uint256 size = getCountOfClaimableGamesForAddress(_address, unclaimedGameIds);
    removableGames = new string[](size);
    results = new int8[](size);

    // Loop through all the votes, if he has won in that game then add to his balance the reward, otherwise reward = 0
    for (uint i = 0; i < unclaimedGameIds.length; i++) {
      Game storage game = existingGames[unclaimedGameIds[i]];
      Vote storage vote = game.voteList[game.aI][game.voteIndex[game.aI][_address]];

      if (!(game.isOn || vote.claimed)) {
        removableGames[index] = unclaimedGameIds[i];

        if (vote.voteTimestamp > game.gameEndTimestamp || game.winner == 0) {
          nonTaxableReward = nonTaxableReward.add(vote.amount);
          results[index] = 0;
        } else if (vote.voteFor == game.winner) {
          claimableReward = claimableReward.add(getRewardAmountForPlayerForGame(vote, game));
          results[index] = 1;
        } else {
          if ((game.winner == 1 && game.validAmountBlack == 0) || (game.winner == 2 && game.validAmountWhite == 0)) {
            nonTaxableReward = nonTaxableReward.add(vote.amount);
          }
          results[index] = - 1;
        }

        index++;
      }
    }

    fees = (claimableReward.mul(feePercent)).div(100);
    claimableReward = nonTaxableReward.add(claimableReward.sub(fees));

    return (claimableReward, fees, removableGames, results);
  }



  // ----------------------------- //
  // External View Functions Below //
  // ----------------------------- //

  function getActiveGames() external view returns (string[] memory) {
    return activeGameIds;
  }

  function getBulkGameDetails(string[] memory gameIdList) external view returns (ReturnableGameData[] memory returnList) {
    uint256 len = gameIdList.length;
    returnList = new ReturnableGameData[](len);

    for (uint256 i = 0; i < len; i++) {
      (returnList[i],) = getGameDetails(gameIdList[i]);
    }

    return returnList;
  }

  function getAllGamesCreatedTillDate() external view returns (string[] memory) {
    return existingGameIds;
  }

  function getGamesPlayedByPlayer(address _address) external view returns (string[] memory) {
    return allPlayerData[_address].allGamesPlayed;
  }

  function getLengthOfUnclaimedGameList(address _address) external view returns (uint256) {
    return allPlayerData[_address].gamesWithUnclaimedBalance.length;
  }

  function getPlayerStatsForUnclaimedGames(address _address, bool modifyWinsAndLosses, uint256 minIndex, uint256 maxIndex) external view returns (ReturnableUserData memory) {
    return formatData(_address, allPlayerData[_address].gamesWithUnclaimedBalance, minIndex, maxIndex, modifyWinsAndLosses);
  }

  function getLengthOfAllGameList(address _address) external view returns (uint256) {
    return allPlayerData[_address].allGamesPlayed.length;
  }

  function getPlayerStatsForAllGames(address _address, bool modifyWinsAndLosses, uint256 minIndex, uint256 maxIndex) external view returns (ReturnableUserData memory) {
    return formatData(_address, allPlayerData[_address].allGamesPlayed, minIndex, maxIndex, modifyWinsAndLosses);
  }
}