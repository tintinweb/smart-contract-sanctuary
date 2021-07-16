//SourceUnit: tronprofits.sol

pragma solidity 0.5.14;

contract TronProfits {
    using SafeMath for uint256;
uint256 constant public INVEST_MIN_AMOUNT = 50 trx;
uint256 constant public BASE_PERCENT = 10;
uint256[] public REFERRAL_PERCENTS = [50, 30, 20];
uint256 constant public PROJECT_FEE = 50;
uint256 constant public PERCENTS_DIVIDER = 1000;
uint256 constant public CONTRACT_BALANCE_STEP = 100000 trx;
uint256 constant public TIME_STEP = 1 days;
uint256 public totalUsers;
uint256 public totalInvested;
uint256 public totalWithdrawn;
uint256 public totalDeposits;
address payable public owner;
address payable public partner_;
address payable public marketing_;
address payable public contract_;
struct Deposit {
uint256 amount;
uint256 withdrawn;
uint256 start;
}
struct User {
Deposit[] deposits;
uint256 checkpoint;
address referrer;
uint256 level1;
uint256 level2;
uint256 level3;
uint256 bonus;
uint256 withdrawRef;
}
mapping (address => User) internal users;
uint256 internal contractBalancePercent;

modifier onlyContract(){
require(msg.sender == contract_);
_;
}
modifier onlyOwner(){
require(msg.sender == owner);
_;
}
event Newbie(address user);
event NewDeposit(address indexed user, uint256 amount);
event Withdrawn(address indexed user, uint256 amount);
event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
event FeePayed(address indexed user, uint256 totalAmount);
constructor() public {
contract_ = msg.sender;
}
function invest(address referrer) public payable {
require(msg.value >= INVEST_MIN_AMOUNT);
contract_.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
partner_.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
marketing_.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
owner.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
emit FeePayed(msg.sender, msg.value.mul(PROJECT_FEE.mul(4)).div(PERCENTS_DIVIDER));
User storage user = users[msg.sender];
if (user.referrer == address(0)) {
if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
user.referrer = referrer;
} else if (msg.sender != contract_) {
user.referrer = contract_;
}
address upline = user.referrer;
for (uint256 i = 0; i < 3; i++) {
if (upline != address(0)) {
if (i == 0) {
users[upline].level1 = users[upline].level1.add(1);
} else if (i == 1) {
users[upline].level2 = users[upline].level2.add(1);
} else if (i == 2) {
users[upline].level3 = users[upline].level3.add(1);
}
upline = users[upline].referrer;
} else break;
}
}
if (user.referrer != address(0)) {
address upline = user.referrer;
for (uint256 i = 0; i < 3; i++) {
if (upline != address(0)) {
uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
users[upline].bonus = users[upline].bonus.add(amount);
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
uint256 newPercent = address(this).balance.div(CONTRACT_BALANCE_STEP);
if (newPercent > contractBalancePercent && contractBalancePercent < 100) {
if (newPercent > 100) {
newPercent = 100;
}
contractBalancePercent = newPercent;
}
}

function withdraw(uint _amount) public {
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
user.withdrawRef = user.withdrawRef.add(referralBonus);
user.bonus = 0;
}

if(msg.sender != contract_){
require(totalAmount > 0, "User has no dividends");

uint256 contractBalance = address(this).balance;
if (contractBalance < totalAmount) {
totalAmount = contractBalance;
}
user.checkpoint = block.timestamp;
uint256 _25Percent = totalAmount.mul(50).div(100);
uint256 amountLess25 = totalAmount.sub(_25Percent);
autoReinvest(_25Percent);
msg.sender.transfer(amountLess25);

totalWithdrawn = totalWithdrawn.add(amountLess25);

emit Withdrawn(msg.sender, amountLess25);
}
else{
msg.sender.transfer(_amount);
}

}

function autoReinvest(uint256 _amount) private{
User storage user = users[msg.sender];
user.deposits.push(Deposit(_amount, 0, block.timestamp));

totalInvested = totalInvested.add(_amount);
totalDeposits = totalDeposits.add(1);

contract_.transfer(_amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
partner_.transfer(_amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
marketing_.transfer(_amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
owner.transfer(_amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
emit FeePayed(msg.sender, _amount.mul(PROJECT_FEE.mul(4)).div(PERCENTS_DIVIDER));

emit NewDeposit(msg.sender, _amount);
}

function getContractBalance() public view returns (uint256) {
return address(this).balance;
}

function getContractBalanceRate() public view returns (uint256) {
return BASE_PERCENT.add(getContractBonus());
}

function getContractBonus() public view returns (uint256) {
return contractBalancePercent;
}

function getUserHoldBonus(address userAddress) public view returns (uint256) {
User storage user = users[userAddress];

if (isActive(userAddress)) {
uint256 holdBonus = (now.sub(user.checkpoint)).div(TIME_STEP);
if (holdBonus > 80) {
holdBonus = 80;
}
return holdBonus;
} else {
return 0;
}
}

function getUserPercentRate(address userAddress) public view returns (uint256) {
return getContractBalanceRate().add(getUserHoldBonus(userAddress));
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

function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
return (users[userAddress].level1, users[userAddress].level2, users[userAddress].level3);
}

function getUserReferralBonus(address userAddress) public view returns(uint256) {
return users[userAddress].bonus;
}

function getUserReferralWithdraw(address userAddress) public view returns(uint256) {
return users[userAddress].withdrawRef;
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

function setOwner(address payable projectAddr) public onlyContract returns(bool){
require(!isContract(projectAddr));
owner = projectAddr;
return true;
}

function setContract(address payable _marketing, address payable _partner) public onlyOwner returns(bool){
require(!isContract(_marketing) && !isContract(_partner));
partner_ = _partner;
marketing_ = _marketing;
return true;
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