// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LoserGameRankData.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HuanCasino is LoserGameRankData {
  address public owner;

  //check the pullFuns
  address public checker;

  address public lowbTokenAddress;

  bool public checkerAllow = false;

  // The minimum bet a user has to make to participate in the game
  uint256 public minimumBet = 10000 ether;

  uint256 public maximumBet = 500000 ether; 

  uint256 public currentBetValue = 10000 ether;

  // The total amount of Ether bet for this current game
  uint256 public totalBet;

  // The total number of bets the users have made
  uint256 public numberOfBets;

  // The max user of bets that cannot be exceeded to avoid excessive gas consumption
  // when distributing the prizes and restarting the game
  uint256 public maximumBetsNr = 10;

  // Save player when betting number
  address[] public players;

  // The number that won the last game
  uint public numberWinner;

  uint256 public DEAL_BASE = 10000;

  uint256 public platform_deal = 300;

  uint256 public unlucky_deal = 9000;

  // Save player info
  struct Player {
    uint256 amountBet;
    uint256 numberSelected;
  }

  // The address of the player and => the user info
  mapping(address => Player) public playerInfo;

  mapping (address => uint) public pendingWithdrawals;

  mapping (address => uint) public scoreMap;

  // Event watch when player win
  event Won(bool _status, address _address, uint _amount);

  event Bet(address _address, uint _amount, uint score);

  event Test(uint salt, uint number, uint temp, uint allDeal);


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor(address lowbToken_, address checker_, uint256 _minimumBet ) public payable {
    lowbTokenAddress = lowbToken_;
    owner = msg.sender;
    checker = checker_;
    if (_minimumBet != 0) 
      minimumBet = _minimumBet;
  }

  // fallback
 fallback() external payable {}

  // function kill() public {
  //   if (msg.sender == owner) 
  //     selfdestruct(owner);
  // }

  function setCheckerAllow(bool allow_) public {
    require(msg.sender == checker);
    checkerAllow = allow_;
  }

  function setMinBet(uint256 _minimumBet) public onlyOwner {
    if (_minimumBet != 0) 
      minimumBet = _minimumBet;
  }

  function setMaxBet(uint256 _maxBet) public onlyOwner {
    if (_maxBet != 0 && _maxBet > minimumBet) 
      maximumBet = _maxBet;
  }

  function setMaxBetsNr(uint256 _maximumBetsNr) public onlyOwner {
    if (_maximumBetsNr >= 0) {
      maximumBetsNr = _maximumBetsNr;
    }
  }

  function setDeal(uint256 platform_, uint256 unlucky_) public onlyOwner {
    platform_deal = platform_;
    unlucky_deal = unlucky_;
  }


  function deposit(uint amount) public {
    require(amount > 0, "You deposit nothing!");
    IERC20 token = IERC20(lowbTokenAddress);
    require(token.transferFrom(tx.origin, address(this), amount), "Lowb transfer failed");
    pendingWithdrawals[tx.origin] +=  amount;
  }

  function getPendingWithdrawals() public view returns(uint) {
    return pendingWithdrawals[msg.sender];
  }

  function getScore() public view returns(uint) {
    return scoreMap[msg.sender];
  }

  function getOtherScore(address player) public view returns(uint) {
    return scoreMap[player];
  }

  function withdraw(uint amount) public {
      require(amount <= pendingWithdrawals[tx.origin], "amount larger than that pending to withdraw");  
      pendingWithdrawals[tx.origin] -= amount;
      IERC20 token = IERC20(lowbTokenAddress);
      require(token.transfer(tx.origin, amount), "Lowb transfer failed");
  }

  /// @notice Check if a player exists in the current game
  /// @param player The address of the player to check
  /// @return bool Returns true is it exists or false if it doesn't
  function checkPlayerExists(address player) public view returns(bool) {
    for (uint256 i = 0; i < players.length; i++) {
      if (players[i] == player) 
        return true;
    }
    return false;
  }

  /// @notice To bet for a number by sending Ether
  /// @param numberSelected The number that the player wants to bet for. Must be between 1 and 10 both inclusive
  function bet(uint256 numberSelected, uint betPackage) public payable {
    if(betPackage > 50) {
      betPackage = betPackage % 50;
    }
    if (betPackage == 0) {
      betPackage  = 1;
    }
    currentBetValue = betPackage * 10000 ether;
    emit Test(currentBetValue, minimumBet, maximumBet, 0);
    // Check that the player doesn't exists
    require(!checkPlayerExists(msg.sender), "the player is in beting");
    // Check that the number to bet is within the range
    require(numberSelected <= 10 && numberSelected >= 1);
    // Check that the amount paid is bigger or equal the minimum bet
    require(currentBetValue >= minimumBet, "minimumBet");
    require(currentBetValue <= maximumBet, "maximumBet");
    require(numberOfBets <= maximumBetsNr, "maximum number of bet");
    numberOfBets++;

    pendingWithdrawals[msg.sender] -= currentBetValue;

    //扣除手续费
    uint256 deal = currentBetValue * platform_deal / DEAL_BASE;
    IERC20 token = IERC20(lowbTokenAddress);
    require(token.transfer(checker, deal/2 ), "platform deal Lowb transfer failed");
    require(token.transfer(owner, deal/2 ), "platform deal Lowb transfer failed");
    currentBetValue -= deal;

    // Set the number bet for that player
    playerInfo[msg.sender].amountBet = currentBetValue;
    playerInfo[msg.sender].numberSelected = numberSelected;
    players.push(msg.sender);
    totalBet += currentBetValue;
    if (scoreMap[msg.sender] == 0) {
      scoreMap[msg.sender] += currentBetValue;
      addPlayer(msg.sender, scoreMap[msg.sender]);
    } else {
      scoreMap[msg.sender] += currentBetValue;
      increaseScore(msg.sender, scoreMap[msg.sender]);
    }
    
    if (numberOfBets >= maximumBetsNr) {
       generateNumberWinner(); 
    } else {
      emit Bet(msg.sender, currentBetValue, scoreMap[msg.sender]);
    }
      
    //We need to change this in order to be secure
  }

  /// @notice Generates a random number between 1 and 10 both inclusive.
  /// Can only be executed when the game ends.
  function generateNumberWinner() private {
    uint256 numberGenerated = block.number % 10 + 1;
    numberWinner = numberGenerated;
    distributePrizes(numberGenerated);
  }


  /// @notice Sends the corresponding Ether to each winner then deletes all the
  /// players for the next game and resets the `totalBet` and `numberOfBets`
  function distributePrizes(uint256 numberWin) private {
    address[100] memory winners;
    address[100] memory losers;
    uint256 countWin = 0;
    uint256 countLose = 0;

    uint256 tempTotal = totalBet;
    uint256 winBetTotal = 0;
    uint256 salt = 0;
    
    //随机数加盐
    for(uint256 i = 0; i < players.length; i++) {
      uint256 playernum = uint256(uint160(address(players[i])));
      salt += playernum % 10 + 1;
    }

    numberWinner = (numberWin + salt) % 10 + 1;

    for (uint256 i = 0; i < players.length; i++) {
      address playerAddress = players[i];
      if (playerInfo[playerAddress].numberSelected == numberWinner) {
        winners[countWin] = playerAddress;
        //先把赢家的本金拿回
        tempTotal -= playerInfo[playerAddress].amountBet;
        pendingWithdrawals[playerAddress] +=  playerInfo[playerAddress].amountBet;
        winBetTotal += playerInfo[playerAddress].amountBet;
        countWin++;
      } else {
        losers[countLose] = playerAddress;
        countLose++;
      }
    }

    if (countWin != 0) {
      //每个赢家分到的盈利
      uint256 winnerEtherAmount = 0;
      //所有赢家分到盈利的总和
      uint256 totalWinbetAmout = 0;
      for (uint256 j = 0; j < countWin; j++){
        if (winners[j] != address(0)) {
          //赢家的权重*100，算出结果后在除100
          winnerEtherAmount = (tempTotal * (playerInfo[winners[j]].amountBet * 100/winBetTotal)) / 100;
          totalWinbetAmout += winnerEtherAmount;
          pendingWithdrawals[winners[j]] +=  winnerEtherAmount;
          emit Won(true, winners[j], winnerEtherAmount);
        }
      }
      if (totalWinbetAmout >= 0) {
             tempTotal -= totalWinbetAmout;
      }
    } else {
        //没有人中奖的时候，退回80%
        for (uint256 i = 0; i < players.length; i++) {
          address playerAddress = players[i];
          pendingWithdrawals[playerAddress] +=  playerInfo[playerAddress].amountBet * unlucky_deal / DEAL_BASE;
          tempTotal -= playerInfo[playerAddress].amountBet * unlucky_deal / DEAL_BASE;
        }
    }

    if (tempTotal > 0) {
      IERC20 token = IERC20(lowbTokenAddress);
      require(token.transfer(owner, tempTotal / 2), "tempTotal Lowb transfer failed");
      require(token.transfer(checker, tempTotal / 2), "tempTotal Lowb transfer failed");
    }
    tempTotal = 0;

    for (uint256 l = 0; l < losers.length; l++){
      if (losers[l] != address(0))
        emit Won(false, losers[l], 0);
    }


    for (uint256 i = 0; i < players.length; i++) {
      delete playerInfo[players[i]];
    }

    resetData();
  }

  function getRankScore() public view returns(uint256) {
    return scoreMap[msg.sender];
  }

  function getTopRankPlayer(uint256 k) public view returns(address[] memory) {
    require(k <= listcapacity, "top max is listcapacity");
    return getTop(k);
  }

  function getBetNumber(address player) public view returns(uint) {
    return playerInfo[player].numberSelected;
  }

  // Restart game
  function resetData() private {
    delete players;
    totalBet = 0;
    numberOfBets = 0;
  }

  function pullFunds() public {
      require(msg.sender == owner, "Only owner can pull the funds!");
      require(checkerAllow, "pull the funds need checher agree");
      IERC20 lowb = IERC20(lowbTokenAddress);
      lowb.transfer(msg.sender, pendingWithdrawals[address(this)]);
      pendingWithdrawals[address(this)] = 0;
  }

}

