//SourceUnit: SafeMath.sol

pragma solidity ^0.5.4;

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

//SourceUnit: financetron.sol

pragma solidity ^0.5.4;

import './SafeMath.sol';
import './ownable.sol';


interface capacitor{
    function decharge(uint256 money) external returns(uint256);
    function charge() payable external;
}

contract FinanceTron is Ownable{
    
    using SafeMath for uint256;

    uint256 public totalReferral;
    uint256 public totalReferralEarn;
    uint256 public totalDeposit;
    uint256 public totalWithdrawn;
    address payable public mainWallet;

    bool private _charged;	
    address payable private _capacitor;

    uint256[] private MIN_DEPOSIT = [100000000, 1000000000, 10000000000, 100000000000]; 
    uint256[] private PROFITS_PERCENTS = [1700, 2100, 2500, 2900];
    uint256 private PROFIT_ON_PROFIT = 50;
    uint256 private FINAL_PROFIT_PERCENT = 200;
    uint256 private DAY = 1 days;
    uint256 private INSURED_PERCENT = 35;
    uint256 private ADMIN_PERCENT = 95; // 9.5%
    uint256[] private REF_PERCENT = [40, 30, 20, 10, 5]; 
    uint256 private BONUS_PERCENT = 20;
    uint256 private normalBalance;
    uint256 private povertyBalance;
    uint256 private CAPACITY_PERCENT = 6;
    uint256 private capacitorTotal;
    uint256 private lastDechargeTime;
    uint256 private previousBalance;
    uint256 private DECHARGE_TIMER_INTERVAL = 43200;
    uint256 private LOSS_RECOVERY_PERCENT = 50;
    uint256 private MIN_RECOVERY_AMOUNT = 10000000000;
    uint256 private totalChargedAmount;
    uint256 private CapacitorStartAmount = 5000000000000;
    mapping (address => investor) investors;


    struct invest{
        uint256[] planType;
        uint256[] startedTime;
        uint256[] investedMoney;
        uint256[] totalEarnedMoney;
        bool[] finished;
        uint256[] withdrawNumber;
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
    }

    event Registration(address indexed addr, address indexed referrer);
    event Deposited(address indexed addr, address indexed referrer, uint256 amount, uint256 planType);
    event Withdrawn(address indexed addr, uint256 amount);
    event DechargeCapacitor(uint256 amount);
    event DechargeRequest(uint256 amount);
    event ChargeCapacitor(uint256 amount);

    constructor(address payable wallet, address payable cap) public {
        mainWallet = wallet;
        investors[mainWallet].initiated = true;
        _capacitor = cap;
        investors[mainWallet].referrer = mainWallet;
        investors[mainWallet].referralsCount = new uint256[](5);
        investors[mainWallet].referralEarn = new uint256[](5);
    }

    function() external payable{
    }

    function receiveMoney() payable public{
        normalBalance = normalBalance.add(msg.value.mul(80).div(100));
        povertyBalance = povertyBalance.add(msg.value.mul(20).div(100));
        if(msg.value < capacitorTotal)
            capacitorTotal = capacitorTotal.sub(msg.value);
        else{
            capacitorTotal = 0;
        }
        emit DechargeCapacitor(msg.value);
    }

    function isCharging() internal view returns (bool) {
        return _charged;
    }
    
    function _registration(address addr, address ref) internal {
        require(investors[ref].initiated , "Inviter address does not exist in the FinanceTron network!");
        investor storage referrer = investors[ref];
        referrer.referrals.push(addr);
        investors[addr].referrer = ref;
        investors[addr].initiated = true;
        totalReferral = totalReferral.add(1);

        if (referrer.referralsCount.length == 0){
            referrer.referralsCount = new uint256[](5);
            referrer.referralEarn = new uint256[](5);
        }      
        address refWallet = ref;
        investors[refWallet].referralsCount[0] = investors[refWallet].referralsCount[0].add(1);
        refWallet = investors[refWallet].referrer;

        uint256 level = 1;
        while (level < 5){
            if(refWallet != mainWallet){
                investors[refWallet].referralsCount[level] = investors[refWallet].referralsCount[level].add(1);
                refWallet = investors[refWallet].referrer;
            }
            level = level.add(1);
        }
        emit Registration(addr, ref);
    }

    function getWhithdrableStat(address addr) public view returns (uint256 profit, uint256 profitOnProfit){
        require(investors[addr].initiated, "address does not exist in the FinanceTron!");

        profit = 0;
        uint256 i = 0;
        invest memory invests = investors[addr].invests;

        while (i < invests.planType.length){
            if(!invests.finished[i]){
                (uint256 benefit, , uint256 p) = calculateBenefit(investors[addr].lastWithdrawTime, invests.planType[i], invests.startedTime[i], invests.investedMoney[i], invests.totalEarnedMoney[i], invests.withdrawNumber[i]);
                if (p >= profitOnProfit)
                    profitOnProfit = p;
                profit = profit.add(benefit);
            }
            i = i.add(1);
        }

        return (investors[addr].withdrableMoney.add(profit), profitOnProfit);
    }


    function calculateBenefit(uint256 lastWithdrawTime, uint256 planType, uint256 startedTime, uint256 investedMoney, uint256 totalEarnedMoney, uint256 withdrawNumber) private view returns (uint256 value, bool finished, uint256 benefitPercent){
        finished = false;
        uint256 startOrWithdrawTime = startedTime;
        if(startOrWithdrawTime < lastWithdrawTime){
            startOrWithdrawTime = lastWithdrawTime;
        }
        uint256 benefitTimeSpent = now.sub(startOrWithdrawTime);
        benefitPercent = PROFITS_PERCENTS[planType].mul(benefitTimeSpent).mul(PROFIT_ON_PROFIT);
        benefitPercent = benefitPercent.div(DAY).div(1000);
        benefitPercent = benefitPercent.add(PROFITS_PERCENTS[planType]);
        value = investedMoney.mul(benefitPercent).mul(now.sub(startOrWithdrawTime)).div(100000).div(DAY);
        uint256 ceiling = investedMoney.mul(FINAL_PROFIT_PERCENT).div(100);
        if(ceiling <= totalEarnedMoney.add(value)) {
            value = ceiling.sub(totalEarnedMoney);
            if(withdrawNumber < 2){
                value = value.add(investedMoney.mul(BONUS_PERCENT).div(100));
            }
            finished = true;
        }
        return (value, finished, benefitPercent);
    }

    function refresh(address addr) private {
        require(investors[addr].initiated, "address does not exist in the FinanceTron!");
        uint256 profit = 0;
        uint256 i = 0;
        invest storage invests = investors[addr].invests;
        while (i < invests.planType.length){
            if(!invests.finished[i]){
                (uint256 benefit, bool finished,) = calculateBenefit(investors[addr].lastWithdrawTime, invests.planType[i], invests.startedTime[i], invests.investedMoney[i], invests.totalEarnedMoney[i], invests.withdrawNumber[i]);
                profit = profit.add(benefit);
                invests.totalEarnedMoney[i] = invests.totalEarnedMoney[i].add(benefit);
                invests.withdrawNumber[i] = invests.withdrawNumber[i].add(1);
                if(finished){
                    invests.finished[i] = true;
                }
            }
            i = i.add(1);
        }
        investors[addr].lastWithdrawTime = now;
        investors[addr].withdrableMoney = investors[addr].withdrableMoney.add(profit);
    }



    function deposit(address referrer, uint256 planType) public payable  {
        require(msg.sender != owner() && msg.sender != mainWallet, "owner cannot invest!");
        require(planType < 4, "Box is not valid!");
        uint256 amount = msg.value;
        require(amount >= MIN_DEPOSIT[planType], "less than Box minimum invest amount!");
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
        investors[addr].invests.finished.push(false);
        investors[addr].invests.totalEarnedMoney.push(0);
        investors[addr].invests.withdrawNumber.push(0);
        investors[addr].totalInvestedMoney = investors[addr].totalInvestedMoney.add(amount);
        totalDeposit = totalDeposit.add(amount);        
        uint256 level = 0;
        uint256 counter = 0;
        address refWallet = investors[addr].referrer;
        while(counter < 5){
            uint256 refValue = amount.mul(REF_PERCENT[counter]).div(1000);
            investors[refWallet].referralEarn[level] = investors[refWallet].referralEarn[level].add(refValue);
            investors[refWallet].withdrableMoney = investors[refWallet].withdrableMoney.add(refValue);
            totalReferralEarn = totalReferralEarn.add(refValue);
            refWallet = investors[refWallet].referrer;
            if(refWallet != mainWallet){    
                level = level.add(1);
            }
            counter = counter.add(1);
        }

        normalBalance = normalBalance.add(amount.mul(1000 - ADMIN_PERCENT).div(1000).mul(80).div(100));
        povertyBalance = povertyBalance.add(amount.mul(1000 - ADMIN_PERCENT).div(1000).mul(20).div(100));

        if(totalDeposit > CapacitorStartAmount)
            _charged = true;

        if(isCharging())
        {
            capacitor c = capacitor(_capacitor);
            uint256 chargeAmount=amount.mul(1000 - ADMIN_PERCENT).div(1000).mul(CAPACITY_PERCENT).div(100);
            c.charge.value(chargeAmount)();
            emit ChargeCapacitor(chargeAmount);
            normalBalance = normalBalance.sub(chargeAmount.mul(80).div(100));
            povertyBalance = povertyBalance.sub(chargeAmount.mul(20).div(100));
            capacitorTotal = capacitorTotal.add(chargeAmount);    
            totalChargedAmount = totalChargedAmount.add(chargeAmount);    
        }
        mainWallet.transfer(amount.mul(ADMIN_PERCENT).div(1000));
        uint256 ourBalance = address(this).balance;
        if(previousBalance < ourBalance){
            previousBalance = ourBalance;
        }
        emit Deposited(addr, investors[addr].referrer, amount, planType);
    }

    function withdraw(uint256 amount) public returns(uint256) {
        require(msg.sender != owner(), "owner cannot withdraw!");
        address payable addr = msg.sender;
        refresh(addr);
        uint256 balance = investors[addr].withdrableMoney;
        require(amount <= balance , "Not enough withdrable money to withdraw!");
        amount = _calculateInternalBalance(amount,addr);
        investors[addr].collectedMoney = investors[addr].collectedMoney.add(amount);
        investors[addr].withdrableMoney = balance.sub(amount);
        
        totalWithdrawn = totalWithdrawn.add(amount);
        addr.transfer(amount);
        if (now.sub(lastDechargeTime) > DECHARGE_TIMER_INTERVAL){
            if(isCharging())
            {
                if (previousBalance > address(this).balance){
                    uint256 diff =  previousBalance.sub(address(this).balance);
                    uint256 recoveryAmount = diff.mul(LOSS_RECOVERY_PERCENT).div(100);
                    if (recoveryAmount > MIN_RECOVERY_AMOUNT){
                        capacitor c = capacitor(_capacitor);
                        c.decharge(recoveryAmount);
                        emit DechargeRequest(recoveryAmount);
                    }
                } 
            }
            lastDechargeTime = now;
            previousBalance = address(this).balance;
        }
        emit Withdrawn(addr, amount);
        return amount;
    }

    function _calculateInternalBalance(uint256 amount, address addr) private returns (uint256 payableAmount){
        if (amount <= normalBalance){
            normalBalance = normalBalance.sub(amount);
            return amount;
        }
        payableAmount = normalBalance;
        normalBalance = 0;
        amount = amount.sub(payableAmount);
        uint256 insuredMoney = investors[addr].totalInvestedMoney.mul(INSURED_PERCENT).div(100);
        if(addr == mainWallet)
            insuredMoney = amount;
        if(insuredMoney >= investors[addr].collectedMoney.add(payableAmount)){
            uint256 remained = insuredMoney.sub(investors[addr].collectedMoney.add(payableAmount));
            if (amount > remained){
                amount = remained;
            }
            if (povertyBalance < amount){
                amount = povertyBalance;
            }
            povertyBalance = povertyBalance.sub(amount);
            payableAmount = payableAmount.add(amount);
        }
        require(payableAmount > 0,'you cannot withdraw more than 35% of your invested money due to contract balance limit'); 
        return payableAmount;
    }
     
    function getInvestorStat(address addr) public view returns (uint256[] memory referralsCount, uint256[] memory referralEarn, address[] memory referrals,
                         address referrer, uint256 WhithdrableMoney, uint256 totalInvestedMoney, uint256 collectedMoney, uint256 lastWithdrawTime, uint256 totalDepositedMoney) {
        investor memory inv =investors[addr];
        uint256 wa = 0;
        if(inv.initiated){
            (wa,) = getWhithdrableStat(addr);   
        }
        return (inv.referralsCount, inv.referralEarn, inv.referrals,
                inv.referrer, wa, inv.totalInvestedMoney, inv.collectedMoney, inv.lastWithdrawTime , totalDeposit );
    }
    
    function getInvestsStat(address addr) public view returns (uint256[] memory investedMoney, uint256[] memory planType, uint256[] memory startedTime, uint256[] memory totalEarned, bool[] memory finished, uint256[] memory withdrawNumber, uint256 lastWithdrawTime) {
        investor memory inv = investors[addr];
        return (inv.invests.investedMoney, inv.invests.planType,inv.invests.startedTime, inv.invests.totalEarnedMoney, inv.invests.finished, inv.invests.withdrawNumber, inv.lastWithdrawTime);
    }

    function increaseInsuredPercent(uint256 percent) public onlyOwner{
        INSURED_PERCENT = INSURED_PERCENT.add(percent);
    }

    function getOveralStat() public view
    returns(uint256 totalReferrals,uint256 totalReferralEarned,uint256 totalDepositedMoney,uint256 totalWithdrawnMoney,uint256 normalBalanceValue,uint256 povertyBalanceValue, uint256 capacitorTotalMoney, bool Charging ,address capacitorAddress,uint256 currentBalance, uint256 TotalChargedAmount){
        bool isCH = isCharging();
        return (totalReferral, totalReferralEarn ,totalDeposit ,totalWithdrawn  ,normalBalance ,povertyBalance ,capacitorTotal ,isCH ,_capacitor, address(this).balance, totalChargedAmount);
    }
    
}

//SourceUnit: ownable.sol

pragma solidity ^0.5.4;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() internal view returns (address) {
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