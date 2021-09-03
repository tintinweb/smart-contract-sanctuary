//SourceUnit: TronFamily_last.sol

/**

████████ ██████   ██████  ███    ██     ███████  █████  ███    ███ ██ ██      ██    ██ 
   ██    ██   ██ ██    ██ ████   ██     ██      ██   ██ ████  ████ ██ ██       ██  ██  
   ██    ██████  ██    ██ ██ ██  ██     █████   ███████ ██ ████ ██ ██ ██        ████   
   ██    ██   ██ ██    ██ ██  ██ ██     ██      ██   ██ ██  ██  ██ ██ ██         ██    
   ██    ██   ██  ██████  ██   ████     ██      ██   ██ ██      ██ ██ ███████    ██    
                                                                                       
**/
pragma solidity 0.8.6;
// SPDX-License-Identifier: MIT

contract TronFamily {
    using SafeMath for *;
    uint constant public INVEST_MIN_AMOUNT = 200 trx;
    uint constant public INVEST_MAX_AMOUNT = 2000000 trx; 
    uint constant public DEPOSITS_MAX = 1000;
    uint constant public WITHDRAW_DAILY_MAX_LIMIT = 100000 trx;
    uint constant public TIME_STEP = 1 days;
    uint constant public PROJECT_FEE = 400;               
    uint constant public MARKETING_FEE = 400;    
    uint constant public SUPPORT_FEE = 300;  
    uint constant public BASE_PERCENT = 70;
    uint constant public MAX_HOLD_PERCENT = 100;        
    uint constant public PERCENTS_DIVIDER = 10000;
    uint[] public REFERRAL_PERCENTS = [500, 250, 100, 50, 40, 30 ,20 ,10]; 
    address payable private projectAddr;
    address payable private supportAddr;
    address payable private marketingAddr;

    struct User {
        address upline;
        Deposit[] deposits;
        uint64 refBonus;
        uint32 checkpoint;
        uint24[8] refs;
        uint turnover;
        uint lastWithdrawn;
    }

    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint32 startTime;
    }

    uint public totalUsers;
    uint public totalDeposits;
    uint public totalWithdrawn;
    mapping (address => User) internal users;
    event Newbie(address addr);
    event NewDeposit(address indexed addr, uint amount);
    event FeePayed(address indexed user, uint amount);
    event ReferralBonus(address indexed upline, address indexed referral, uint level, uint amount);
    event Withdraw(address indexed addr, uint amount);

    constructor(address payable project, address payable marketing, address payable support)  {
        require(!isContract(project));
        projectAddr = project;
        marketingAddr = marketing;
        supportAddr = support;
    }
    
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function deposit(address referrer) external payable{
     	require(!isContract(msg.sender),"Contract Registration Not Allowed!");
    	require(!isContract(referrer),"Upline Contract Address Not Allowed!");
    	require(referrer != msg.sender,"Upline Contract And User Address Can't Be Same!");
        require(msg.value >= INVEST_MIN_AMOUNT && msg.value <= INVEST_MAX_AMOUNT, "Bad Deposit");
        User storage user = users[msg.sender];
        require(user.deposits.length < DEPOSITS_MAX, "Maximum deposits reached!");
        uint toDeposit = msg.value;
        uint projectFee = toDeposit.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        uint supportFee = toDeposit.mul(SUPPORT_FEE).div(PERCENTS_DIVIDER);
        uint marketingFee = toDeposit.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        projectAddr.transfer(projectFee);
        supportAddr.transfer(supportFee);
        marketingAddr.transfer(marketingFee);
        emit FeePayed(msg.sender, projectFee.add(supportFee).add(marketingFee));
        if (user.upline == address(0) && users[referrer].deposits.length > 0) {
            user.upline = referrer;
        }
        if (user.deposits.length == 0) {
            totalUsers++;
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }
        if (user.upline != address(0)) {
            address upline = user.upline;
            for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if(upline == address(0)) break;
                if(isActive(upline)) {
                    uint reward = toDeposit.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].refBonus = uint64(uint(users[upline].refBonus).add(reward));
                    users[upline].refs[i]++;
                    payable(upline).transfer(reward);
                    emit ReferralBonus(upline, msg.sender, i, reward);
                    
                }               
                upline = users[upline].upline;
            }
        }
        user.deposits.push(Deposit(uint64(toDeposit), 0, uint32(block.timestamp)));
        totalDeposits = totalDeposits.add(toDeposit);
        emit NewDeposit(msg.sender, toDeposit);
    }

    function withdraw() external{
    	require(!isContract(msg.sender),"Contract Address Withdraw Not Allowed!");
        User storage user = users[msg.sender];
        address payable addr = payable(msg.sender); 
        uint toSend;
        uint dividends;
        uint userPercentRate = getUserPercentRate(msg.sender);
        for (uint i = 0; i < user.deposits.length; i++) {
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {
                if (user.deposits[i].startTime > user.checkpoint) {
                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].startTime)))
                        .div(TIME_STEP);
                } else {
                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);
                }
                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn));
                }
                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends));
                toSend = toSend.add(dividends);
            }
        }
  
        if(user.turnover > 0) {
            toSend = toSend.add(uint(user.turnover));
            user.turnover = 0;
        }

        if (block.timestamp < uint(user.checkpoint) + TIME_STEP) {
            if(toSend >= WITHDRAW_DAILY_MAX_LIMIT.sub(user.lastWithdrawn)){
                user.turnover = toSend.sub(WITHDRAW_DAILY_MAX_LIMIT.sub(user.lastWithdrawn));
                toSend = WITHDRAW_DAILY_MAX_LIMIT.sub(user.lastWithdrawn);
            }
        }else {
            if(toSend >= WITHDRAW_DAILY_MAX_LIMIT){
                user.turnover = toSend.sub(WITHDRAW_DAILY_MAX_LIMIT);
                toSend = WITHDRAW_DAILY_MAX_LIMIT;
            }
        }
        
        uint contractBalance = address(this).balance;
        if (contractBalance < toSend) {
            toSend = contractBalance;
        }
        require(toSend > 0, "User has no dividends");
        user.checkpoint = uint32(block.timestamp);
        user.lastWithdrawn = toSend;
        totalWithdrawn = totalWithdrawn.add(toSend);
        addr.transfer(toSend);
        emit Withdraw(addr, toSend);
    }

    function getUserAvailable(address userAddr) public view returns (uint) {
        User storage user = users[userAddr];
        uint userPercentRate = getUserPercentRate(msg.sender);
        uint totalDividends;
        uint dividends;
        for (uint i = 0; i < user.deposits.length; i++) {
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {
                if (user.deposits[i].startTime > user.checkpoint) {
                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].startTime)))
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
            }
        }
        return totalDividends;
    }

    function getUserPercentRate(address userAddr) public view returns (uint) {
        User storage user = users[userAddr];
        if (isActive(userAddr)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP.div(2)).mul(5);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
            return BASE_PERCENT.add(timeMultiplier);
        } else {
            return BASE_PERCENT;
        }
    }


    function getUpline(address userAddr) public view returns (address) {
         User storage user = users[userAddr];
         return user.upline;
    }
    function isActive(address userAddr) public view returns (bool) {
        User storage user = users[userAddr];
        return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(2);
    }

    function getUserDeposits(address userAddr, uint last, uint first) public view returns (uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[userAddr];
        uint count = first.sub(last);
        if (count > user.deposits.length) {
            count = user.deposits.length;
        }

        uint[] memory amount = new uint[](count);
        uint[] memory withdrawn = new uint[](count);
        uint[] memory start = new uint[](count);

        uint index = 0;
        for (uint i = first; i > last; i--) {
            amount[index] = uint(user.deposits[i-1].amount);
            withdrawn[index] = uint(user.deposits[i-1].withdrawn);
            start[index] = uint(user.deposits[i-1].startTime);
            index++;
        }
        return (amount, withdrawn, start);
    }

    function getContractBalance() public view returns (uint) {
		return address(this).balance;
	}

    function getUserStats(address userAddr) public view returns (uint, uint, uint32, uint24[8] memory, address, uint, uint) {
        User storage user = users[userAddr];
        return (
          user.refBonus,
          user.deposits.length,
          user.checkpoint,
          user.refs,
          user.upline,
          user.turnover,
          user.lastWithdrawn
       );
    }
    
    function getUserTotalDeposits(address userAddr) public view returns (uint) {
        User storage user = users[userAddr];
        uint amount;
        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].amount));
        }
        return amount;
    }
    
    function getUserTotalWithdrawn(address userAddr) public view returns (uint) {
        User storage user = users[userAddr];
        uint amount;
        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].withdrawn));
        }
        return amount;
    }

    function getGlobalStats() public view returns(uint, uint, uint) {
        return (
          totalDeposits,
          totalWithdrawn,
          totalUsers
        );
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