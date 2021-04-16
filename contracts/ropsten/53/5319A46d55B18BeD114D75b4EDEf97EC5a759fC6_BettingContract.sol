/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity >=0.4.22 <0.7.1;
pragma experimental ABIEncoderV2;

contract BettingContract {

    // Addresses

    address payable owner;

    uint public availableBalance = 0;
    uint public marginPct = 1;

    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // Constructor

    constructor() public payable {
        owner = msg.sender;
    }

    // Allow the contract to receive Ether
    function () external payable  {}

    function makePayment() payable public {}

    function withdrawBalance() onlyOwner public payable {
        msg.sender.transfer(availableBalance);
        emit Transfer(address(this), msg.sender, availableBalance);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawUserBalance() public {
        require(userBalances[msg.sender] > 0, "Nothing to withdraw, balance is 0.");

        uint userBalanceGross = userBalances[msg.sender];
        uint marginAmount = calculateMargin(userBalanceGross); 
        uint userBalanceNet = userBalanceGross - marginAmount;

        (bool sent, ) = msg.sender.call.value(userBalanceNet)("");
        require(sent, "Failed to withdraw balance");               
                        
        emit Transfer(address(this), msg.sender, userBalanceNet);
        availableBalance += marginAmount;
        userBalances[msg.sender] = 0;
    }

    // Events
    
    event FixtureRegistered(string match_id);
    event StakePlaced(uint stake_id, uint amount);
    event BetPlaced(uint bet_id, uint amount);

    event MatchFinished(string match_id);
    event StakePaid(uint stake_id, uint amount);
    event BetPaid(uint bet_id, uint amount);
    event StakeRefunded(uint stake_id, uint amount);
    event BetRefunded(uint bet_id, uint amount);

    event Transfer(address indexed from, address indexed to, uint value);

    enum Status {
        Unknown,
        Open, 
        Paid,
        Cancelled,
        Refunded
    }

    struct Fixture {
        string id; 
        
        uint startTimestamp;
        Status status;
    }

    struct Stake {
        string matchId;
        uint amount;
        uint outcomeType;
        uint outcome;
        
        uint[] odds; // e.g. Victory, Draw, Defeat
        uint[] availableAmounts;

        uint timestamp;
        Status status; 
        uint payout;
        address payable delegate;
    }

    struct Bet {
        uint[] stakeIds; 
        uint[] amounts;
        uint resultBet;

        uint timestamp;
        Status status; 
        uint payout;
        address payable delegate;
    }

    struct Odds {
        uint[] lengths; 
        uint[] amounts;
        uint[] stakeIds;

        uint lengthsIndex;
        uint amountsIndex; 
        uint stakeIdsIndex;
    }

    mapping(string => Fixture) public fixtureDict;
    mapping(uint => Stake) public stakeList;
    uint public stakesCount = 0;
    mapping(uint => Bet) public betList;
    uint public betsCount = 0;
    mapping(address => uint[]) public userStakes;
    mapping(address => uint[]) public userBets;
    mapping(string => uint[]) public matchStakes;
    mapping(string => uint[]) public matchBets;
    mapping(uint => uint[]) public stakeBets;
    mapping(address => uint) public userBalances;

    function createFixture(string calldata match_id, uint match_start) onlyOwner external payable {
        Fixture memory fixture;
        fixture.id = match_id;
        fixture.startTimestamp = match_start;
        fixture.status = Status.Open;
        
        fixtureDict[match_id] = fixture;

        emit FixtureRegistered(match_id);
    }

    function calculateMargin(uint grossAmount) private view returns (uint) {
        return (grossAmount * marginPct) / 100;
    }

    function subtractMargin(uint grossAmount) private view returns (uint) {
        return grossAmount - ((grossAmount * marginPct) / 100);
    }

    function subtractSlippage(uint grossAmount, uint slippagePct) private pure returns (uint) {
        return grossAmount - ((grossAmount * slippagePct) / 100);
    }

    function cutPrecision(uint input) private pure returns (uint) {
        return (input / 100) * 100;
    }

    function placeStake(string calldata match_id, uint amount, uint outcomeType, uint[] calldata odds, bool useUserBalance) external payable {
        require(odds.length > 1, "List of odds must contain more than 1 element.");
        require(fixtureDict[match_id].status == Status.Open, "Fixture was already processed");

        uint userBalanceUsed = checkAmount(msg.value, amount, useUserBalance);
        require(msg.value + userBalanceUsed == amount, "You have to send the exact amount of ether");
        uint netAmount = subtractMargin(amount);
        uint marginAmount = calculateMargin(amount);
        
        Stake memory stake;
        stake.matchId = match_id;
        stake.timestamp = now;
        stake.status = Status.Open;
        stake.delegate = msg.sender;
        stake.amount = netAmount;
        stake.outcome = 0;
        stake.payout = 0;
        stake.outcomeType = outcomeType;
        stake.odds = odds;
        stake.availableAmounts = new uint[](odds.length);
        for (uint i = 0; i < odds.length; i++) {
            stake.availableAmounts[i] = netAmount;
        }
        
        stakesCount ++;
        stakeList[stakesCount] = stake;
        userStakes[msg.sender].push(stakesCount);
        matchStakes[match_id].push(stakesCount);

        userBalances[msg.sender] -= userBalanceUsed;
        availableBalance += marginAmount;

        emit StakePlaced(stakesCount, netAmount);
    }

    function checkAmount(uint sentAmountGross, uint amountGross, bool useUserBalance) private view returns (uint) {
        require(amountGross > 0, "Amount cannot be 0");
        
        if (useUserBalance) {
            require(sentAmountGross <= amountGross, "Too much ether sent for this transaction");
            require(sentAmountGross + userBalances[msg.sender] >= amountGross, "Not enough funds to combine with the sent value");
            return amountGross - sentAmountGross;
        } else {
            require(sentAmountGross == amountGross, "You have to send exact amount of ether");
            return 0;
        }
    }

    function sumAmounts(uint[] memory amounts) private pure returns (uint) {
        uint amountSum = 0;
        for (uint i = 0; i < amounts.length; i++) {
            amountSum += amounts[i];
        }
        return amountSum;
    }

    function placeBets(string[] memory match_ids, uint[] memory resultBets, uint[] memory lengths, uint[] memory amounts, uint[] memory stakeIds, bool useUserBalance) public payable {
        require(match_ids.length > 0, "List of fixtures cannot be empty.");
        require(match_ids.length == resultBets.length, "Indices cannot differ in length.");
        require(match_ids.length == lengths.length, "Indices cannot differ in length.");

        uint sumAmountsGross = sumAmounts(amounts);
        uint userBalanceUsed = checkAmount(msg.value, sumAmountsGross, useUserBalance);
        require(msg.value + userBalanceUsed == sumAmountsGross, "You have to send the exact amount of ether");
        uint marginAmount = calculateMargin(msg.value + userBalanceUsed);
        uint currentIndex = 0;

        for (uint betIndex = 0; betIndex < match_ids.length; betIndex++) {
            require(fixtureDict[match_ids[betIndex]].status == Status.Open, "Fixture was already processed");
            require(now < fixtureDict[match_ids[betIndex]].startTimestamp, "Betting window already closed.");

            uint resultBet = resultBets[betIndex];
            uint betLength = lengths[betIndex];
            uint sumAmountsNet = 0;

            for (uint i = 0; i < betLength; i++) {
                uint stakeId = stakeIds[currentIndex + i];
                Stake storage stake = stakeList[stakeId];
                
                uint currentAmount = amounts[currentIndex + i];
                require(cutPrecision(currentAmount) == currentAmount, "Precision overflow (6)");
                uint netAmount = subtractMargin(currentAmount);

                uint winAmount = (netAmount * stake.odds[resultBet]) / 1 ether;
                require(stake.availableAmounts[resultBet] >= winAmount, "Insufficient funds available in stake");
                stake.availableAmounts[resultBet] -= winAmount;

                sumAmountsNet += netAmount;
            }

            createBet(match_ids[betIndex], amounts, stakeIds, resultBet, betLength, currentIndex);
            
            emit BetPlaced(betsCount, sumAmountsNet);

            currentIndex += betLength;
        }

        userBalances[msg.sender] -= userBalanceUsed;
        availableBalance += marginAmount;
    }

    function placeBetsWithSlippage(string[] memory match_ids, uint[] memory amounts, uint[] memory outcomeTypes, uint[] memory outcomeIndices, uint[] memory expectedOdds, uint slippagePct, uint maxStakesCount, bool useUserBalance) public payable {
        require(match_ids.length > 0, "List of fixtures cannot be empty.");
        require(match_ids.length == amounts.length, "Indices cannot differ in length.");
        require(match_ids.length == outcomeTypes.length, "Indices cannot differ in length.");
        require(match_ids.length == outcomeIndices.length, "Indices cannot differ in length.");
        require(match_ids.length == expectedOdds.length, "Indices cannot differ in length.");
        
        Odds memory odds;
        odds.stakeIds = new uint[](maxStakesCount);
        odds.amounts = new uint[](maxStakesCount); 
        odds.lengths = new uint[](maxStakesCount);

        for (uint i = 0; i < match_ids.length; i++) {
            string memory match_id = match_ids[i];
            
            require(fixtureDict[match_id].status == Status.Open, "Fixture was already processed");
            require(now < fixtureDict[match_id].startTimestamp, "Betting window already closed.");

            uint betLength = 0;
            uint resultBet = outcomeIndices[i];
            uint remainder = amounts[i];

            require(cutPrecision(remainder) == remainder, "Precision overflow (7)");

            uint[] memory stakeIds = matchStakes[match_id];
            
            for (uint a = 0; a < stakeIds.length - 1; a++) {
                for (uint b = 0; b < stakeIds.length - a - 1; b++) {
                    if (stakeList[stakeIds[b + 1]].odds[resultBet] > stakeList[stakeIds[b]].odds[resultBet]) {
                        uint tmpId = stakeIds[b];
                        stakeIds[b] = stakeIds[b + 1];
                        stakeIds[b + 1] = tmpId;
                    }
                }
            }

            uint oddsSum = 0; 
            uint weightsSum = 0;
            {
                for (uint j = 0; j < stakeIds.length; j++) {
                    Stake memory stake = stakeList[stakeIds[j]];
                    
                    // Filter stakes by outcomeType
                    if (stake.outcomeType == resultBet) {
                        uint availableAmount = stake.availableAmounts[resultBet];
                        if (availableAmount > 0 && remainder > 0) {
                            
                            require(odds.stakeIdsIndex < maxStakesCount, "Max stakes count reached, please raise maxStakesCount parameter");
                            odds.stakeIds[odds.stakeIdsIndex] = stakeIds[j];
                            odds.stakeIdsIndex++;

                            uint stakeOdds = stake.odds[resultBet];
                            uint stakeAmount = 0;
                            if (((remainder * stakeOdds) / 1 ether) > availableAmount) {
                                stakeAmount = (availableAmount * 1 ether) / stakeOdds;
                            } else {
                                stakeAmount = remainder;
                            }
                            stakeAmount = cutPrecision(stakeAmount);
                            
                            remainder -= stakeAmount;

                            require(odds.amountsIndex < maxStakesCount, "Max stakes count reached, please raise maxStakesCount parameter");
                            odds.amounts[odds.amountsIndex] = stakeAmount; 
                            odds.amountsIndex++;

                            oddsSum += (stakeAmount * stakeOdds) / 1 ether;
                            weightsSum += stakeAmount;

                            betLength++;
                        }
                    }
                }
            }

            require(odds.lengthsIndex < maxStakesCount, "Max stakes count reached, please raise maxStakesCount parameter");
            odds.lengths[odds.lengthsIndex] = betLength; 
            odds.lengthsIndex++;

            uint weightedOdds = 0; 
            if (weightsSum > 0) {
                weightedOdds = (oddsSum * 1 ether) / weightsSum;
            }
            
            uint minimalOdds = subtractSlippage(expectedOdds[i], slippagePct);
            require(weightedOdds >= minimalOdds, "Slippage condition failed");
        }

        sliceOdds(odds);
        placeBets(match_ids, outcomeIndices, odds.lengths, odds.amounts, odds.stakeIds, useUserBalance);
    }

    function sliceOdds(Odds memory odds) private pure {
        uint[] memory tmpLengths = new uint[](odds.lengthsIndex);
        for (uint i = 0; i < odds.lengthsIndex; i++) {
            tmpLengths[i] = odds.lengths[i];
        }
        odds.lengths = tmpLengths;
        
        uint[] memory tmpAmounts = new uint[](odds.amountsIndex);
        for (uint i = 0; i < odds.amountsIndex; i++) {
            tmpAmounts[i] = odds.amounts[i];
        }
        odds.amounts = tmpAmounts;
        
        uint[] memory tmpStakeIds = new uint[](odds.stakeIdsIndex);
        for (uint i = 0; i < odds.stakeIdsIndex; i++) {
            tmpStakeIds[i] = odds.stakeIds[i];
        }
        odds.stakeIds = tmpStakeIds;
    }

    function createBet(string memory match_id, uint[] memory amounts, uint[] memory stakeIds, uint resultBet, uint betLength, uint currentIndex) private {
        uint[] memory a = new uint[](betLength);  
        uint[] memory s = new uint[](betLength);
        for (uint i = 0; i < betLength; i++) {
            a[i] = subtractMargin(amounts[currentIndex + i]);
            s[i] = stakeIds[currentIndex + i];
        }

        Bet memory bet;
        bet.timestamp = now;
        bet.status = Status.Open;
        bet.stakeIds = s;
        bet.amounts = a;
        bet.resultBet = resultBet;
        bet.payout = 0;
        bet.delegate = msg.sender;
        
        betsCount ++;
        betList[betsCount] = bet;
        userBets[msg.sender].push(betsCount);
        matchBets[match_id].push(betsCount);

        for (uint i = 0; i < betLength; i++) {
            stakeBets[stakeIds[currentIndex + i]].push(betsCount);
        }
    }

    function evaluateMatch(string calldata match_id, uint[] calldata outcomeTypes, uint[] calldata results) onlyOwner external payable {
        require(outcomeTypes.length == results.length, "Outcome types and results cannot differ in length");
        require(fixtureDict[match_id].status == Status.Open, "Fixture was already processed");

        uint[] memory stakeIds = matchStakes[match_id];
        uint[] memory betIds = matchBets[match_id];
        
        for (uint j = 0; j < stakeIds.length; j++) {
            Stake storage stake = stakeList[stakeIds[j]];
            for (uint r = 0; r < outcomeTypes.length; r++) {
                if (outcomeTypes[r] == stake.outcomeType) {
                    stake.outcome = results[r];
                }
            }
            stake.payout = stake.amount;
        }

        for (uint j = 0; j < betIds.length; j++) {
            Bet storage bet = betList[betIds[j]];
            uint bookiePayout = 0;

            for (uint k = 0; k < bet.stakeIds.length; k++) {
                Stake storage stake = stakeList[bet.stakeIds[k]];

                stake.payout += bet.amounts[k];

                if (bet.resultBet == stake.outcome) {
                    uint winAmount = (bet.amounts[k] * stake.odds[stake.outcome]) / 1 ether;
                    bookiePayout += winAmount;
                    stake.payout -= winAmount;
                }
            }
            
            bet.status = Status.Paid;
            bet.payout = bookiePayout;
            
            userBalances[bet.delegate] += bookiePayout;
            emit BetPaid(betIds[j], bookiePayout);
        }

        for (uint j = 0; j < stakeIds.length; j++) {
            Stake storage stake = stakeList[stakeIds[j]];
            stake.status = Status.Paid;
            
            userBalances[stake.delegate] += stake.payout;
            emit StakePaid(stakeIds[j], stake.payout);
        }

        fixtureDict[match_id].status = Status.Paid;
        emit MatchFinished(match_id);
    }

    // Getters

    function getUserStakes(address userAddress) public view returns (uint[] memory) {
        return userStakes[userAddress];
    }

    function getUserBets(address userAddress) public view returns (uint[] memory) {
        return userBets[userAddress];
    }
    
    function getMatchStakes(string memory matchId) public view returns (uint[] memory) {
        return matchStakes[matchId];
    }

    function getStakeById(uint stakeId) public view returns (Stake memory) {
        return stakeList[stakeId];
    }

    function getBetById(uint betId) public view returns (Bet memory) {
        return betList[betId];
    }

    function getFixtureById(string memory fixtureId) public view returns (Fixture memory) {
        return fixtureDict[fixtureId];
    }

    // Cleaners 
    
    function refundMatch(string calldata match_id, uint confirmationCode) onlyOwner external payable {
        if (confirmationCode == 9999) {
            // Refund bets 
            uint[] memory betIds = matchBets[match_id];
            for (uint i = 0; i < betIds.length; i++) {
                Bet storage bet = betList[betIds[i]];

                if (bet.status == Status.Open) {
                    uint betTotalAmount = 0;
                    for (uint k = 0; k < bet.amounts.length; k++) {
                        betTotalAmount += bet.amounts[k];
                    }
                    
                    require(address(this).balance >= betTotalAmount, "Insufficient funds to refund a bet");
                    bet.delegate.transfer(betTotalAmount);
                    emit Transfer(address(this), bet.delegate, betTotalAmount);

                    bet.status = Status.Refunded;
                    emit BetRefunded(betIds[i], betTotalAmount);
                }
            }
            // Refund stakes 
            uint[] memory stakeIds = matchStakes[match_id];
            for (uint i = 0; i < stakeIds.length; i++) {
                Stake storage stake = stakeList[stakeIds[i]];

                if (stake.status == Status.Open) {
                    require(address(this).balance >= stake.amount, "Insufficient funds to refund a stake");
                    stake.delegate.transfer(stake.amount);
                    emit Transfer(address(this), stake.delegate, stake.amount);
                
                    stake.status = Status.Refunded;
                    emit StakeRefunded(stakeIds[i], stake.amount);
                }
            }
        }
    }

}