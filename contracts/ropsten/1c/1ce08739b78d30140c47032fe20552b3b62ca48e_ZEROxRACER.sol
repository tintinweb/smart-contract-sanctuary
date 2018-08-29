// 0xRACER is a brand new team-based pot lottery game. 
// Users are grouped into teams based on the first byte of their address.
// Team One: 0x0..., 0x1..., 0x2..., 0x3..., 0x4..., 0x5..., 0x6..., 0x7...
// Team Two: 0x8..., 0x9..., 0xa..., 0xb..., 0xc..., 0xd..., 0xe..., 0x0...

// DISCLAIMER: This is an experimental game in distributed psychology and distributed technology.
// DISCLAIMER: You can, and likely will, lose any ETH you send to this contract. Don&#39;t send more than you can afford to lose.

// RULES:

// 1. The team with the highest buy volume when the clock expires wins the pot.
// 2. The pot is divided among the winning team members, proportional to their share of team volume. 
// 3. Every new buy adds time to the clock at the rate of 1 second/finney. The timer is capped at 24h.
// 4. You can also reduce the clock at the rate of 1 second/finney, but this does not count towards your share. The timer can&#39;t go below 2 minutes with this method.
// 5. Refferals and dividends are distributed by team. 20% of each new buy is proportionally split between that team&#39;s members.
// 6. New seeded rounds with new teams will begin on a semi-regular basis. Each game will use a new contract.
// 7. In the extremely unlikely event of a tie, the pot is distrubted proportionally as shares of total volume.
// 8. The minimum buy is 1 finney. No maximum.
// 9. No contracts allowed.
// 10. Users can withdraw earned dividends from referrals or pot wins at any time. Shares cannot be sold.

// STRATEGY:

// A. This game is designed to support multiple modes of play.
// B. Get in early and shill your team to collect divs.
// C. Manage risk by playing both sides of the fence.
// D. Flex your whale wallet by front running and reducing the timer.
// E. Piggy back on big players by making sure you&#39;re on the same team.
// F. Gain a larger share of divs by supporting the underdog.

// https://zeroxracer.surge.sh/ ropsten testing 
// by nightman


pragma solidity ^0.4.24;

