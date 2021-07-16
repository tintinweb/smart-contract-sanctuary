//SourceUnit: WinnerProd.sol

pragma solidity ^0.5.10;


contract WinnerProd {
    using SafeMath for uint256;
    uint256 constant public TIME_STEP = 1 days;
    uint256 constant public MIN_INVESTMENT = 100 trx;//trx;
    uint constant public CONTRACT_BALANCE_STEP = 1e7 trx;//trx;
    uint256 constant public CONTRACT_PERCENT_START_BALANCE = 5e7 trx;//trx;

    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public ADMIN_FEE = 50;
    uint256 constant public MARKETING_FEE = 50;
    uint256 constant public DIRECT_BONUS_PERCENT = 100;
    uint256[] public REFERRAL_PERCENTS = [300, 200, 100, 100, 100, 80, 80, 80, 80, 80, 50, 50, 50, 50, 50];

    uint256 constant public BASE_PERCENT = 10;
    uint256 constant public MAX_CONTRACT_PERCENT = 10;
    uint256 constant public MAX_HOLD_PERCENT = 20;
    uint8 constant public DIRECT_TOP = 20;
    uint256 public contractPercent;

    address payable owner;


    struct Deposit {
        uint amount;
        uint withdrawn;
        uint start;
    }

    struct User {
        Deposit[] deposits;
        address[] childs;
        address upline;
        uint256 referrals;
        uint256 totalStructure;

        uint256 performanceSum;

        uint256 directBonus;
        uint256 poolBonus;
        uint256 bonus;

        uint256 depositsSum;
        uint256 withdrawnSum;
        uint40 checkpoint;
    }

    mapping(address => User) public users;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;




    function conctractInfo() external view returns(uint[6] memory res){
        res[0]=totalInvested;
        res[1]=totalWithdrawn;
        res[2]=address(this).balance;
        res[3]=totalUsers;
        res[4]=pool_balance;
        res[5]=uint(pool_last_draw);
        return res;
    }


    function userInfo(address addr) external view returns(address upline,uint[17] memory res){
        User memory user = users[addr];
        uint256 maxPayOut;
        uint256 status;
        uint256 lastDeposite;
        if(user.deposits.length > 0){
            Deposit memory deposit = user.deposits[user.deposits.length-1];
            maxPayOut = deposit.amount.mul(3);
            lastDeposite = deposit.amount;
            if(isActive(addr)){
                status = 1;
            }else{
                status = 2;
            }
        }
        res[0]= user.referrals;
        res[1]= user.totalStructure;
        res[2]= maxPayOut;
        res[3]= status;
        res[4]= user.directBonus;
        res[5]= uint(getRanking(addr)) ;
        res[6]= user.bonus;
        res[7]= user.poolBonus;
        res[8]= BASE_PERCENT;
        res[9]= contractPercent - BASE_PERCENT;
        res[10]= getUserPercentRate(addr);
        res[11]= user.depositsSum;
        res[12]= user.withdrawnSum;
        res[13]= user.performanceSum;
        res[14]= uint(user.checkpoint);
        res[15]= unWithdraw(addr);
        res[16]= lastDeposite;
        return (user.upline,res);
    }

    function getChilds(address addr) external view returns(address[] memory){
        return users[addr].childs;
    }

    function getRanking(address addr) public view returns(uint8){
        for(uint8 i=0;i<DIRECT_TOP;i++){
            if(addr != address(0) && addr == pool_top[i]){
                return i+1;
            }
        }
        return 0;
    }


    address payable public marketingAddress;
    address payable public adminAddress;


    uint[] public pool_bonuses = [350, 250, 150, 120,80,50];
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;


    event NewUser(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event FeePayed(address indexed user, uint totalAmount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address up,address _addr,uint256 bonus);


    constructor(address payable _marketingAddr, address payable _adminAddr) public {
        owner = msg.sender;
        marketingAddress = _marketingAddr;
        adminAddress = _adminAddr;
        contractPercent = BASE_PERCENT;
    }

    function invest(address _upline) payable external {
        uint256 amount = msg.value;
        require(amount >= MIN_INVESTMENT, 'The investment amount is wrong');
        require(!isActive(msg.sender), 'Deposit already exists');
        User storage user = users[msg.sender];
        if (user.deposits.length > 0) {
            Deposit memory d = user.deposits[user.deposits.length - 1];
            require(amount > d.amount, 'The investment amount must be greater than the last time');
        }

        uint marketingFee = amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint adminFee = amount.mul(ADMIN_FEE).div(PERCENTS_DIVIDER);
        marketingAddress.transfer(marketingFee);
        adminAddress.transfer(adminFee);
        emit FeePayed(msg.sender, marketingFee.add(adminFee));

        if (user.upline == address(0) && users[_upline].deposits.length > 0 && _upline != msg.sender) {
            user.upline = _upline;
        }

        address up = user.upline;
        if (user.upline != address(0)) {
            users[up].directBonus += (amount.mul(DIRECT_BONUS_PERCENT).div(PERCENTS_DIVIDER));
        }

        user.checkpoint = uint40(block.timestamp);
        if (user.deposits.length == 0) {
            totalUsers++;
            users[up].referrals++;
            users[up].childs.push(msg.sender);
            for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (up == address(0)) break;
                users[up].totalStructure++;
                up = users[up].upline;
            }
            emit NewUser(msg.sender);
        }

        user.deposits.push(Deposit(amount, 0, uint40(block.timestamp)));
        user.depositsSum += amount;
        totalInvested = totalInvested.add(amount);
        totalDeposits++;

        _caclPerformance(msg.sender, amount);

        emit NewDeposit(msg.sender, amount);

        _pollDeposits(msg.sender, amount);
        if (pool_last_draw + 2 days < block.timestamp) {
            _drawPool();
        }
        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }

    }

    function _caclPerformance(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;
        if (up == address(0)) return;

        for (uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
            if(up == address(0)) break;
            users[up].performanceSum += _amount;
            up = users[up].upline;
        }
    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 2 / 100;

        address upline = users[_addr].upline;

        if (upline == address(0)) return;

        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for (uint8 i = 0; i < DIRECT_TOP; i++) {
            if (pool_top[i] == upline) break;

            if (pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if (pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for (uint8 j = i + 1; j < DIRECT_TOP; j++) {
                    if (pool_top[j] == upline) {
                        for (uint8 k = j; k <= DIRECT_TOP; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for (uint8 j = (DIRECT_TOP - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }
                pool_top[i] = upline;
                break;
            }
        }
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for (uint8 i = 0; i < pool_bonuses.length; i++) {
            if (pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / PERCENTS_DIVIDER;

            users[pool_top[i]].poolBonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }
        for (uint8 i = 0; i < DIRECT_TOP; i++) {
            pool_top[i] = address(0);
        }
    }

    function getPoolTop() external view returns(address[6] memory addr,uint[6] memory performace,uint[6] memory poolBonus){
        uint256 draw_amount = pool_balance / 5;
        for(uint8 i=0; i< 6; i++){
            if (pool_top[i] == address(0)) break;
            addr[i] = pool_top[i];
            performace[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
            poolBonus[i] = draw_amount * pool_bonuses[i] / PERCENTS_DIVIDER;
        }
    }


    function unWithdraw(address addr) public view returns (uint){
        User storage user = users[addr];
        if(!isActive(addr)){
            return 0;
        }
        Deposit memory deposit = user.deposits[user.deposits.length-1];

        uint256 maxPayOut = deposit.amount.mul(3);
        uint userPercentRate = getUserPercentRate(addr);

        uint256 totalAmount;
        uint256 dividends =  (deposit.amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
        .mul(block.timestamp.sub(user.checkpoint))
        .div(TIME_STEP);
        totalAmount+=dividends;
        totalAmount+=user.directBonus;
        totalAmount+=user.bonus;
        totalAmount+=user.poolBonus;

        if(deposit.withdrawn + totalAmount > maxPayOut){
            totalAmount = maxPayOut - deposit.withdrawn;
        }
        return totalAmount;
    }

    function withdraw() external returns (bool res){
        User storage user = users[msg.sender];
        require(user.deposits.length>0,'you have not invested');
        Deposit storage deposit = user.deposits[user.deposits.length-1];
        uint256 maxPayOut = deposit.amount.mul(3);
        require( deposit.withdrawn < maxPayOut, "User has no dividends");
        uint userPercentRate = getUserPercentRate(msg.sender);

        uint256 totalAmount;
        uint256 dividends =  (deposit.amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
        .mul(block.timestamp.sub(user.checkpoint))
        .div(TIME_STEP);
        if((deposit.withdrawn + dividends)>maxPayOut){
            dividends = maxPayOut.sub(deposit.withdrawn);
        }
        if(dividends > 0){
            deposit.withdrawn += dividends;
            totalAmount += dividends;
            refBonus(msg.sender,dividends);
        }

        if(deposit.withdrawn < maxPayOut && user.directBonus>0){
            uint256 directBonus = user.directBonus;
            if(deposit.withdrawn + directBonus > maxPayOut){
                directBonus = maxPayOut - deposit.withdrawn;
            }
            user.directBonus -= directBonus;
            deposit.withdrawn +=  directBonus;
            totalAmount +=  directBonus;
        }

        if(deposit.withdrawn < maxPayOut && user.bonus >0){
            uint256 bonus = user.bonus;
            if(deposit.withdrawn + bonus >maxPayOut){
                bonus = maxPayOut - deposit.withdrawn;
            }
            user.bonus -= bonus;
            deposit.withdrawn +=  bonus;
            totalAmount +=  bonus;
        }

        if(deposit.withdrawn < maxPayOut && user.poolBonus >0){
            uint256  poolBonus = user.poolBonus;
            if(deposit.withdrawn + poolBonus> maxPayOut){
                poolBonus = maxPayOut - deposit.withdrawn;
            }
            user.poolBonus -= poolBonus;
            deposit.withdrawn +=  poolBonus;
            totalAmount +=  poolBonus;
        }
        require(totalAmount > 0, "User has no dividends");

        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = uint40(block.timestamp);
        msg.sender.transfer(totalAmount);

        user.withdrawnSum += totalAmount;
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        if(contractPercent > BASE_PERCENT && getContractBalance() < CONTRACT_PERCENT_START_BALANCE){
            contractPercent = BASE_PERCENT;
        }
        emit Withdrawn(msg.sender, totalAmount);
        return true;
    }


    function refBonus(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < REFERRAL_PERCENTS.length; i++) {
            if(up == address(0)) break;

            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * REFERRAL_PERCENTS[i] / PERCENTS_DIVIDER;

                users[up].bonus += bonus;

                emit RefBonus(up, _addr, bonus);
            }
            up = users[up].upline;
        }
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getContractBalanceRate() internal view returns (uint) {
        uint contractBalance = address(this).balance;
        if (contractBalance < CONTRACT_PERCENT_START_BALANCE) {
            return BASE_PERCENT;
        }
        contractBalance = contractBalance.sub(CONTRACT_PERCENT_START_BALANCE);
        uint contractBalancePercent = BASE_PERCENT.add(contractBalance.div(CONTRACT_BALANCE_STEP).add(1));

        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }

    function getUserPercentRate(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        if (isActive(userAddress)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
            return contractPercent.add(timeMultiplier);
        } else {
            return contractPercent;
        }
    }


    function getUserDepositInfoByIndex(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
        User storage user = users[userAddress];
        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }

    function getUserTotalInvestAndWithdrawnForDeposits(address userAddress) public view returns(uint8 _length,uint256 _totalAmountForDeposits,uint256 _totalWithdrawn) {
        User memory user = users[userAddress];
        uint256 totalAmountForDeposits;
        uint256 totalWithdrawnForDeposits;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            totalAmountForDeposits = totalAmountForDeposits.add(user.deposits[i].amount);
            totalWithdrawnForDeposits = totalWithdrawnForDeposits.add(user.deposits[i].withdrawn);
        }
        return (uint8(user.deposits.length),totalAmountForDeposits,totalWithdrawnForDeposits);
    }

    function isActive(address userAddress) public view returns (bool res) {
        User storage user = users[userAddress];
        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length - 1].withdrawn < user.deposits[user.deposits.length - 1].amount.mul(3)) {
                return true;
            }
        }
    }





    modifier onlyOwner() {
        require(msg.sender == owner, 'only owner can execute this method');
        _;
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}