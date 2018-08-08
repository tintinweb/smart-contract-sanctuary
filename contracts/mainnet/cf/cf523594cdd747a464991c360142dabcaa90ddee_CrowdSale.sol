pragma solidity ^0.4.15;

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract SafeMath {
    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }
}


/*
    We deleted unused part.
    To see full source code, refer below : 
    https://github.com/pipermerriam/ethereum-datetime

    The MIT License (MIT)

    Copyright (c) 2015 Piper Merriam

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/
contract DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) constant returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) constant returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) constant returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal returns (DateTime dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);
        }

        function getYear(uint timestamp) constant returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) constant returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) constant returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) constant returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }
}

contract ITGTokenBase is ERC20, SafeMath {

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract Authable {
    address public owner;
    address public executor;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
   
    modifier onlyAuth(){
        require(msg.sender == owner || msg.sender == executor);
        _;
    }

    function setOwner(address _owner){
        require(owner == 0x0 || owner == msg.sender);
        owner = _owner;
    }

    function setExecutor(address exec) {
        require(executor == 0x0 || owner == msg.sender || executor == msg.sender);
        executor = exec;
    }
}

contract CrowdSale is SafeMath, Authable {

    struct SaleAttr{
        uint amountRaisedTotal;  // Total funding

        uint saleSupplyPre; // Supply for Pre crowdSale
        uint saleSupply1; // Supply for 1st crowdSale
        uint saleSupply2; // Supply for 2nd crowdSale
        uint saleSupply3; // Supply for 3rd crowdSale
        uint saleSupply4; // Supply for 4th crowdSale
        
        uint amountRaisedPre;   // Only count Pre crowdSale funding for distribute
        uint amountRaised1;     // Only count 1st crowdSale funding for distribute
        uint amountRaised2;     // Only count 2nd crowdSale funding for just record
        uint amountRaised3;     // Only count 3rd crowdSale funding for distribute
        uint amountRaised4;     // Only count 4th crowdSale funding for just record

        uint soldSupply2;
        uint soldSupply4;
    }
    SaleAttr public s;
    mapping(address => uint) public participantsForPreSale;    // Pre crowdSale participants
    mapping(address => uint) public participantsFor1stSale;    // 1st crowdSale participants
    mapping(address => uint) public participantsFor3rdSale;    // 3rd crowdSale participants

    event LogCustomSale(uint startTime, uint endTime, uint tokPerEth, uint supply);

    struct SaleTimeAttr{
        uint pstart;
        uint pdeadline;

        // 1st, 3rd sale is time based share
        // 2nd, 4th sale is price sale
        uint start;         // When 1st crowdSale starts
        uint deadline1;     // When 1st crowdSale ends and 2nd crowdSale starts
        uint deadline2;     // When 2nd crowdSale ends
        uint deadline3;     // When 3rd crowdSale ends
        uint deadline4;     // When 4th crowdSale ends
    }
    SaleTimeAttr public t;

    struct CustomSaleAttr{
        uint start;
        uint end;
        uint tokenPerEth;   // 0 means period sale
        uint saleSupply;
        uint soldSupply;
        uint amountRaised;
    }
    CustomSaleAttr public cs;
    mapping(uint => mapping(address => uint)) public participantsForCustomSale;

    function setAttrs(uint supplyPre, uint supply1, uint supply2, uint supply3, uint supply4
            , uint preStart, uint preEnd, uint start, uint end1, uint end2, uint end3, uint end4
        ) onlyAuth {
        s.saleSupplyPre = supplyPre; // totalSupply * 10 / 100
        //start, deadline1~4 should be set before start
        s.saleSupply1 = supply1;    //totalSupply * 10 / 100;     // 10% of totalSupply. Total 40% to CrowdSale, 5% to dev team, 55% will be used for game and vote
        s.saleSupply2 = supply2;    //totalSupply *  5 / 100;
        s.saleSupply3 = supply3;    //totalSupply * 10 / 100;
        s.saleSupply4 = supply4;    //totalSupply *  5 / 100;

        t.pstart = preStart;
        t.pdeadline = preEnd;
        t.start = start;
        t.deadline1 = end1;
        t.deadline2 = end2;
        t.deadline3 = end3;
        t.deadline4 = end4;
    }

    function setAttrCustom(uint startTime, uint endTime, uint tokPerEth, uint supply) onlyAuth {
        cs.start = startTime;
        cs.end = endTime;
        cs.tokenPerEth = tokPerEth;
        cs.saleSupply = supply;
        cs.soldSupply = 0;
        cs.amountRaised = 0;
        LogCustomSale(startTime, endTime, tokPerEth, supply);
    }

    function process(address sender, uint sendValue) onlyOwner returns (uint tokenAmount) {
        if(now > t.pstart && now <= t.pdeadline){
            participantsForPreSale[sender] = add(participantsForPreSale[sender],sendValue);
            s.amountRaisedPre = add(s.amountRaisedPre, sendValue);
        }else if(now > t.start && now <= t.deadline1){
            participantsFor1stSale[sender] = add(participantsFor1stSale[sender],sendValue);
            s.amountRaised1 = add(s.amountRaised1, sendValue);
        }else if(now > t.deadline1 && now <= t.deadline2 && s.soldSupply2 < s.saleSupply2){
            tokenAmount = sendValue / (s.amountRaised1 / s.saleSupply1 * 120 / 100);    //Token Price = s.amountRaised1 / s.saleSupply1. Price is going up 20%
            s.soldSupply2 = add(s.soldSupply2, tokenAmount);
            s.amountRaised2 = add(s.amountRaised2, sendValue);

            require(s.soldSupply2 < s.saleSupply2 * 105 / 100);   // A little bit more sale is granted for the price sale.
        }else if(now > t.deadline2 && now <= t.deadline3){
            participantsFor3rdSale[sender] = add(participantsFor3rdSale[sender],sendValue);
            s.amountRaised3 = add(s.amountRaised3, sendValue);
        }else if(now > t.deadline3 && now <= t.deadline4 && s.soldSupply4 < s.saleSupply4){
            tokenAmount = sendValue / (s.amountRaised3 / s.saleSupply3 * 120 / 100);     //Token Price = s.amountRaised3 / s.saleSupply3. Price is going up 20%
            s.soldSupply4 = add(s.soldSupply4, tokenAmount);
            s.amountRaised4 = add(s.amountRaised4, sendValue);

            require(s.soldSupply4 < s.saleSupply4 * 105 / 100);   // A little bit more sale is granted for the price sale.
        }else if(now > cs.start && now <= cs.end && cs.soldSupply < cs.saleSupply){
            if(cs.tokenPerEth > 0){
                tokenAmount = sendValue * cs.tokenPerEth;
                cs.soldSupply = add(cs.soldSupply, tokenAmount);

                require(cs.soldSupply < cs.saleSupply * 105 / 100); // A little bit more sale is granted for the price sale.
            }else{
                participantsForCustomSale[cs.start][sender] = add(participantsForCustomSale[cs.start][sender],sendValue);
                cs.amountRaised = add(cs.amountRaised, sendValue);
            }
        }else{
            throw;
        }
        s.amountRaisedTotal = add(s.amountRaisedTotal, sendValue);
    }

    function getToken(address sender) onlyOwner returns (uint tokenAmount){
        if(now > t.pdeadline && participantsForPreSale[sender] != 0){
            tokenAmount = add(tokenAmount,participantsForPreSale[sender] * s.saleSupplyPre / s.amountRaisedPre);  //Token Amount Per Eth = s.saleSupplyPre / s.amountRaisedPre
            participantsForPreSale[sender] = 0;
        }
        if(now > t.deadline1 && participantsFor1stSale[sender] != 0){
            tokenAmount = add(tokenAmount,participantsFor1stSale[sender] * s.saleSupply1 / s.amountRaised1);  //Token Amount Per Eth = s.saleSupply1 / s.amountRaised1
            participantsFor1stSale[sender] = 0;
        }
        if(now > t.deadline3 && participantsFor3rdSale[sender] != 0){
            tokenAmount = add(tokenAmount,participantsFor3rdSale[sender] * s.saleSupply3 / s.amountRaised3);  //Token Amount Per Eth = s.saleSupply3 / s.amountRaised3
            participantsFor3rdSale[sender] = 0;
        }
        if(now > cs.end && participantsForCustomSale[cs.start][sender] != 0){
            tokenAmount = add(tokenAmount,participantsForCustomSale[cs.start][sender] * cs.saleSupply / cs.amountRaised);  //Token Amount Per Eth = cs.saleSupply / cs.amountRaised
            participantsForCustomSale[cs.start][sender] = 0;
        }
    }
}

contract Voting is SafeMath, Authable {
    mapping(uint => uint) public voteRewardPerUnit; // If the voters vote, they will rewarded x% of tokens by their balances. 100 means 1%, 1000 means 10%
    mapping(uint => uint) public voteWeightUnit;    // If 100 * 1 ether, each 100 * 1 ether token of holder will get vote weight 1. 
    mapping(uint => uint) public voteStart;
    mapping(uint => uint) public voteEnd;
    mapping(uint => uint) public maxCandidateId;

    mapping(uint => mapping(address => bool)) public voted;
    mapping(uint => mapping(uint => uint)) public results;

    event LogVoteInitiate(uint _voteId, uint _voteRewardPerUnit, uint _voteWeightUnit, uint _voteStart, uint _voteEnd, uint _maxCandidateId);
    event LogVote(address voter, uint weight, uint voteId, uint candidateId, uint candidateValue);

    function voteInitiate(uint _voteId, uint _voteRewardPerUnit, uint _voteWeightUnit, uint _voteStart, uint _voteEnd, uint _maxCandidateId) onlyOwner {   
        require(voteEnd[_voteId] == 0);  // Do not allow duplicate voteId
        require(_voteEnd != 0);

        voteRewardPerUnit[_voteId] = _voteRewardPerUnit;
        voteWeightUnit[_voteId] = _voteWeightUnit;
        voteStart[_voteId] = _voteStart;
        voteEnd[_voteId] = _voteEnd;
        maxCandidateId[_voteId] = _maxCandidateId;

        LogVoteInitiate(_voteId, _voteRewardPerUnit, _voteWeightUnit, _voteStart, _voteEnd, _maxCandidateId);
    }

     function vote(address sender, uint holding, uint voteId, uint candidateId) onlyOwner returns (uint tokenAmount, uint lockUntil){
        require(now > voteStart[voteId] && now <= voteEnd[voteId]);
        require(maxCandidateId[voteId] >= candidateId);
        require(holding >= voteRewardPerUnit[voteId]);
        require(!voted[voteId][sender]);

        uint weight = holding / voteWeightUnit[voteId];

        results[voteId][candidateId] = add(results[voteId][candidateId], weight);
        voted[voteId][sender] = true;
        tokenAmount = weight * voteWeightUnit[voteId] * voteRewardPerUnit[voteId] / 100 / 100;
        lockUntil = voteEnd[voteId];

        LogVote(sender, weight, voteId, candidateId, results[voteId][candidateId]);
    }
}

contract Games is SafeMath, DateTime, Authable {
    enum GameTime { Hour, Month, Year, OutOfTime }
    enum GameType { Range, Point}

    struct Participant {
        address sender;
        uint value;
        uint currency; // 1 : Eth, 2 : Tok
    }

    struct DateAttr{
        uint currentYear;
        uint gameStart; //Only for Range Game
        uint gameEnd;   //For both Range Game and point Game(=intime timestamp)
        uint prevGameEnd; //Only for Point Game
    }
    DateAttr public d;

    struct CommonAttr{
        GameTime currentGameTimeType;      // Current Game time type
        GameType gameType;

        uint hourlyAmountEth;  // Funded Eth amount
        uint monthlyAmountEth;
        uint yearlyAmountEth;
        uint charityAmountEth;

    }
    CommonAttr public c;

    struct FundAmountStatusAttr{
        uint hourlyStatusEth;  // Funded Eth amount in current game time
        uint monthlyStatusEth;
        uint yearlyStatusEth;

        uint hourlyStatusTok;  // Funded Token amount in current game time
        uint monthlyStatusTok;
    }
    FundAmountStatusAttr public f;

    struct PriceAttr{
        uint bonusPerEth;   // If you not won, xx token to 1 Eth will be rewarded

        uint inGameTokPricePerEth;   // Regard xx token to 1 Eth for token participants
        uint inGameTokWinRatioMax;   // 100 means 100%. Disadventage against Eth. Change prize ratio like 25~50%
        uint inGameTokWinRatioMin;
        uint currentInGameTokWinRatio;  // Current token winners prize ratio

        uint hourlyMinParticipateRatio;     // If participants.length are less than 100, x100 would be min prize ratio
        uint monthlyMinParticipateRatio;    // If participants.length are less than 300, x300 would be min prize ratio
        uint yearlyMinParticipateRatio;     // If participants.length are less than 1000, x1000 would be min prize ratio

        uint boostPrizeEth;    // Boosts prize amount. Default is 100 and it means 100%
    }
    PriceAttr public p;


    struct RangeGameAttr{
        uint inTimeRange_H; // 10 means +-10 mins in time
        uint inTimeRange_M;
        uint inTimeRange_Y;
    }
    RangeGameAttr public r;
    Participant[] public participants;  // RangeGame participants

    mapping(uint256 => mapping(address => uint256)) public winners; // Eth reward
    mapping(uint256 => mapping(address => uint256)) public tokTakers; // Tok reward
    mapping(uint256 => uint256) public winPrizes;
    mapping(uint256 => uint256) public tokPrizes;

    event LogSelectWinner(uint rand, uint luckyNumber, address sender, uint reward, uint currency, uint amount);

    function setPriceAttr(
            GameType _gameType, uint _bonusPerEth, uint _inGameTokPricePerEth
            , uint _inGameTokWinRatioMax, uint _inGameTokWinRatioMin, uint _currentInGameTokWinRatio
            , uint _hourlyMinParticipateRatio, uint _monthlyMinParticipateRatio, uint _yearlyMinParticipateRatio, uint _boostPrizeEth
        ) onlyAuth {
        c.gameType = _gameType;

        p.bonusPerEth = _bonusPerEth;   //300   // Depends on crowdSale average price. Vote needed, but we assume AVG/4 is reasonable.
        p.inGameTokPricePerEth = _inGameTokPricePerEth; //300   // Regard xx token to 1 Eth for token participants. Depends on crowdSale, too.
        p.inGameTokWinRatioMax = _inGameTokWinRatioMax; //50    // 100 means 100%. Disadventage against Eth. Change prize ratio like 25~50%
        p.inGameTokWinRatioMin = _inGameTokWinRatioMin; //25
        p.currentInGameTokWinRatio = _currentInGameTokWinRatio;    //50
        p.hourlyMinParticipateRatio = _hourlyMinParticipateRatio;   //100   // If participants.length are less than 100, x100 would be min prize ratio
        p.monthlyMinParticipateRatio = _monthlyMinParticipateRatio; //300
        p.yearlyMinParticipateRatio = _yearlyMinParticipateRatio;   //1000
        p.boostPrizeEth = _boostPrizeEth;   //100
    }

    function setRangeGameAttr(uint _inTimeRange_H, uint _inTimeRange_M, uint _inTimeRange_Y) onlyAuth {
        r.inTimeRange_H = _inTimeRange_H;   //10       // 10 mean +-10 mins in time
        r.inTimeRange_M = _inTimeRange_M;   //190 = 3 * 60 + r.inTimeRange_H
        r.inTimeRange_Y = _inTimeRange_Y;   //370 = 6 * 60 + r.inTimeRange_H
    }
     
    // Calulate game time and gc amount record
    modifier beforeRangeGame(){
        require(now > d.gameStart && now <= d.gameEnd);
        _;
    }

    modifier beforePointGame(){
        refreshGameTime();
        _;
    }

    function process(address sender, uint sendValue) onlyOwner {
        if(c.gameType == GameType.Range){
            RangeGameProcess(sender, sendValue);
        }else if(c.gameType == GameType.Point){
            PointGameProcess(sender, sendValue);
        }
    }

    function processWithITG(address sender, uint tokenAmountToGame) onlyOwner {
        if(c.gameType == GameType.Range){
            RangeGameWithITG(sender, tokenAmountToGame);
        }else if(c.gameType == GameType.Point){
            PointGameWithITG(sender, tokenAmountToGame);
        }
    }

    // Range Game
    function RangeGameProcess(address sender, uint sendValue) private beforeRangeGame {
        if(c.currentGameTimeType == GameTime.Year){
            c.yearlyAmountEth = add(c.yearlyAmountEth, sendValue);
            f.yearlyStatusEth = add(f.yearlyStatusEth, sendValue);
        }else if(c.currentGameTimeType == GameTime.Month){
            c.monthlyAmountEth = add(c.monthlyAmountEth, sendValue);
            f.monthlyStatusEth = add(f.monthlyStatusEth, sendValue);
        }else if(c.currentGameTimeType == GameTime.Hour){
            c.hourlyAmountEth = add(c.hourlyAmountEth, sendValue);
            f.hourlyStatusEth = add(f.hourlyStatusEth, sendValue);
        }
        participants.push(Participant(sender,sendValue,1));
        if(p.bonusPerEth != 0){
            tokTakers[d.currentYear][sender] = add(tokTakers[d.currentYear][sender], sendValue * p.bonusPerEth);
            tokPrizes[d.currentYear] = add(tokPrizes[d.currentYear], sendValue * p.bonusPerEth);
        }
    }

    function RangeGameWithITG(address sender, uint tokenAmountToGame) private beforeRangeGame {
        require(c.currentGameTimeType != GameTime.Year);

        if(c.currentGameTimeType == GameTime.Month){
            f.monthlyStatusTok = add(f.monthlyStatusTok, tokenAmountToGame);
        }else if(c.currentGameTimeType == GameTime.Hour){
            f.hourlyStatusTok = add(f.hourlyStatusTok, tokenAmountToGame);
        }
        participants.push(Participant(sender,tokenAmountToGame,2));
    }

    function getTimeRangeInfo() private returns (GameTime, uint, uint, uint) {
        uint nextTimeStamp;
        uint nextYear;
        uint nextMonth;
        uint basis;
        if(c.gameType == GameType.Range){
            nextTimeStamp = now + r.inTimeRange_Y * 1 minutes + 1 hours;
            nextYear = getYear(nextTimeStamp);
            if(getYear(now - r.inTimeRange_Y * 1 minutes + 1 hours) != nextYear){
                basis = nextTimeStamp - (nextTimeStamp % 1 days);    //Time range limit is less than 12 hours
                return (GameTime.Year, nextYear, basis - r.inTimeRange_Y * 1 minutes, basis + r.inTimeRange_Y * 1 minutes);
            }
            nextTimeStamp = now + r.inTimeRange_M * 1 minutes + 1 hours;
            nextMonth = getMonth(nextTimeStamp);
            if(getMonth(now - r.inTimeRange_M * 1 minutes + 1 hours) != nextMonth){
                basis = nextTimeStamp - (nextTimeStamp % 1 days); 
                return (GameTime.Month, nextYear, basis - r.inTimeRange_M * 1 minutes, basis + r.inTimeRange_M * 1 minutes);
            }
            nextTimeStamp = now + r.inTimeRange_H * 1 minutes + 1 hours;
            basis = nextTimeStamp - (nextTimeStamp % 1 hours); 
            return (GameTime.Hour, nextYear, basis - r.inTimeRange_H * 1 minutes, basis + r.inTimeRange_H * 1 minutes);
        }else if(c.gameType == GameType.Point){
            nextTimeStamp = now - (now % 1 hours) + 1 hours;
            nextYear = getYear(nextTimeStamp);
            if(getYear(now) != nextYear){
                return (GameTime.Year, nextYear, 0, nextTimeStamp);
            }
            nextMonth = getMonth(nextTimeStamp);
            if(getMonth(now) != nextMonth){
                return (GameTime.Month, nextYear, 0, nextTimeStamp);
            }
            return (GameTime.Hour, nextYear, 0, nextTimeStamp);
        }
    }

    function refreshGameTime() private {
        (c.currentGameTimeType, d.currentYear, d.gameStart, d.gameEnd) = getTimeRangeInfo();
    }

    // Garbage Collect previous funded amount record and log the status
    function gcFundAmount() private {
        f.hourlyStatusEth = 0;
        f.monthlyStatusEth = 0;
        f.yearlyStatusEth = 0;

        f.hourlyStatusTok = 0;
        f.monthlyStatusTok = 0;
    }

    function selectWinner(uint rand) onlyOwner {
        uint luckyNumber = participants.length * rand / 100000000;
        uint rewardDiv100 = 0;

        uint participateRatio = participants.length;
        if(participateRatio != 0){
            if(c.currentGameTimeType == GameTime.Year){
                participateRatio = participateRatio > p.yearlyMinParticipateRatio?participateRatio:p.yearlyMinParticipateRatio;
            }else if(c.currentGameTimeType == GameTime.Month){
                participateRatio = participateRatio > p.monthlyMinParticipateRatio?participateRatio:p.monthlyMinParticipateRatio;
            }else if(c.currentGameTimeType == GameTime.Hour){
                participateRatio = participateRatio > p.hourlyMinParticipateRatio?participateRatio:p.hourlyMinParticipateRatio;
            }

            if(participants[luckyNumber].currency == 1){
                rewardDiv100 = participants[luckyNumber].value * participateRatio * p.boostPrizeEth / 100 / 100;
                if(p.currentInGameTokWinRatio < p.inGameTokWinRatioMax){
                    p.currentInGameTokWinRatio++;
                }
            }else if(participants[luckyNumber].currency == 2){
                rewardDiv100 = (participants[luckyNumber].value / p.inGameTokPricePerEth * p.currentInGameTokWinRatio / 100) * participateRatio / 100;
                if(p.currentInGameTokWinRatio > p.inGameTokWinRatioMin){
                    p.currentInGameTokWinRatio--;
                }
            }

            if(c.currentGameTimeType == GameTime.Year){
                if(c.yearlyAmountEth >= rewardDiv100*104){  //1.04
                    c.yearlyAmountEth = sub(c.yearlyAmountEth, rewardDiv100*104);
                }else{
                    rewardDiv100 = c.yearlyAmountEth / 104;
                    c.yearlyAmountEth = 0;
                }
            }else if(c.currentGameTimeType == GameTime.Month){
                if(c.monthlyAmountEth >= rewardDiv100*107){    //1.07
                    c.monthlyAmountEth = sub(c.monthlyAmountEth, rewardDiv100*107);
                }else{
                    rewardDiv100 = c.monthlyAmountEth / 107;
                    c.monthlyAmountEth = 0;
                }
                c.yearlyAmountEth = add(c.yearlyAmountEth,rewardDiv100 * 3); //0.03, 1.1
            }else if(c.currentGameTimeType == GameTime.Hour){
                if(c.hourlyAmountEth >= rewardDiv100*110){
                    c.hourlyAmountEth = sub(c.hourlyAmountEth, rewardDiv100*110);
                }else{
                    rewardDiv100 = c.hourlyAmountEth / 110;
                    c.hourlyAmountEth = 0;
                }
                c.monthlyAmountEth = add(c.monthlyAmountEth,rewardDiv100 * 3);
                c.yearlyAmountEth = add(c.yearlyAmountEth,rewardDiv100 * 3);
            }
            c.charityAmountEth = add(c.charityAmountEth,rewardDiv100 * 4);

            winners[d.currentYear][participants[luckyNumber].sender] = add(winners[d.currentYear][participants[luckyNumber].sender],rewardDiv100*100);
            winPrizes[d.currentYear] = add(winPrizes[d.currentYear],rewardDiv100*100);
        
            LogSelectWinner(rand, luckyNumber, participants[luckyNumber].sender, rewardDiv100*100, participants[luckyNumber].currency, participants[luckyNumber].value);

            // Initialize participants
            participants.length = 0;
        }
        if(c.gameType == GameType.Range){
            refreshGameTime();
        }
        gcFundAmount();    
    }

    //claimAll
    function getPrize(address sender) onlyOwner returns (uint ethPrize, uint tokPrize) {
        ethPrize = add(winners[d.currentYear][sender],winners[d.currentYear-1][sender]);
        tokPrize = add(tokTakers[d.currentYear][sender],tokTakers[d.currentYear-1][sender]);

        winPrizes[d.currentYear] = sub(winPrizes[d.currentYear],winners[d.currentYear][sender]);
        tokPrizes[d.currentYear] = sub(tokPrizes[d.currentYear],tokTakers[d.currentYear][sender]);
        winners[d.currentYear][sender] = 0;
        tokTakers[d.currentYear][sender] = 0;

        winPrizes[d.currentYear-1] = sub(winPrizes[d.currentYear-1],winners[d.currentYear-1][sender]);
        tokPrizes[d.currentYear-1] = sub(tokPrizes[d.currentYear-1],tokTakers[d.currentYear-1][sender]);
        winners[d.currentYear-1][sender] = 0;
        tokTakers[d.currentYear-1][sender] = 0;
    }

    // Point Game
    function PointGameProcess(address sender, uint sendValue) private beforePointGame {
        if(c.currentGameTimeType == GameTime.Year){
            c.yearlyAmountEth = add(c.yearlyAmountEth, sendValue);
            f.yearlyStatusEth = add(f.yearlyStatusEth, sendValue);
        }else if(c.currentGameTimeType == GameTime.Month){
            c.monthlyAmountEth = add(c.monthlyAmountEth, sendValue);
            f.monthlyStatusEth = add(f.monthlyStatusEth, sendValue);
        }else if(c.currentGameTimeType == GameTime.Hour){
            c.hourlyAmountEth = add(c.hourlyAmountEth, sendValue);
            f.hourlyStatusEth = add(f.hourlyStatusEth, sendValue);
        }

        PointGameParticipate(sender, sendValue, 1);
        
        if(p.bonusPerEth != 0){
            tokTakers[d.currentYear][sender] = add(tokTakers[d.currentYear][sender], sendValue * p.bonusPerEth);
            tokPrizes[d.currentYear] = add(tokPrizes[d.currentYear], sendValue * p.bonusPerEth);
        }
    }

    function PointGameWithITG(address sender, uint tokenAmountToGame) private beforePointGame {
        require(c.currentGameTimeType != GameTime.Year);

        if(c.currentGameTimeType == GameTime.Month){
            f.monthlyStatusTok = add(f.monthlyStatusTok, tokenAmountToGame);
        }else if(c.currentGameTimeType == GameTime.Hour){
            f.hourlyStatusTok = add(f.hourlyStatusTok, tokenAmountToGame);
        }

        PointGameParticipate(sender, tokenAmountToGame, 2);
    }

    function PointGameParticipate(address sender, uint sendValue, uint currency) private {
        if(d.prevGameEnd != d.gameEnd){
            selectWinner(1);
        }
        participants.length = 0;
        participants.push(Participant(sender,sendValue,currency));

        d.prevGameEnd = d.gameEnd;
    }

    function lossToCharity(uint year) onlyOwner returns (uint amt) {
        require(year < d.currentYear-1);
        
        amt = winPrizes[year];
        tokPrizes[year] = 0;
        winPrizes[year] = 0;
    }

    function charityAmtToCharity() onlyOwner returns (uint amt) {
        amt = c.charityAmountEth;
        c.charityAmountEth = 0;
    }

    function distributeTokenSale(uint hour, uint month, uint year, uint charity) onlyOwner{
        c.hourlyAmountEth = add(c.hourlyAmountEth, hour);
        c.monthlyAmountEth = add(c.monthlyAmountEth, month);
        c.yearlyAmountEth = add(c.yearlyAmountEth, year);
        c.charityAmountEth = add(c.charityAmountEth, charity);
    }
}

contract ITGToken is ITGTokenBase, Authable {
    bytes32  public  symbol = "ITG";
    uint256  public  decimals = 18;
    bytes32   public  name = "ITG";

    enum Status { CrowdSale, Game, Pause }
    Status public status;

    CrowdSale crowdSale;
    Games games;
    Voting voting;

    mapping(address => uint) public withdrawRestriction;

    uint public minEtherParticipate;
    uint public minTokParticipate;

    event LogFundTransfer(address sender, address to, uint amount, uint8 currency);

    modifier beforeTransfer(){
        require(withdrawRestriction[msg.sender] < now);
        _;
    }

    function transfer(address _to, uint _value) beforeTransfer returns (bool success) {
        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) beforeTransfer returns (bool success) {
        uint _allowance = allowed[_from][msg.sender];

        balances[_to] = add(balances[_to], _value);
        balances[_from] = sub(balances[_from], _value);
        allowed[_from][msg.sender] = sub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    /*  at initialization, setup the owner */
    function ITGToken() {
        owner = msg.sender;
        totalSupply = 100000000 * 1 ether;
        balances[msg.sender] = totalSupply;

        status = Status.Pause;
    }
    function () payable {
       if(msg.value < minEtherParticipate){
            throw;
       }

       if(status == Status.CrowdSale){
            LogFundTransfer(msg.sender, 0x0, msg.value, 1);
            itgTokenTransfer(crowdSale.process(msg.sender,msg.value),true);
       }else if(status == Status.Game){
            LogFundTransfer(msg.sender, 0x0, msg.value, 1);
            games.process(msg.sender, msg.value);
       }else if(status == Status.Pause){
            throw;
       }
    }

    function setAttrs(address csAddr, address gmAddr, address vtAddr, Status _status, uint amtEth, uint amtTok) onlyAuth {
        crowdSale = CrowdSale(csAddr);
        games = Games(gmAddr);
        voting = Voting(vtAddr);
        status = _status;
        minEtherParticipate = amtEth;
        minTokParticipate = amtTok;
    }

    //getCrowdSaleToken
    function USER_GET_CROWDSALE_TOKEN() {
        itgTokenTransfer(crowdSale.getToken(msg.sender),true);
    }

    //vote
    function USER_VOTE(uint voteId, uint candidateId){
        uint addedToken;
        uint lockUntil;
        (addedToken, lockUntil) = voting.vote(msg.sender,balances[msg.sender],voteId,candidateId);
        itgTokenTransfer(addedToken,true);

        if(withdrawRestriction[msg.sender] < lockUntil){
            withdrawRestriction[msg.sender] = lockUntil;
        }
    }

    function voteInitiate(uint voteId, uint voteRewardPerUnit, uint voteWeightUnit, uint voteStart, uint voteEnd, uint maxCandidateId) onlyAuth {
        voting.voteInitiate(voteId, voteRewardPerUnit, voteWeightUnit, voteStart, voteEnd, maxCandidateId);
    }

    function itgTokenTransfer(uint amt, bool fromOwner) private {
        if(amt > 0){
            if(fromOwner){
                balances[owner] = sub(balances[owner], amt);
                balances[msg.sender] = add(balances[msg.sender], amt);
                Transfer(owner, msg.sender, amt);
                LogFundTransfer(owner, msg.sender, amt, 2);
            }else{
                balances[owner] = add(balances[owner], amt);
                balances[msg.sender] = sub(balances[msg.sender], amt);
                Transfer(msg.sender, owner, amt);
                LogFundTransfer(msg.sender, owner, amt, 2);
            }
        }
    }

    function ethTransfer(address target, uint amt) private {
        if(amt > 0){
            target.transfer(amt);
            LogFundTransfer(0x0, target, amt, 1);
        }
    }

    //gameWithToken
    function USER_GAME_WITH_TOKEN(uint tokenAmountToGame) {
        require(status == Status.Game);
        require(balances[msg.sender] >= tokenAmountToGame * 1 ether);
        require(tokenAmountToGame * 1 ether >= minTokParticipate);

        itgTokenTransfer(tokenAmountToGame * 1 ether,false);

        games.processWithITG(msg.sender, tokenAmountToGame * 1 ether);
        
    }

    //getPrize
    function USER_GET_PRIZE() {
        uint ethPrize;
        uint tokPrize;
        (ethPrize, tokPrize) = games.getPrize(msg.sender);
        itgTokenTransfer(tokPrize,true);
        ethTransfer(msg.sender, ethPrize);
    }

    function selectWinner(uint rand) onlyAuth {
        games.selectWinner(rand);
    }

    function burn(uint amt) onlyOwner {
        balances[msg.sender] = sub(balances[msg.sender], amt);
        totalSupply = sub(totalSupply,amt);
    }

    function mint(uint amt) onlyOwner {
        balances[msg.sender] = add(balances[msg.sender], amt);
        totalSupply = add(totalSupply,amt);
    }

    // We do not want big difference with our contract&#39;s balance and actual prize pool.
    // So the ethereum that the winners didn&#39;t get over at least 1 year will be used for our charity business.
    // We strongly hope winners get their prize after the game.
    function lossToCharity(uint year,address charityAccount) onlyAuth {
        ethTransfer(charityAccount, games.lossToCharity(year));
    }

    function charityAmtToCharity(address charityAccount) onlyOwner {
        ethTransfer(charityAccount, games.charityAmtToCharity());
    }

    function distributeTokenSale(uint hour, uint month, uint year, uint charity) onlyAuth{
        games.distributeTokenSale(hour, month, year, charity);
    }

}