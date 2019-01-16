pragma solidity ^0.4.25;

contract eth5io {
    address public owner;
    address public admin;
    uint constant public TEST_DRIVE_INVEST = 5 finney;
    uint constant public MINIMUM_INVEST = 50 finney;
    uint constant public MINIMUM_VIP_INVEST = 5 ether;
    uint constant public MINIMUM_SVIP_INVEST = 25 ether;
    uint constant public OWNER_FEE_DENOMINATOR = 100;
    uint constant public FUND_FEE_DENOMINATOR = 100;
    uint constant public INTEREST = 5;
    uint constant public FUND_DAILY_USER = 500;
    uint public multiplier = 1;
    uint public dailyDepositLimit = 555 ether;
    uint public fund;
    uint  public funduser;
    
    uint public round = 0;
    address[] public addresses;
    mapping(address => Investor) public investors;
    bool public pause = true;
    uint constant period = 60 * 60 * 24;
    
    
    uint dailyDeposit;
    uint roundStartDate;
    uint daysFromRoundStart;
    uint deposit;
    enum Status { TEST, BASIC, VIP, SVIP }

    struct Investor {
        uint id;
        uint round;
        uint deposit;
        uint deposits;
        uint investDate;
        uint lastPaymentDate;
        address referrer;
        Status status;
        bool refPayed;
    }

    event TestDrive(address addr, uint date);
    event Invest(address addr, uint amount, address referrer);
    event WelcomeVIP(address addr);
    event WelcomeSuperVIP(address addr);
    event Payout(address addr, uint amount, string eventType, address from);
    event NextRoundStarted(uint round, uint date);

    modifier onlyOwner {
        require(msg.sender == owner, "Sender not authorised.");
        _;
    }

    constructor() public {

        owner = msg.sender;
        admin = msg.sender;
        
        nextRound();
    }

    function() payable public {

        if((msg.sender == owner) || (msg.sender == admin)) {
            return;
        }

        require(pause == false, "5eth.io is paused. Please wait for the next round.");

        if (0 == msg.value) {
            payout();
            return;
        }

        require(msg.value >= MINIMUM_INVEST || msg.value == TEST_DRIVE_INVEST, "Too small amount, minimum 0.005 ether");
        
        if (daysFromRoundStart < daysFrom(roundStartDate)) {
            dailyDeposit = 0;
            funduser = 0;
            daysFromRoundStart = daysFrom(roundStartDate);
        }
        
        require(msg.value + dailyDeposit <= dailyDepositLimit, "Daily deposit limit reached! See you soon");
        dailyDeposit += msg.value;
        
        Investor storage user = investors[msg.sender];

        if ((user.id == 0) || (user.round < round)) {
            
            msg.sender.transfer(0 wei); 

            addresses.push(msg.sender);
            user.id = addresses.length;
            user.deposit = 0;
            user.deposits = 0;
            user.lastPaymentDate = now;
            user.investDate = now;
            user.round = round;

            // referrer
            address referrer = bytesToAddress(msg.data);
            if (investors[referrer].id > 0 && referrer != msg.sender
               && investors[referrer].round == round) {
                user.referrer = referrer;
            }
        }

        // save investor
        user.deposit += msg.value;
        user.deposits += 1;
        deposit += msg.value;
        emit Invest(msg.sender, msg.value, user.referrer);

        // sequential deposit cash-back on 20+ day
        if ((user.deposits > 1) && (user.status != Status.TEST) && (daysFrom(user.investDate) > 20)) {
            uint mul = daysFrom(user.investDate) > 40 ? 4 : 2;
            uint cashBack = (msg.value / 100) *INTEREST* mul;
            if (msg.sender.send(cashBack)) {
                emit Payout(user.referrer, cashBack, "seq-deposit-cash-back", msg.sender);
            }
        }
        
        Status newStatus;
        if (msg.value >= MINIMUM_SVIP_INVEST) {
            emit WelcomeSuperVIP(msg.sender);
            newStatus = Status.SVIP;
        } else if (msg.value >= MINIMUM_VIP_INVEST) {
            emit WelcomeVIP(msg.sender);
            newStatus = Status.VIP;
        } else if (msg.value >= MINIMUM_INVEST) {
            newStatus = Status.BASIC;
        } else if (msg.value == TEST_DRIVE_INVEST) {
            if (user.deposits == 1){
                funduser += 1;
                require(FUND_DAILY_USER>funduser,"Fund full, See you soon!");
                emit TestDrive(msg.sender, now);
                fund += msg.value;
                if(sendFromFund(TEST_DRIVE_INVEST, msg.sender)){
                    
                    emit Payout(msg.sender,TEST_DRIVE_INVEST,"test-drive-cashback",0);
                }
            }
            newStatus = Status.TEST;
        }
        if (newStatus > user.status) {
            user.status = newStatus;
        }
        // proccess fees and referrers
        if(newStatus!=Status.TEST){
            admin.transfer(msg.value / OWNER_FEE_DENOMINATOR * 4); // administration fee
            owner.transfer(msg.value / OWNER_FEE_DENOMINATOR * 10); // owners fee
            fund += msg.value / FUND_FEE_DENOMINATOR;          // test-drive fund
        }
        user.lastPaymentDate = now;
    }

    function payout() private {
        
        Investor storage user = investors[msg.sender];

        require(user.id > 0, "Investor not found.");
        require(user.round == round, "Your round is over.");

        require(daysFrom(user.lastPaymentDate) >= 1, "Wait at least 24 hours.");
        
        uint amount = getInvestorDividendsAmount(msg.sender);
        if (address(this).balance < amount) {
            pause = true;
            return;
        }
        
        if ((user.referrer > 0x0) && !user.refPayed && (user.status != Status.TEST)) {
            user.refPayed = true;
            Investor storage ref = investors[user.referrer];
            if (ref.id > 0 && ref.round == round) {
                uint bonusAmount = (user.deposit / 100) * INTEREST;
                uint refBonusAmount = bonusAmount * uint(ref.status);
            
                if (user.referrer.send(refBonusAmount)) {
                    emit Payout(user.referrer, refBonusAmount, "referral", msg.sender);
                }
            
                if (user.deposits == 1) { // cashback only for the first deposit
                    if (msg.sender.send(bonusAmount)) {
                        emit Payout(msg.sender, bonusAmount, "ref-cash-back", 0);
                    }
                }
            }
        }
        
        if (user.status == Status.TEST) {
            uint daysFromInvest = daysFrom(user.investDate);
            require(daysFromInvest <= 20, "Your test drive is over!");

            if (sendFromFund(amount, msg.sender)) {
                emit Payout(msg.sender, TEST_DRIVE_INVEST, "test-drive-self-payout", 0);
            }
        } else {
            msg.sender.transfer(amount);
            emit Payout(msg.sender, amount, "self-payout", 0);
        }
        user.lastPaymentDate = now;
    }

    function sendFromFund(uint amount, address user) private returns (bool) {

        require(fund > amount, "Test-drive fund empty! See you later.");
        if (user.send(amount)) {
            fund -= amount;
            return true;
        }
        return false;
    }

    // views
    
    function getInvestorCount() public view returns (uint) {

        return addresses.length - 1;
    }

    function getInvestorDividendsAmount(address addr) public view returns (uint) {

        return investors[addr].deposit / 100 * INTEREST 
                * daysFrom(investors[addr].lastPaymentDate) * multiplier;
    }

    // configuration
    
    function setMultiplier(uint newMultiplier) onlyOwner public {

        multiplier = newMultiplier;
    }

    function setDailyDepositLimit(uint newDailyDepositLimit) onlyOwner public {

        dailyDepositLimit = newDailyDepositLimit;
    }

    function setAdminAddress(address newAdmin) onlyOwner public {

        admin = newAdmin;
    }

    function addInvestors(address[] addr, uint[] amount, bool[] isSuper) onlyOwner public {

        // create VIP/SVIP refs
        for (uint i = 0; i < addr.length; i++) {
            uint id = addresses.length;
            if (investors[addr[i]].deposit == 0) {
                addresses.push(addr[i]);
                deposit += amount[i];
            }
            
            Status s = isSuper[i] ? Status.SVIP : Status.VIP;
            investors[addr[i]] = Investor(id, round, amount[i], 1, now, now, 0, s, false);

        }
    }

    function nextRound() onlyOwner public {
            if(pause==true){
                delete addresses;
                addresses.length = 1;
                deposit = 0;
                fund = 0;
        
                dailyDeposit = 0;
                roundStartDate = now;
                daysFromRoundStart = 0;

                owner.transfer(address(this).balance);

                emit NextRoundStarted(round, now);
                pause = false;
                round += 1;
            }
        
    }

    // util
    
    function daysFrom(uint date) private view returns (uint) {
        return (now - date) / period;
    }

    function bytesToAddress(bytes bys) private pure returns (address addr) {

        assembly {
            addr := mload(add(bys, 20))
        }
    }
}