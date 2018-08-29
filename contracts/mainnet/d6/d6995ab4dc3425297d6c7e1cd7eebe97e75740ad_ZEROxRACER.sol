// 0xRACER is a brand new team-based pot lottery game. 
// Users are grouped into teams based on the first byte of their address.
// Team One: 0x0..., 0x1..., 0x2..., 0x3..., 0x4..., 0x5..., 0x6..., 0x7...
// Team Two: 0x8..., 0x9..., 0xa..., 0xb..., 0xc..., 0xd..., 0xe..., 0x0...

// DISCLAIMER: This is an experimental game in distributed psychology and distributed technology.
// DISCLAIMER: You can, and likely will, lose any ETH you send to this contract. Don&#39;t send more than you can afford to lose. Or any at all.

// RULES:

// 1. The team with the highest buy volume when the clock expires wins the pot.
// 2. The pot is divided among the winning team members, proportional to a weighted share of team volume. 
// 3. Each team has a different share price that increases at a rate of 102% per ETH of buy volume.
// 4. Every new buy adds time to the clock at the rate of 1 second/finney. The timer is capped at 24h.
// 5. You can also reduce the clock at the rate of 1 second/finney, but this does not count towards your share. The timer can&#39;t go below 5 minutes with this method.
// 6. Referrals and dividends are distributed by team. 50% of each new buy is proportionally split between that team&#39;s members.
// 7. New seeded rounds with new teams will begin on a semi-regular basis based on user interest. Each game will use a new contract.
// 8. In the unlikely event of a tie, the pot is distributed proportionally as weighted shares of total volume.
// 9. The minimum buy starts at 1 finney and increases with share price. No maximum.
// 10. There is no maximum buy, but large buys receive proportionally fewer shares. For example: 1 x 100 ETH buy (33,333 shares) vs. 100 x 1 ETH (55,265 shares).
// 10. No contracts allowed.
// 11. Users can withdraw earned dividends from referrals or pot wins at any time. Shares cannot be sold.
// 12. The round will automatically open based on a preset timer.
// 13. The contract will be closed no sooner than 100 days after the round ends. Any unclaimed user funds left past this time may be lost.

// STRATEGY:

// A. This game is designed to support multiple modes of play.
// B. Get in early and shill your team to collect divs.
// C. Manage risk by playing both sides of the fence.
// D. Flex your whale wallet by front running and reducing the timer.
// E. Piggy back on big players by making sure you&#39;re on the same team.
// F. Gain a larger share of divs by supporting the underdog.
// G. Buy smaller amounts to maximize your share count.

// https://zeroxracer.surge.sh/
// https://discord.gg/6Q7kGpc
// by nightman

pragma solidity ^0.4.24;

