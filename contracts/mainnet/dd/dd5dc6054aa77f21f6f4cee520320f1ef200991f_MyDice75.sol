pragma solidity ^0.4.2;


// Etheroll Functions
contract DSSafeAddSub {
    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }
    function safeAdd(uint a, uint b) internal returns (uint) {
        require(safeToAdd(a, b));
        return a + b;
    }

    function safeToSubtract(uint a, uint b) internal returns (bool) {
        return (b <= a);
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(safeToSubtract(a, b));
        return a - b;
    }
}

contract MyDice75 is DSSafeAddSub {

    /*
     * checks player profit and number is within range
    */
    modifier betIsValid(uint _betSize, uint _playerNumber) {
        
    require(((((_betSize * (10000-(safeSub(_playerNumber,1)))) / (safeSub(_playerNumber,1))+_betSize))*houseEdge/houseEdgeDivisor)-_betSize <= maxProfit);

    require(_playerNumber < maxNumber);
    require(_betSize >= minBet);
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
     * game vars
    */

    uint constant public maxBetDivisor = 1000000;
    uint constant public houseEdgeDivisor = 1000;
    bool public gamePaused;
    address public owner;
    bool public payoutsPaused;
    uint public contractBalance;
    uint public houseEdge;
    uint public maxProfit;
    uint public maxProfitAsPercentOfHouse;
    uint public minBet;
    uint public totalBets;
    uint public totalUserProfit;


    uint private randomNumber;  //上一次的randomNumber会参与到下一次的随机数产生
    uint public  nonce;         //计数器，也是随机数生成的种子
    uint private maxNumber = 10000;
    uint public  underNumber = 7500;

    mapping (address => uint) playerPendingWithdrawals;

    /*
     * events
    */
    /* Status: 0=lose, 1=win, 2=win + failed send,*/
    event LogResult(uint indexed BetID, address indexed PlayerAddress, uint indexed PlayerNumber, uint DiceResult, uint Value, int Status,uint BetValue,uint targetNumber);
    /* log owner transfers */
    event LogOwnerTransfer(address indexed SentToAddress, uint indexed AmountTransferred);

    /*
     * init
    */
    function MyDice75() {

        owner = msg.sender;

        ownerSetHouseEdge(935);

        ownerSetMaxProfitAsPercentOfHouse(20000);
     
        ownerSetMinBet(10000000000000000);
    }

    function GetRandomNumber() internal 
        returns(uint randonmNumber)
    {
        nonce++;
        randomNumber = randomNumber % block.timestamp + uint256(block.blockhash(block.number - 1));
        randomNumber = randomNumber + block.timestamp * block.difficulty * block.number + 1;
        randomNumber = randomNumber % 80100011001110010011000010110111001101011011110017;

        randomNumber = uint(sha3(randomNumber,nonce,10 + 10*1000000000000000000/msg.value));

        return (maxNumber - randomNumber % maxNumber);
    }

    /*
     * public function
     * player submit bet
     * only if game is active & bet is valid can query and set player vars
    */
    function playerRollDice() public
        payable
        gameIsActive
        betIsValid(msg.value, underNumber)
    {
        totalBets += 1;

        uint randReuslt = GetRandomNumber();

        /*
        * pay winner
        * update contract balance to calculate new max bet
        * send reward
        * if send of reward fails save value to playerPendingWithdrawals
        */
        if(randReuslt < underNumber){

            uint playerProfit = ((((msg.value * (maxNumber-(safeSub(underNumber,1)))) / (safeSub(underNumber,1))+msg.value))*houseEdge/houseEdgeDivisor)-msg.value;

            /* safely reduce contract balance by player profit */
            contractBalance = safeSub(contractBalance, playerProfit);

            /* safely calculate total payout as player profit plus original wager */
            uint reward = safeAdd(playerProfit, msg.value);

            totalUserProfit = totalUserProfit + playerProfit; // total profits

            LogResult(totalBets, msg.sender, underNumber, randReuslt, reward, 1, msg.value,underNumber);

            /* update maximum profit */
            setMaxProfit();

            /*
            * send win - external call to an untrusted contract
            * if send fails map reward value to playerPendingWithdrawals[address]
            * for withdrawal later via playerWithdrawPendingTransactions
            */
            if(!msg.sender.send(reward)){
                LogResult(totalBets, msg.sender, underNumber, randReuslt, reward, 2, msg.value,underNumber);

                /* if send failed let player withdraw via playerWithdrawPendingTransactions */
                playerPendingWithdrawals[msg.sender] = safeAdd(playerPendingWithdrawals[msg.sender], reward);
            }

            return;
        }

        /*
        * no win
        * send 1 wei to a losing bet
        * update contract balance to calculate new max bet
        */
        if(randReuslt >= underNumber){

            LogResult(totalBets, msg.sender, underNumber, randReuslt, msg.value, 0, msg.value,underNumber);

            /*
            *  safe adjust contractBalance
            *  setMaxProfit
            *  send 1 wei to losing bet
            */
            contractBalance = safeAdd(contractBalance, msg.value-1);

            /* update maximum profit */
            setMaxProfit();

            /*
            * send 1 wei - external call to an untrusted contract
            */
            if(!msg.sender.send(1)){
                /* if send failed let player withdraw via playerWithdrawPendingTransactions */
               playerPendingWithdrawals[msg.sender] = safeAdd(playerPendingWithdrawals[msg.sender], 1);
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
        maxProfit = (contractBalance*maxProfitAsPercentOfHouse)/maxBetDivisor;
    }

    /*
    * owner address only functions
    */
    function ()
        payable
    {
        playerRollDice();
    }

    function setNonce(uint value) public
        onlyOwner
    {
        nonce = value;
    }

    function ownerAddBankroll()
    payable
    onlyOwner
    {
        /* safely update contract balance */
        contractBalance = safeAdd(contractBalance, msg.value);
        /* update the maximum profit */
        setMaxProfit();
    }

    function getcontractBalance() public 
    onlyOwner 
    returns(uint)
    {
        return contractBalance;
    }

    function getTotalBets() public
    onlyOwner
    returns(uint)
    {
        return totalBets;
    }

    /* only owner address can set houseEdge */
    function ownerSetHouseEdge(uint newHouseEdge) public
        onlyOwner
    {
        houseEdge = newHouseEdge;
    }

    function getHouseEdge() public 
    onlyOwner 
    returns(uint)
    {
        return houseEdge;
    }

    /* only owner address can set maxProfitAsPercentOfHouse */
    function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public
        onlyOwner
    {
        /* restrict to maximum profit of 5% of total house balance*/
        require(newMaxProfitAsPercent <= 50000);
        maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
        setMaxProfit();
    }

    function getMaxProfitAsPercentOfHouse() public 
    onlyOwner 
    returns(uint)
    {
        return maxProfitAsPercentOfHouse;
    }

    /* only owner address can set minBet */
    function ownerSetMinBet(uint newMinimumBet) public
        onlyOwner
    {
        minBet = newMinimumBet;
    }

    function getMinBet() public 
    onlyOwner 
    returns(uint)
    {
        return minBet;
    }

    /* only owner address can transfer ether */
    function ownerTransferEther(address sendTo, uint amount) public
        onlyOwner
    {
        /* safely update contract balance when sending out funds*/
        contractBalance = safeSub(contractBalance, amount);
        /* update max profit */
        setMaxProfit();
        require(sendTo.send(amount));
        LogOwnerTransfer(sendTo, amount);
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


    /* only owner address can set owner address */
    function ownerChangeOwner(address newOwner) public
        onlyOwner
    {
        owner = newOwner;
    }

    /* only owner address can suicide - emergency */
    function ownerkill() public
        onlyOwner
    {
        suicide(owner);
    }

}