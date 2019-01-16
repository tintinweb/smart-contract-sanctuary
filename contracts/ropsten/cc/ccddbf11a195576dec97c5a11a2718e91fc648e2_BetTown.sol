pragma solidity ^0.4.24;


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

contract BetTown{
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
     * checks only RandomServer address is calling
    */
    modifier onlyRandomServer {
        require(msg.sender == randomServer);
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
    bool public payoutsPaused; 
    address public treasury;
    uint public contractBalance;
    uint public houseEdge;     
    uint public maxProfit;   
    uint public maxProfitAsPercentOfHouse;                    
    uint public minBet; 
    address public randomServer;
    uint public betId;

    uint public totalBets = 0;
    uint public totalWeiWon = 0;
    uint public totalWeiWagered = 0; 

    uint public maxPendingPayouts;
    
    /*
     * player vars
    */
    mapping (uint => address) playerAddress;
    mapping (uint => address) playerTempAddress;
    mapping (uint => uint) playerBetId;
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
    /* log bets + output to web3 for precise &#39;payout on win&#39; field in UI */
    event LogBet(uint indexed BetID, address indexed PlayerAddress, uint indexed RewardValue, uint ProfitValue, uint BetValue, uint PlayerNumber);      
    /* output to web3 UI on bet result*/
    /* Status: 0=lose, 1=win, 2=win + failed send, 3=refund, 4=refund + failed send*/
	event LogResult(uint indexed BetID, address indexed PlayerAddress, uint PlayerNumber, uint DiceResult, uint ProfitValue, uint BetValue, int Status);   
    /* log manual refunds */
    event LogRefund(uint indexed BetID, address indexed PlayerAddress, uint indexed RefundValue);
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
        /* init 50,000 = 5%  */
        ownerSetMaxProfitAsPercentOfHouse(50000);
        /* init min bet (0.01 ether) */
        ownerSetMinBet(10000000000000000);        
    }

    /*
     * public function
     * player submit bet
     * only if game is active & bet is valid    
    */
    function playerRollDice(uint rollUnder) public 
        payable
        gameIsActive
        betIsValid(msg.value, rollUnder)
	{   
        betId += 1;
        /* map bet id to this oraclize query */
		playerBetId[betId] = betId;
        /* map player lucky number to this oraclize query */
		playerNumber[betId] = rollUnder;
        /* map value of wager to this oraclize query */
        playerBetValue[betId] = msg.value;
        /* map player address to this oraclize query */
        playerAddress[betId] = msg.sender;
        /* safely map player profit to this oraclize query */                     
        playerProfit[betId] = ((((msg.value * (100-(rollUnder.sub(1)))) / (rollUnder.sub(1))+msg.value))*houseEdge/houseEdgeDivisor)-msg.value;        
        /* safely increase maxPendingPayouts liability - calc all pending payouts under assumption they win */
        maxPendingPayouts = maxPendingPayouts.add(playerProfit[betId]);
        /* check contract can payout on win */
        if(maxPendingPayouts >= contractBalance) revert();
        /* provides accurate numbers for web3 and allows for manual refunds in case of no oraclize __callback */
        emit LogBet(playerBetId[betId], playerAddress[betId], playerBetValue[betId].add(playerProfit[betId]), playerProfit[betId], playerBetValue[betId], playerNumber[betId]);          
    }   
             

    /*
    * semi-public function - only randomServer can call
    */
	function randomResult(uint myid, uint result) public   
		onlyRandomServer
		payoutsAreActive
	{

        /* player address mapped to query id does not exist */
        require(playerAddress[myid]!=0x0);

            
        /* map random result to player */
        playerDieResult[myid] = result;
        /* get the playerAddress for this query id */
        playerTempAddress[myid] = playerAddress[myid];
        /* delete playerAddress for this query id */
        delete playerAddress[myid];

        /* map the playerProfit for this query id */
        playerTempReward[myid] = playerProfit[myid];
        /* set  playerProfit for this query id to 0 */
        playerProfit[myid] = 0; 

        /* safely reduce maxPendingPayouts liability */
        maxPendingPayouts = maxPendingPayouts.sub(playerTempReward[myid]);         

        /* map the playerBetValue for this query id */
        playerTempBetValue[myid] = playerBetValue[myid];
        /* set  playerBetValue for this query id to 0 */
        playerBetValue[myid] = 0; 

        /* total number of bets */
        totalBets += 1;

        /* total wagered */
        totalWeiWagered += playerTempBetValue[myid];    

        /*
        * refund
        * if result is 0 result is empty refund original bet value
        * if refund fails save refund value to playerPendingWithdrawals
        */
        if (playerDieResult[myid] == 0 || result == 0) {
            emit LogResult(playerBetId[myid], playerTempAddress[myid], playerNumber[myid], playerDieResult[myid], 0, playerTempBetValue[myid], 3);            

            /*
            * send refund - external call to an untrusted contract
            * if send fails map refund value to playerPendingWithdrawals[address]
            * for withdrawal later via playerWithdrawPendingTransactions
            */
            if(!playerTempAddress[myid].send(playerTempBetValue[myid])){
                emit LogResult(playerBetId[myid], playerTempAddress[myid], playerNumber[myid], playerDieResult[myid], 0, playerTempBetValue[myid], 4);              
                /* if send failed let player withdraw via playerWithdrawPendingTransactions */
                playerPendingWithdrawals[playerTempAddress[myid]] = playerPendingWithdrawals[playerTempAddress[myid]].add(playerTempBetValue[myid]);
            }

            return;
        }

        /*
        * pay winner
        * update contract balance to calculate new max bet
        * send reward
        * if send of reward fails save value to playerPendingWithdrawals        
        */
        if(playerDieResult[myid] < playerNumber[myid]){ 

            /* safely reduce contract balance by player profit */
            contractBalance = contractBalance.sub(playerTempReward[myid]); 

            /* update total wei won */
            totalWeiWon = totalWeiWon.add(playerTempReward[myid]);              

            /* safely calculate payout via profit plus original wager */
            playerTempReward[myid] = playerTempReward[myid].add(playerTempBetValue[myid]); 

            emit LogResult(playerBetId[myid], playerTempAddress[myid], playerNumber[myid], playerDieResult[myid], playerTempReward[myid], playerTempBetValue[myid],1);                            

            /* update maximum profit */
            setMaxProfit();
            
            /*
            * send win - external call to an untrusted contract
            * if send fails map reward value to playerPendingWithdrawals[address]
            * for withdrawal later via playerWithdrawPendingTransactions
            */
            if(!playerTempAddress[myid].send(playerTempReward[myid])){
                emit LogResult(playerBetId[myid], playerTempAddress[myid], playerNumber[myid], playerDieResult[myid], playerTempReward[myid], playerTempBetValue[myid], 2);                   
                /* if send failed let player withdraw via playerWithdrawPendingTransactions */
                playerPendingWithdrawals[playerTempAddress[myid]] = playerPendingWithdrawals[playerTempAddress[myid]].add(playerTempReward[myid]);                               
            }

            return;

        }

        /*
        * no win
        * send 1 wei to a losing bet
        * update contract balance to calculate new max bet
        */
        if(playerDieResult[myid] >= playerNumber[myid]){

            emit LogResult(playerBetId[myid], playerTempAddress[myid], playerNumber[myid], playerDieResult[myid], 0, playerTempBetValue[myid], 0);                                

            /*  
            *  safe adjust contractBalance
            *  setMaxProfit
            *  send 1 wei to losing bet
            */
            contractBalance = contractBalance.add((playerTempBetValue[myid]-1));                                                                         

            /* update maximum profit */
            setMaxProfit(); 

            /*
            * send 1 wei - external call to an untrusted contract                  
            */
            if(!playerTempAddress[myid].send(1)){
                /* if send failed let player withdraw via playerWithdrawPendingTransactions */                
               playerPendingWithdrawals[playerTempAddress[myid]] = playerPendingWithdrawals[playerTempAddress[myid]].add(1);                                
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

    /* check for pending withdrawals  */
    function playerGetPendingTxByAddress(address addressToCheck) public constant returns (uint) {
        return playerPendingWithdrawals[addressToCheck];
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
    function ownerUpdateContractBalance(uint newContractBalanceInWei) public 
		onlyOwner
    {        
       contractBalance = newContractBalanceInWei;
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
        /* restrict each bet to a maximum profit of 1% contractBalance */
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

    /* only owner address can transfer ether */
    function ownerTransferEther(address sendTo, uint amount) public 
		onlyOwner
    {        
        /* safely update contract balance when sending out funds*/
        contractBalance = contractBalance.sub(amount);		
        /* update max profit */
        setMaxProfit();
        if(!sendTo.send(amount)) revert();
        emit LogOwnerTransfer(sendTo, amount); 
    }

    /* only owner address can do manual refund
    * used only if bet placed + oraclize failed to __callback
    * filter LogBet by address and/or playerBetId:
    * LogBet(playerBetId[rngId], playerAddress[rngId], safeAdd(playerBetValue[rngId], playerProfit[rngId]), playerProfit[rngId], playerBetValue[rngId], playerNumber[rngId]);
    * check the following logs do not exist for playerBetId and/or playerAddress[rngId] before refunding:
    * LogResult or LogRefund
    * if LogResult exists player should use the withdraw pattern playerWithdrawPendingTransactions 
    */
    function ownerRefundPlayer(uint originalPlayerBetId, address sendTo, uint originalPlayerProfit, uint originalPlayerBetValue) public 
		onlyOwner
    {        
        /* safely reduce pendingPayouts by playerProfit[rngId] */
        maxPendingPayouts = maxPendingPayouts.sub(originalPlayerProfit);
        /* send refund */
        if(!sendTo.send(originalPlayerBetValue)) revert();
        /* log refunds */
        emit LogRefund(originalPlayerBetId, sendTo, originalPlayerBetValue);        
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