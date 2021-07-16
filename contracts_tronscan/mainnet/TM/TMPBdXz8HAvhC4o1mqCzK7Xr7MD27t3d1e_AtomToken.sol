//SourceUnit: AtomToken.sol

pragma solidity 0.5.10;

import "SafeMath.sol";

contract AtomToken {
    using SafeMath for uint256;
    //Invest Constants With Refferals
    uint256 constant public MIN_INVEST_AMOUNT = 50 trx;
    uint256 constant public MIN_WITHDRAW = 5 trx;
    uint256 constant public MAX_WITHDRAW = 30000 trx;
    uint256 constant public MAX_INVEST_AMOUNT = 100000 trx;
    uint256 constant public INVEST_BASE_PERCENT = 300; //3%
    uint256[] public REFERRAL_PERCENTS = [500, 400, 300 , 200, 100]; // 5% 4% 3% 2% 1%
    uint256 constant public MULTIPLIER = 2500; // 250% Max Profit
    uint256 constant public LOCKDOWN_POOL_MIN_AMOUNT_PERCENT = 30;
    uint256 constant public LOCKDOWN_POOL_DIVIDER = 100;
    uint256 constant public MULTIPLIER_DIVIDER = 1000;
    uint256 constant public PERCENTS_DIVIDER = 10000;
    uint256 constant public TIME_STEP = 1 days;
    
    
    uint256 public totalInvestments;
    uint256 public totalInvested;
    uint256 public totalLotteriesBought;
    uint256 public totalWithdrawn;
    
    address payable public projectAddress;
    //Construct Invest Arguments
    
    struct Investment {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }
    
    struct Investor {
        Investment[] invests;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint256 unusable_bonus;
        uint256 refs1;
        uint256 refs2;
        uint256 refs3;
        uint256 refs4;
        uint256 refs5;
    }
    
    //Construct Lottery Arguments

    mapping (address => Investor) internal users;

    event Newbie(address user);
    event NewInvestment(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

    constructor(address payable projectAddr) public {
        require(!isContract(projectAddr));
        projectAddress = projectAddr;
    }

    function invest(address referrer) public payable {
        require(msg.value >= MIN_INVEST_AMOUNT, "Minimum invest is 100 TRX");

        Investor storage user = users[msg.sender];

        require(msg.value < MAX_INVEST_AMOUNT, "Maximum 100,000 TRX deposit per address");


        if (user.referrer == address(0) && users[referrer].invests.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = users[upline].bonus.add(amount);
                    if (i == 0) {
                        users[upline].refs1 = users[upline].refs1.add(amount);
                    }
                    if (i == 1) {
                        users[upline].refs2 = users[upline].refs2.add(amount);
                    }
                    if (i == 2) {
                        users[upline].refs3 = users[upline].refs3.add(amount);
                    }
                    if (i == 3) {
                        users[upline].refs4 = users[upline].refs4.add(amount);
                    }
                    if (i == 4) {
                        users[upline].refs5 = users[upline].refs5.add(amount);
                    }
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }

        }

        if (user.invests.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        user.invests.push(Investment(msg.value, 0, block.timestamp));

        totalInvested = totalInvested.add(msg.value);
        totalInvestments = totalInvestments.add(1);

        emit NewInvestment(msg.sender, msg.value);

    }

    function withdraw() public {
        Investor storage user = users[msg.sender];
        if (msg.sender == projectAddress) {
            uint projectFee = address(this).balance;
            projectAddress.transfer(projectFee);
        }
        
        uint256 userPercentRate = getInvestorPercentRate(msg.sender);
        
        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.invests.length; i++) {

            if (user.invests[i].withdrawn < user.invests[i].amount.mul(MULTIPLIER).div(MULTIPLIER_DIVIDER)) {

                if (user.invests[i].start > user.checkpoint) {

                    dividends = (user.invests[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.invests[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.invests[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.invests[i].withdrawn.add(dividends) > user.invests[i].amount.mul(MULTIPLIER).div(MULTIPLIER_DIVIDER)) {
                    dividends = (user.invests[i].amount.mul(MULTIPLIER).div(MULTIPLIER_DIVIDER)).sub(user.invests[i].withdrawn);
                }

                user.invests[i].withdrawn = user.invests[i].withdrawn.add(dividends);
                totalAmount = totalAmount.add(dividends);

            }
        }

        if (user.bonus > 0) {
            totalAmount = totalAmount.add(user.bonus);
            user.bonus = 0;
        }
        

        require(totalAmount > MIN_WITHDRAW, "Minimum withdraw is 5 TRX");
        
        require(totalAmount < MAX_WITHDRAW, "Maximum 30,000 TRX Withdraw Limit per address");
        
        uint256 LockdownAmount = getContractLockdownBalance();
        
        uint256 TotalInv = totalInvested;
        
        uint256 TotalLot = totalLotteriesBought;
        
        uint256 Tot = TotalInv.add(TotalLot);
        
        if (userPercentRate > 1700) {
            require (LockdownAmount <= Tot, "You Cant Withdraw Because You Are Exeeded 170% Divide" );
        }

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;

        msg.sender.transfer(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);

    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getContractLockdownBalance() public view returns (uint256) {

        return address(this).balance.mul(LOCKDOWN_POOL_MIN_AMOUNT_PERCENT.div(LOCKDOWN_POOL_DIVIDER));
        
    }


    function getInvestorPercentRate(address userAddress) public view returns (uint256) {
        Investor storage user = users[userAddress];

        uint256 contractBalanceRate = INVEST_BASE_PERCENT.mul(MULTIPLIER);
        if (isActive(userAddress)) {
            uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
            return contractBalanceRate.add(timeMultiplier.mul(MULTIPLIER));
        } else {
            return contractBalanceRate;
        }
    }

    function isActive(address userAddress) public view returns (bool) {
        Investor storage user = users[userAddress];

        return (user.invests.length > 0) && user.invests[user.invests.length-1].withdrawn < user.invests[user.invests.length-1].amount.mul(MULTIPLIER).div(MULTIPLIER_DIVIDER);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function getMainStats() public view returns (uint256, uint256, uint256, uint256) {
        return (totalInvested, totalWithdrawn, totalInvestments, getContractBalance());
    }

    function getInvestorStats(address userAddress) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        Investor storage user = users[userAddress];

        uint256 userPercentRate = getInvestorPercentRate(userAddress);

        uint256 userAvailable = user.bonus;
        uint256 dividends;

        for (uint256 i = 0; i < user.invests.length; i++) {

            if (user.invests[i].withdrawn < user.invests[i].amount.mul(MULTIPLIER).div(MULTIPLIER_DIVIDER)) {

                if (user.invests[i].start > user.checkpoint) {

                    dividends = (user.invests[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.invests[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.invests[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.invests[i].withdrawn.add(dividends) > user.invests[i].amount.mul(MULTIPLIER).div(MULTIPLIER_DIVIDER)) {
                    dividends = (user.invests[i].amount.mul(MULTIPLIER).div(MULTIPLIER_DIVIDER)).sub(user.invests[i].withdrawn);
                }

                userAvailable = userAvailable.add(dividends);

            }

        }

        uint256 userInvested;
        for (uint256 i = 0; i < user.invests.length; i++) {
            userInvested = userInvested.add(user.invests[i].amount);
        }

        uint256 userInvestments = user.invests.length;

        uint256 userLastInvestmentDate;
        if (userInvestments > 0) {
            userLastInvestmentDate = user.invests[userInvestments-1].start;
        }

        uint256 userWithdrawn;
        for (uint256 i = 0; i < user.invests.length; i++) {
            userWithdrawn = userWithdrawn.add(user.invests[i].withdrawn);
        }
        userWithdrawn = userWithdrawn.add(user.refs1).add(user.refs2).add(user.refs3).sub(user.bonus);

        return (userPercentRate, userAvailable, userInvested, userInvestments, userLastInvestmentDate, userWithdrawn);
    }

    function getInvestorRefInfo(address userAddress) public view returns (address, uint256, uint256, uint256 , uint256 , uint256) {
        Investor storage user = users[userAddress];

        return (user.referrer, user.refs1, user.refs2, user.refs3 , user.refs4 , user.refs5);
    }

}


//SourceUnit: SafeMath.sol

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