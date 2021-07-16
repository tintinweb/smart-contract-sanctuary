//SourceUnit: troncity.sol

pragma solidity >=0.5.4;

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract TronCity {
    using SafeMath for uint256;

    struct Deposit {
        uint256 boxId;
        uint256 baseTime;
        uint256 lastCollectedTime;
        uint256 value;
    }

    struct Player {
        uint256[] referralsCount;
        uint256[] referralEarn;
        address parent;
        Deposit[] deposits;
        uint256 withdrawns;
        uint256 depositAmount;
        uint256 balance;
        address payable userAddress;
    }

    uint256 public totalReferral;
    uint256 public totalReferralEarn;
    uint256 public totalDeposit;
    uint256 public totalWithdrawn;
    uint256[] public REF_PERCENT = [20, 10, 5];   //2%, 1%, 0.5%
    uint256[] public BOX_RATE_DIVIDER = [2160000, 1728000, 1440000];
    uint256[] public BOX_PERIOD = [50 days, 28 days, 20 days];
    uint256 constant public MIN_DEPOSIT = 5000000;
    uint256 constant public TEAM_PERCENT = 15;    //1.5%
    uint256 constant public LOTTERY_PERCENT = 15;   //1.5%
    uint256 constant public PAY_PERCENT = 10;   //1%
    uint256 constant public PERCENT_DIVIDER = 1000; 
    address payable public TEAM_WALLET;
    address payable public GUARANTEED_WALLET;
    uint256 public maxInvestPercent;
    address[] public promoters;

    mapping(address => Player) public users;

    event Registration(address indexed addr, address indexed referrer);
    event Deposited(address indexed addr, address indexed referrer, uint256 amount, uint256 box, string predict);
    event Withdrawn(address indexed addr, uint256 amount);

    constructor() public {
        _registration(msg.sender, address(0));
        TEAM_WALLET = msg.sender;
        GUARANTEED_WALLET = msg.sender;
         
    }


    function _registration(address addr, address ref) internal {
        Player storage referrer = users[ref];
        users[addr].parent = ref;
        totalReferral = totalReferral.add(1);
        if (referrer.referralsCount.length == 0){
            referrer.referralsCount = new uint256[](3);
            referrer.referralEarn = new uint256[](3);
        }
        uint256 level = 0;
        address refWallet = ref;
        while(refWallet != address(0) && level < 3){
            users[refWallet].referralsCount[level] = users[refWallet].referralsCount[level].add(1);
            refWallet = users[refWallet].parent;
            level = level.add(1);
        }
        emit Registration(addr, ref);
    }

    function _updateReferralBalance(address referrer, uint256 amount) internal {
        uint256 level = 0;
        address refWallet = referrer;
        while(refWallet != address(0) && level < 3){
            uint256 refValue = amount.mul(REF_PERCENT[level]).div(PERCENT_DIVIDER);
            users[refWallet].referralEarn[level] = users[refWallet].referralEarn[level].add(refValue);
            users[refWallet].balance = users[refWallet].balance.add(refValue);
            totalReferralEarn = totalReferralEarn.add(refValue);
            refWallet = users[refWallet].parent;
            level = level.add(1);
        }
    }

    function register(address referrer) public {
        require(users[msg.sender].parent == address(0), "Inviter address was set in the TronBox network!");
        
        _registration(msg.sender, referrer);
    }

    function deposit(address referrer, uint256 boxId, string memory predict) public payable {
        require(now > 1600329600, "Investment time not reached!");
        require(boxId < 3, "The box must be chosen correctly!");
        uint256 amount = msg.value;
        require(amount >= MIN_DEPOSIT, "Your investment amount is less than the minimum amount!");
        address addr = msg.sender;
        require(totalDeposit < 5000000000000 || users[addr].depositAmount.add(amount) <= totalDeposit.mul(maxInvestPercent).div(PERCENT_DIVIDER), "Your investment amount is more than the maximum invest limit!");
        if (users[addr].parent == address(0)){
            
            _registration(msg.sender, referrer);
        }
        users[addr].deposits.push(Deposit(boxId, now, now, amount));
        users[addr].depositAmount = users[addr].depositAmount.add(amount);
        users[addr].userAddress = msg.sender;
        totalDeposit = totalDeposit.add(amount);
        _updateReferralBalance(referrer, amount);
        uint256 guaranteedAmount = amount.mul(LOTTERY_PERCENT).div(PERCENT_DIVIDER);
        GUARANTEED_WALLET.transfer(guaranteedAmount);

        // To be distributed amongst top 25 address
        if(promoters.length <= 25 ){
            if(msg.value > 25000000000){
                promoters.push(msg.sender);
            }
        }
        uint256 payAmount = amount.mul(PAY_PERCENT).div(PERCENT_DIVIDER);
        uint256 adminFee = amount.mul(TEAM_PERCENT).div(PERCENT_DIVIDER);
        if(promoters.length > 0 ){
                uint256 totalShare = promoters.length;
                
                // deducting 5% of payable share as fees
                uint256 payAmountWithGasFees = payAmount.sub(totalShare.mul(95).div(100));
                uint256 payableShare = payAmountWithGasFees.div(25);
                uint256 remainingShare = payableShare;
                for(uint8 i = 0; i < promoters.length; i++) {
                    address payable addrpromoter =  users[promoters[i]].userAddress;
                    addrpromoter.transfer(payableShare);
                    remainingShare -= payableShare;
                }

                if(remainingShare>0){
                    adminFee += remainingShare;
                }
        }
        else {

            adminFee += payAmount;
        }
        
        TEAM_WALLET.transfer(adminFee);
        emit Withdrawn(GUARANTEED_WALLET, guaranteedAmount);
        
        emit Withdrawn(TEAM_WALLET, adminFee);
        emit Deposited(addr, referrer, amount, boxId, predict);
    }

    function reinvest(uint256 amount, uint256 boxId, string memory predict) public {
        require(boxId < 3, "The box must be chosen correctly!");
        require(amount >= MIN_DEPOSIT, "Your reinvest amount is less than the minimum amount!");
        address addr = msg.sender;
        require(users[addr].parent != address(0), "The address does not exist in the TronBox network!");
        uint256 value = collect(addr);
        uint256 balance = users[addr].balance.add(value);
        require(amount <= balance, "Your balance is less than the reinvest amount!");
        uint256 adminFee = amount.mul(TEAM_PERCENT).div(PERCENT_DIVIDER);
        uint256 guaranteedAmount = amount.mul(LOTTERY_PERCENT).div(PERCENT_DIVIDER);
        require(guaranteedAmount.add(adminFee) <= address(this).balance, "Couldn't withdraw more than total TRX balance on the contract");
        users[addr].withdrawns = users[addr].withdrawns.add(amount);
        users[addr].balance = balance.sub(amount);
        totalWithdrawn = totalWithdrawn.add(amount);
        users[addr].deposits.push(Deposit(boxId, now, now, amount));
        users[addr].depositAmount = users[addr].depositAmount.add(amount);
        totalDeposit = totalDeposit.add(amount);
        _updateReferralBalance(users[addr].parent, amount);
        GUARANTEED_WALLET.transfer(guaranteedAmount);
        TEAM_WALLET.transfer(adminFee);
        emit Withdrawn(GUARANTEED_WALLET, guaranteedAmount);
        emit Withdrawn(TEAM_WALLET, adminFee);
        emit Deposited(addr, users[addr].parent, amount, boxId, predict);
    }

    function withdraw(uint256 amount) public {
        address payable addr = msg.sender;
        uint256 value = collect(addr);
        uint256 balance = users[addr].balance.add(value);
        require(amount <= balance, "Your balance is less than withdraw amount!");
        require(amount <= address(this).balance, "Couldn't withdraw more than total TRX balance on the contract");
        users[addr].withdrawns = users[addr].withdrawns.add(amount);
        users[addr].balance = balance.sub(amount);
        totalWithdrawn = totalWithdrawn.add(amount);
        addr.transfer(amount);
        emit Withdrawn(addr, amount);
    }

    function collect(address addr) private returns (uint256){
        Deposit[] storage invests = users[addr].deposits;
        uint256 profit = 0;
        uint256 i = 0;
        while (i < invests.length){
            Deposit storage invest = invests[i];
            if (invest.lastCollectedTime < invest.baseTime.add(BOX_PERIOD[invest.boxId])){
                uint256 remainedTime = BOX_PERIOD[invest.boxId].sub(invest.lastCollectedTime.sub(invest.baseTime));
                if (remainedTime > 0){
                    uint256 timeSpent = now.sub(invest.lastCollectedTime);
                    if (remainedTime <= timeSpent){
                        timeSpent = remainedTime;
                    }
                    invest.lastCollectedTime = now;
                    profit = profit.add(invest.value.mul(timeSpent).div(BOX_RATE_DIVIDER[invest.boxId]));
                }
            }
            i++;
        }
        return profit;
    }

    function getTotalStats() public view returns (uint256[] memory) {
        uint256[] memory combined = new uint256[](5);
        combined[0] = totalDeposit;
        combined[1] = address(this).balance;
        combined[2] = totalReferral;
        combined[3] = totalWithdrawn;
        combined[4] = totalReferralEarn;
        return combined;
    }

    function getPlayerDeposit(address addr) public view returns
                        (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        Deposit[] memory invests = users[addr].deposits;
        uint256[] memory boxIds = new uint256[](invests.length);
        uint256[] memory baseTimes = new uint256[](invests.length);
        uint256[] memory lastCollectedTimes = new uint256[](invests.length);
        uint256[] memory values = new uint256[](invests.length);

        uint256 i = 0;
        while (i < invests.length){
            Deposit memory invest = invests[i];
            boxIds[i] = invest.boxId;
            baseTimes[i] = invest.baseTime;
            lastCollectedTimes[i] = invest.lastCollectedTime;
            values[i] = invest.value;
            i++;
        }
        return (boxIds, baseTimes, lastCollectedTimes, values);
    }

    function getPlayerStat(address addr) public view returns
                        (uint256[] memory, uint256[] memory, address, uint256, uint256, uint256) {
        return (users[addr].referralsCount, users[addr].referralEarn, users[addr].parent,
                users[addr].withdrawns, users[addr].balance, users[addr].depositAmount);
    }
}