pragma solidity ^0.4.18;

contract DSSafeAddSub {
    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        if (!safeToAdd(a, b)) throw;
        return a + b;
    }

    function safeToSubtract(uint a, uint b) internal returns (bool) {
        return (b <= a);
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        if (!safeToSubtract(a, b)) throw;
        return a - b;
    }
}


contract LuckyDice is DSSafeAddSub {

    /*
     * bet size >= minBet, minNumber < minRollLimit < maxRollLimit - 1 < maxNumber
    */
    modifier betIsValid(uint _betSize, uint minRollLimit, uint maxRollLimit) {
        if (_betSize < minBet || maxRollLimit < minNumber || minRollLimit > maxNumber || maxRollLimit - 1 <= minRollLimit) throw;
        _;
    }

    /*
     * checks game is currently active
    */
    modifier gameIsActive {
        if (gamePaused == true) throw;
        _;
    }

    /*
     * checks payouts are currently active
    */
    modifier payoutsAreActive {
        if (payoutsPaused == true) throw;
        _;
    }


    /*
     * checks only owner address is calling
    */
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    /*
     * checks only treasury address is calling
    */
    modifier onlyCasino {
        if (msg.sender != casino) throw;
        _;
    }

    /*
     * probabilities
    */
    uint[] rollSumProbability = [0, 0, 0, 0, 0, 128600, 643004, 1929012, 4501028, 9002057, 16203703, 26363168, 39223251, 54012345, 69444444, 83719135, 94521604, 100308641, 100308641, 94521604, 83719135, 69444444, 54012345, 39223251, 26363168, 16203703, 9002057, 4501028, 1929012, 643004, 128600];
    uint probabilityDivisor = 10000000;

    /*
     * game vars
    */
    uint constant public maxProfitDivisor = 1000000;
    uint constant public houseEdgeDivisor = 1000;
    uint constant public maxNumber = 30;
    uint constant public minNumber = 5;
    bool public gamePaused;
    address public owner;
    bool public payoutsPaused;
    address public casino;
    uint public contractBalance;
    uint public houseEdge;
    uint public maxProfit;
    uint public maxProfitAsPercentOfHouse;
    uint public minBet;
    int public totalBets;
    uint public maxPendingPayouts;
    uint public totalWeiWon = 0;
    uint public totalWeiWagered = 0;

    // JP
    uint public jackpot = 0;
    uint public jpPercentage = 40; // = 4%
    uint public jpPercentageDivisor = 1000;
    uint public jpMinBet = 10000000000000000; // = 0.01 Eth

    // TEMP
    uint tempDiceSum;
    bool tempJp;
    uint tempDiceValue;
    bytes tempRollResult;
    uint tempFullprofit;

    /*
     * player vars
    */
    mapping(bytes32 => address) public playerAddress;
    mapping(bytes32 => address) playerTempAddress;
    mapping(bytes32 => bytes32) playerBetDiceRollHash;
    mapping(bytes32 => uint) playerBetValue;
    mapping(bytes32 => uint) playerTempBetValue;
    mapping(bytes32 => uint) playerRollResult;
    mapping(bytes32 => uint) playerMaxRollLimit;
    mapping(bytes32 => uint) playerMinRollLimit;
    mapping(address => uint) playerPendingWithdrawals;
    mapping(bytes32 => uint) playerProfit;
    mapping(bytes32 => uint) playerToJackpot;
    mapping(bytes32 => uint) playerTempReward;

    /*
     * events
    */
    /* log bets + output to web3 for precise &#39;payout on win&#39; field in UI */
    event LogBet(bytes32 indexed DiceRollHash, address indexed PlayerAddress, uint ProfitValue, uint ToJpValue,
        uint BetValue, uint minRollLimit, uint maxRollLimit);

    /* output to web3 UI on bet result*/
    /* Status: 0=lose, 1=win, 2=win + failed send, 3=refund, 4=refund + failed send*/
    event LogResult(bytes32 indexed DiceRollHash, address indexed PlayerAddress, uint minRollLimit, uint maxRollLimit,
        uint DiceResult, uint Value, string Salt, int Status);

    /* log manual refunds */
    event LogRefund(bytes32 indexed DiceRollHash, address indexed PlayerAddress, uint indexed RefundValue);

    /* log owner transfers */
    event LogOwnerTransfer(address indexed SentToAddress, uint indexed AmountTransferred);

    // jp logging
    // Status: 0=win JP, 1=failed send
    event LogJpPayment(bytes32 indexed DiceRollHash, address indexed PlayerAddress, uint DiceResult, uint JackpotValue,
        int Status);


    /*
     * init
    */
    function LuckyDice() {

        owner = msg.sender;
        casino = msg.sender;

        /* init 960 = 96% (4% houseEdge)*/
        ownerSetHouseEdge(960);

        /* 10,000 = 1%; 55,556 = 5.5556%  */
        ownerSetMaxProfitAsPercentOfHouse(55556);

        /* init min bet (0.1 ether) */
        ownerSetMinBet(100000000000000000);
    }

    /*
     * public function
     * player submit bet
     * only if game is active & bet is valid
    */
    function playerMakeBet(uint minRollLimit, uint maxRollLimit, bytes32 diceRollHash, uint8 v, bytes32 r, bytes32 s) public
    payable
    gameIsActive
    betIsValid(msg.value, minRollLimit, maxRollLimit)
    {
        /* checks if bet was already made */
        if (playerAddress[diceRollHash] != 0x0) throw;

        /* checks hash sign */
        if (casino != ecrecover(diceRollHash, v, r, s)) throw;

        tempFullprofit = getFullProfit(msg.value, minRollLimit, maxRollLimit);
        playerProfit[diceRollHash] = getProfit(msg.value, tempFullprofit);
        playerToJackpot[diceRollHash] = getToJackpot(msg.value, tempFullprofit);
        if (playerProfit[diceRollHash] - playerToJackpot[diceRollHash] > maxProfit)
            throw;

        /* map bet id to serverSeedHash */
        playerBetDiceRollHash[diceRollHash] = diceRollHash;
        /* map player limit to serverSeedHash */
        playerMinRollLimit[diceRollHash] = minRollLimit;
        playerMaxRollLimit[diceRollHash] = maxRollLimit;
        /* map value of wager to serverSeedHash */
        playerBetValue[diceRollHash] = msg.value;
        /* map player address to serverSeedHash */
        playerAddress[diceRollHash] = msg.sender;
        /* safely increase maxPendingPayouts liability - calc all pending payouts under assumption they win */
        maxPendingPayouts = safeAdd(maxPendingPayouts, playerProfit[diceRollHash]);


        /* check contract can payout on win */
        if (maxPendingPayouts >= contractBalance)
            throw;

        /* provides accurate numbers for web3 and allows for manual refunds in case of any error */
        LogBet(diceRollHash, playerAddress[diceRollHash], playerProfit[diceRollHash], playerToJackpot[diceRollHash],
            playerBetValue[diceRollHash], playerMinRollLimit[diceRollHash], playerMaxRollLimit[diceRollHash]);
    }

    function getFullProfit(uint _betSize, uint minRollLimit, uint maxRollLimit) internal returns (uint){
        uint probabilitySum = 0;
        for (uint i = minRollLimit + 1; i < maxRollLimit; i++)
        {
            probabilitySum += rollSumProbability[i];
        }

        return _betSize * safeSub(probabilityDivisor * 100, probabilitySum) / probabilitySum;
    }

    function getProfit(uint _betSize, uint fullProfit) internal returns (uint){
        return (fullProfit + _betSize) * houseEdge / houseEdgeDivisor - _betSize;
    }

    function getToJackpot(uint _betSize, uint fullProfit) internal returns (uint){
        return (fullProfit + _betSize) * jpPercentage / jpPercentageDivisor;
    }

    function withdraw(bytes32 diceRollHash, string rollResult, string salt) public
    payoutsAreActive
    {
        /* player address mapped to query id does not exist */
        if (playerAddress[diceRollHash] == 0x0) throw;

        /* checks hash */
        bytes32 hash = sha256(rollResult, salt);
        if (diceRollHash != hash) throw;

        /* get the playerAddress for this query id */
        playerTempAddress[diceRollHash] = playerAddress[diceRollHash];
        /* delete playerAddress for this query id */
        delete playerAddress[diceRollHash];

        /* map the playerProfit for this query id */
        playerTempReward[diceRollHash] = playerProfit[diceRollHash];
        /* set  playerProfit for this query id to 0 */
        playerProfit[diceRollHash] = 0;

        /* safely reduce maxPendingPayouts liability */
        maxPendingPayouts = safeSub(maxPendingPayouts, playerTempReward[diceRollHash]);

        /* map the playerBetValue for this query id */
        playerTempBetValue[diceRollHash] = playerBetValue[diceRollHash];
        /* set  playerBetValue for this query id to 0 */
        playerBetValue[diceRollHash] = 0;

        /* total number of bets */
        totalBets += 1;

        /* total wagered */
        totalWeiWagered += playerTempBetValue[diceRollHash];

        tempDiceSum = 0;
        tempJp = true;
        tempRollResult = bytes(rollResult);
        for (uint i = 0; i < 5; i++) {
            tempDiceValue = uint(tempRollResult[i]) - 48;
            tempDiceSum += tempDiceValue;
            playerRollResult[diceRollHash] = playerRollResult[diceRollHash] * 10 + tempDiceValue;

            if (tempRollResult[i] != tempRollResult[1]) {
                tempJp = false;
            }
        }

        /*
        * CONGRATULATIONS!!! SOMEBODY WON JP!
        */
        if (playerTempBetValue[diceRollHash] >= jpMinBet && tempJp) {
            LogJpPayment(playerBetDiceRollHash[diceRollHash], playerTempAddress[diceRollHash],
                playerRollResult[diceRollHash], jackpot, 0);

            uint jackpotTmp = jackpot;
            jackpot = 0;

            if (!playerTempAddress[diceRollHash].send(jackpotTmp)) {
                LogJpPayment(playerBetDiceRollHash[diceRollHash], playerTempAddress[diceRollHash],
                    playerRollResult[diceRollHash], jackpotTmp, 1);

                /* if send failed let player withdraw via playerWithdrawPendingTransactions */
                playerPendingWithdrawals[playerTempAddress[diceRollHash]] =
                safeAdd(playerPendingWithdrawals[playerTempAddress[diceRollHash]], jackpotTmp);
            }
        }

        /*
        * pay winner
        * update contract balance to calculate new max bet
        * send reward
        * if send of reward fails save value to playerPendingWithdrawals
        */
        if (playerMinRollLimit[diceRollHash] < tempDiceSum && tempDiceSum < playerMaxRollLimit[diceRollHash]) {
            /* safely reduce contract balance by player profit */
            contractBalance = safeSub(contractBalance, playerTempReward[diceRollHash]);

            /* update total wei won */
            totalWeiWon = safeAdd(totalWeiWon, playerTempReward[diceRollHash]);

            // adding JP percentage
            playerTempReward[diceRollHash] = safeSub(playerTempReward[diceRollHash], playerToJackpot[diceRollHash]);
            jackpot = safeAdd(jackpot, playerToJackpot[diceRollHash]);

            /* safely calculate payout via profit plus original wager */
            playerTempReward[diceRollHash] = safeAdd(playerTempReward[diceRollHash], playerTempBetValue[diceRollHash]);

            LogResult(playerBetDiceRollHash[diceRollHash], playerTempAddress[diceRollHash],
                playerMinRollLimit[diceRollHash], playerMaxRollLimit[diceRollHash], playerRollResult[diceRollHash],
                playerTempReward[diceRollHash], salt, 1);

            /* update maximum profit */
            setMaxProfit();

            /*
            * send win - external call to an untrusted contract
            * if send fails map reward value to playerPendingWithdrawals[address]
            * for withdrawal later via playerWithdrawPendingTransactions
            */
            if (!playerTempAddress[diceRollHash].send(playerTempReward[diceRollHash])) {
                LogResult(playerBetDiceRollHash[diceRollHash], playerTempAddress[diceRollHash],
                    playerMinRollLimit[diceRollHash], playerMaxRollLimit[diceRollHash], playerRollResult[diceRollHash],
                    playerTempReward[diceRollHash], salt, 2);

                /* if send failed let player withdraw via playerWithdrawPendingTransactions */
                playerPendingWithdrawals[playerTempAddress[diceRollHash]] =
                safeAdd(playerPendingWithdrawals[playerTempAddress[diceRollHash]], playerTempReward[diceRollHash]);
            }

            return;

        } else {
            /*
            * no win
            * update contract balance to calculate new max bet
            */

            LogResult(playerBetDiceRollHash[diceRollHash], playerTempAddress[diceRollHash],
                playerMinRollLimit[diceRollHash], playerMaxRollLimit[diceRollHash], playerRollResult[diceRollHash],
                playerTempBetValue[diceRollHash], salt, 0);

            /*
            *  safe adjust contractBalance
            *  setMaxProfit
            */
            contractBalance = safeAdd(contractBalance, (playerTempBetValue[diceRollHash]));

            /* update maximum profit */
            setMaxProfit();

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
        maxProfit = (contractBalance * maxProfitAsPercentOfHouse) / maxProfitDivisor;
    }

    /*
    * owner address only functions
    */
    function()
    payable
    onlyOwner
    {
        /* safely update contract balance */
        contractBalance = safeAdd(contractBalance, msg.value);
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
        maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
        setMaxProfit();
    }

    /* only owner address can set minBet */
    function ownerSetMinBet(uint newMinimumBet) public
    onlyOwner
    {
        minBet = newMinimumBet;
    }

    /* only owner address can set jpMinBet */
    function ownerSetJpMinBet(uint newJpMinBet) public
    onlyOwner
    {
        jpMinBet = newJpMinBet;
    }

    /* only owner address can transfer ether */
    function ownerTransferEther(address sendTo, uint amount) public
    onlyOwner
    {
        /* safely update contract balance when sending out funds*/
        contractBalance = safeSub(contractBalance, amount);
        /* update max profit */
        setMaxProfit();
        if (!sendTo.send(amount)) throw;
        LogOwnerTransfer(sendTo, amount);
    }

    /* only owner address can do manual refund
    * used only if bet placed + server error had a place
    * filter LogBet by address and/or diceRollHash
    * check the following logs do not exist for diceRollHash and/or playerAddress[diceRollHash] before refunding:
    * LogResult or LogRefund
    * if LogResult exists player should use the withdraw pattern playerWithdrawPendingTransactions
    */
    function ownerRefundPlayer(bytes32 diceRollHash, address sendTo, uint originalPlayerProfit, uint originalPlayerBetValue) public
    onlyOwner
    {
        /* safely reduce pendingPayouts by playerProfit[rngId] */
        maxPendingPayouts = safeSub(maxPendingPayouts, originalPlayerProfit);
        /* send refund */
        if (!sendTo.send(originalPlayerBetValue)) throw;
        /* log refunds */
        LogRefund(diceRollHash, sendTo, originalPlayerBetValue);
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

    /* only owner address can set casino address */
    function ownerSetCasino(address newCasino) public
    onlyOwner
    {
        casino = newCasino;
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