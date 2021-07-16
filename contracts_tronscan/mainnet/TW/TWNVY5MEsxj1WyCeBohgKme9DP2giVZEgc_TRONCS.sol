//SourceUnit: TRONCS.sol

/**
    TRONCS - Investment platform based on TRX blockchain smart-contract technology. 

    Website: https://troncs.io
    Telegram Public Group: @troncs                                      
    Twitter: https://twitter.com/troncs_io                                  
    YouTube: https://www.youtube.com/channel/UCO9DVRyWCa-POXfMgGmJmkA
    E-mail: admin@troncs.io
    
    [OPERATING GUIDE]
    
    1) Connect TRON browser extension TronLink or mobile wallet apps like TronWallet
    2) Send any TRX amount (1000 TRX minimum) using our website invest button
    3) Wait for your earnings
    4) Withdraw earnings any time using our website "Withdraw" button
    
    [INVESTMENT CONDITIONS]
    
    1) Contract reward
    Basic interest rate: 1% per 24 hours
    Minimum deposit: 1000 TRX, no maximum limit
    Total income: 200% (including deposits)
    
    Instant income, withdrawal at any time
    
    2) Personal bonus
    Individual holding bonus: 1.5% of total deposit will be given if no withdrawal is made every 240 hours 
    Individual reinvestment: after obtaining the individual holding bonus, the re-investment of this part of the fund will obtain the total deposit of 1.5% again, the excess deposit will not increase the excess part of the bonus. 
    
    Withdrawal or reinvestment will reset the calculation time of individual holding bonuses
    
    3) Referral plan
    Level 2 recommendation reward: 3%-2% Referral rewards will be automatically credited to your balance and can be withdrawn at any time 
    
    Referral rewards apply to activated wallets only
    
    4) Union Accelerated Rate
    Real-time statistics of new effective deposits by partners every 240 hours and increase the daily interest rate for the following 240 hours:
    The effective deposits of partners are increased within 100,000 to 300,000, and then the interest rate is increased by 0.1%
    The effective deposits of partners are increased by 300,000 to 1 million，and then the interest rate is increased by 0.3%
    The effective deposit of partners is increased by 1 million to 3 million, and then the interest rate is increased by 0.5%
    The effective deposit of partners is increased by 3 million to 8 million, and then the interest rate is increased by 1%
    Effective deposits of partners increased by more than 8 million, and then the interest rate increased by 1.5%
    For two consecutive cycles, the effective deposits of partners increased by more than 8 million, and the interest rate increased by 2%. And so on, with no ceiling, the interest rate increases by 0.5% for each additional period
    Re-count new deposits every 240 hours and reset the accelerated rate
    New effective deposits: Equal to the total deposits of all partners within Level 5 after subtracting the maximum performance of level 1 partners
    
    5) Global performance bonus
    
    Ranking the top 50 new partner deposits up to level 5 per 240 hour snapshot, dividing the 5% global bonus pool of new deposits by the condition of performance
    
    Global performance rankings are updated in real time
    
    The award will be automatically paid to the balance at the beginning of the new phase and can be withdrawn at any time
    
    New effective deposits: Equal to the total deposits of all partners within Level 5 after subtracting the maximum performance of level 1 partners
    
    [FUNDS DISTRIBUTION]
    
    80% Platform main balance, participants payouts
    8% Advertising and promotion expenses
    10% Affiliate program bonuses
    2% Support work, technical functioning, administration fee
 */ 

pragma solidity 0.5.9;

