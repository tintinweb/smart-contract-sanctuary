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

  bool public poolSwitch1 = true;
  bool public poolSwitch2 = true;
  bool public poolSwitch3 = true;
  bool public poolSwitch4 = true;
  bool public poolSwitch5 = true;

  // The minimum bet a user has to make to participate in the game

  uint256 public maximumBet = 500000 ether; 


  // The total amount of Ether bet for this current game
  uint256 public totalBet_1;

  uint256 public totalBet_5;

  uint256 public totalBet_10;

  uint256 public totalBet_20;

  uint256 public totalBet_50;

  // The total number of bets the users have made
  uint256 public numberOfBets_1;

  uint256 public numberOfBets_5;

  uint256 public numberOfBets_10;

  uint256 public numberOfBets_20;

  uint256 public numberOfBets_50;

  // The max user of bets that cannot be exceeded to avoid excessive gas consumption
  // when distributing the prizes and restarting the game
  uint256 public maximumBetsNr = 10;

  // Save player when betting number
  address[] public players_1;

  address[] public players_5;

  address[] public players_10;

  address[] public players_20;

  address[] public players_50;

  // The number that won the last game
  uint public numberWinner_1;

  uint public numberWinner_5;

  uint public numberWinner_10;

  uint public numberWinner_20;

  uint public numberWinner_50;

  uint256 public DEAL_BASE = 10000;

  uint256 public platform_deal = 300;

  uint256 public unlucky_deal = 9000;

  // Save player info
  struct Player {
    uint256 amountBet;
    uint256 numberSelected;
  }

  // The address of the player and => the user info
  mapping(address => Player) public playerInfo_1;

  mapping(address => Player) public playerInfo_5;

  mapping(address => Player) public playerInfo_10;

  mapping(address => Player) public playerInfo_20;

  mapping(address => Player) public playerInfo_50;

  mapping (address => uint) public pendingWithdrawals;

  mapping (address => uint) public scoreMap;

  mapping (address => mapping(uint => uint)) public winnerMap_1;
  mapping (address => mapping(uint => uint)) public winnerMap_5;
  mapping (address => mapping(uint => uint)) public winnerMap_10;
  mapping (address => mapping(uint => uint)) public winnerMap_20;
  mapping (address => mapping(uint => uint)) public winnerMap_50;

  // Event watch when player win
  event Won(bool _status, address _address, uint _amount);

  event Bet(address _address, uint _amount, uint score);

  event Test(uint salt, uint number, uint temp, uint allDeal);


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor(address lowbToken_, address checker_ ) public payable {
    lowbTokenAddress = lowbToken_;
    owner = msg.sender;
    checker = checker_;
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

  function setPlloSwitch1(bool open_) public onlyOwner {
    poolSwitch1 = open_;
  }

  function setPlloSwitch2(bool open_) public onlyOwner {
    poolSwitch2 = open_;
  }

  function setPlloSwitch3(bool open_) public onlyOwner {
    poolSwitch3 = open_;
  }

  function setPlloSwitch4(bool open_) public onlyOwner {
    poolSwitch4 = open_;
  }

  function setPlloSwitch5(bool open_) public onlyOwner {
    poolSwitch5 = open_;
  }

  function setMaxBet(uint256 _maxBet) public onlyOwner {
    if (_maxBet != 0 ) 
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

//get tones token
  function getTonesToken(address player, uint level, uint tonesIndex) public view returns(uint) {
    if (level == 1) {
      return winnerMap_1[player][tonesIndex];
    } else if (level == 2) {
      return winnerMap_5[player][tonesIndex];
    } else if (level == 3) {
      return winnerMap_10[player][tonesIndex];
    } else if (level == 4) {
      return winnerMap_20[player][tonesIndex];
    } else if (level == 5) {
      return winnerMap_50[player][tonesIndex];
    } else {
      return 0;
    }
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
    for (uint256 i = 0; i < players_1.length; i++) {
      if (players_1[i] == player) 
        return true;
    }

    for (uint256 i = 0; i < players_5.length; i++) {
      if (players_5[i] == player) 
        return true;
    }

    for (uint256 i = 0; i < players_10.length; i++) {
      if (players_10[i] == player) 
        return true;
    }

    for (uint256 i = 0; i < players_20.length; i++) {
      if (players_20[i] == player) 
        return true;
    }

    for (uint256 i = 0; i < players_50.length; i++) {
      if (players_50[i] == player) 
        return true;
    }
    return false;
  }

  /// @notice To bet for a number by sending Ether
  /// @param numberSelected The number that the player wants to bet for. Must be between 1 and 10 both inclusive
  function bet_5(uint256 numberSelected) public payable {

    uint256 betValue5 = 50000 ether;

    require(poolSwitch2, "the pool close");
    // Check that the player doesn't exists
    require(!checkPlayerExists(msg.sender), "the player is in beting");
    // Check that the number to bet is within the range
    require(numberSelected <= 10 && numberSelected >= 1);
    // Check that the amount paid is bigger or equal the minimum bet
    require(pendingWithdrawals[msg.sender] >= betValue5, "you dont desposit enough lowb");
    require(numberOfBets_5 <= maximumBetsNr, "maximum number of bet");
    numberOfBets_5++;

    pendingWithdrawals[msg.sender] -= betValue5 ;

    //扣除手续费
    uint256 deal = betValue5 * platform_deal / DEAL_BASE;
    IERC20 token = IERC20(lowbTokenAddress);
    require(token.transfer(checker, deal/2 ), "platform deal Lowb transfer failed");
    require(token.transfer(owner, deal/2 ), "platform deal Lowb transfer failed");
    betValue5 -= deal;

    // Set the number bet for that player
    playerInfo_5[msg.sender].amountBet = betValue5;
    playerInfo_5[msg.sender].numberSelected = numberSelected;
    players_5.push(msg.sender);
    totalBet_5 += betValue5;
    if (scoreMap[msg.sender] == 0) {
      scoreMap[msg.sender] += betValue5;
      addPlayer(msg.sender, scoreMap[msg.sender]);
    } else {
      scoreMap[msg.sender] += betValue5;
      increaseScore(msg.sender, scoreMap[msg.sender]);
    }
    
    if (numberOfBets_5 >= maximumBetsNr) {
       generateNumberWinner_5(); 
    } else {
      emit Bet(msg.sender, betValue5, scoreMap[msg.sender]);
    }
      
    //We need to change this in order to be secure
  }

  /// @notice Generates a random number between 1 and 10 both inclusive.
  /// Can only be executed when the game ends.
  function generateNumberWinner_5() private {
    uint256 numberGenerated = block.number % 10 + 1;
    numberWinner_5 = numberGenerated;
    distributePrizes_5(numberGenerated);
  }


  /// @notice Sends the corresponding Ether to each winner then deletes all the
  /// players for the next game and resets the `totalBet` and `numberOfBets`
  function distributePrizes_5(uint256 numberWin) private {
    address[100] memory winners;
    address[100] memory losers;
    uint256 countWin = 0;
    uint256 countLose = 0;

    uint256 tempTotal = totalBet_5;
    uint256 winBetTotal = 0;
    uint256 salt = 0;
    
    //随机数加盐
    for(uint256 i = 0; i < players_5.length; i++) {
      uint256 playernum = uint256(uint160(address(players_5[i])));
      salt += playernum % 10 + 1;
    }

    numberWinner_5 = (numberWin + salt) % 10 + 1;

    for (uint256 i = 0; i < players_5.length; i++) {
      address playerAddress = players_5[i];
      if (playerInfo_5[playerAddress].numberSelected == numberWinner_5) {
        winners[countWin] = playerAddress;
        //先把赢家的本金拿回
        tempTotal -= playerInfo_5[playerAddress].amountBet;
        pendingWithdrawals[playerAddress] +=  playerInfo_5[playerAddress].amountBet;
        winBetTotal += playerInfo_5[playerAddress].amountBet;
        winnerMap_5[playerAddress][numberWinner_5] += 1;
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
          winnerEtherAmount = (tempTotal * (playerInfo_5[winners[j]].amountBet * 100/winBetTotal)) / 100;
          totalWinbetAmout += winnerEtherAmount;
          pendingWithdrawals[winners[j]] +=  winnerEtherAmount;
          emit Won(true, winners[j], winnerEtherAmount);
        }
      }
      if (totalWinbetAmout >= 0) {
             tempTotal -= totalWinbetAmout;
      }
    } else {
        //没有人中奖的时候，退回100%
        for (uint256 i = 0; i < players_5.length; i++) {
          address playerAddress = players_5[i];
          pendingWithdrawals[playerAddress] +=  playerInfo_5[playerAddress].amountBet;
          tempTotal -= playerInfo_5[playerAddress].amountBet;
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


    for (uint256 i = 0; i < players_5.length; i++) {
      delete playerInfo_5[players_5[i]];
    }

    resetData_5();
  }

  function getRankScore() public view returns(uint256) {
    return scoreMap[msg.sender];
  }

  function getTopRankPlayer(uint256 k) public view returns(address[] memory) {
    require(k <= listcapacity, "top max is listcapacity");
    return getTop(k);
  }

  function getBetNumber(address player, uint bettype) public view returns(uint) {
    if (bettype == 1) {
      return playerInfo_1[player].numberSelected;
    } else if (bettype == 5) {
      return playerInfo_5[player].numberSelected;
    } else if (bettype == 10) {
      return playerInfo_10[player].numberSelected;
    } else if (bettype == 20) {
      return playerInfo_20[player].numberSelected;
    } else if (bettype == 50) {
      return playerInfo_50[player].numberSelected;
    } else {
      return 0;
    }
    
  }

  // Restart game
  function resetData_5() private {
    delete players_5;
    totalBet_5 = 0;
    numberOfBets_5 = 0;
  }

  function pullFunds() public {
      require(msg.sender == owner, "Only owner can pull the funds!");
      require(checkerAllow, "pull the funds need checher agree");
      IERC20 lowb = IERC20(lowbTokenAddress);
      lowb.transfer(msg.sender, pendingWithdrawals[address(this)]);
      pendingWithdrawals[address(this)] = 0;
  }


    /// @notice To bet for a number by sending Ether
  /// @param numberSelected The number that the player wants to bet for. Must be between 1 and 10 both inclusive
  function bet_1(uint256 numberSelected) public payable {

    uint256 betValue1 = 10000 ether;
    require(poolSwitch1, "the pool close");
    // Check that the player doesn't exists
    require(!checkPlayerExists(msg.sender), "the player is in beting");
    // Check that the number to bet is within the range
    require(numberSelected <= 10 && numberSelected >= 1);
    // Check that the amount paid is bigger or equal the minimum bet
    require(pendingWithdrawals[msg.sender] >= betValue1, "you dont desposit enough lowb");
    require(numberOfBets_1 <= maximumBetsNr, "maximum number of bet");
    numberOfBets_1++;

    pendingWithdrawals[msg.sender] -= betValue1 ;

    //扣除手续费
    uint256 deal = betValue1 * platform_deal / DEAL_BASE;
    IERC20 token = IERC20(lowbTokenAddress);
    require(token.transfer(checker, deal/2 ), "platform deal Lowb transfer failed");
    require(token.transfer(owner, deal/2 ), "platform deal Lowb transfer failed");
    betValue1 -= deal;

    // Set the number bet for that player
    playerInfo_1[msg.sender].amountBet = betValue1;
    playerInfo_1[msg.sender].numberSelected = numberSelected;
    players_1.push(msg.sender);
    totalBet_1 += betValue1;
    if (scoreMap[msg.sender] == 0) {
      scoreMap[msg.sender] += betValue1;
      addPlayer(msg.sender, scoreMap[msg.sender]);
    } else {
      scoreMap[msg.sender] += betValue1;
      increaseScore(msg.sender, scoreMap[msg.sender]);
    }
    
    if (numberOfBets_1 >= maximumBetsNr) {
       generateNumberWinner_1(); 
    } else {
      emit Bet(msg.sender, betValue1, scoreMap[msg.sender]);
    }
      
    //We need to change this in order to be secure
  }

  /// @notice Generates a random number between 1 and 10 both inclusive.
  /// Can only be executed when the game ends.
  function generateNumberWinner_1() private {
    uint256 numberGenerated = block.number % 10 + 1;
    numberWinner_1 = numberGenerated;
    distributePrizes_1(numberGenerated);
  }


  /// @notice Sends the corresponding Ether to each winner then deletes all the
  /// players for the next game and resets the `totalBet` and `numberOfBets`
  function distributePrizes_1(uint256 numberWin) private {
    address[100] memory winners;
    address[100] memory losers;
    uint256 countWin = 0;
    uint256 countLose = 0;

    uint256 tempTotal = totalBet_1;
    uint256 winBetTotal = 0;
    uint256 salt = 0;
    
    //随机数加盐
    for(uint256 i = 0; i < players_1.length; i++) {
      uint256 playernum = uint256(uint160(address(players_1[i])));
      salt += playernum % 10 + 1;
    }

    numberWinner_1 = (numberWin + salt) % 10 + 1;

    for (uint256 i = 0; i < players_1.length; i++) {
      address playerAddress = players_1[i];
      if (playerInfo_1[playerAddress].numberSelected == numberWinner_1) {
        winners[countWin] = playerAddress;
        //先把赢家的本金拿回
        tempTotal -= playerInfo_1[playerAddress].amountBet;
        pendingWithdrawals[playerAddress] +=  playerInfo_1[playerAddress].amountBet;
        winBetTotal += playerInfo_1[playerAddress].amountBet;
        winnerMap_1[playerAddress][numberWinner_1] += 1;
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
          winnerEtherAmount = (tempTotal * (playerInfo_1[winners[j]].amountBet * 100/winBetTotal)) / 100;
          totalWinbetAmout += winnerEtherAmount;
          pendingWithdrawals[winners[j]] +=  winnerEtherAmount;
          emit Won(true, winners[j], winnerEtherAmount);
        }
      }
      if (totalWinbetAmout >= 0) {
             tempTotal -= totalWinbetAmout;
      }
    } else {
        //没有人中奖的时候，退回100%
        for (uint256 i = 0; i < players_1.length; i++) {
          address playerAddress = players_1[i];
          pendingWithdrawals[playerAddress] +=  playerInfo_1[playerAddress].amountBet;
          tempTotal -= playerInfo_1[playerAddress].amountBet;
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


    for (uint256 i = 0; i < players_1.length; i++) {
      delete playerInfo_1[players_1[i]];
    }

    resetData_1();
  }

    // Restart game
  function resetData_1() private {
    delete players_1;
    totalBet_1 = 0;
    numberOfBets_1 = 0;
  }


      /// @notice To bet for a number by sending Ether
  /// @param numberSelected The number that the player wants to bet for. Must be between 1 and 10 both inclusive
  function bet_10(uint256 numberSelected) public payable {

    uint256 betValue1 = 100000 ether;
    require(poolSwitch3, "the pool close");
    // Check that the player doesn't exists
    require(!checkPlayerExists(msg.sender), "the player is in beting");
    // Check that the number to bet is within the range
    require(numberSelected <= 10 && numberSelected >= 1);
    // Check that the amount paid is bigger or equal the minimum bet
    require(pendingWithdrawals[msg.sender] >= betValue1, "you dont desposit enough lowb");
    require(numberOfBets_10 <= maximumBetsNr, "maximum number of bet");
    numberOfBets_10++;

    pendingWithdrawals[msg.sender] -= betValue1 ;

    //扣除手续费
    uint256 deal = betValue1 * platform_deal / DEAL_BASE;
    IERC20 token = IERC20(lowbTokenAddress);
    require(token.transfer(checker, deal/2 ), "platform deal Lowb transfer failed");
    require(token.transfer(owner, deal/2 ), "platform deal Lowb transfer failed");
    betValue1 -= deal;

    // Set the number bet for that player
    playerInfo_10[msg.sender].amountBet = betValue1;
    playerInfo_10[msg.sender].numberSelected = numberSelected;
    players_10.push(msg.sender);
    totalBet_10 += betValue1;
    if (scoreMap[msg.sender] == 0) {
      scoreMap[msg.sender] += betValue1;
      addPlayer(msg.sender, scoreMap[msg.sender]);
    } else {
      scoreMap[msg.sender] += betValue1;
      increaseScore(msg.sender, scoreMap[msg.sender]);
    }
    
    if (numberOfBets_10 >= maximumBetsNr) {
       generateNumberWinner_10(); 
    } else {
      emit Bet(msg.sender, betValue1, scoreMap[msg.sender]);
    }
      
    //We need to change this in order to be secure
  }

  /// @notice Generates a random number between 1 and 10 both inclusive.
  /// Can only be executed when the game ends.
  function generateNumberWinner_10() private {
    uint256 numberGenerated = block.number % 10 + 1;
    numberWinner_10 = numberGenerated;
    distributePrizes_10(numberGenerated);
  }


  /// @notice Sends the corresponding Ether to each winner then deletes all the
  /// players for the next game and resets the `totalBet` and `numberOfBets`
  function distributePrizes_10(uint256 numberWin) private {
    address[100] memory winners;
    address[100] memory losers;
    uint256 countWin = 0;
    uint256 countLose = 0;

    uint256 tempTotal = totalBet_10;
    uint256 winBetTotal = 0;
    uint256 salt = 0;
    
    //随机数加盐
    for(uint256 i = 0; i < players_10.length; i++) {
      uint256 playernum = uint256(uint160(address(players_10[i])));
      salt += playernum % 10 + 1;
    }

    numberWinner_10 = (numberWin + salt) % 10 + 1;

    for (uint256 i = 0; i < players_10.length; i++) {
      address playerAddress = players_10[i];
      if (playerInfo_10[playerAddress].numberSelected == numberWinner_10) {
        winners[countWin] = playerAddress;
        //先把赢家的本金拿回
        tempTotal -= playerInfo_10[playerAddress].amountBet;
        pendingWithdrawals[playerAddress] +=  playerInfo_10[playerAddress].amountBet;
        winBetTotal += playerInfo_10[playerAddress].amountBet;
        winnerMap_10[playerAddress][numberWinner_10] += 1;
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
          winnerEtherAmount = (tempTotal * (playerInfo_10[winners[j]].amountBet * 100/winBetTotal)) / 100;
          totalWinbetAmout += winnerEtherAmount;
          pendingWithdrawals[winners[j]] +=  winnerEtherAmount;
          emit Won(true, winners[j], winnerEtherAmount);
        }
      }
      if (totalWinbetAmout >= 0) {
             tempTotal -= totalWinbetAmout;
      }
    } else {
        //没有人中奖的时候，退回100%
        for (uint256 i = 0; i < players_10.length; i++) {
          address playerAddress = players_10[i];
          pendingWithdrawals[playerAddress] +=  playerInfo_10[playerAddress].amountBet;
          tempTotal -= playerInfo_10[playerAddress].amountBet;
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


    for (uint256 i = 0; i < players_10.length; i++) {
      delete playerInfo_10[players_10[i]];
    }

    resetData_10();
  }

    // Restart game
  function resetData_10() private {
    delete players_10;
    totalBet_10 = 0;
    numberOfBets_10 = 0;
  }



        /// @notice To bet for a number by sending Ether
  /// @param numberSelected The number that the player wants to bet for. Must be between 1 and 10 both inclusive
  function bet_20(uint256 numberSelected) public payable {

    uint256 betValue1 = 200000 ether;

    require(poolSwitch4, "the pool close");
    // Check that the player doesn't exists
    require(!checkPlayerExists(msg.sender), "the player is in beting");
    // Check that the number to bet is within the range
    require(numberSelected <= 10 && numberSelected >= 1);
    // Check that the amount paid is bigger or equal the minimum bet
    require(pendingWithdrawals[msg.sender] >= betValue1, "you dont desposit enough lowb");
    require(numberOfBets_20 <= maximumBetsNr, "maximum number of bet");
    numberOfBets_20++;

    pendingWithdrawals[msg.sender] -= betValue1 ;

    //扣除手续费
    uint256 deal = betValue1 * platform_deal / DEAL_BASE;
    IERC20 token = IERC20(lowbTokenAddress);
    require(token.transfer(checker, deal/2 ), "platform deal Lowb transfer failed");
    require(token.transfer(owner, deal/2 ), "platform deal Lowb transfer failed");
    betValue1 -= deal;

    // Set the number bet for that player
    playerInfo_20[msg.sender].amountBet = betValue1;
    playerInfo_20[msg.sender].numberSelected = numberSelected;
    players_20.push(msg.sender);
    totalBet_20 += betValue1;
    if (scoreMap[msg.sender] == 0) {
      scoreMap[msg.sender] += betValue1;
      addPlayer(msg.sender, scoreMap[msg.sender]);
    } else {
      scoreMap[msg.sender] += betValue1;
      increaseScore(msg.sender, scoreMap[msg.sender]);
    }
    
    if (numberOfBets_20 >= maximumBetsNr) {
       generateNumberWinner_20(); 
    } else {
      emit Bet(msg.sender, betValue1, scoreMap[msg.sender]);
    }
      
    //We need to change this in order to be secure
  }

  /// @notice Generates a random number between 1 and 10 both inclusive.
  /// Can only be executed when the game ends.
  function generateNumberWinner_20() private {
    uint256 numberGenerated = block.number % 10 + 1;
    numberWinner_20 = numberGenerated;
    distributePrizes_20(numberGenerated);
  }


  /// @notice Sends the corresponding Ether to each winner then deletes all the
  /// players for the next game and resets the `totalBet` and `numberOfBets`
  function distributePrizes_20(uint256 numberWin) private {
    address[100] memory winners;
    address[100] memory losers;
    uint256 countWin = 0;
    uint256 countLose = 0;

    uint256 tempTotal = totalBet_20;
    uint256 winBetTotal = 0;
    uint256 salt = 0;
    
    //随机数加盐
    for(uint256 i = 0; i < players_20.length; i++) {
      uint256 playernum = uint256(uint160(address(players_20[i])));
      salt += playernum % 10 + 1;
    }

    numberWinner_20 = (numberWin + salt) % 10 + 1;

    for (uint256 i = 0; i < players_20.length; i++) {
      address playerAddress = players_20[i];
      if (playerInfo_20[playerAddress].numberSelected == numberWinner_20) {
        winners[countWin] = playerAddress;
        //先把赢家的本金拿回
        tempTotal -= playerInfo_20[playerAddress].amountBet;
        pendingWithdrawals[playerAddress] +=  playerInfo_20[playerAddress].amountBet;
        winBetTotal += playerInfo_20[playerAddress].amountBet;
        winnerMap_20[playerAddress][numberWinner_20] += 1;
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
          winnerEtherAmount = (tempTotal * (playerInfo_20[winners[j]].amountBet * 100/winBetTotal)) / 100;
          totalWinbetAmout += winnerEtherAmount;
          pendingWithdrawals[winners[j]] +=  winnerEtherAmount;
          emit Won(true, winners[j], winnerEtherAmount);
        }
      }
      if (totalWinbetAmout >= 0) {
             tempTotal -= totalWinbetAmout;
      }
    } else {
        //没有人中奖的时候，退回100%
        for (uint256 i = 0; i < players_20.length; i++) {
          address playerAddress = players_20[i];
          pendingWithdrawals[playerAddress] +=  playerInfo_20[playerAddress].amountBet;
          tempTotal -= playerInfo_20[playerAddress].amountBet;
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


    for (uint256 i = 0; i < players_20.length; i++) {
      delete playerInfo_20[players_20[i]];
    }

    resetData_20();
  }

    // Restart game
  function resetData_20() private {
    delete players_20;
    totalBet_20 = 0;
    numberOfBets_20 = 0;
  }


       /// @notice To bet for a number by sending Ether
  /// @param numberSelected The number that the player wants to bet for. Must be between 1 and 10 both inclusive
  function bet_50(uint256 numberSelected) public payable {

    uint256 betValue1 = 500000 ether;

    require(poolSwitch5, "the pool close");
    // Check that the player doesn't exists
    require(!checkPlayerExists(msg.sender), "the player is in beting");
    // Check that the number to bet is within the range
    require(numberSelected <= 10 && numberSelected >= 1);
    // Check that the amount paid is bigger or equal the minimum bet
    require(pendingWithdrawals[msg.sender] >= betValue1, "you dont desposit enough lowb");
    require(numberOfBets_50 <= maximumBetsNr, "maximum number of bet");
    numberOfBets_50++;

    pendingWithdrawals[msg.sender] -= betValue1 ;

    //扣除手续费
    uint256 deal = betValue1 * platform_deal / DEAL_BASE;
    IERC20 token = IERC20(lowbTokenAddress);
    require(token.transfer(checker, deal/2 ), "platform deal Lowb transfer failed");
    require(token.transfer(owner, deal/2 ), "platform deal Lowb transfer failed");
    betValue1 -= deal;

    // Set the number bet for that player
    playerInfo_50[msg.sender].amountBet = betValue1;
    playerInfo_50[msg.sender].numberSelected = numberSelected;
    players_50.push(msg.sender);
    totalBet_50 += betValue1;
    if (scoreMap[msg.sender] == 0) {
      scoreMap[msg.sender] += betValue1;
      addPlayer(msg.sender, scoreMap[msg.sender]);
    } else {
      scoreMap[msg.sender] += betValue1;
      increaseScore(msg.sender, scoreMap[msg.sender]);
    }
    
    if (numberOfBets_50 >= maximumBetsNr) {
       generateNumberWinner_50(); 
    } else {
      emit Bet(msg.sender, betValue1, scoreMap[msg.sender]);
    }
      
    //We need to change this in order to be secure
  }

  /// @notice Generates a random number between 1 and 10 both inclusive.
  /// Can only be executed when the game ends.
  function generateNumberWinner_50() private {
    uint256 numberGenerated = block.number % 10 + 1;
    numberWinner_50 = numberGenerated;
    distributePrizes_50(numberGenerated);
  }


  /// @notice Sends the corresponding Ether to each winner then deletes all the
  /// players for the next game and resets the `totalBet` and `numberOfBets`
  function distributePrizes_50(uint256 numberWin) private {
    address[100] memory winners;
    address[100] memory losers;
    uint256 countWin = 0;
    uint256 countLose = 0;

    uint256 tempTotal = totalBet_50;
    uint256 winBetTotal = 0;
    uint256 salt = 0;
    
    //随机数加盐
    for(uint256 i = 0; i < players_50.length; i++) {
      uint256 playernum = uint256(uint160(address(players_50[i])));
      salt += playernum % 10 + 1;
    }

    numberWinner_50 = (numberWin + salt) % 10 + 1;

    for (uint256 i = 0; i < players_50.length; i++) {
      address playerAddress = players_50[i];
      if (playerInfo_50[playerAddress].numberSelected == numberWinner_50) {
        winners[countWin] = playerAddress;
        //先把赢家的本金拿回
        tempTotal -= playerInfo_50[playerAddress].amountBet;
        pendingWithdrawals[playerAddress] +=  playerInfo_50[playerAddress].amountBet;
        winBetTotal += playerInfo_50[playerAddress].amountBet;
        winnerMap_50[playerAddress][numberWinner_50] += 1;
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
          winnerEtherAmount = (tempTotal * (playerInfo_50[winners[j]].amountBet * 100/winBetTotal)) / 100;
          totalWinbetAmout += winnerEtherAmount;
          pendingWithdrawals[winners[j]] +=  winnerEtherAmount;
          emit Won(true, winners[j], winnerEtherAmount);
        }
      }
      if (totalWinbetAmout >= 0) {
             tempTotal -= totalWinbetAmout;
      }
    } else {
        //没有人中奖的时候，退回100%
        for (uint256 i = 0; i < players_50.length; i++) {
          address playerAddress = players_50[i];
          pendingWithdrawals[playerAddress] +=  playerInfo_50[playerAddress].amountBet;
          tempTotal -= playerInfo_50[playerAddress].amountBet;
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


    for (uint256 i = 0; i < players_50.length; i++) {
      delete playerInfo_50[players_50[i]];
    }

    resetData_50();
  }

    // Restart game
  function resetData_50() private {
    delete players_50;
    totalBet_50 = 0;
    numberOfBets_50 = 0;
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}