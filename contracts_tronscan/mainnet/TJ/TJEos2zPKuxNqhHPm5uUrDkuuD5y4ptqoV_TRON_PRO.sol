//SourceUnit: TRON_PRO.sol



pragma solidity 0.5.10;

// Bonus Base ROI is based on invested amount. up to 10,000: 1.5 ROI, 10,000 - 50,000: 2 ROI, 50,000 - 100,000: 2.5 ROI, 100,000+: 3 ROI
// Bonus Personal 0.1 % daily without withdrow - Bonus Balance 0.1 % every 500.000 in Live Balance.
// Up to 5 level Referral Bonus Level-1 4% / Level-2 3% / Level-3 1% / Level-4 1% / Level-5 1%
// 200 % included initial deposit
// Maximum Bonus Rate 35 % daily / If Withdraw Bonus Balance set in Zero % forever
// 90 % Balance Deposit Fund / 7 % Marketing / 3 % Developers
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


contract TRON_PRO {
    using SafeMath for uint256;

    uint256 constant public INVEST_MIN_AMOUNT = 200 trx;

    uint256 constant public BASE1 = 10000;
    uint256 constant public BASE2 = 50000;
    uint256 constant public BASE3 = 100000;
    

    uint256[] public REFERRAL_PERCENTS = [40, 30, 10, 10, 10];
    uint256 constant public MARKETING_FEE = 70;
    uint256 constant public RESERVE_FEE = 10;
    uint256 constant public PROJECT_FEE = 20;
    uint256 constant public MAX_CONTRACT_PERCENT = 150; 
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public AMOUNT_DIVIDER = 1000000; 
    uint256 constant public CONTRACT_BALANCE_STEP = 500000 trx;
    uint256 constant public TIME_STEP = 1 days;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;
    uint256 public backBalance;

    address payable public marketingAddress;
    address payable public projectAddress;
    address payable public reserveAddress;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint24[5] refs;
        uint256 base_ROI;

    }

    mapping (address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address payable marketingAddr, address payable projectAddr, address payable reserveAddr) public {
        require(!isContract(marketingAddr) && !isContract(projectAddr) && !isContract(reserveAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        reserveAddress = reserveAddr;
    }

    function invest(address referrer) public payable {
        require(msg.value >= INVEST_MIN_AMOUNT);

        marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
        projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
        reserveAddress.transfer(msg.value.mul(RESERVE_FEE).div(PERCENTS_DIVIDER));
        emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE).add(RESERVE_FEE)).div(PERCENTS_DIVIDER));

        User storage user = users[msg.sender];

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = users[upline].bonus.add(amount);
                    emit RefBonus(upline, msg.sender, i, amount);
                    users[upline].refs[i]++;

                    upline = users[upline].referrer;
                } else break;
            }

        }
        user.deposits.push(Deposit(msg.value, 0, block.timestamp));
        
        uint256 BaseROI;
        uint256 totalDepAmount= getRealAmount(msg.sender);
        
        if(totalDepAmount<=BASE1){
            BaseROI =15;
        }
        else if(totalDepAmount>BASE1 && totalDepAmount<=BASE2){
            BaseROI =20;
        }
        else if(totalDepAmount>BASE2 && totalDepAmount<=BASE3){
            BaseROI =25;
        }
        else{
            BaseROI =30;
        }

        if (user.deposits.length == 1) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            user.base_ROI= BaseROI;
            emit Newbie(msg.sender);
        }
        else
        {
            user.base_ROI= BaseROI;
            emit Newbie(msg.sender);
        }
        
        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);
        backBalance = backBalance.add(msg.value.div(100).mul(90));

        emit NewDeposit(msg.sender, msg.value);

    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 userPercentRate = getUserPercentRate(msg.sender);

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                    dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
                }

                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            user.bonus = 0;
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;

        msg.sender.transfer(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);

    }
    function getRealAmount(address userAddress) public view returns(uint256) {
        uint256 totalDepAmount= getUserTotalDeposits(userAddress);

        uint256 amount; 
        amount = totalDepAmount.div(AMOUNT_DIVIDER);
        return amount;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractBalanceRate() public view returns (uint256) {
        uint256 contractBalance = backBalance;
        uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
        if (contractBalancePercent < (MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return (MAX_CONTRACT_PERCENT);
        }

        return contractBalancePercent;
    }
    function getUserBaseRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 UserBase_ROI= user.base_ROI;
        return UserBase_ROI;

    }
    function getUserPercentRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 UserBase_ROI= user.base_ROI;
        uint256 contractBalanceRate = getContractBalanceRate();
        contractBalanceRate = contractBalanceRate.add(UserBase_ROI);
        if (getUserTotalWithdrawn(userAddress) > 0){ // if User Whithdrawn Shometing, set 0 balance bonus + basic
            contractBalanceRate = UserBase_ROI;
        }

        if (isActive(userAddress)) {
            uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP).mul(1);

            if(contractBalanceRate.add(timeMultiplier) >= 350){ // if % is more than 35% , set 35%
                return 350;
            }else{
                return contractBalanceRate.add(timeMultiplier) ;
            }

        } else {
            if(contractBalanceRate >= 350){ // if % is more than 35% , set 35%
                return 350;
            } else{
                return contractBalanceRate;
            }

        }
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                    dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function

            }

        }

        return totalDividends;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].bonus;
    }

    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
                return true;
            }
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }
    function getSiteStats() public view returns (uint, uint, uint, uint) {
        return (totalInvested, totalDeposits, address(this).balance,
        getContractBalanceRate());
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint256, uint24[5] memory) {
        User storage user = users[userAddress];

        return (user.referrer, user.bonus, user.refs);
    }


    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}