contract TRONCS {
    using SafeMath for uint256;
    
    uint256 constant public INVEST_MIN_AMOUNT = 1000 trx;
    
    uint256 constant public BASE_PERCENT = 10;
    
    uint256[2]  public REFERRAL_PERCENTS = [30,20];
    
    uint256 constant public SUBORDINATE_NUMBER  = 5;
    
    uint256 constant public MARKETING_FEE = 80;
    
    uint256 constant public PROJECT_FEE = 20;
    
    uint256 constant public PERCENTS_DIVIDER = 1000;
    
    uint256 constant public CONTRACT_BALANCE_STEP = 1 trx;
    
    uint256 constant public TIME_STEP = 1 days;

    uint256 constant public MAX_BONUS_FEE = 2;
    
    uint256 constant public HAVE_FEE = 15;
    
    uint256 constant public AGAIN_INVESTED_FEE = 15;
    
    uint256 constant public AGAGIN_FEE_START = 115;
    
    uint256 constant public CYCLE_TIME_STEP = 10 days;

    uint256 constant public POOL_FEE  = 50;
    
    uint256 constant public SORT_NUMBER = 50;

    uint256 public cycleInvested;

    uint256 public cycleStart;

    uint256 public totalUsers;
    
    uint256 public totalInvested;

    uint256 public totalWithdrawn;

    uint256 public totalDeposits;

    address payable public marketingAddress;

    address payable public projectAddress;

    address[SORT_NUMBER] sortAddress;

    PoolExtend[SORT_NUMBER][] allPoolExtends;

    struct CycleInfo{
        uint256 cycleTotalInvest;
        
        uint256 cycleStart;
    }

    struct PoolExtend{
        address userAddress;
        
        uint256 subordinateInvest;
        
        uint256 extendNumber;
    }

    struct SubInvestLog{
        uint256 investedNumber;
        
        uint256 start;
    }

    struct Deposit {
        uint256 amount;
        
        uint256 withdrawn;
        
        uint256 start;
    }
    
    struct Speedup {
        uint256 cycleFee;
        
        uint256 start;
    }

    struct User {
        address userAddress;
        
        address referrer;
        
        uint256 totalWithdrawn;
        
        uint256 checkpoint;
        
        uint256 lastOpTime;
        
        uint256 referralBonus;
        
        uint256 referralWithdrawn;
        
        uint256 haveBonus;
        
        uint256 haveWithdrawn;
        
        uint256 topInvestedNumber;
        
        uint256 againInvestedBonus;
        
        uint256 againInvestedWithdrawn;
        
        uint256 poolBonus;
        
        uint256 poolWithdrawn;
        
        uint256 totalSubordinateInvest;
        
        uint256 validSubordinateInvest;
        
        uint256 maxSubordinateInvest;
        
        uint256 userCycleStart;
        
        uint256 userCycleInvestSum;
        
        uint256 subordinateInvestUserNumber;
        
        address maxSubordinateInvestUser;
        
        mapping(address => SubInvestLog) subordinateInvestInfo;
        
        Deposit[] deposits;
        
        Speedup[] speedups;
        
        uint256[2] subordinateInfo;
    }

    mapping (address => User) private users;
    mapping (uint256 => CycleInfo) private cycleLogInfo;
    
    event NewUser(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);
    event AgainBonus(address indexed user,uint256 amount);

    constructor(address payable marketingAddr, address payable projectAddr) public {
        require(!isContract(marketingAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        
        cycleStart = block.timestamp;
    }

    function invest(address referrer) public payable{
        require(msg.value >= INVEST_MIN_AMOUNT);
        
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        
        marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
        projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
        emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

        User storage user = users[msg.sender];
        user.userAddress = msg.sender;
        
        if (user.deposits.length == 0 && referrer != address(0) && referrer != msg.sender) {
            if(users[referrer].deposits.length > 0){
                user.referrer = referrer;
            }
        }
        
        if(block.timestamp.sub(user.userCycleStart) > CYCLE_TIME_STEP){
            delete user.totalSubordinateInvest;
            delete user.validSubordinateInvest;
            delete user.maxSubordinateInvest;
            delete user.maxSubordinateInvestUser;
            delete user.subordinateInvestUserNumber;
            
            user.userCycleInvestSum = msg.value;
            user.userCycleStart = cycleStart;
            
            user.totalSubordinateInvest = user.totalSubordinateInvest.add(msg.value);
        }else{
            user.userCycleInvestSum = user.userCycleInvestSum.add(msg.value);
            user.totalSubordinateInvest = user.totalSubordinateInvest.add(msg.value);
        }
        
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            address underAddress = msg.sender;
            
            for (uint256 i = 0; i < SUBORDINATE_NUMBER; i++) {
                if (upline != address(0)) {
                    User storage upline_user = users[upline];
                    
                     if(user.deposits.length == 0){
                         if(i < upline_user.subordinateInfo.length){
                             upline_user.subordinateInfo[i] = upline_user.subordinateInfo[i].add(1);
                         }
                     }
                    
                    if(upline_user.deposits.length > 0){
                        if(block.timestamp.sub(upline_user.userCycleStart) > CYCLE_TIME_STEP){
                            delete upline_user.totalSubordinateInvest;
                            delete upline_user.validSubordinateInvest;
                            delete upline_user.maxSubordinateInvest;
                            delete upline_user.maxSubordinateInvestUser;
                            delete upline_user.subordinateInvestUserNumber;
                            delete upline_user.userCycleInvestSum;
                            
                            upline_user.userCycleStart = cycleStart;
                        }
                        
                        if(i < REFERRAL_PERCENTS.length){
                            uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                            upline_user.referralBonus = upline_user.referralBonus.add(amount);
                            
                            emit RefBonus(upline, msg.sender, i, amount);
                        }
                        upline_user.totalSubordinateInvest = upline_user.totalSubordinateInvest.add(msg.value);
                         
                        updateUserSubordinateInvest(upline,underAddress);
                        
                        sortSubordinate(upline);
                    
                        updateUserSpeedup(upline);
                    }
                    underAddress = upline;
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            user.userCycleStart = cycleStart;
            
            totalUsers = totalUsers.add(1);
            
            emit NewUser(msg.sender);
        }
        updateUserAgainInvestedBonus(msg.sender,msg.value);
        
        user.haveBonus = getUserHaveBonus(msg.sender);
        
        user.lastOpTime = block.timestamp;
        user.topInvestedNumber = 0;
        
        user.deposits.length++;
        Deposit storage deposits = user.deposits[user.deposits.length-1];
        deposits.amount = msg.value;
        deposits.start = block.timestamp;
        
        cycleInvested = cycleInvested.add(msg.value);
        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, msg.value);
    }
    
    function updateUserSubordinateInvest(address userAddress,address underAddress) private{
        User storage user = users[userAddress];
        User storage underUser = users[underAddress];
        
        uint256 underSubordinateInvest = underUser.totalSubordinateInvest;
        
        if(user.maxSubordinateInvest == 0){
            user.subordinateInvestUserNumber = user.subordinateInvestUserNumber.add(1);
            user.maxSubordinateInvest = underSubordinateInvest;
            user.maxSubordinateInvestUser = underAddress;
            user.subordinateInvestInfo[underAddress].start = cycleStart;
         }else{
             if(user.subordinateInvestInfo[underAddress].start < cycleStart){
                 user.subordinateInvestUserNumber = user.subordinateInvestUserNumber.add(1);
                 user.subordinateInvestInfo[underAddress].start = cycleStart;
                 user.subordinateInvestInfo[underAddress].investedNumber = 0;
             }
             
             if(underAddress == user.maxSubordinateInvestUser){
                 user.maxSubordinateInvest = underSubordinateInvest;
             }else{
                 if(user.maxSubordinateInvest >= underSubordinateInvest){
                    if(underSubordinateInvest > user.subordinateInvestInfo[underAddress].investedNumber){
                        user.validSubordinateInvest = user.validSubordinateInvest.add(underSubordinateInvest
                        .sub(user.subordinateInvestInfo[underAddress].investedNumber));
                    }
                 }else{
                     user.validSubordinateInvest = user.validSubordinateInvest.add(user.maxSubordinateInvest
                             .sub(user.subordinateInvestInfo[underAddress].investedNumber));
                     
                     user.maxSubordinateInvest = underSubordinateInvest;
                     user.maxSubordinateInvestUser = underAddress;
                 }
             }
         }
         user.subordinateInvestInfo[underAddress].investedNumber = underSubordinateInvest;
    }
    
    function updateUserSpeedup(address userAddress) private{
        User storage user = users[userAddress];
        
        if(user.deposits.length > 0){
            Speedup[] storage speedups = user.speedups;
            
            uint256 subordinate_invest_number = user.validSubordinateInvest.div(CONTRACT_BALANCE_STEP);
            
             uint256 cycle_max_number;
             if(speedups.length > 0){
                 for(uint256 i = 0; i < speedups.length; i ++){
                     if(block.timestamp > speedups[i].start){
                         if(speedups[i].cycleFee >= 15){
                            cycle_max_number = cycle_max_number.add(1);
                         }else{
                             cycle_max_number = 0;
                         }
                     }
                 }
             }
             
            uint256 cycle_fee;
            if(subordinate_invest_number >= 100000 && subordinate_invest_number < 300000){
                cycle_fee = 1;
            }else if(subordinate_invest_number >= 300000 && subordinate_invest_number < 1000000){
                cycle_fee = 3; 
            }else if(subordinate_invest_number >= 1000000 && subordinate_invest_number < 3000000){
                cycle_fee = 5;
            }else if(subordinate_invest_number >= 3000000 && subordinate_invest_number < 8000000){
                cycle_fee = 10;
            }else if(subordinate_invest_number >= 8000000){
                cycle_fee = 15;
            }
            
            if(cycle_fee >= 15){
                cycle_max_number = cycle_max_number.add(1);
            }
            
            if(cycle_max_number >= 2){
                cycle_fee = cycle_fee.add(cycle_max_number.sub(1).mul(5));
            }
            
            if(cycle_fee > 0){
                if(speedups.length != 0 && speedups[speedups.length-1].start > block.timestamp){
                    speedups[speedups.length-1].cycleFee = cycle_fee;
                }else{
                    if(speedups.length > 1){
                        if(speedups[speedups.length-2].start != cycleStart.add(CYCLE_TIME_STEP)){
                            speedups.length++;
                            speedups[speedups.length-1] = Speedup(cycle_fee,cycleStart.add(CYCLE_TIME_STEP));
                        }
                    }else{
                        speedups.length++;
                        speedups[speedups.length-1] = Speedup(cycle_fee,cycleStart.add(CYCLE_TIME_STEP));
                    }
                }
            }
        }
    }

    function updateUserAgainInvestedBonus(address userAddress,uint256 amount) private{
        bool bonus_run = false;
        if(block.timestamp.sub(users[userAddress].lastOpTime) >= CYCLE_TIME_STEP){
            uint256 totalAmount = getUserTotalDeposits(userAddress);
            if(amount >= totalAmount.mul(AGAGIN_FEE_START).div(PERCENTS_DIVIDER)){
                uint256 againInvestedBonus = totalAmount.mul(AGAIN_INVESTED_FEE).div(PERCENTS_DIVIDER);
                
                users[userAddress].againInvestedBonus = users[userAddress].againInvestedBonus.add(againInvestedBonus);
                
                bonus_run = true;
                
                emit AgainBonus(userAddress,users[userAddress].againInvestedBonus);
            }
        }
        
        if(!bonus_run){    
            if(users[userAddress].topInvestedNumber > 0){
                if(amount >= users[userAddress].topInvestedNumber.mul(AGAGIN_FEE_START).div(PERCENTS_DIVIDER)){
                    uint256 againInvestedBonus = users[userAddress].topInvestedNumber.mul(AGAIN_INVESTED_FEE).div(PERCENTS_DIVIDER);
                        
                    users[userAddress].againInvestedBonus = users[userAddress].againInvestedBonus.add(againInvestedBonus);
                
                    emit AgainBonus(userAddress,users[userAddress].againInvestedBonus);
                }
            }
        }
    }

    function sortSubordinate(address userAddress) private{
        User storage user = users[userAddress];
        
        bool is_sort;
        
        uint256 min_index;
        uint256 min_number;
        for (uint256 i = 0; i < sortAddress.length; i++){
            if(i == 0){
                min_number = users[sortAddress[i]].validSubordinateInvest;
                min_index = i;
            }
            
            if(users[sortAddress[i]].validSubordinateInvest < min_number){
                min_number = users[sortAddress[i]].validSubordinateInvest;
                min_index = i;
            }
            
            if(user.userAddress == sortAddress[i]){
                is_sort = true;
                break;
            }
            
            if(users[sortAddress[i]].validSubordinateInvest == 0){
                min_number = 0;
                min_index = i;
                break;
            }
        }
        if(user.validSubordinateInvest > min_number && !is_sort){
            sortAddress[min_index] = user.userAddress;
        }  
    }
    
    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(MAX_BONUS_FEE)) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }
            
                for(uint256 ii = 0;ii < user.speedups.length; ii++){
                    Speedup storage speedup = user.speedups[ii];
                    if(block.timestamp > speedup.start){
                         if(speedup.start >= user.checkpoint){
                             if(block.timestamp.sub(speedup.start) >= CYCLE_TIME_STEP){
                                 dividends = dividends.add((user.deposits[i].amount.mul(speedup.cycleFee).div(PERCENTS_DIVIDER))
                                    .mul(CYCLE_TIME_STEP)
                                    .div(TIME_STEP));
                             }else{
                                  dividends = dividends.add((user.deposits[i].amount.mul(speedup.cycleFee).div(PERCENTS_DIVIDER))
                                    .mul(block.timestamp.sub(speedup.start))
                                    .div(TIME_STEP));
                             }
                         }else{
                             if(speedup.start.add(CYCLE_TIME_STEP) >= user.checkpoint){
                                  if(speedup.start.add(CYCLE_TIME_STEP) >= block.timestamp){
                                      dividends = dividends.add((user.deposits[i].amount.mul(speedup.cycleFee).div(PERCENTS_DIVIDER))
                                        .mul(block.timestamp.sub(user.checkpoint))
                                        .div(TIME_STEP));
                                  }else{
                                      dividends = dividends.add((user.deposits[i].amount.mul(speedup.cycleFee).div(PERCENTS_DIVIDER))
                                        .mul(speedup.start.add(CYCLE_TIME_STEP).sub(user.checkpoint))
                                        .div(TIME_STEP));
                                  }
                              }
                         }
                    }
                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(MAX_BONUS_FEE)) {
                    dividends = (user.deposits[i].amount.mul(MAX_BONUS_FEE)).sub(user.deposits[i].withdrawn);
                }

                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);
                totalAmount = totalAmount.add(dividends);
            }
        }

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            user.referralBonus = 0;
            
            user.referralWithdrawn = user.referralWithdrawn.add(referralBonus);
        }
        
        uint256 againInvestedBonus = getUserAgainInvestedBonus(msg.sender);
        if (againInvestedBonus > 0) {
            totalAmount = totalAmount.add(againInvestedBonus);
            user.againInvestedBonus = 0;
            
            user.againInvestedWithdrawn = user.againInvestedWithdrawn.add(againInvestedBonus);
        }
        
        uint256 haveBonus = getUserHaveBonus(msg.sender);
        if (haveBonus > 0) {
            totalAmount = totalAmount.add(haveBonus);
            user.haveBonus = 0;
            
            user.haveWithdrawn = user.haveWithdrawn.add(haveBonus);
        }
        
        uint256 poolBonus = getUserPoolBonus(msg.sender);
        if (poolBonus > 0) {
            totalAmount = totalAmount.add(poolBonus);
            user.poolBonus = 0;
            
            user.poolWithdrawn = user.poolWithdrawn.add(poolBonus);
        }
        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        
        if(block.timestamp.sub(user.lastOpTime) >= CYCLE_TIME_STEP){
            user.topInvestedNumber = getUserTotalDeposits(msg.sender);
        }
        user.lastOpTime = block.timestamp;
        user.checkpoint = block.timestamp;
        user.totalWithdrawn = user.totalWithdrawn.add(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
            
        msg.sender.transfer(totalAmount);
        
        emit Withdrawn(msg.sender, totalAmount);
    }

    function getContractStatistics() public view returns (uint256[] memory) {
        uint256[] memory datas = new uint256[](4);
        
        datas[0] = totalInvested;
        datas[1] = totalDeposits;
        datas[2] = totalUsers;
        datas[3] = address(this).balance;
        
        return datas;
    }
    
    function getUserStatistics(address userAddress) public view returns(uint256[] memory){
        uint256[] memory datas = new uint256[](8);
        datas[0] = getUserTotalDeposits(userAddress);
        datas[1] = getUserNumberOfDeposits(userAddress);
        if(users[userAddress].deposits.length > 0){
            datas[2] = users[userAddress].deposits[users[userAddress].deposits.length -1].start;
        }
        
        datas[3] = getUserAllHaveBonus(userAddress);
        datas[4] = getUserAllAgainInvestedBonus(userAddress);
        datas[5] = getUserAllPoolBonus(userAddress);
        datas[7] = getUserAllReferralBonus(userAddress);
        datas[6] = getUserTotalWithdrawn(userAddress);
        
        return datas;
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(MAX_BONUS_FEE)) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (user.deposits[i].amount.mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }
            
                for(uint256 ii = 0;ii < user.speedups.length; ii++){
                    Speedup storage speedup = user.speedups[ii];
                    if(block.timestamp > speedup.start){
                         if(speedup.start >= user.checkpoint){
                             if(block.timestamp.sub(speedup.start) >= CYCLE_TIME_STEP){
                                 dividends = dividends.add((user.deposits[i].amount.mul(speedup.cycleFee).div(PERCENTS_DIVIDER))
                                    .mul(CYCLE_TIME_STEP)
                                    .div(TIME_STEP));
                             }else{
                                  dividends = dividends.add((user.deposits[i].amount.mul(speedup.cycleFee).div(PERCENTS_DIVIDER))
                                    .mul(block.timestamp.sub(speedup.start))
                                    .div(TIME_STEP));
                             }
                         }else{
                             if(speedup.start.add(CYCLE_TIME_STEP) >= user.checkpoint){
                                  if(speedup.start.add(CYCLE_TIME_STEP) >= block.timestamp){
                                      dividends = dividends.add((user.deposits[i].amount.mul(speedup.cycleFee).div(PERCENTS_DIVIDER))
                                        .mul(block.timestamp.sub(user.checkpoint))
                                        .div(TIME_STEP));
                                  }else{
                                      dividends = dividends.add((user.deposits[i].amount.mul(speedup.cycleFee).div(PERCENTS_DIVIDER))
                                        .mul(speedup.start.add(CYCLE_TIME_STEP).sub(user.checkpoint))
                                        .div(TIME_STEP));
                                  }
                              }
                         }
                    }
                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(MAX_BONUS_FEE)) {
                    dividends = (user.deposits[i].amount.mul(MAX_BONUS_FEE)).sub(user.deposits[i].withdrawn);
                }
                totalAmount = totalAmount.add(dividends);
            }
        }

        uint256 referralBonus = getUserReferralBonus(userAddress);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
        }
        
        uint256 againInvestedBonus = getUserAgainInvestedBonus(userAddress);
        if (againInvestedBonus > 0) {
            totalAmount = totalAmount.add(againInvestedBonus);
        }
        
        uint256 haveBonus = getUserHaveBonus(userAddress);
        if (haveBonus > 0) {
            totalAmount = totalAmount.add(haveBonus);
        }
        
        uint256 poolBonus = getUserPoolBonus(userAddress);
        if (poolBonus > 0) {
            totalAmount = totalAmount.add(poolBonus);
        }

        return totalAmount;
    }
    
    function getUserAgainExpectedBonus(address userAddress) public view returns (uint256[] memory){
        uint256[] memory datas = new uint256[](5);
        
        if(users[userAddress].topInvestedNumber > 0 || block.timestamp.sub(users[userAddress].lastOpTime) >= CYCLE_TIME_STEP){
            datas[0] = 1;
           
            uint256 totalAmount;
            if(users[userAddress].topInvestedNumber > 0){
                totalAmount = users[userAddress].topInvestedNumber;
            }else{
                totalAmount = getUserTotalDeposits(userAddress);
            }
            
            uint256 min_amount = totalAmount.mul(AGAGIN_FEE_START).div(PERCENTS_DIVIDER);
            datas[1] = min_amount;
            
            uint256 againInvestedBonus = totalAmount.mul(AGAIN_INVESTED_FEE).div(PERCENTS_DIVIDER);
            datas[2] = againInvestedBonus;
        }

        uint256 haveExpected = getUserTotalDeposits(userAddress).mul(HAVE_FEE).div(PERCENTS_DIVIDER);
        datas[3] = haveExpected;
        
        uint256 date_length = 10;
        
        if(users[userAddress].deposits.length == 0){
            datas[4] = 0;
        }else{
            uint256 distance_day = block.timestamp.sub(users[userAddress].lastOpTime).div(TIME_STEP);
            distance_day = date_length.sub(distance_day.mod(date_length));
            
            datas[4] = distance_day;
        }
        return datas;
    }
    
    function getUserSubordinateInvestUserNumber(address userAddress) public view returns(uint256){
        return users[userAddress].subordinateInvestUserNumber;
    }
    
    function getUserSubordinateInvestByUser(address userAddress,address underAddress) public view returns(uint256,uint256){
        return (users[userAddress].subordinateInvestInfo[underAddress].investedNumber,
        users[userAddress].subordinateInvestInfo[underAddress].start);
    }

    function getUserSubordinateInvest(address userAddress) public view returns(uint256,uint256){
        return (users[userAddress].totalSubordinateInvest,users[userAddress].validSubordinateInvest);
    }

    function getUserCheckpoint(address userAddress) private view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrerAndMaxSubordinateInvest(address userAddress) public view returns(address[] memory) {
        address[] memory datas = new address[](2);
        datas[0] = users[userAddress].referrer;
        
        if(users[userAddress].userCycleStart >= cycleStart){
            datas[1] = users[userAddress].maxSubordinateInvestUser;
        } 
        return datas;
    }

    function getUserSubordinateInfo(address userAddress) public view returns(uint256[2] memory) {
        return users[userAddress].subordinateInfo;
    }
    
    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].referralBonus;
    }
    
    function getUserAllReferralBonus(address userAddress) private view returns(uint256) {
        return users[userAddress].referralBonus.add(users[userAddress].referralWithdrawn);
    }
    
    function getUserPoolBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].poolBonus;
    }
    
    function getUserAllPoolBonus(address userAddress) private view returns(uint256) {
        return users[userAddress].poolBonus.add(users[userAddress].poolWithdrawn);
    }
    
    function getUserHaveBonus(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];
        
        uint256 cycle = block.timestamp.sub(user.lastOpTime).div(CYCLE_TIME_STEP);
        
        if(cycle > 0){
            uint256 have_bonus = getUserTotalDeposits(userAddress).mul(cycle.mul(HAVE_FEE)).div(PERCENTS_DIVIDER);
            return user.haveBonus.add(have_bonus);
        }
        return user.haveBonus;
    }
    
    function getUserAllHaveBonus(address userAddress) private view returns(uint256) {
        return getUserHaveBonus(userAddress).add(users[userAddress].haveWithdrawn);
    }
    
    function getUserAgainInvestedBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].againInvestedBonus;
    }
    
    function getUserAllAgainInvestedBonus(address userAddress) private view returns(uint256) {
        return users[userAddress].againInvestedBonus.add(users[userAddress].againInvestedWithdrawn);
    }
    
    function getUserSpeedupsByIndex(address userAddress,uint256 index) public view returns(uint256,uint256){
        if(users[userAddress].speedups.length > index){
            return (users[userAddress].speedups[index].cycleFee,users[userAddress].speedups[index].start);
        }
        return (0,0);
    }
    
    function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
        return users[userAddress].totalWithdrawn;
    }

    function getUserNumberOfDeposits(address userAddress) private view returns(uint256) {
        return users[userAddress].deposits.length;
    }
    
    function getUserAmountOfLastDeposits(address userAddress) public view returns(uint256) {
        if(users[userAddress].deposits.length > 0){
            return users[userAddress].deposits[users[userAddress].deposits.length-1].amount;
        }
        return 0;
    }
    
    function getUserTotalDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }
        return amount;
    }
    
    function getUserSpeedupPercentRate(address userAddress) public view returns(uint256){
        User storage user = users[userAddress];
        Speedup[] storage speedups = user.speedups;
        
        if(speedups.length > 0){
            for(uint256 i = 0;i < speedups.length;i ++){
                if(block.timestamp > speedups[i].start && block.timestamp.sub(speedups[i].start) < CYCLE_TIME_STEP){
                    return speedups[i].cycleFee;
                }
            }
        }
        return 0;
    }
    
    function getPoolExtendsByAddress(uint256 cycleNumber) public view returns(address[] memory){
        address[] memory address_arr = new address[](SORT_NUMBER);
        if(cycleNumber >= allPoolExtends.length){
            for(uint256 i = 0; i < SORT_NUMBER; i ++){
                address_arr[i] = sortAddress[i];
            }
        }else{
            PoolExtend[SORT_NUMBER] storage poolExtends = allPoolExtends[cycleNumber];
        
            for(uint256 i = 0; i < poolExtends.length; i ++){
                address_arr[i] = poolExtends[i].userAddress;
            }
        }
        return address_arr;
    }

    function getPoolExtendsByExtendNumber(uint256 cycleNumber) public view returns(uint256[] memory){
        uint256[] memory extend_arr = new uint256[](SORT_NUMBER);
        
        if(cycleNumber >= allPoolExtends.length){
            uint256 poolNumber = cycleInvested.mul(POOL_FEE).div(PERCENTS_DIVIDER);
            
             uint256 topInvestSum;
             for(uint256 i = 0;i < SORT_NUMBER; i++){
                 if(sortAddress[i] != address(0)){
                     topInvestSum = topInvestSum.add(users[sortAddress[i]].validSubordinateInvest);
                 }
             }
             topInvestSum = topInvestSum.div(CONTRACT_BALANCE_STEP);
             
             if(topInvestSum == 0){
                 return extend_arr;
             }
             
             for(uint256 i = 0;i < SORT_NUMBER; i++){
                 User storage user = users[sortAddress[i]];
                 if(user.deposits.length > 0){
                     extend_arr[i] = user.validSubordinateInvest.div(topInvestSum).mul(poolNumber).div(CONTRACT_BALANCE_STEP);
                 }
             }
        }else{
            PoolExtend[SORT_NUMBER] storage poolExtends = allPoolExtends[cycleNumber];
        
            for(uint256 i = 0; i < poolExtends.length; i ++){
                extend_arr[i] = poolExtends[i].extendNumber;
            }
        }
        return extend_arr;
    }
    
    function getPoolExtendsByInvestNumber(uint256 cycleNumber) public view returns(uint256[] memory){
        uint256[] memory invest_arr = new uint256[](SORT_NUMBER);
        if(cycleNumber >= allPoolExtends.length){
             for(uint256 i = 0; i < SORT_NUMBER; i ++){
                invest_arr[i] = users[sortAddress[i]].validSubordinateInvest;
            }
        }else{
            PoolExtend[SORT_NUMBER] storage poolExtends = allPoolExtends[cycleNumber];
        
            for(uint256 i = 0; i < poolExtends.length; i ++){
                invest_arr[i] = poolExtends[i].subordinateInvest;
            }
        }
        return invest_arr;
    }
    
    function getPoolExtendsByCycleInfo(uint256 cycleNumber) public view returns(uint256[] memory){
        uint256[] memory datas = new uint256[](2);
        if(cycleNumber >= allPoolExtends.length){
            datas[0] = cycleInvested;
            datas[1] = cycleStart;
        }else{
             PoolExtend[SORT_NUMBER] storage poolExtends = allPoolExtends[cycleNumber];
        
            if(poolExtends.length > 0){
                CycleInfo memory cycleInfo = cycleLogInfo[cycleNumber];
                datas[0] = cycleInfo.cycleTotalInvest;
                datas[1] = cycleInfo.cycleStart;
            }
        }
        return datas;
    }
    
    function getPoolExtendsCycle() public view returns(uint256){
        return allPoolExtends.length;
    }
    
    function getUserPoolSortNumber(address userAddress) public view returns(uint256[] memory){
        uint256[] memory datas = new uint256[](6);
        
        if(allPoolExtends.length > 0){
             PoolExtend[SORT_NUMBER] storage poolExtend = allPoolExtends[allPoolExtends.length-1];
             
             for(uint256 i = 0; i < poolExtend.length; i ++){
                 if(userAddress == poolExtend[i].userAddress){
                     datas[1] = poolExtend[i].extendNumber;
                     
                     datas[2] = poolExtend[i].subordinateInvest;
                     break;
                 }
             }
             CycleInfo memory cycleInfo = cycleLogInfo[allPoolExtends.length-1];
             datas[0] = cycleInfo.cycleTotalInvest;
        }
        
        if(users[userAddress].userCycleStart >= cycleStart){
            if(users[userAddress].totalSubordinateInvest >= users[userAddress].userCycleInvestSum){
                datas[3] = users[userAddress].totalSubordinateInvest.sub(users[userAddress].userCycleInvestSum);
            }else{
                datas[3] = users[userAddress].totalSubordinateInvest;
            }
            datas[4] = users[userAddress].validSubordinateInvest;
            datas[5] = users[userAddress].maxSubordinateInvest;
        }
        
        return datas;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    function poolExtendTimer() public{
        if((block.timestamp.sub(cycleStart)) >= CYCLE_TIME_STEP){
            cycleStart = block.timestamp;
            
             uint256 poolNumber = cycleInvested.mul(POOL_FEE).div(PERCENTS_DIVIDER);
             
             allPoolExtends.length++;
             
             PoolExtend[SORT_NUMBER] storage lastPoolExtends = allPoolExtends[allPoolExtends.length-1];
             
             cycleLogInfo[allPoolExtends.length-1] = CycleInfo(cycleInvested,cycleStart);
             
             uint256 topInvestSum;
             for(uint256 i = 0;i < SORT_NUMBER; i++){
                 if(sortAddress[i] != address(0)){
                     topInvestSum = topInvestSum.add(users[sortAddress[i]].validSubordinateInvest);
                 }
             }
             
             topInvestSum = topInvestSum.div(CONTRACT_BALANCE_STEP);
             
             if(topInvestSum > 0){
                for(uint256 i = 0;i < SORT_NUMBER; i++){
                     User storage user = users[sortAddress[i]];
            
                     uint256 amount = user.validSubordinateInvest.div(topInvestSum).mul(poolNumber).div(CONTRACT_BALANCE_STEP);
                    
                     user.poolBonus = user.poolBonus.add(amount);
                     
                     lastPoolExtends[i] = PoolExtend(user.userAddress,user.validSubordinateInvest,amount);
                 }
             }
             delete cycleInvested;
             delete sortAddress;
        }
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}