contract ZEROxRACER {

    //VARIABLES AND CONSTANTS

    //global 
    address public owner;
    uint256 public devFeeRate = 3; //3% of pot, not volume 
    uint256 public devBalance;
    uint256 public precisionFactor = 6; //shares precise to 0.0001%

    //team 
    string public teamOnePrefix = &#39;Team One&#39;;
    uint256 public teamOneId = 1; 
    string public teamTwoPrefix = &#39;Team Two&#39;;
    uint256 public teamTwoId = 2;
    address public addThreshold = 0x7F00000000000000000000000000000000000000; //addresses that start with 0x00-0x7f on Team One; 0x80-0xff on Team Two

    //user 
    address[] public teamOneMembers;
    mapping (address => bool) public isTeamOneMember;
    mapping (address => uint256) public teamOneStake;
    mapping (address => uint256) private userDivsTeamOneTotal;
    mapping (address => uint256) private userDivsTeamOneClaimed;
    mapping (address => uint256) private userDivsTeamOneUnclaimed;
    mapping (address => uint256) private userDivRateTeamOne;
    
    address[] public teamTwoMembers;
    mapping (address => bool) public isTeamTwoMember;
    mapping (address => uint256) public teamTwoStake;
    mapping (address => uint256) private userDivsTeamTwoTotal;
    mapping (address => uint256) private userDivsTeamTwoClaimed;
    mapping (address => uint256) private userDivsTeamTwoUnclaimed;
    mapping (address => uint256) private userDivRateTeamTwo;

    //round 
    uint256 public divRate = 20; //20% dividends for each buy, distributed proportionally to team volume
    uint256 public pot;
    uint256 public teamOneVolume;
    uint256 public teamOneDivsTotal;
    uint256 public teamOneDivsUnclaimed;
    uint256 public teamTwoVolume;
    uint256 public teamTwoDivsTotal;
    uint256 public teamTwoDivsUnclaimed;
    bool public currentRoundOpen = false;
    bool public roundSetUp = false;
    bool public roundResolved = false;
    uint256 public timerStart;
    uint256 public timerMax;
    uint256 public roundStartTime;
    uint256 public roundEndTime;
    

    //CONSTRUCTOR

    constructor() public {
        owner = msg.sender;
    }
    

    //MODIFIERS

    modifier onlyOwner() { 
        require (msg.sender == owner, &#39;you are not the owner&#39;); 
        _; 
    }

    modifier gameOpen() {
        require (currentRoundOpen == true, &#39;the game is not open&#39;);
        require (roundResolved == false);
        require (now < roundEndTime);
        _; 
    }

    modifier onlyHumans() { 
        require (msg.sender == tx.origin, &#39;you cannot use a contract&#39;); 
        _; 
    }
    

    //EVENTS

    event potFunded(
        address _funder, 
        uint256 _amount
    );
    
    event teamBuy(
        address _buyer, 
        uint256 _amount, 
        uint256 _teamID
    );
    
    event roundEnded(
        uint256 _winningTeamId, 
        string _winningTeamString, 
        uint256 _pot
    );
    
    event newRoundStarted(
        uint256 _timeStart, 
        uint256 _timeMax,
        uint256 _seed
    );


    //DEV FUNCTIONS

    //start round
    function openRound (uint _timerStart, uint _timerMax) public payable onlyOwner() {
        require (currentRoundOpen == false, &#39;you can only start the game once&#39;);
        require (roundResolved == false, &#39;you cannot restart a finished game&#39;); //currently set up so this can only be called once. new games require a new contract 
        require (msg.value > 0, &#39;you must give a seed&#39;);

        roundSetUp = true;
        currentRoundOpen = true;
        timerStart = _timerStart;
        timerMax = _timerMax;
        roundStartTime = now;
        roundEndTime = now + timerStart;
        pot += msg.value;

        emit newRoundStarted(timerStart, timerMax, msg.value);
    }

    //dev withdraw
    function devWithdraw() public onlyOwner() {
        require (devBalance > 0, &#39;you must have an available balance&#39;);
        require(devBalance <= address(this).balance, &#39;you cannot print money&#39;);
        owner.transfer(devBalance);
        devBalance = 0;
    }

    //PUBLIC FUNCTIONS

    function buy() public payable gameOpen() onlyHumans() { 
        require (msg.value >= 1 finney, &#39;you must send at least 0.001 ETH&#39;);
        uint256 _teamID;
        
        //establish team affliation 
        if (checkAddressTeamOne(msg.sender) == true) {
            _teamID = 1;
        } else if (checkAddressTeamTwo(msg.sender) == true) {
            _teamID = 2;
        }

        //adjust pot and div balances
        if (_teamID == 1 && teamOneMembers.length == 0 || _teamID == 2 && teamTwoMembers.length == 0) { //do not distribute divs on first buy from either team. prevents blackholed ether
            pot += msg.value;
        } else {
            uint256 divContribution = uint256(SafeMaths.div(SafeMaths.mul(msg.value, divRate), 100)); //divFees
            uint256 potContribution = msg.value - divContribution;
            pot += potContribution; 
            distributeDivs(divContribution, _teamID); 
        }

        //adjust time 
        timeAdjustPlus();

        //update team and player accounting 
        if (_teamID == 1) {
            if (isTeamOneMember[msg.sender] == false) {
                isTeamOneMember[msg.sender] = true;
                teamOneMembers.push(msg.sender);
            }
            teamOneStake[msg.sender] += msg.value;
            teamOneVolume += msg.value;
        } else if (_teamID == 2) {
            if (isTeamTwoMember[msg.sender] == false) {
                isTeamTwoMember[msg.sender] = true;
                teamTwoMembers.push(msg.sender);
            }
            teamTwoStake[msg.sender] += msg.value;
            teamTwoVolume += msg.value;
        }
    
        emit teamBuy(msg.sender, msg.value, _teamID);
    }  

    function resolveRound() public onlyHumans() { //can be called by anyone if the round has ended 
        require (now > roundEndTime, &#39;you can only call this if time has expired&#39;);
        require (roundSetUp == true, &#39;you cannot call this before the game starts&#39;);
        require (roundResolved == false, &#39;you can only call this once&#39;);

        if (teamOneVolume > teamTwoVolume) {
            teamOneWin();
        } else if (teamOneVolume < teamTwoVolume) {
            teamTwoWin();
        } else if (teamOneVolume == teamTwoVolume) {
            tie();
        }

        roundResolved = true; 
        currentRoundOpen = false;
    }

    function userWithdraw() public onlyHumans() {

        //user divs calculated on withdraw to prevent runaway gas costs associated with looping balance updates in distributeDivs

        if (teamOneStake[msg.sender] > 0) {
            userDivRateTeamOne[msg.sender] = SafeMaths.div(SafeMaths.div(SafeMaths.mul(teamOneStake[msg.sender], 10 ** (precisionFactor + 1)), teamOneVolume) + 5, 10);
            userDivsTeamOneTotal[msg.sender] = uint256(SafeMaths.div(SafeMaths.mul(teamOneDivsTotal, userDivRateTeamOne[msg.sender]), 10 ** precisionFactor));
            userDivsTeamOneUnclaimed[msg.sender] = SafeMaths.sub(userDivsTeamOneTotal[msg.sender], userDivsTeamOneClaimed[msg.sender]);
                if (userDivsTeamOneUnclaimed[msg.sender] > 0) {
                    assert(userDivsTeamOneUnclaimed[msg.sender] <= address(this).balance && userDivsTeamOneUnclaimed[msg.sender] <= teamOneDivsUnclaimed);
                    msg.sender.transfer(userDivsTeamOneUnclaimed[msg.sender]);
                    userDivsTeamOneClaimed[msg.sender] = userDivsTeamOneTotal[msg.sender];
                    teamOneDivsUnclaimed -= userDivsTeamOneUnclaimed[msg.sender];
                    userDivsTeamOneUnclaimed[msg.sender] = 0;
                }   
        } else if (teamTwoStake[msg.sender] > 0) {
        userDivRateTeamTwo[msg.sender] = SafeMaths.div(SafeMaths.div(SafeMaths.mul(teamTwoStake[msg.sender], 10 ** (precisionFactor + 1)), teamTwoVolume) + 5, 10);
        userDivsTeamTwoTotal[msg.sender] = uint256(SafeMaths.div(SafeMaths.mul(teamTwoDivsTotal, userDivRateTeamTwo[msg.sender]), 10 ** precisionFactor));
        userDivsTeamTwoUnclaimed[msg.sender] = SafeMaths.sub(userDivsTeamTwoTotal[msg.sender], userDivsTeamTwoClaimed[msg.sender]);
            if (userDivsTeamTwoUnclaimed[msg.sender] > 0) {
                assert(userDivsTeamTwoUnclaimed[msg.sender] <= address(this).balance && userDivsTeamTwoUnclaimed[msg.sender] <= teamTwoDivsUnclaimed);
                msg.sender.transfer(userDivsTeamTwoUnclaimed[msg.sender]);
                userDivsTeamTwoClaimed[msg.sender] = userDivsTeamTwoTotal[msg.sender];
                teamTwoDivsUnclaimed -= userDivsTeamTwoUnclaimed[msg.sender];
                userDivsTeamTwoUnclaimed[msg.sender] = 0;
            }
        }
    }

    function fundPot() public payable onlyHumans() gameOpen() {
        pot += msg.value;
        emit potFunded(msg.sender, msg.value);
    }

    function reduceTime() public payable onlyHumans() gameOpen(){
        timeAdjustNeg();
        pot += msg.value;
        emit potFunded(msg.sender, msg.value);
    }


    //VIEW FUNCTIONS

    function calcUserDivsTotal(address _user) public view returns(uint256 _divs) {

        //calculated locally to avoid unnessisary state change

        if (teamOneStake[_user] > 0) {
            uint256 userDivRateTeamOneView = SafeMaths.div(SafeMaths.div(SafeMaths.mul(teamOneStake[_user], 10 ** (precisionFactor + 1)), teamOneVolume) + 5, 10);
            uint256 userDivsTeamOneTotalView = uint256(SafeMaths.div(SafeMaths.mul(teamOneDivsTotal, userDivRateTeamOneView), 10 ** precisionFactor));
        } else if (teamTwoStake[_user] > 0) {
            uint256 userDivRateTeamTwoView = SafeMaths.div(SafeMaths.div(SafeMaths.mul(teamTwoStake[_user], 10 ** (precisionFactor + 1)), teamTwoVolume) + 5, 10);
            uint256 userDivsTeamTwoTotalView = uint256(SafeMaths.div(SafeMaths.mul(teamTwoDivsTotal, userDivRateTeamTwoView), 10 ** precisionFactor));
        }

        uint256 userDivsTotal = userDivsTeamOneTotalView + userDivsTeamTwoTotalView;
        return userDivsTotal;
    }

    function calcUserDivsAvailable(address _user) public view returns(uint256 _divs) {

        //calculated locally to avoid unnessisary state change
        
        if (teamOneStake[_user] > 0) {
            uint256 userDivRateTeamOneView = SafeMaths.div(SafeMaths.div(SafeMaths.mul(teamOneStake[_user], 10 ** (precisionFactor + 1)), teamOneVolume) + 5, 10);
            uint256 userDivsTeamOneTotalView = uint256(SafeMaths.div(SafeMaths.mul(teamOneDivsTotal, userDivRateTeamOneView), 10 ** precisionFactor));
            uint256 userDivsTeamOneUnclaimedView = SafeMaths.sub(userDivsTeamOneTotalView, userDivsTeamOneClaimed[_user]);
        } else if (teamTwoStake[_user] > 0) {
            uint256 userDivRateTeamTwoView = SafeMaths.div(SafeMaths.div(SafeMaths.mul(teamTwoStake[_user], 10 ** (precisionFactor + 1)), teamTwoVolume) + 5, 10);
            uint256 userDivsTeamTwoTotalView = uint256(SafeMaths.div(SafeMaths.mul(teamTwoDivsTotal, userDivRateTeamTwoView), 10 ** precisionFactor));
            uint256 userDivsTeamTwoUnclaimedView = SafeMaths.sub(userDivsTeamTwoTotalView, userDivsTeamTwoClaimed[_user]);
        }

        uint256 userDivsUnclaimed = userDivsTeamOneUnclaimedView + userDivsTeamTwoUnclaimedView;
        return userDivsUnclaimed;
    }

    function currentRoundInfo() public view gameOpen() returns(uint256 _pot, uint256 _teamOneVolume, uint256 _teamTwoVolume, uint256 _timerStart, uint256 _timerMax, uint256 _roundStartTime, uint256 _roundEndTime) {
        return (pot, teamOneVolume, teamTwoVolume, timerStart, timerMax, roundStartTime, roundEndTime);
    }

    function getTimeLeft() public view returns(uint256 _timeLeftSeconds) {
        if (now > roundEndTime) {
            return 0;
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

    function currentWinner() public view returns(string _winner) {
        if (teamOneVolume > teamTwoVolume) {
            return teamOnePrefix;
        } else if (teamOneVolume < teamTwoVolume) {
            return teamTwoPrefix;
        } else if (teamOneVolume == teamTwoVolume) {
            return &#39;a tie? wtf&#39;;
        }
    }


    //INTERNAL FUNCTIONS

    //time
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
            if (roundEndTime - timeShares < now + 2 minutes) {
                roundEndTime = now + 2 minutes; //you can&#39;t win by buying up the clock, but you can come close
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

        emit roundEnded(1, teamOnePrefix, potAdjusted);

        teamOneDivsTotal += potAdjusted;
        teamOneDivsUnclaimed += potAdjusted;
   
    }

    function teamTwoWin() internal {

        uint256 devShare = uint256(SafeMaths.div(SafeMaths.mul(pot, devFeeRate), 100)); 
        devBalance += devShare;
        uint256 potAdjusted = pot - devShare;

        emit roundEnded(2, teamTwoPrefix, potAdjusted);

        teamTwoDivsTotal += potAdjusted;
        teamTwoDivsUnclaimed += potAdjusted;

    }

    function tie() internal { //very unlikely this will happen, but just in case 

        uint256 devShare = uint256(SafeMaths.div(SafeMaths.mul(pot, devFeeRate), 100)); 
        devBalance += devShare;
        uint256 potAdjusted = pot - devShare;

        emit roundEnded(0, &#39;a tie? wtf!&#39;, potAdjusted);

        teamOneDivsTotal += SafeMaths.div(potAdjusted, 2);
        teamOneDivsUnclaimed += SafeMaths.div(potAdjusted, 2);
        teamTwoDivsTotal += SafeMaths.div(potAdjusted, 2);
        teamTwoDivsUnclaimed += SafeMaths.div(potAdjusted, 2);

    }


    //address check functions
    function toBytes(address a) internal pure returns (bytes b) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
        return b;
    }
    
    function toBytes1(bytes data) internal pure returns (bytes1) {
        uint val;
        for (uint i = 0; i < 0 + 1; i++)  {
            val *= 256;
            if (i < data.length)
                val |= uint8(data[i]);
        }
        return bytes1(val);
    }
    
    function addressToBytes1(address input) internal pure returns(bytes1) {
        bytes1 output = toBytes1(toBytes(input));
        return output;
    }

    //address checks
    function checkAddressTeamOne(address _input) internal view returns(bool) {
        if (addressToBytes1(_input) <= addressToBytes1(addThreshold)) {
            return true;
        } else {
            return false;
        }
    }
    
    function checkAddressTeamTwo(address _input) internal view returns(bool) {
        if (addressToBytes1(_input) > addressToBytes1(addThreshold)) {
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

//an alternate version of this game grouped teams based on vanity addresses. the comments and code are included here for posterity

// 0xRACER is a brand new team-based pot lottery game. 
// In order to play, you must have a vanity address that starts with the same prefix as your team. 
// For example: 0xBEEF vs. 0xBABE.

// VANITY ADDRESSES:

// In order to generate a vanity address with the prefix you&#39;re looking for, you need to "mine" millions of private keys.
// This provides an asynchronous start time, preventing "sniping" commonly seen in similar games. 
// It also provides a level of commitment and irrational tribal loyalty that makes the game more fun (team 0xBABE for life).
// One user-friendly tool for generating vanity addresses is https://vanity-eth.tk/ (not affiliated with this project). 
// A four character prefix can take anywhere from 2-15 minutes on a standard machine. 
// When you find your target address, save it as an encrypted JSON file.
// Keep this file. This is your private key. 
// Import the JSON file into MetaMask. You can now use this account as you would any other.
// If you don&#39;t trust this tool, feel free to generate an address with any alternative method you choose.

/*

//internal functions for prefix check
    function toBytes(address a) internal pure returns (bytes b) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
        return b;
    }
    
    function toBytes2(bytes data) internal pure returns (bytes2) {
        uint val;
        for (uint i = 0; i < 0 + 2; i++)  {
            val *= 256;
            if (i < data.length)
                val |= uint8(data[i]);
        }
        return bytes2(val);
    }
    
    function addressToBytes2(address input) internal pure returns(bytes2) {
        bytes2 output = toBytes2(toBytes(input));
        return output;
    }

    //address checks
    function checkAddressTeamOne(address _input) internal view returns(bool) {
        bytes2 a = addressToBytes2(teamOneRefAddress);
        bytes2 b = addressToBytes2(_input);
        if (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b))) {
            return true; //returns true if prefix matches first 2 bytes of teamOnePrefix
        } else {
            return false;
        }
    }

    function checkAddressTeamTwo(address _input) internal view returns(bool) {
        bytes2 a = addressToBytes2(teamTwoRefAddress);
        bytes2 b = addressToBytes2(_input);
        if (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b))) {
            return true; //returns true if prefix matches first 2 bytes of teamTwoPrefix
        } else {
            return false;
        }
    }
*/