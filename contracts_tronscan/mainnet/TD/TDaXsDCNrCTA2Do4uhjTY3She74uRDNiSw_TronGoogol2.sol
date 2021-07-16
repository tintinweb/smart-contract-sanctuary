//SourceUnit: planB.sol

pragma solidity 0.5.14;

contract capacitor{
    function decharge(uint256 money) public returns(uint256);
    function charge() payable public;
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner; 
    }
}

contract Pausable is Ownable{
    event Paused(address account);
    event Unpaused(address account);

    bool private _charged;
    bool private _paused;
    address payable _capacitor;
    
    modifier whenNotPaused() {
        require(!_paused || msg.sender == owner(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }
    
    constructor () internal {
        _paused = false;
        _charged = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function isCharging() internal view returns (bool) {
        return _charged;
    }

    function setCapacitor(address payable cap) public onlyOwner{
        require(cap != address(0), "Invalid Address");
        _capacitor = cap;
    }
    
    function setCharged() public onlyOwner{
        _charged = true;
    }
    
    function setUnCharged() public onlyOwner{
        _charged = false;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
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

contract TronGoogol2 is Pausable{
    using SafeMath for uint256;

    uint256 public totalReferral;
    uint256 public totalReferralEarn;
    uint256 public totalDeposit;
    uint256 public totalWithdrawn;
    address private accessAddress;
    address[] private addressList;
    address payable public mainWallet;
    address payable public DWallet;
    address payable public stakeWallet;
    address payable public personalWallet1;
    address payable public personalWallet2;
    address payable public promotionWallet;
    
    
    uint256[] private MIN_DEPOSIT = [100 trx, 1000 trx, 5000 trx, 20000 trx]; 
    uint256[] private PROFITS_PERCENTS = [25, 23, 22, 2]; //  plan 1 : 2.5% - plan 2: 2.3% - plan 3: 2.2% - plan 4: 2 - plan 
    uint256[] private FINAL_PROFIT_TIME = [90 days, 120 days, 150 days, 180 days]; //in seconds for each plan
    uint256 private DAY_LENGTH_IN_SECONDS = 86400; // 1 day
    uint256 private adminPercent;
    uint256 private INSURED_PERCENT = 50;
    uint256 private aAFA; // available Amount For Admin
    uint256 private ADMIN_PERCENT = 5; 
    uint256[] private REF_PERCENT = [4, 3, 2, 1];   //4%, 3%, 2%, 1%
    uint256[] private MAX_WITHDRAW = [25000 trx, 50000 trx, 75000 trx, 100000 trx] ;
    uint256[] private PERCENTS = [5, 2, 6]; // 0 - Dwallet
    uint256 private normalBalance;
    uint256 private povertyBalance;
    uint256 private CAPACITY_PERCENT = 0;
    uint256 private CAPACITY_EXTRA_PERCENT = 0;
    uint256 private capacitorTotal;
    uint256 private capacitorExtraMoney;
    uint256 private lastDechargeTime;
    uint256 private previousBalance;
    uint256 private DECHARGE_TIMER_INTERVAL = 1800;
    uint256 private LOSS_RECOVERY_PERCENT = 0;
    uint256 private MIN_RECOVERY_AMOUNT = 0;
    uint256[] private EXTRA_BONUS = [0.1 trx, 0.1 trx, 0.1 trx]; // HoldBonus, FundBonus, RefferralBonus
    uint private BonusLimit = 1000000 trx; // Fund and Referral 
    
    mapping (address => investor) investors; 
    uint public DWalletBalance;

    struct invest{
        uint8[] planType; // plan 0 - plan 1 - plan 2 - plan 3
        uint256[] startedTime;
        uint256[] lastRefreshTime;
        uint256[] investedMoney;
        bool[] finished;
    }

    struct investor{
        uint256 totalInvestedMoney;
        uint256 withdrableMoney;
        uint256 lastWithdrawTime;
        uint256 collectedMoney;
        uint256 currentPlan;
        invest invests;
        address[] referrals;
        uint256[] referralsCount;
        uint256[] referralEarn;
        uint256 referralTotalDeposit;
        address referrer;
        bool initiated;
    }
    
    mapping(address => uint) public virtualWithdrwal;
    event Registration(address indexed addr, address indexed referrer, uint Time);
    event RefEarnings(address indexed receiver, address indexed caller, uint tier, uint refEarn, uint Time);
    event Deposited(address indexed addr, address indexed referrer, uint amount, uint planType, uint Time);
    event Withdrawn(address indexed addr, uint256 amount, uint Time);
    event earnedHoldBonus(address indexed addr, uint256 amount, uint Time);
    event earnedFundBonus(address indexed addr, uint256 amount, uint Time);
    event earnedRefBonus(address indexed addr, uint256 amount, uint Time);     event DechargeCapacitor(uint256 amount);
    event ChargeCapacitor(uint256 amount);

    constructor(address payable wallet, address payable staWallet, address payable cap, address payable _personal1, address payable _personal2, address payable _promotion) public {
        mainWallet = wallet;
        stakeWallet = staWallet;
        personalWallet1 = _personal1;
        personalWallet2 = _personal2;
        promotionWallet = _promotion;
        
        investors[mainWallet].initiated = true;
        addressList.push(mainWallet);
        _capacitor = cap;
        investors[mainWallet].referrer = mainWallet;
        investors[mainWallet].referralsCount = new uint256[](4);//level =0 means children , level =1 means grandchilds
        investors[mainWallet].referralEarn = new uint256[](4);
    }


    function() external payable{
        normalBalance = normalBalance.add(msg.value.mul(70).div(100));
        povertyBalance = povertyBalance.add(msg.value.mul(30).div(100));
        emit DechargeCapacitor(msg.value);
    }

    function _registration(address user, address ref) internal {
        require(investors[ref].initiated , "Inviter address does not exist in the TrustTron network!");
        investor storage referrer = investors[ref];
        referrer.referrals.push(user);
        investors[user].referrer = ref;
        investors[user].initiated = true;
        addressList.push(user);
        totalReferral = totalReferral.add(1);

        if (referrer.referralsCount.length == 0){
            referrer.referralsCount = new uint256[](4); //level =0 means children , level =1 means grandchilds
            referrer.referralEarn = new uint256[](4);
        }
        
        address refWallet = ref;
        investors[refWallet].referralsCount[0] = investors[refWallet].referralsCount[0].add(1);
        refWallet = investors[refWallet].referrer;

        uint256 level = 1;
        
        while (level < 4){
            
            if(refWallet != mainWallet){
                investors[refWallet].referralsCount[level] = investors[refWallet].referralsCount[level].add(1);
                refWallet = investors[refWallet].referrer;
            }
            
            level = level.add(1);
            
        }
        emit Registration(user, ref, now);
    }

    function _updateReferralBalance(address referrer, uint256 amount) internal {
        uint256 level = 0;
        uint256 counter = 0;
        address refWallet = referrer;
        
        while(counter < 4) {
            uint256 refValue = amount.mul(REF_PERCENT[counter]).div(100);
            investors[refWallet].referralEarn[level] = investors[refWallet].referralEarn[level].add(refValue);
            emit RefEarnings(refWallet, msg.sender, level, refValue, now);
            investors[refWallet].withdrableMoney = investors[refWallet].withdrableMoney.add(refValue);
            investors[refWallet].referralTotalDeposit = investors[refWallet].referralTotalDeposit.add(amount);
            totalReferralEarn = totalReferralEarn.add(refValue);
            refWallet = investors[refWallet].referrer;
            if(refWallet != mainWallet){    
                level = level.add(1);
            }
            counter = counter.add(1);
        }
    }

    function refresh(address user) internal {
        invest storage invests = investors[user].invests;
        uint256 profit = 0;
        uint256 i = 0;
        
        while (i < invests.planType.length) {
            uint256 planType = invests.planType[i];
            if(invests.lastRefreshTime[i].sub(invests.startedTime[i]) <  FINAL_PROFIT_TIME[planType]){
                uint256 nowOrEndOfProfit = now;
                if (now > invests.startedTime[i].add(FINAL_PROFIT_TIME[planType])){
                    nowOrEndOfProfit = invests.startedTime[i].add(FINAL_PROFIT_TIME[planType]);
                }
                uint256 timeSpent = nowOrEndOfProfit.sub(invests.lastRefreshTime[i]);
                invests.lastRefreshTime[i] = now;
                profit = profit.add(invests.investedMoney[i].mul(timeSpent).mul(PROFITS_PERCENTS[planType]).div(DAY_LENGTH_IN_SECONDS).div(1000));
            }

            if(invests.lastRefreshTime[i].sub(invests.startedTime[i]) >  FINAL_PROFIT_TIME[planType]){
                invests.finished[i] = true;   
            }

            i = i.add(1);
        }
        
        investors[user].withdrableMoney = investors[user].withdrableMoney.add(profit);
    }


    function getWithdrawStat() public view returns (uint256){
        address addr = msg.sender;
        require(investors[addr].initiated, "Reinvester address does not exist in the TrusTron!");

        invest memory invests = investors[addr].invests;
        uint256 profit = 0;
        uint256 i = 0;
        
        while (i < invests.planType.length) {
            uint256 planType = invests.planType[i];
            if(invests.lastRefreshTime[i].sub(invests.startedTime[i]) <  FINAL_PROFIT_TIME[planType]){
                uint256 nowOrEndOfProfit = now;
                if (now > invests.startedTime[i].add(FINAL_PROFIT_TIME[planType])){
                    nowOrEndOfProfit = invests.startedTime[i].add(FINAL_PROFIT_TIME[planType]);
                }
                uint256 timeSpent = nowOrEndOfProfit.sub(invests.lastRefreshTime[i]);
                
                profit = profit.add(invests.investedMoney[i].mul(timeSpent).mul(PROFITS_PERCENTS[planType]).div(DAY_LENGTH_IN_SECONDS).div(1000));
            }
            i = i.add(1);
        }
        return investors[addr].withdrableMoney.add(profit);
    }

    function deposit(address referrer, uint8 planType) public whenNotPaused payable  {
        //require(now > 1597325400, "Investment time not reached!"); // for live deployment
        require(planType < 4, "The box must be chosen correctly!");
        uint256 amount = msg.value;
        require(amount >= MIN_DEPOSIT[planType], "Your investment amount is less than the minimum amount!");
        address addr = msg.sender;
        require(!investors[addr].initiated || investors[addr].referrer == referrer, "Referrer is not Valid!");

        if(referrer == address(0) || !investors[referrer].initiated){
            referrer = mainWallet;
        }

        if (!investors[addr].initiated){
            _registration(addr,referrer);
        }
        
        if(investors[addr].currentPlan == 0)
            investors[addr].currentPlan = planType;
        else if(investors[addr].currentPlan<planType)
            investors[addr].currentPlan = planType;
        
        investors[addr].invests.planType.push(planType);
        investors[addr].invests.startedTime.push(now);
        investors[addr].invests.investedMoney.push(amount);
        investors[addr].invests.lastRefreshTime.push(now);
        investors[addr].invests.finished.push(false);
        
        investors[addr].totalInvestedMoney = investors[addr].totalInvestedMoney.add(amount);
        totalDeposit = totalDeposit.add(amount);
        
        DWalletBalance += (amount.mul(PERCENTS[0]).div(100));
        personalWallet1.transfer((amount.mul(2.25 trx)).div(100 trx));
        personalWallet2.transfer((amount.mul(2.25 trx)).div(100 trx));
        promotionWallet.transfer((amount.mul(0.5 trx)).div(100 trx)); 

        _updateReferralBalance(investors[addr].referrer, amount);

        if(isCharging())
        {
            capacitor c = capacitor(_capacitor);
            uint256 chargeAmount=amount.mul(82).div(100).mul(CAPACITY_PERCENT).div(100);
            c.charge.value(chargeAmount)();
            emit ChargeCapacitor(chargeAmount);

            capacitorTotal = capacitorTotal.add(chargeAmount); 
            capacitorExtraMoney = capacitorExtraMoney.add(amount.mul(82).div(100).mul(CAPACITY_EXTRA_PERCENT).div(100));
        
        }
            

        adminPercent = adminPercent.add(amount.mul(ADMIN_PERCENT).div(100));
        investors[mainWallet].withdrableMoney = investors[mainWallet].withdrableMoney.add(amount.mul(ADMIN_PERCENT).div(100));
        normalBalance = normalBalance.add(amount.mul(100-ADMIN_PERCENT-PERCENTS[0]-PERCENTS[1]-PERCENTS[2]-1).div(100).mul(70).div(100));
        povertyBalance = povertyBalance.add(amount.mul(100-ADMIN_PERCENT-PERCENTS[0]-PERCENTS[1]-PERCENTS[2]-1).div(100).mul(30).div(100));
        aAFA = aAFA.add(amount.mul(10).div(100));

        emit Deposited(addr, investors[addr].referrer, amount, planType, now);
    } 
    
   

    function withdraw() public whenNotPaused {
        address payable addr = msg.sender;
        refresh(addr); 
        uint amount = investors[addr].withdrableMoney;
        
        if(msg.sender != mainWallet) {
            
            if(amount <= MAX_WITHDRAW[investors[addr].currentPlan]) {
                investors[addr].withdrableMoney=0;
            }
            else {
                investors[addr].withdrableMoney = investors[addr].withdrableMoney.sub(MAX_WITHDRAW[investors[addr].currentPlan]);
                amount = MAX_WITHDRAW[investors[addr].currentPlan];
            }
            
            uint _days = now.sub(investors[addr].lastWithdrawTime).div(DAY_LENGTH_IN_SECONDS);
        
            if(_days == 0)
                require(virtualWithdrwal[addr].add(amount) <= MAX_WITHDRAW[investors[addr].currentPlan], "Your amount request is more than withdraw limit!");
            else{
                require(amount <= MAX_WITHDRAW[investors[addr].currentPlan], "Your amount request is more than withdraw limit!");
                virtualWithdrwal[addr] = 0;
                investors[addr].lastWithdrawTime = now;
            }
        }
        
        amount = _calculateInternalBalance(amount,addr); 
        
        investors[addr].collectedMoney = investors[addr].collectedMoney.add(amount); 
        
        uint holdBonus = getHoldBonus(addr); // Hold Bonus
        uint fundBonus = getFundBonus(addr); // Fund Bonus
        uint refBonus = getRefferralBonus(addr); // RefBonus
        virtualWithdrwal[addr] = virtualWithdrwal[addr].add(amount);
        
        if(holdBonus > 0) {
            require((addr).send(holdBonus),"Hold Bonus Transaction Failed");
            emit earnedHoldBonus(addr, holdBonus, now);
        }
        
        
        if(fundBonus > 0) {
            require((addr).send(fundBonus),"Hold Bonus Transaction Failed");
            emit earnedFundBonus(addr, fundBonus, now);
         }
         
         
          
        if(refBonus > 0) {
            require((addr).send(refBonus),"Hold Bonus Transaction Failed"); 
            emit earnedRefBonus(addr, refBonus, now);
        }

        
        totalWithdrawn = totalWithdrawn.add(amount);
        
        if(msg.sender == mainWallet) {
            uint256 finalMainAmount = 0;
            uint256 finalAmount = amount;
            if(amount > adminPercent){
                finalAmount = adminPercent;
                finalMainAmount = amount.sub(adminPercent);
            }
            stakeWallet.transfer(finalAmount.mul(PERCENTS[1]).div(ADMIN_PERCENT));
            mainWallet.transfer(finalAmount.mul(PERCENTS[2]).div(ADMIN_PERCENT).add(finalMainAmount));
            adminPercent = adminPercent.sub(finalAmount);
        }
        else {
            addr.transfer(amount);
        }

        
        if (now.sub(lastDechargeTime) > DECHARGE_TIMER_INTERVAL) {
            
            if(isCharging())
            {
                if (capacitorTotal > 0 && previousBalance > address(this).balance){
                    uint256 diff =  previousBalance.sub(address(this).balance);
                    uint256 recoveryAmount = diff.mul(LOSS_RECOVERY_PERCENT).div(100);
                    if (recoveryAmount >= MIN_RECOVERY_AMOUNT){
                        capacitor c = capacitor(_capacitor);
                        uint256 returnedMoney = c.decharge(recoveryAmount);
                        
                        if(returnedMoney < capacitorTotal)
                            capacitorTotal = capacitorTotal.sub(returnedMoney);
                        else{
                            capacitorTotal = 0;
                        }
                    }
                } 
            }
            lastDechargeTime = now;
            previousBalance = address(this).balance;
        }
        
        emit Withdrawn(addr, amount, now);
    }
    
    
    function getHoldBonus(address user) public view returns(uint)  {
        invest storage invests = investors[user].invests;
        uint i=0;
        uint holdProfit = 0;
        
        while (i < invests.planType.length){
            uint256 planType = invests.planType[i];
            if(invests.lastRefreshTime[i].sub(invests.startedTime[i]) <  FINAL_PROFIT_TIME[planType]){
                uint256 nowOrEndOfProfit = now;
                if (now > invests.startedTime[i].add(FINAL_PROFIT_TIME[planType])){
                    nowOrEndOfProfit = invests.startedTime[i].add(FINAL_PROFIT_TIME[planType]);
                }
                uint256 timeSpent = nowOrEndOfProfit.sub(invests.lastRefreshTime[i]);
                
                if(timeSpent >= 2 days)
                    holdProfit = holdProfit.add(invests.investedMoney[i].mul(timeSpent).mul(EXTRA_BONUS[0]).div(DAY_LENGTH_IN_SECONDS).div(100 trx));
            }


            i = i.add(1);
        }
        
        return holdProfit; 
    }
    
    
    function getFundBonus(address user) public view returns(uint){
        invest storage invests = investors[user].invests;
        uint fundProfit = 0;
        uint i=0;
        
        if(totalDeposit > (BonusLimit)) {
            uint profit = 0;
           
            while (i < invests.planType.length){
                uint8 planType = invests.planType[i];
                if(invests.lastRefreshTime[i].sub(invests.startedTime[i]) <  FINAL_PROFIT_TIME[planType]){
                    uint256 nowOrEndOfProfit = now;
                    if (now > invests.startedTime[i].add(FINAL_PROFIT_TIME[planType])){
                        nowOrEndOfProfit = invests.startedTime[i].add(FINAL_PROFIT_TIME[planType]);
                    }
                    uint256 timeSpent = nowOrEndOfProfit.sub(invests.lastRefreshTime[i]);
                    
                    if(timeSpent >= DAY_LENGTH_IN_SECONDS)
                        profit = profit.add(invests.investedMoney[i].mul(timeSpent).mul(EXTRA_BONUS[1]).div(DAY_LENGTH_IN_SECONDS).div(100 trx));
                }
    
    
                i = i.add(1);
            }
            
            
            if(profit > 0 &&  totalDeposit.div(BonusLimit) >= 1) 
                fundProfit = fundProfit.add(profit.mul(totalDeposit.div(BonusLimit)));
        }

        
        return fundProfit;
       
        
    }
    
    
    
    function getRefferralBonus(address user) public view returns(uint) {
        invest storage invests = investors[user].invests;
        uint refProfit = 0;
        uint i=0;
        
        if(investors[user].referralTotalDeposit > (BonusLimit)) {
            uint profit = 0;
           
            while (i < invests.planType.length){
                uint8 planType = invests.planType[i];
                if(invests.lastRefreshTime[i].sub(invests.startedTime[i]) <  FINAL_PROFIT_TIME[planType]){
                    uint256 nowOrEndOfProfit = now;
                    if (now > invests.startedTime[i].add(FINAL_PROFIT_TIME[planType])){
                        nowOrEndOfProfit = invests.startedTime[i].add(FINAL_PROFIT_TIME[planType]);
                    }
                    uint256 timeSpent = nowOrEndOfProfit.sub(invests.lastRefreshTime[i]);
                    
                    if(timeSpent >= DAY_LENGTH_IN_SECONDS)
                        profit = profit.add(invests.investedMoney[i].mul(timeSpent).mul(EXTRA_BONUS[2]).div(DAY_LENGTH_IN_SECONDS).div(100 trx));
                }
    
    
                i = i.add(1);
            }
            
            
            if(profit > 0 &&  investors[user].referralTotalDeposit.div(BonusLimit) >= 1) 
                refProfit = refProfit.add(profit.mul(investors[user].referralTotalDeposit.div(BonusLimit)));
        }

        return refProfit; 
    }
    
    
   
    function setAccessAddress(address accessAddr) public onlyOwner{
        require(accessAddr != address(0), "Invalid Address");
        accessAddress  = accessAddr;
    }

    function getAddressList() public view onlyOwner returns(address[] memory){
        return addressList;
    }

    function _calculateInternalBalance(uint256 amount, address user) internal returns (uint256) {
        uint256 payableAmount = 0;

        if(user == mainWallet) {
            
            if(amount < investors[mainWallet].withdrableMoney){
                return amount;
            }

            uint256 rem = amount.sub(investors[mainWallet].withdrableMoney);
            if (aAFA < rem){
                rem = aAFA;
            }
            
            aAFA = aAFA.sub(rem);
            if(normalBalance > rem){
                normalBalance = normalBalance.sub(rem);
                return rem.add(investors[mainWallet].withdrableMoney);
            }

            uint256 remNormal = rem.sub(normalBalance);
            rem = normalBalance;
            normalBalance = 0;

            if(povertyBalance > remNormal){
                povertyBalance = povertyBalance.sub(remNormal);
                return remNormal.add(rem).add(investors[mainWallet].withdrableMoney);
            }

            remNormal = povertyBalance;
            povertyBalance = 0;
            return remNormal.add(rem).add(investors[mainWallet].withdrableMoney);
        }

       
        if (amount <= normalBalance){
            normalBalance = normalBalance.sub(amount);
            return amount;
        }

        payableAmount = normalBalance;
        normalBalance = 0;
    
        amount = amount.sub(payableAmount);


        uint256 insuredMoney = investors[user].totalInvestedMoney.mul(82).div(100).mul(INSURED_PERCENT).div(100);

        if(insuredMoney >= investors[user].collectedMoney.add(payableAmount)) {
            
            uint256 remained = insuredMoney.sub(investors[user].collectedMoney.add(payableAmount));
            
            if (amount > remained){
                amount = remained;
            }
            //require(povertyBalance >= amount,"Contract run out of Money :(");
            
            if(povertyBalance >= amount) {
                povertyBalance = povertyBalance.sub(amount);
                payableAmount = payableAmount.add(amount);
            }
            else {
                revert("Contract run out of money :(");
            }
        }
        
        //require(payableAmount > 0,'you cannot withdraw more than 50% of your invested money due to contract balance limit'); 
        
        if(payableAmount > 0)
            return payableAmount;
            
        else {
            revert("You cannot withdraw more than 50% of your invested money due to contract balance limit");
        }
    }
     
    function getInvestorStat(address user) public view returns (uint256[] memory, uint256[] memory, address[] memory,
                         address, uint256, uint256, uint256, uint256, uint256, uint256) {
                             
        investor memory inv =investors[user];
        require(user == msg.sender || msg.sender == owner() || msg.sender == accessAddress, 'Your access to stat is restricted!');
        uint256 withdrableMoney = 0;
        
        if(inv.initiated) {
            withdrableMoney = getWithdrawStat();   
        }
        
        return (inv.referralsCount, inv.referralEarn, inv.referrals,
                inv.referrer, withdrableMoney, inv.totalInvestedMoney, inv.collectedMoney,
                inv.lastWithdrawTime , totalDeposit, inv.currentPlan );
    }
    
    function getInvestsStat(address user) public view returns (uint256[] memory, uint8[] memory, uint256[] memory, bool[] memory) {
        investor memory inv = investors[user];

        require(user == msg.sender || msg.sender == owner() || msg.sender == accessAddress,'your access to stat is restricted!');
        
        return (inv.invests.investedMoney,
            inv.invests.planType,
            inv.invests.startedTime,
            inv.invests.finished);
    }

    function configCapacitor (uint percent, uint256 extraPercent,uint256 interval ,uint256 loss, uint256 minAmount) public onlyOwner{
        require(percent > 0 && percent <= 100, "Invalid capacity percentage");
        require(extraPercent > 0 && extraPercent <= 100, "Invalid capacity extra percentage");
        require(loss > 0 && loss <= 100, "Invalid loss percentage");
        
        CAPACITY_PERCENT = percent;
        CAPACITY_EXTRA_PERCENT = extraPercent;
        DECHARGE_TIMER_INTERVAL = interval;
        LOSS_RECOVERY_PERCENT = loss;
        MIN_RECOVERY_AMOUNT = minAmount;
    }
    
    function sendExtraMoneyToCapacitor() public onlyOwner{
        capacitor c = capacitor(_capacitor);
        c.charge.value(capacitorExtraMoney)();
        capacitorTotal = capacitorTotal.add(capacitorExtraMoney);        
        capacitorExtraMoney = 0;
    }

    function setInsuredPercent(uint256 percent) public onlyOwner{
        require(percent > 0 && percent <=100, "Invalid insure percentage");
        
        INSURED_PERCENT = percent;
    }

    function getOveralStat() public view onlyOwner returns(uint256,uint256,uint256,uint256,address,uint256,uint256,uint256,uint256,uint256,uint256,bool,address){
        bool isCH = isCharging();
        
        return (totalReferral, totalReferralEarn, totalDeposit, totalWithdrawn, accessAddress, adminPercent, aAFA, normalBalance, povertyBalance, capacitorTotal, capacitorExtraMoney, isCH , _capacitor);
    }
}