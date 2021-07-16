//SourceUnit: Tron_Swift.sol

pragma solidity 0.5.10;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

contract Tron_Swift {
using SafeMath for uint256;

address payable owner;

uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
uint256 constant public BASE_PERCENT = 30;
uint256[] public REFERRAL_PERCENTS = [10,5,3,2,1,1,1,1,1,1];
uint256 constant public MARKETING_FEE = 10;
uint256 constant public PROJECT_FEE = 4;
uint256 constant public PERCENTS_DIVIDER = 1000;
uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx ;
uint256 constant public TIME_STEP = 1 days;

uint256 public totalUsers;
uint256 public totalInvested;
uint256 public totalWithdrawn;
uint256 public totalDeposits;

address payable public marketingAddress;
address payable public projectAddress;

struct Deposit {
uint256 amount;
uint256 withdrawn;
uint256 start;
}

struct User {
Deposit[] deposits;
uint256 checkpoint;
address referrer;
uint256 bonus;
uint256 level1;
uint256 level2;
uint256 level3;
uint256 level4;
uint256 level5;
uint256 level6;
uint256 level7;
uint256 level8;
uint256 level9;
uint256 level10;
}

mapping (address => User) internal users;

event Newbie(address user);
event NewDeposit(address indexed user, uint256 amount);
event Withdrawn(address indexed user, uint256 amount);
event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
event FeePayed(address indexed user, uint256 totalAmount);

constructor(address payable marketingAddr, address payable projectAddr) public {
require(!isContract(marketingAddr) && !isContract(projectAddr));
marketingAddress = marketingAddr;
projectAddress = projectAddr;
owner = msg.sender;
}

function invest(address referrer) public payable {
require(msg.value >= INVEST_MIN_AMOUNT);

marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

User storage user = users[msg.sender];

if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
user.referrer = referrer;
}

if (user.referrer != address(0)) {

address upline = user.referrer;
for (uint256 i = 0; i < 10; i++) {
if (upline != address(0)) {
uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
users[upline].bonus = users[upline].bonus.add(amount);
if(i == 0){
users[upline].level1 = users[upline].level1.add(1);
} else if(i == 1){
users[upline].level2 = users[upline].level2.add(1);
} else if(i == 2){
users[upline].level3 = users[upline].level3.add(1);
}else if(i == 3){
users[upline].level4 = users[upline].level4.add(1);
}else if(i == 4){
users[upline].level5 = users[upline].level5.add(1);
}else if(i == 5){
users[upline].level6 = users[upline].level6.add(1);
}else if(i == 6){
users[upline].level7 = users[upline].level7.add(1);
}else if(i == 7){
users[upline].level8 = users[upline].level8.add(1);
}else if(i == 8){
users[upline].level9 = users[upline].level9.add(1);
}else if(i == 9){
users[upline].level10 = users[upline].level10.add(1);
}
emit RefBonus(upline, msg.sender, i, amount);
upline = users[upline].referrer;
} else break;
}

}

if (user.deposits.length == 0) {
user.checkpoint = block.timestamp;
totalUsers = totalUsers.add(1);
emit Newbie(msg.sender);
}

user.deposits.push(Deposit(msg.value, 0, block.timestamp));

totalInvested = totalInvested.add(msg.value);
totalDeposits = totalDeposits.add(1);

emit NewDeposit(msg.sender, msg.value);

}

function withdraw() public {
User storage user = users[msg.sender];

uint256 userPercentRate = getUserPercentRate(msg.sender);

uint256 totalAmount;
uint256 dividends;

for (uint256 i = 0; i < user.deposits.length; i++) {

if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

if (user.deposits[i].start > user.checkpoint) {

dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
.mul(block.timestamp.sub(user.deposits[i].start))
.div(TIME_STEP);

} else {

dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
.mul(block.timestamp.sub(user.checkpoint))
.div(TIME_STEP);

}

if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
}

user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
totalAmount = totalAmount.add(dividends);

}
}

uint256 referralBonus = getUserReferralBonus(msg.sender);
if (referralBonus > 0) {
totalAmount = totalAmount.add(referralBonus);
user.bonus = 0;
}

require(totalAmount > 0, "User has no dividends");

uint256 contractBalance = address(this).balance;
if (contractBalance < totalAmount) {
totalAmount = contractBalance;
}

user.checkpoint = block.timestamp;

msg.sender.transfer(totalAmount);

totalWithdrawn = totalWithdrawn.add(totalAmount);

emit Withdrawn(msg.sender, totalAmount);

}

function getContractBalance() public view returns (uint256) {
return address(this).balance;
}

function getContractBalanceRate() public view returns (uint256) {
uint256 contractBalance = address(this).balance;
uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
return BASE_PERCENT.add(contractBalancePercent);
}

function getUserPercentRate(address userAddress) public view returns (uint256) {
User storage user = users[userAddress];

uint256 contractBalanceRate = getContractBalanceRate();
if (isActive(userAddress)) {
uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
return contractBalanceRate.add(timeMultiplier);
} else {
return contractBalanceRate;
}
}

function getUserDividends(address userAddress) public view returns (uint256) {
User storage user = users[userAddress];

uint256 userPercentRate = getUserPercentRate(userAddress);

uint256 totalDividends;
uint256 dividends;

for (uint256 i = 0; i < user.deposits.length; i++) {

if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

if (user.deposits[i].start > user.checkpoint) {

dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
.mul(block.timestamp.sub(user.deposits[i].start))
.div(TIME_STEP);

} else {

dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
.mul(block.timestamp.sub(user.checkpoint))
.div(TIME_STEP);

}

if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
}

totalDividends = totalDividends.add(dividends);

/// no update of withdrawn because that is view function

}

}

return totalDividends;
}

function getUserCheckpoint(address userAddress) public view returns(uint256) {
return users[userAddress].checkpoint;
}

function getUserReferrer(address userAddress) public view returns(address) {
return users[userAddress].referrer;
}

function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
User memory a = users[userAddress];
return (a.level1, a.level2, a.level3, a.level4, a.level5, a.level6, a.level7, a.level8, a.level9, a.level10);
}

function getUserReferralBonus(address userAddress) public view returns(uint256) {
return users[userAddress].bonus;
}

function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
}

function isActive(address userAddress) public view returns (bool) {
User storage user = users[userAddress];

if (user.deposits.length > 0) {
if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
return true;
}
}
}

function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
   User storage user = users[userAddress];

return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
}

function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
return users[userAddress].deposits.length;
}

function getUserTotalDeposits(address userAddress) public view returns(uint256) {
   User storage user = users[userAddress];

uint256 amount;

for (uint256 i = 0; i < user.deposits.length; i++) {
amount = amount.add(user.deposits[i].amount);
}

return amount;
}

function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
   User storage user = users[userAddress];

uint256 amount;

for (uint256 i = 0; i < user.deposits.length; i++) {
amount = amount.add(user.deposits[i].withdrawn);
}

return amount;
}

function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }


    function getHoldBonus(address userAddress) public view returns(uint256) {
    if(getUserCheckpoint(userAddress) == 0){
        return (block.timestamp.sub(users[userAddress].checkpoint)).mod(24);
    }else {
    return 0;
    }
    }
   
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
   
    function withdrawOwner() public onlyOwner() returns(uint) {
        owner.transfer(address(this).balance);
        return address(this).balance;
    }
}