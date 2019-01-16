pragma solidity 0.4.25;

/**
* @title SafeMath
* @dev Math operations with safety checks that revert on error
*/
library SafeMath {
  
  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }
    
    uint256 c = a * b;
    require(c / a == b);
    
    return c;
  }
  
  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    
    return c;
  }
  
  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    
    return c;
  }
  
  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    
    return c;
  }
  
  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract BMRoll {
  using SafeMath for uint256;
  /*
  * checks player profit, bet size and player number is within range
  */
  modifier betIsValid(uint _betSize, uint _playerNumber) {
    require(_betSize >= minBet && _playerNumber >= minNumber && _playerNumber <= maxNumber && (((((_betSize * (100-(_playerNumber.sub(1)))) / (_playerNumber.sub(1))+_betSize))*houseEdge/houseEdgeDivisor)-_betSize <= maxProfit));
    _;
  }
  
  /*
  * checks game is currently active
  */
  modifier gameIsActive {
    require(gamePaused == false);
    _;
  }
  
  /*
  * checks payouts are currently active
  */
  modifier payoutsAreActive {
    require(payoutsPaused == false);
    _;
  }
  /*
  * checks only owner address is calling
  */
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
  /*
  * checks only treasury address is calling
  */
  modifier onlyTreasury {
    require (msg.sender == treasury);
    _;
  }
  
  /*
  * game vars
  */
  uint constant public maxProfitDivisor = 1000000;
  uint constant public houseEdgeDivisor = 1000;
  uint constant public maxNumber = 99;
  uint constant public minNumber = 2;
  bool public gamePaused;
  address public owner;
  address public server;
  bool public payoutsPaused;
  address public treasury;
  uint public contractBalance;
  uint public houseEdge;
  uint public maxProfit;
  uint public maxProfitAsPercentOfHouse;
  uint public minBet;
  
  uint public totalBets = 0;
  uint public totalSunWon = 0;
  uint public totalSunWagered = 0;
  
  address[100] lastUser;
  
  /*
  * player vars
  */
  mapping (uint => address) playerAddress;
  mapping (uint => address) playerTempAddress;
  mapping (uint => uint) playerBetValue;
  mapping (uint => uint) playerTempBetValue;
  mapping (uint => uint) playerDieResult;
  mapping (uint => uint) playerNumber;
  mapping (address => uint) playerPendingWithdrawals;
  mapping (uint => uint) playerProfit;
  mapping (uint => uint) playerTempReward;
  
  /*
  * events
  */
  /* output to web3 UI on bet result*/
  /* Status: 0=lose, 1=win, 2=win + failed send, 3=refund, 4=refund + failed send*/
  event LogResult(uint indexed BetID, address indexed PlayerAddress, uint PlayerNumber, uint DiceResult, uint ProfitValue, uint BetValue, int Status);
  /* log owner transfers */
  event LogOwnerTransfer(address indexed SentToAddress, uint indexed AmountTransferred);
  
  /*
  * init
  */
  constructor() public {
    
    owner = msg.sender;
    treasury = msg.sender;
    /* init 980 = 98% (2% houseEdge)*/
    ownerSetHouseEdge(980);
    /* init 50,000 = 5% */
    ownerSetMaxProfitAsPercentOfHouse(50000);
    /* init min bet (0.1 eth) */
    ownerSetMinBet(100000000000000000);   
  }
  
  /*
  * public function
  * player submit bet
  * only if game is active & bet is valid can rollDice
  */
  function playerRollDice(uint rollUnder) public
  payable
  gameIsActive
  betIsValid(msg.value, rollUnder)
  {
    /* total number of bets */
    
    lastUser[totalBets % 100] = msg.sender;
    totalBets += 1;
    
    /* map player lucky number to totalBets */
    playerNumber[totalBets] = rollUnder;
    /* map value of wager to totalBets */
    playerBetValue[totalBets] = msg.value;
    /* map player address to totalBets */
    playerAddress[totalBets] = msg.sender;
    /* safely map player profit to totalBets */
    playerProfit[totalBets] = ((((msg.value * (100-(rollUnder.sub(1)))) / (rollUnder.sub(1))+msg.value))*houseEdge/houseEdgeDivisor)-msg.value;
    
    //rand result
    uint256 random1 = uint256(blockhash(block.number-1));
    uint256 random2 = uint256(lastUser[random1 % 100]);
    uint256 random3 = uint256(block.coinbase) + random2;
    uint256 result = uint256(keccak256(abi.encodePacked(random1 + random2 + random3 + now + totalBets))) % 100 + 1; // this is an efficient way to get the uint out in the [0, maxRange] range;
    
    /* map random result to player */
    playerDieResult[totalBets] = result;
    /* get the playerAddress for this query id */
    playerTempAddress[totalBets] = playerAddress[totalBets];
    /* delete playerAddress for this query id */
    delete playerAddress[totalBets];
    
    /* map the playerProfit for this query id */
    playerTempReward[totalBets] = playerProfit[totalBets];
    /* set playerProfit for this query id to 0 */
    playerProfit[totalBets] = 0;
    
    /* map the playerBetValue for this query id */
    playerTempBetValue[totalBets] = playerBetValue[totalBets];
    /* set playerBetValue for this query id to 0 */
    playerBetValue[totalBets] = 0;
    
    /* total wagered */
    totalSunWagered += playerTempBetValue[totalBets];
    
    /*
    * pay winner
    * update contract balance to calculate new max bet
    * send reward
    * if send of reward fails save value to playerPendingWithdrawals
    */
    if(playerDieResult[totalBets] < playerNumber[totalBets]){
      
      /* safely reduce contract balance by player profit */
      contractBalance = contractBalance.sub(playerTempReward[totalBets]);
      
      /* update total sun won */
      totalSunWon = totalSunWon.add(playerTempReward[totalBets]);
      
      /* safely calculate payout via profit plus original wager */
      playerTempReward[totalBets] = playerTempReward[totalBets].add(playerTempBetValue[totalBets]);
      
      emit LogResult(totalBets, playerTempAddress[totalBets], playerNumber[totalBets], playerDieResult[totalBets], playerTempReward[totalBets], playerTempBetValue[totalBets],1);
      
      /* update maximum profit */
      setMaxProfit();
      
      /*
      * send win - external call to an untrusted contract
      * if send fails map reward value to playerPendingWithdrawals[address]
      * for withdrawal later via playerWithdrawPendingTransactions
      */
      if(!playerTempAddress[totalBets].send(playerTempReward[totalBets])){
        emit LogResult(totalBets, playerTempAddress[totalBets], playerNumber[totalBets], playerDieResult[totalBets], playerTempReward[totalBets], playerTempBetValue[totalBets], 2);
        /* if send failed let player withdraw via playerWithdrawPendingTransactions */
        playerPendingWithdrawals[playerTempAddress[totalBets]] = playerPendingWithdrawals[playerTempAddress[totalBets]].add(playerTempReward[totalBets]);
      }
      
      return;
      
    }
    
    /*
    * no win
    * send 1 sun to a losing bet
    * update contract balance to calculate new max bet
    */
    if(playerDieResult[totalBets] >= playerNumber[totalBets]){
      
      emit LogResult(totalBets, playerTempAddress[totalBets], playerNumber[totalBets], playerDieResult[totalBets], 0, playerTempBetValue[totalBets], 0);
      
      /*
      * safe adjust contractBalance
      * setMaxProfit
      * send 1 sun to losing bet
      */
      contractBalance = contractBalance.add((playerTempBetValue[totalBets]-1));
      
      /* update maximum profit */
      setMaxProfit();
      
      /*
      * send 1 sun - external call to an untrusted contract
      */
      if(!playerTempAddress[totalBets].send(1)){
        /* if send failed let player withdraw via playerWithdrawPendingTransactions */
        playerPendingWithdrawals[playerTempAddress[totalBets]] = playerPendingWithdrawals[playerTempAddress[totalBets]].add(1);
      }
      
      return;
      
    }
  }
  
  /*
  * public function
  * in case of a failed refund or win send
  */
  function playerWithdrawPendingTransactions() public
  payoutsAreActive
  returns (bool)
  {
    uint withdrawAmount = playerPendingWithdrawals[msg.sender];
    playerPendingWithdrawals[msg.sender] = 0;
    /* external call to untrusted contract */
    if (msg.sender.call.value(withdrawAmount)()) {
      return true;
      } else {
        /* if send failed revert playerPendingWithdrawals[msg.sender] = 0; */
        /* player can try to withdraw again later */
        playerPendingWithdrawals[msg.sender] = withdrawAmount;
        return false;
      }
    }
    
    /* check for pending withdrawals */
    function playerGetPendingTxByAddress(address addressToCheck) public view returns (uint) {
      return playerPendingWithdrawals[addressToCheck];
    }
    
    /* get game status */
    function getGameStatus() public view returns(uint, uint, uint, uint, uint, uint) {
      return (minBet, minNumber, maxNumber, houseEdge, houseEdgeDivisor, maxProfit);
    }
    
    /*
    * internal function
    * sets max profit
    */
    function setMaxProfit() internal {
      maxProfit = (contractBalance*maxProfitAsPercentOfHouse)/maxProfitDivisor;
    }
    
    /*
    * owner/treasury address only functions
    */
    function ()
        payable public
        onlyTreasury
    {
      /* safely update contract balance */
      contractBalance = contractBalance.add(msg.value);
      /* update the maximum profit */
      setMaxProfit();
    }
    
    /* only owner adjust contract balance variable (only used for max profit calc) */
    function ownerUpdateContractBalance(uint newContractBalanceInSun) public
    onlyOwner
    {
      contractBalance = newContractBalanceInSun;
    }
    
    /* only owner address can set houseEdge */
    function ownerSetHouseEdge(uint newHouseEdge) public
    onlyOwner
    {
      houseEdge = newHouseEdge;
    }
    
    /* only owner address can set maxProfitAsPercentOfHouse */
    function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public
    onlyOwner
    {
      /* restrict each bet to a maximum profit of 5% contractBalance */
      require(newMaxProfitAsPercent <= 50000);
      maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
      setMaxProfit();
    }
    
    /* only owner address can set minBet */
    function ownerSetMinBet(uint newMinimumBet) public
    onlyOwner
    {
      minBet = newMinimumBet;
    }
    
    /* only owner address can transfer eth */
    function ownerTransferEth(address sendTo, uint amount) public
    onlyOwner
    {
      /* safely update contract balance when sending out funds*/
      contractBalance = contractBalance.sub(amount);
      /* update max profit */
      setMaxProfit();
      if(!sendTo.send(amount)) revert();
      emit LogOwnerTransfer(sendTo, amount);
    }
    
    
    /* only owner address can set emergency pause #1 */
    function ownerPauseGame(bool newStatus) public
    onlyOwner
    {
      gamePaused = newStatus;
    }
    
    /* only owner address can set emergency pause #2 */
    function ownerPausePayouts(bool newPayoutStatus) public
    onlyOwner
    {
      payoutsPaused = newPayoutStatus;
    }
    
    /* only owner address can set treasury address */
    function ownerSetTreasury(address newTreasury) public
    onlyOwner
    {
      treasury = newTreasury;
    }
    
    /* only owner address can set owner address */
    function ownerChangeOwner(address newOwner) public
    onlyOwner
    {
      require(newOwner != 0);
      owner = newOwner;
    }
    
    /* only owner address can suicide - emergency */
    function ownerkill() public
    onlyOwner
    {
      selfdestruct(owner);
    }
    
    
  }