contract ZEROxRACER {

    //VARIABLES AND CONSTANTS

    //global 
    address public owner;
    uint256 public devBalance;
    uint256 public devFeeRate = 4; //4% of pot, not volume; effective dev fee, including premine, is ~2.5-3.5% depending on volume
    uint256 public precisionFactor = 6; //shares precise to 0.0001%
    address public addressThreshold = 0x7F00000000000000000000000000000000000000; //0x00-0x7f on Team One; 0x80-0xff on Team Two
    uint256 public divRate = 50; //50% dividends for each buy, distributed proportionally to weighted team volume

    //team accounting
    uint256 public teamOneId = 1; 
    string public teamOnePrefix = "Team 0x1234567";
    uint256 public teamOneVolume;
    uint256 public teamOneShares;
    uint256 public teamOneDivsTotal;
    uint256 public teamOneDivsUnclaimed;
    uint256 public teamOneSharePrice = 1000000000000000; //1 finney starting price; increases 102% per ETH bought


    uint256 public teamTwoId = 2;
    string public teamTwoPrefix = "Team 0x89abcdef";
    uint256 public teamTwoVolume;
    uint256 public teamTwoShares;
    uint256 public teamTwoDivsTotal;
    uint256 public teamTwoDivsUnclaimed;
    uint256 public teamTwoSharePrice = 1000000000000000; //1 finney starting price; increases 102% per ETH bought

    //user accounting
    address[] public teamOneMembers;
    mapping (address => bool) public isTeamOneMember;
    mapping (address => uint256) public userTeamOneStake;
    mapping (address => uint256) public userTeamOneShares;
    mapping (address => uint256) private userDivsTeamOneTotal;
    mapping (address => uint256) private userDivsTeamOneClaimed;
    mapping (address => uint256) private userDivsTeamOneUnclaimed;
    mapping (address => uint256) private userDivRateTeamOne;
    
    address[] public teamTwoMembers;
    mapping (address => bool) public isTeamTwoMember;
    mapping (address => uint256) public userTeamTwoStake;
    mapping (address => uint256) public userTeamTwoShares;
    mapping (address => uint256) private userDivsTeamTwoTotal;
    mapping (address => uint256) private userDivsTeamTwoClaimed;
    mapping (address => uint256) private userDivsTeamTwoUnclaimed;
    mapping (address => uint256) private userDivRateTeamTwo;

    //round accounting
    uint256 public pot;
    uint256 public timerStart;
    uint256 public timerMax;
    uint256 public roundStartTime;
    uint256 public roundEndTime;
    bool public roundOpen = false;
    bool public roundSetUp = false;
    bool public roundResolved = false;
    

    //CONSTRUCTOR

    constructor() public {
        owner = msg.sender;
        emit contractLaunched(owner);
    }
    

    //MODIFIERS

    modifier onlyOwner() { 
        require (msg.sender == owner, "you are not the owner"); 
        _; 
    }

    modifier gameOpen() {
        require (roundResolved == false);
        require (roundSetUp == true);
        require (now < roundEndTime, "it is too late to play");
        require (now >= roundStartTime, "it is too early to play");
        _; 
    }

    modifier onlyHumans() { 
        require (msg.sender == tx.origin, "you cannot use a contract"); 
        _; 
    }
    

    //EVENTS

    event potFunded(
        address _funder, 
        uint256 _amount,
        string _message
    );
    
    event teamBuy(
        address _buyer, 
        uint256 _amount, 
        uint256 _teamID,
        string _message
    );
    
    event roundEnded(
        uint256 _winningTeamId, 
        string _winningTeamString, 
        uint256 _pot,
        string _message
    );
    
    event newRoundStarted(
        uint256 _timeStart, 
        uint256 _timeMax,
        uint256 _seed,
        string _message
    );

    event userWithdrew(
        address _user,
        uint256 _teamID,
        uint256 _teamAmount,
        string _message
    );

    event devWithdrew(
        address _owner,
        uint256 _amount, 
        string _message
    );

    event contractClosed(
        address _owner,
        uint256 _amount,
        string _message
    );

    event contractLaunched(
        address _owner
    );


    //DEV FUNCTIONS

    //start round
    function openRound (uint _timerStart, uint _timerMax) public payable onlyOwner() {
        require (roundOpen == false, "you can only start the game once");
        require (roundResolved == false, "you cannot restart a finished game"); 
        require (msg.value == 2 ether, "you must give a decent seed");

        //round set up
        roundSetUp = true;
        timerStart = _timerStart;
        timerMax = _timerMax;
        roundStartTime = 1535504400; //Tuesday, August 28, 2018 9:00:00 PM Eastern Time
        roundEndTime = 1535504400 + timerStart;
        pot += msg.value;

        //the seed is also a sneaky premine
        //set up correct accounting for 1 ETH buy to each team without calling buy()
        address devA = 0x5C035Bb4Cb7dacbfeE076A5e61AA39a10da2E956;
        address devB = 0x84ECB387395a1be65E133c75Ff9e5FCC6F756DB3;
        teamOneVolume = 1 ether;
        teamTwoVolume = 1 ether;
        teamOneMembers.push(devA);
        teamTwoMembers.push(devB);
        isTeamOneMember[devA] = true;
        isTeamOneMember[devB] = true;
        userTeamOneStake[devA] = 1 ether;
        userTeamTwoStake[devB] = 1 ether;
        userTeamOneShares[devA] = 1000;
        userTeamTwoShares[devB] = 1000;
        teamOneShares = 1000;
        teamTwoShares = 1000;

        emit newRoundStarted(timerStart, timerMax, msg.value, "a new game was just set up");
    }

    //dev withdraw
    function devWithdraw() public onlyOwner() {
        require (devBalance > 0, "you must have an available balance");
        require(devBalance <= address(this).balance, "you cannot print money");

        uint256 shareTemp = devBalance;
        devBalance = 0;
        owner.transfer(shareTemp);

        emit devWithdrew(owner, shareTemp, "the dev just withdrew");
    }

    //close contract 
    //this function allows the dev to collect any wei dust from rounding errors no sooner than 100 days after the game ends
    //wei dust will be at most (teamOneVolume + teamTwoVolume) / 10 ** precisionFactor (ie, 0.0001% of the total buy volume)
    //users must withdraw any earned divs before this date, or risk losing them
    function zeroOut() public onlyOwner() { 
        require (now >= roundEndTime + 100 days, "too early to exit scam"); 
        require (roundResolved == true && roundOpen == false, "the game is not resolved");

        emit contractClosed(owner, address(this).balance, "the contract is now closed");

        selfdestruct(owner);
    }


    //PUBLIC FUNCTIONS

    function buy() public payable gameOpen() onlyHumans() { 

        //toggle roundOpen on first buy after roundStartTime
        if (roundOpen == false && now >= roundStartTime && now < roundEndTime) {
            roundOpen = true;
        }
        
        //establish team affiliation 
        uint256 _teamID;
        if (checkAddressTeamOne(msg.sender) == true) {
            _teamID = 1;
        } else if (checkAddressTeamTwo(msg.sender) == true) {
            _teamID = 2;
        }

        //adjust pot and div balances
        if (_teamID == 1 && teamOneMembers.length == 0 || _teamID == 2 && teamTwoMembers.length == 0) { 
            //do not distribute divs on first buy from either team. prevents black-holed ether
            //redundant if openRound() includes a premine
            pot += msg.value;
        } else {
            uint256 divContribution = uint256(SafeMaths.div(SafeMaths.mul(msg.value, divRate), 100)); 
            uint256 potContribution = msg.value - divContribution;
            pot += potContribution; 
            distributeDivs(divContribution, _teamID); 
        }

        //adjust time 
        timeAdjustPlus();

        //update team and player accounting 
        if (_teamID == 1) {
            require (msg.value >= teamOneSharePrice, "you must buy at least one Team One share");

            if (isTeamOneMember[msg.sender] == false) {
                isTeamOneMember[msg.sender] = true;
                teamOneMembers.push(msg.sender);
            }

            userTeamOneStake[msg.sender] += msg.value;
            teamOneVolume += msg.value;

            //adjust team one share price
            uint256 shareIncreaseOne = SafeMaths.mul(SafeMaths.div(msg.value, 100000), 2); //increases 102% per ETH spent
            teamOneSharePrice += shareIncreaseOne;

            uint256 newSharesOne = SafeMaths.div(msg.value, teamOneSharePrice);
            userTeamOneShares[msg.sender] += newSharesOne;
            teamOneShares += newSharesOne;

        } else if (_teamID == 2) {
            require (msg.value >= teamTwoSharePrice, "you must buy at least one Team Two share");

            if (isTeamTwoMember[msg.sender] == false) {
                isTeamTwoMember[msg.sender] = true;
                teamTwoMembers.push(msg.sender);
            }

            userTeamTwoStake[msg.sender] += msg.value;
            teamTwoVolume += msg.value;

            //adjust team two share price
            uint256 shareIncreaseTwo = SafeMaths.mul(SafeMaths.div(msg.value, 100000), 2); //increases 102% per ETH spent
            teamTwoSharePrice += shareIncreaseTwo;

            uint256 newSharesTwo = SafeMaths.div(msg.value, teamTwoSharePrice);
            userTeamTwoShares[msg.sender] += newSharesTwo;
            teamTwoShares += newSharesTwo;
        }
    
        emit teamBuy(msg.sender, msg.value, _teamID, "a new buy just happened");
    }  

    function resolveRound() public onlyHumans() { 

        //can be called by anyone if the round has ended 
        require (now > roundEndTime, "you can only call this if time has expired");
        require (roundSetUp == true, "you cannot call this before the game starts");
        require (roundResolved == false, "you can only call this once");

        //resolve round based on current winner 
        if (teamOneVolume > teamTwoVolume) {
            teamOneWin();
        } else if (teamOneVolume < teamTwoVolume) {
            teamTwoWin();
        } else if (teamOneVolume == teamTwoVolume) {
            tie();
        }

        //ensure this function can only be called once
        roundResolved = true; 
        roundOpen = false;
    }

    function userWithdraw() public onlyHumans() {

        //user divs calculated on withdraw to prevent runaway gas costs associated with looping balance updates in distributeDivs
        if (userTeamOneShares[msg.sender] > 0) { 

            //first, calculate total earned user divs as a proportion of their shares vs. team shares
            //second, determine whether the user has available divs 
            //precise to 0.0001%
            userDivRateTeamOne[msg.sender] = SafeMaths.div(SafeMaths.div(SafeMaths.mul(userTeamOneShares[msg.sender], 10 ** (precisionFactor + 1)), teamOneShares) + 5, 10);
            userDivsTeamOneTotal[msg.sender] = uint256(SafeMaths.div(SafeMaths.mul(teamOneDivsTotal, userDivRateTeamOne[msg.sender]), 10 ** precisionFactor));
            userDivsTeamOneUnclaimed[msg.sender] = SafeMaths.sub(userDivsTeamOneTotal[msg.sender], userDivsTeamOneClaimed[msg.sender]);

            if (userDivsTeamOneUnclaimed[msg.sender] > 0) {
                //sanity check
                assert(userDivsTeamOneUnclaimed[msg.sender] <= address(this).balance && userDivsTeamOneUnclaimed[msg.sender] <= teamOneDivsUnclaimed);

                //update user accounting and transfer
                teamOneDivsUnclaimed -= userDivsTeamOneUnclaimed[msg.sender];
                userDivsTeamOneClaimed[msg.sender] = userDivsTeamOneTotal[msg.sender];
                uint256 shareTempTeamOne = userDivsTeamOneUnclaimed[msg.sender];
                userDivsTeamOneUnclaimed[msg.sender] = 0;
                msg.sender.transfer(shareTempTeamOne);

                emit userWithdrew(msg.sender, 1, shareTempTeamOne, "a user just withdrew team one shares");
            }

        }  else if (userTeamTwoShares[msg.sender] > 0) {

            //first, calculate total earned user divs as a proportion of their shares vs. team shares
            //second, determine whether the user has available divs 
            //precise to 0.0001%
            userDivRateTeamTwo[msg.sender] = SafeMaths.div(SafeMaths.div(SafeMaths.mul(userTeamTwoShares[msg.sender], 10 ** (precisionFactor + 1)), teamTwoShares) + 5, 10);
            userDivsTeamTwoTotal[msg.sender] = uint256(SafeMaths.div(SafeMaths.mul(teamTwoDivsTotal, userDivRateTeamTwo[msg.sender]), 10 ** precisionFactor));
            userDivsTeamTwoUnclaimed[msg.sender] = SafeMaths.sub(userDivsTeamTwoTotal[msg.sender], userDivsTeamTwoClaimed[msg.sender]);

            if (userDivsTeamTwoUnclaimed[msg.sender] > 0) {
                //sanity check
                assert(userDivsTeamTwoUnclaimed[msg.sender] <= address(this).balance && userDivsTeamTwoUnclaimed[msg.sender] <= teamTwoDivsUnclaimed);

                //update user accounting and transfer
                teamTwoDivsUnclaimed -= userDivsTeamTwoUnclaimed[msg.sender];
                userDivsTeamTwoClaimed[msg.sender] = userDivsTeamTwoTotal[msg.sender];
                uint256 shareTempTeamTwo = userDivsTeamTwoUnclaimed[msg.sender];
                userDivsTeamTwoUnclaimed[msg.sender] = 0;
                msg.sender.transfer(shareTempTeamTwo);

                emit userWithdrew(msg.sender, 2, shareTempTeamTwo, "a user just withdrew team one shares");
            }
        }
    }

    function fundPot() public payable onlyHumans() gameOpen() {
        //ETH sent with this function is a benevolent gift. It does not count towards user shares or adjust the clock
        pot += msg.value;
        emit potFunded(msg.sender, msg.value, "a generous person funded the pot");
    }

    function reduceTime() public payable onlyHumans() gameOpen() {
        //ETH sent with this function does not count towards user shares 
        timeAdjustNeg();
        pot += msg.value;
        emit potFunded(msg.sender, msg.value, "someone just reduced the clock");
    }


    //VIEW FUNCTIONS

    function calcUserDivsTotal(address _user) public view returns(uint256 _divs) {

        //calculated locally to avoid unnecessary state change
        if (userTeamOneShares[_user] > 0) {

            uint256 userDivRateTeamOneView = SafeMaths.div(SafeMaths.div(SafeMaths.mul(userTeamOneShares[_user], 10 ** (precisionFactor + 1)), teamOneShares) + 5, 10);
            uint256 userDivsTeamOneTotalView = uint256(SafeMaths.div(SafeMaths.mul(teamOneDivsTotal, userDivRateTeamOneView), 10 ** precisionFactor));

        } else if (userTeamTwoShares[_user] > 0) {

            uint256 userDivRateTeamTwoView = SafeMaths.div(SafeMaths.div(SafeMaths.mul(userTeamTwoShares[_user], 10 ** (precisionFactor + 1)), teamTwoShares) + 5, 10);
            uint256 userDivsTeamTwoTotalView = uint256(SafeMaths.div(SafeMaths.mul(teamTwoDivsTotal, userDivRateTeamTwoView), 10 ** precisionFactor));

        }

        uint256 userDivsTotal = userDivsTeamOneTotalView + userDivsTeamTwoTotalView;
        return userDivsTotal;
    }

    function calcUserDivsAvailable(address _user) public view returns(uint256 _divs) {

        //calculated locally to avoid unnecessary state change
        if (userTeamOneShares[_user] > 0) {

            uint256 userDivRateTeamOneView = SafeMaths.div(SafeMaths.div(SafeMaths.mul(userTeamOneShares[_user], 10 ** (precisionFactor + 1)), teamOneShares) + 5, 10);
            uint256 userDivsTeamOneTotalView = uint256(SafeMaths.div(SafeMaths.mul(teamOneDivsTotal, userDivRateTeamOneView), 10 ** precisionFactor));
            uint256 userDivsTeamOneUnclaimedView = SafeMaths.sub(userDivsTeamOneTotalView, userDivsTeamOneClaimed[_user]);

        } else if (userTeamTwoShares[_user] > 0) {

            uint256 userDivRateTeamTwoView = SafeMaths.div(SafeMaths.div(SafeMaths.mul(userTeamTwoShares[_user], 10 ** (precisionFactor + 1)), teamTwoShares) + 5, 10);
            uint256 userDivsTeamTwoTotalView = uint256(SafeMaths.div(SafeMaths.mul(teamTwoDivsTotal, userDivRateTeamTwoView), 10 ** precisionFactor));
            uint256 userDivsTeamTwoUnclaimedView = SafeMaths.sub(userDivsTeamTwoTotalView, userDivsTeamTwoClaimed[_user]);

        }

        uint256 userDivsUnclaimed = userDivsTeamOneUnclaimedView + userDivsTeamTwoUnclaimedView;
        return userDivsUnclaimed;
    }

    function currentRoundInfo() public view returns(
        uint256 _pot, 
        uint256 _teamOneVolume, 
        uint256 _teamTwoVolume, 
        uint256 _teamOnePlayerCount,
        uint256 _teamTwoPlayerCount,
        uint256 _totalPlayerCount,
        uint256 _timerStart, 
        uint256 _timerMax, 
        uint256 _roundStartTime, 
        uint256 _roundEndTime, 
        uint256 _timeLeft,
        string _currentWinner
    ) {
        return (
            pot, 
            teamOneVolume, 
            teamTwoVolume, 
            teamOneTotalPlayers(), 
            teamTwoTotalPlayers(), 
            totalPlayers(), 
            timerStart, 
            timerMax, 
            roundStartTime, 
            roundEndTime, 
            getTimeLeft(),
            currentWinner()
        );
    }

    function getTimeLeft() public view returns(uint256 _timeLeftSeconds) {
        //game over: display zero
        if (now >= roundEndTime) {
            return 0;
        //game not yet started: display countdown until roundStartTime
        } else if (roundOpen == false && roundResolved == false && roundSetUp == false) {
            return roundStartTime - now;
        //game in progress: display time left 
        } else {
            return roundEndTime - now;
        }
    }
    
    function teamOneTotalPlayers() public view returns(uint256 _teamOnePlayerCount) {
        return teamOneMembers.length;
    }

    function teamTwoTotalPlayers() public view returns(uint256 _teamTwoPlayerCount) {
        return teamTwoMembers.length;
    }

    function totalPlayers() public view returns(uint256 _totalPlayerCount) {
        return teamOneMembers.length + teamTwoMembers.length;
    }

    function adjustedPotBalance() public view returns(uint256 _adjustedPotBalance) {
        uint256 devFee = uint256(SafeMaths.div(SafeMaths.mul(pot, devFeeRate), 100));
        return pot - devFee;
    }

    function contractBalance() public view returns(uint256 _contractBalance) {
        return address(this).balance;
    }

    function currentTime() public view returns(uint256 _time) {
        return now;
    }

    function currentWinner() public view returns(string _winner) {
        if (teamOneVolume > teamTwoVolume) {
            return teamOnePrefix;
        } else if (teamOneVolume < teamTwoVolume) {
            return teamTwoPrefix;
        } else if (teamOneVolume == teamTwoVolume) {
            return "a tie? wtf";
        }
    }


    //INTERNAL FUNCTIONS

    //time adjustments
    function timeAdjustPlus() internal {
        if (msg.value >= 1 finney) {
            uint256 timeFactor = 1000000000000000; //one finney in wei
            uint256 timeShares = uint256(SafeMaths.div(msg.value, timeFactor)); 

            if (timeShares + roundEndTime > now + timerMax) {
                roundEndTime = now + timerMax;
            } else {
                roundEndTime += timeShares; //add one second per finney  
            }
        }
    }

    function timeAdjustNeg() internal {
        if (msg.value >= 1 finney) {
            uint256 timeFactor = 1000000000000000; //one finney in wei
            uint256 timeShares = uint256(SafeMaths.div(msg.value, timeFactor));

            // prevents extreme edge case underflow if someone sends more than 1.5 million ETH
            require (timeShares < roundEndTime, "you sent an absurd amount! relax vitalik"); 

            if (roundEndTime - timeShares < now + 5 minutes) {
                roundEndTime = now + 5 minutes; //you can&#39;t win by buying up the clock, but you can come close
            } else {
                roundEndTime -= timeShares; //subtract one second per finney  
            }
        }
    }

    //divs 
    function distributeDivs(uint256 _divContribution, uint256 _teamID) internal {
        if (_teamID == 1) {
            teamOneDivsTotal += _divContribution;
            teamOneDivsUnclaimed += _divContribution;
        } else if (_teamID == 2) {
            teamTwoDivsTotal += _divContribution;
            teamTwoDivsUnclaimed += _divContribution;
        }
    }

    //round payouts
    function teamOneWin() internal {
        uint256 devShare = uint256(SafeMaths.div(SafeMaths.mul(pot, devFeeRate), 100)); 
        devBalance += devShare;
        uint256 potAdjusted = pot - devShare;

        teamOneDivsTotal += potAdjusted;
        teamOneDivsUnclaimed += potAdjusted;

        emit roundEnded(1, teamOnePrefix, potAdjusted, "team one won!");
    }

    function teamTwoWin() internal {
        uint256 devShare = uint256(SafeMaths.div(SafeMaths.mul(pot, devFeeRate), 100)); 
        devBalance += devShare;
        uint256 potAdjusted = pot - devShare;

        teamTwoDivsTotal += potAdjusted;
        teamTwoDivsUnclaimed += potAdjusted;

        emit roundEnded(2, teamTwoPrefix, potAdjusted, "team two won!");        
    }

    function tie() internal { //very unlikely this will happen, but just in case 
        uint256 devShare = uint256(SafeMaths.div(SafeMaths.mul(pot, devFeeRate), 100)); 
        devBalance += devShare;
        uint256 potAdjusted = pot - devShare;

        teamOneDivsTotal += SafeMaths.div(potAdjusted, 2);
        teamOneDivsUnclaimed += SafeMaths.div(potAdjusted, 2);
        teamTwoDivsTotal += SafeMaths.div(potAdjusted, 2);
        teamTwoDivsUnclaimed += SafeMaths.div(potAdjusted, 2);

        emit roundEnded(0, "Tied", potAdjusted, "a tie?! wtf");
    }


    //convert and address to bytes format
    function toBytes(address a) internal pure returns (bytes b) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
        return b;
    }
    
    //take the first byte of a bytes argument and return bytes1
    function toBytes1(bytes data) internal pure returns (bytes1) {
        uint val;
        for (uint i = 0; i < 1; i++)  {
            val *= 256;
            if (i < data.length)
                val |= uint8(data[i]);
        }
        return bytes1(val);
    }
    
    //combine the above function
    function addressToBytes1(address input) internal pure returns(bytes1) {
        bytes1 output = toBytes1(toBytes(input));
        return output;
    }

    //address checks
    function checkAddressTeamOne(address _input) internal view returns(bool) {
        if (addressToBytes1(_input) <= addressToBytes1(addressThreshold)) {
            return true;
        } else {
            return false;
        }
    }
    
    function checkAddressTeamTwo(address _input) internal view returns(bool) {
        if (addressToBytes1(_input) > addressToBytes1(addressThreshold)) {
            return true;
        } else {
            return false;
        }
    }

}  

//LIBRARIES

library SafeMaths {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}