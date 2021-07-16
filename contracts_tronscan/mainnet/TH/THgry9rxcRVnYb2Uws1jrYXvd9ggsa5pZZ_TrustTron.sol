//SourceUnit: TrustTron.sol

pragma solidity ^0.5.4;

/*****
******
Developers Signature(MD5 Hash) : d6b0169c679a33d9fb19562f135ce6ee
website : trusttron.com
******
*****/

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
        _capacitor = cap;
    }
    function setCharged() public onlyOwner{
        _charged = true;
    }
    function setUnCharged() public onlyOwner{
        _charged = false;
    }
    
    modifier whenNotPaused() {
        require(!_paused || msg.sender == owner(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
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
        return c;
    }
}


contract TrustTron is Pausable{
    using SafeMath for uint256;

    uint256 public totalReferral;
    uint256 public totalReferralEarn;
    uint256 public totalDeposit;
    uint256 public totalWithdrawn;
    address private accessAddress;
    address[] private addressList;
    address payable private mainWallet;
    address payable private DWallet;
    address payable private stakeWallet;
    
    uint256[] private MIN_DEPOSIT = [10000000, 1000000000, 5000000000, 25000000000]; 

    uint256[] private PROFITS_PERCENTS = [30, 32, 36, 39, 41]; //  plan 1 : 3% - plan 2: 3.2% - plan 3: 3.6% - plan 4: 3.9 - plan reinvest :4.1%
    uint256[] private FINAL_PROFIT_TIME = [6336000,6075000,5520000,5316923]; //in seconds for each plan (p1 : 220% , p2 : 225% , p3 : 230% , p4 : 240%)
    uint256 private DAY_LENGTH_IN_SECONDS = 86400;
    uint256 private adminPercent;
    uint256 private INSURED_PERCENT = 45;
    uint256 private aAFA; // available Amount For Admin
    uint256 private ADMIN_PERCENT = 8; 
    uint256[] private REF_PERCENT = [5, 3, 1];   //5%, 3%, 1%
    uint256 private MAX_WITHDRAW = 50000000000;
    uint256[] private PERCENTS = [1, 2, 6];
    uint256 private normalBalance;
    uint256 private povertyBalance;
    uint256 private CAPACITY_PERCENT = 6;
    uint256 private CAPACITY_EXTRA_PERCENT = 0;
    uint256 private capacitorTotal;
    uint256 private capacitorExtraMoney;
    uint256 private lastDechargeTime;
    uint256 private previousBalance;
    uint256 private DECHARGE_TIMER_INTERVAL = 1800;
    uint256 private LOSS_RECOVERY_PERCENT = 20;
    uint256 private MIN_RECOVERY_AMOUNT = 0;

    mapping (address => investor) investors;

    struct invest{
        uint256[] planType; // plan 0 - plan 1 - plan 2 - plan 3
        uint256[] startedTime;
        uint256[] lastRefreshTime;
        uint256[] investedMoney;
        bool[] finished;
    }

    struct investor{
        uint256 totalInvestedMoney;
        uint256 withdrableMoney;
        uint256 lastWithdrawTime;
        uint256 lastReinvestedTime;
        uint256 collectedMoney;        
        invest invests;
        address[] referrals;
        uint256[] referralsCount;
        uint256[] referralEarn;
        address referrer;
        bool initiated;
        invest reInvest;
    }

    event Registration(address indexed addr, address indexed referrer);
    event Deposited(address indexed addr, address indexed referrer, uint256 amount, uint256 planType);
    event Withdrawn(address indexed addr, uint256 amount);
    event DechargeCapacitor(uint256 amount);
    event ChargeCapacitor(uint256 amount);

    constructor(address payable wallet, address payable devWallet, address payable staWallet, address payable cap) public {
        mainWallet = wallet;
        DWallet = devWallet;
        stakeWallet = staWallet;
        investors[mainWallet].initiated = true;
        addressList.push(mainWallet);
        _capacitor = cap;
        investors[mainWallet].referrer = mainWallet;
        investors[mainWallet].referralsCount = new uint256[](3);//level =0 means children , level =1 means grandchilds
        investors[mainWallet].referralEarn = new uint256[](3);
    }


    function() external payable{
        normalBalance = normalBalance.add(msg.value.mul(70).div(100));
        povertyBalance = povertyBalance.add(msg.value.mul(30).div(100));
        emit DechargeCapacitor(msg.value);
    }

    function _registration(address addr, address ref) internal {
        require(investors[ref].initiated , "Inviter address does not exist in the TrustTron network!");
        investor storage referrer = investors[ref];
        referrer.referrals.push(addr);
        investors[addr].referrer = ref;
        investors[addr].initiated = true;
        addressList.push(addr);
        totalReferral = totalReferral.add(1);

        if (referrer.referralsCount.length == 0){
            referrer.referralsCount = new uint256[](3);//level =0 means children , level =1 means grandchilds
            referrer.referralEarn = new uint256[](3);
        }

        
        
        address refWallet = ref;
        investors[refWallet].referralsCount[0] = investors[refWallet].referralsCount[0].add(1);
        refWallet = investors[refWallet].referrer;

        uint256 level = 1;
        while (level < 3){
            if(refWallet != mainWallet){
                investors[refWallet].referralsCount[level] = investors[refWallet].referralsCount[level].add(1);
                refWallet = investors[refWallet].referrer;
            }
            level = level.add(1);
        }
        emit Registration(addr, ref);
    }

    function _updateReferralBalance(address referrer, uint256 amount) internal {
        uint256 level = 0;
        uint256 counter = 0;
        address refWallet = referrer;
        
        while(counter < 3){
            uint256 refValue = amount.mul(REF_PERCENT[counter]).div(100);
            investors[refWallet].referralEarn[level] = investors[refWallet].referralEarn[level].add(refValue);
            investors[refWallet].withdrableMoney = investors[refWallet].withdrableMoney.add(refValue);
            totalReferralEarn = totalReferralEarn.add(refValue);
            refWallet = investors[refWallet].referrer;
            if(refWallet != mainWallet){    
                level = level.add(1);
            }
            counter = counter.add(1);
        }
    }

    function refresh(address addr) internal {
        invest storage invests = investors[addr].invests;
        uint256 profit = 0;
        uint256 i = 0;
        if (investors[addr].reInvest.planType.length == 1){
            uint256 timeSpent = now.sub(investors[addr].reInvest.lastRefreshTime[0]);
            profit = profit.add(investors[addr].reInvest.investedMoney[0].mul(timeSpent).mul(PROFITS_PERCENTS[4]).div(DAY_LENGTH_IN_SECONDS).div(1000));
            investors[addr].reInvest.lastRefreshTime[0] = now;
        }
        while (i < invests.planType.length){
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
        investors[addr].withdrableMoney = investors[addr].withdrableMoney.add(profit);
    }


    function getWhithdrableStat() public view returns (uint256){
        address addr = msg.sender;
        require(investors[addr].initiated, "Reinvester address does not exist in the TrusTron!");

        invest memory invests = investors[addr].invests;
        uint256 profit = 0;
        uint256 i = 0;
        if (investors[addr].reInvest.planType.length == 1){
            uint256 timeSpent = now.sub(investors[addr].reInvest.lastRefreshTime[0]);
            profit = profit.add(investors[addr].reInvest.investedMoney[0].mul(timeSpent).mul(PROFITS_PERCENTS[4]).div(DAY_LENGTH_IN_SECONDS).div(1000));
        }
        while (i < invests.planType.length){
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

    function reInvest(uint256 amount) public whenNotPaused {
        address addr = msg.sender;
        
        require(investors[addr].initiated, "Reinvester address does not exist in the TrusTron!");
        require(now.sub(investors[addr].lastReinvestedTime) >= DAY_LENGTH_IN_SECONDS, "Reinvesting is allowed once a day!");
        investors[addr].lastReinvestedTime = now;

        refresh(addr);
        require(amount <= investors[addr].withdrableMoney , "Not enough withdrable money to invest!");
        
        investors[addr].withdrableMoney = investors[addr].withdrableMoney.sub(amount);

        if(investors[addr].reInvest.planType.length == 0){
            investors[addr].reInvest.investedMoney.push(amount);
            investors[addr].reInvest.planType.push(4);
            investors[addr].reInvest.lastRefreshTime.push(now);
        }
        else
        {
            investors[addr].reInvest.investedMoney[0] = investors[addr].reInvest.investedMoney[0].add(amount) ;
        }

        emit Deposited(addr, investors[addr].referrer, amount, 4);
    }

    function deposit(address referrer, uint256 planType) public whenNotPaused payable  {
        //require(now > 1597325400, "Investment time not reached!");
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
        
        
        investors[addr].invests.planType.push(planType);
        investors[addr].invests.startedTime.push(now);
        investors[addr].invests.investedMoney.push(amount);
        investors[addr].invests.lastRefreshTime.push(now);
        investors[addr].invests.finished.push(false);
        
        investors[addr].totalInvestedMoney = investors[addr].totalInvestedMoney.add(amount);
        totalDeposit = totalDeposit.add(amount);
        
        DWallet.transfer(amount.mul(PERCENTS[0]).div(100));
        

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

        emit Deposited(addr, investors[addr].referrer, amount, planType);
    }

    function withdraw(uint256 amount) public whenNotPaused{
        address payable addr = msg.sender;
        require(msg.sender == mainWallet || amount <= MAX_WITHDRAW, "Your amount request is more than withdraw limit!");
        require(msg.sender == mainWallet || now.sub(investors[addr].lastWithdrawTime) >= DAY_LENGTH_IN_SECONDS, "withdraw is allowd once a day!");
        investors[addr].lastWithdrawTime = now;

        refresh(addr);
        uint256 balance = investors[addr].withdrableMoney;
        require(amount <= balance || addr ==  mainWallet , "Not enough withdrable money to withdraw!");
        
        amount = _calculateInternalBalance(amount,addr);
        investors[addr].collectedMoney = investors[addr].collectedMoney.add(amount);
        if(investors[addr].withdrableMoney<amount){
            investors[addr].withdrableMoney=0;
        }else{
            investors[addr].withdrableMoney = balance.sub(amount);
        }
        totalWithdrawn = totalWithdrawn.add(amount);
        if(msg.sender == mainWallet){
            uint256 finalMainAmount = 0;
            uint256 finalAmount = amount;
            if(amount > adminPercent){
                finalAmount = adminPercent;
                finalMainAmount = amount.sub(adminPercent);
            }
            stakeWallet.transfer(finalAmount.mul(PERCENTS[1]).div(ADMIN_PERCENT));
            mainWallet.transfer(finalAmount.mul(PERCENTS[2]).div(ADMIN_PERCENT).add(finalMainAmount));
            adminPercent = adminPercent.sub(finalAmount);
        }else{
            addr.transfer(amount);
        }

        
        if (now.sub(lastDechargeTime) > DECHARGE_TIMER_INTERVAL){
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
        emit Withdrawn(addr, amount);
    }
   
    function setAccessAddress(address adre) public onlyOwner{
        accessAddress  = adre;
    }

    function getAddressList() public view onlyOwner returns(address[] memory){
        return addressList;
    }

    function _calculateInternalBalance(uint256 amount, address addr) internal returns (uint256){
        uint256 payableAmount = 0;

        if(addr == mainWallet){
            
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


        uint256 insuredMoney = investors[addr].totalInvestedMoney.mul(82).div(100).mul(INSURED_PERCENT).div(100);

        if(insuredMoney >= investors[addr].collectedMoney.add(payableAmount)){
            uint256 remained = insuredMoney.sub(investors[addr].collectedMoney.add(payableAmount));
            if (amount > remained){
                amount = remained;
            }
            require(povertyBalance >= amount,"Contract run out of Money :(");

            povertyBalance = povertyBalance.sub(amount);
            payableAmount = payableAmount.add(amount);
        }
        require(payableAmount > 0,'you cannot withdraw more than 45% of your invested money due to contract balance limit'); 
        return payableAmount;
    }
     
    function getInvestorStat(address addr) public view returns (uint256[] memory, uint256[] memory, address[] memory,
                         address, uint256, uint256, uint256, uint256, uint256,uint256) {
        investor memory inv =investors[addr];
        require(addr == msg.sender || msg.sender == owner() || msg.sender == accessAddress,'your access to stat is restricted!');
        uint256 wa = 0;
        if(inv.initiated){
            wa = getWhithdrableStat();   
        }
        return (inv.referralsCount, inv.referralEarn, inv.referrals,
                inv.referrer, wa, inv.totalInvestedMoney, inv.collectedMoney,inv.lastReinvestedTime , inv.lastWithdrawTime , totalDeposit );
    }
    
    function getInvestsStat(address addr) public view returns (uint256[] memory, uint256[] memory, uint256[] memory,bool[] memory,uint256) {
        investor memory inv = investors[addr];

        require(addr == msg.sender || msg.sender == owner() || msg.sender == accessAddress,'your access to stat is restricted!');
        if(inv.reInvest.investedMoney.length == 1){
            return (inv.invests.investedMoney, inv.invests.planType,inv.invests.startedTime, inv.invests.finished, inv.reInvest.investedMoney[0]);
        }
        return (inv.invests.investedMoney, inv.invests.planType,inv.invests.startedTime, inv.invests.finished,0);
    }

    function configCapacitor (uint256 percent,uint256 interval ,uint256 loss, uint256 minAmount) public onlyOwner{
        CAPACITY_EXTRA_PERCENT = percent;
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
        INSURED_PERCENT = percent;
    }

    function getOveralStat() public view onlyOwner returns(uint256,uint256,uint256,uint256,address,uint256,uint256,uint256,uint256,uint256,uint256,bool,address){
        bool isCH = isCharging();
        return (totalReferral, totalReferralEarn ,totalDeposit ,totalWithdrawn ,accessAddress ,adminPercent ,aAFA ,normalBalance ,povertyBalance ,capacitorTotal ,capacitorExtraMoney ,isCH ,_capacitor);
    }
}