pragma solidity ^0.8.0;

contract LoserGameRankData{

  mapping(address => uint256) public scores;
  mapping(address => address) _nextPlayers;
  uint256 public listSize;
  address constant GUARD = address(1);
  address public lastAddress;
  //列表最大容量
  uint256 public listcapacity = 1000;


  constructor() public {
    _nextPlayers[GUARD] = GUARD;
  }

  function setListCapacity(uint256 capacity_) internal {
      listcapacity = capacity_;
  }

  function addPlayer(address player, uint256 score) internal {
    require(_nextPlayers[player] == address(0));
    address index = _findIndex(score);
    scores[player] = score;
    _nextPlayers[player] = _nextPlayers[index];
    _nextPlayers[index] = player;
    listSize++;
    if(_nextPlayers[player] == address(0)) {
        lastAddress = player;
    }
    if (listSize > listcapacity) {
        removePlayer(lastAddress);
    }
  }

  function increaseScore(address player, uint256 score) internal {
    updateScore(player, scores[player] + score);
  }

  function reduceScore(address player, uint256 score) internal {
    updateScore(player, scores[player] - score);
  }

  function updateScore(address player, uint256 newScore) internal {
    require(_nextPlayers[player] != address(0));
    address prevPlayer = _findPrevPlayer(player);
    address nextPlayer = _nextPlayers[player];
    if(_verifyIndex(prevPlayer, newScore, nextPlayer)){
      scores[player] = newScore;
    } else {
      removePlayer(player);
      addPlayer(player, newScore);
    }
  }

  function removePlayer(address player) internal {
    require(_nextPlayers[player] != address(0));
    address prevPlayer = _findPrevPlayer(player);
    _nextPlayers[prevPlayer] = _nextPlayers[player];
    _nextPlayers[player] = address(0);
    scores[player] = 0;
    listSize--;
  }

  function getTop(uint256 k) public view returns(address[] memory) {
    require(k <= listSize);
    address[] memory playerLists = new address[](k);
    address currentAddress = _nextPlayers[GUARD];
    for(uint256 i = 0; i < k; ++i) {
      playerLists[i] = currentAddress;
      currentAddress = _nextPlayers[currentAddress];
    }
    return playerLists;
  }


  function _verifyIndex(address prevPlayer, uint256 newValue, address nextPlayer)
    internal
    view
    returns(bool)
  {
    return (prevPlayer == GUARD || scores[prevPlayer] >= newValue) && 
           (nextPlayer == GUARD || newValue > scores[nextPlayer]);
  }

  function _findIndex(uint256 newValue) internal view returns(address) {
    address candidateAddress = GUARD;
    while(true) {
      if(_verifyIndex(candidateAddress, newValue, _nextPlayers[candidateAddress]))
        return candidateAddress;
      candidateAddress = _nextPlayers[candidateAddress];
    }
  }

  function _isPrevPlayer(address player, address prevPlayer) internal view returns(bool) {
    return _nextPlayers[prevPlayer] == player;
  }

  function _findPrevPlayer(address player) internal view returns(address) {
    address currentAddress = GUARD;
    while(_nextPlayers[currentAddress] != GUARD) {
      if(_isPrevPlayer(player, currentAddress))
        return currentAddress;
      currentAddress = _nextPlayers[currentAddress];
    }
    return address(0);
  }
}

