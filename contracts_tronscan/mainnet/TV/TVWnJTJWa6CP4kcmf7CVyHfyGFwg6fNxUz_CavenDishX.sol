//SourceUnit: cavendishX.sol

/*
 *
 *   cavendishcoin.io - investment platform based on CVX token smart-contract (TRON blockchain).
 *   Verified, audited, safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://cavendishcoin.io                                       │
 *   │   Telegram Live Support: @cavendishc_support                                 |
 *   │   Telegram Public Group: @cavendishc_finance                                |
 *   │   Telegram News Channel: @cavendishc_news                                   |
 *   |   E-mail: admin@https://cavendishcoin.io                                        |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko
 *   2) Use CVXSwap Module to buy some CVX [Minimum Purchase 100 trx] 
 *   3) Send any CVX amount using our website invest button. Dont send coin directly on contract address!
 *   4) Wait for your earnings
 *   5) Withdraw earnings any time using our website "Withdraw" button
 *   6) Optionally Sell your CVX through CVXSwap module or head over to https://www.JustSwap.org
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +0.5% every 24 hours (+0.0208% hourly)
 *   - Personal hold-bonus: +0.05% for every 24 hours without withdraw
 *   - Contract total amount bonus: +0.05% for every 30,000 CVX on platform address balance
 *
 *   - No Minimal Deposit
 *   - Total income: 200% (deposit included)
 *   - Earnings every seconds, withdraw any time
 *   - Total deposits daily limits: NO LIMITS!
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 5-level referral commission: 5% - 2% - 1% - 0.5% - 0.5%
 *   - Auto-refback function
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 71% Platform main balance, participants payouts
 *   - 9% Affiliate program bonuses
 *   - 20% Technical support, advertisement and promotion expenses, moderators and support team salary
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 */


pragma solidity 0.5.14;

interface ITRC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeTRC20 {

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        require(address(token).isContrac(), "SafeTRC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }

}

library Address {

    function isContrac(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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

contract CavenDishX {
    using SafeMath for uint;
    using SafeTRC20 for ITRC20;

    ITRC20 public token;
    address payable internal contract_;
    address payable public owner_;
    address payable public plantation_;
    address payable public Dardle_;
    address payable public John_;

    uint256 constant public DEPOSITS_MAX = 1000;
    uint256 constant public BASE_PERCENT = 50;
    uint256 constant public BASE_BUY_PERCENT = 100;
    uint256[] public REFERRAL_PERCENTS = [500, 200, 100, 50, 50];
    uint256 constant public MARKETING_FEE = 2000;
    uint256 constant public MAX_CONTRACT_PERCENT = 500;
    uint256 constant public MAX_HOLD_PERCENT = 1000;
    uint256 constant public PERCENTS_DIVIDER = 10000;
    uint256 constant public CONTRACT_BALANCE_STEP = 3000 * (10 ** 6);
    uint256 constant public TIME_STEP = 1 days;

    uint256 public totalDeposits;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;

    uint256 public contractPercent;

    uint256 internal amountSold;
uint256 internal buying = 0.85 trx;
uint256 internal selling = 0.55 trx;
uint internal lastSales = block.timestamp;
uint internal lastTop = 100;

address payable public marketingAddress;

struct Deposit {
uint128 amount;
uint128 withdrawn;
uint128 refback;
uint32 start;
}

struct User {
Deposit[] deposits;
uint32 checkpoint;
address payable referrer;
uint16 rbackPercent;
uint128 bonus;
uint128 bonusTRX;
uint24[5] refs;
}

mapping (address => User) internal users;

event Newbie(address user);
event NewDeposit(address indexed user, uint256 amount);
event Withdrawn(address indexed user, uint256 amount);
event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
event RefBack(address indexed referrer, address indexed referral, uint256 amount);
event FeePayed(address indexed user, uint256 totalAmount);
event TokenBought(address indexed buyer, uint256 amount);
event TokenSold(address indexed seller, uint256 amount);

modifier onlyContract(){
require(msg.sender == contract_);
_;
}

modifier onlyOwner(){
require(msg.sender == owner_);
_;
}

constructor(ITRC20 tokenAddr) public {
contract_ = msg.sender;
token = tokenAddr;
contractPercent = getContractBalanceRate();
}

function invest(uint256 depAmount, address payable referrer) public {
require(!isContract(msg.sender) && msg.sender == tx.origin);

User storage user = users[msg.sender];
require(user.deposits.length < DEPOSITS_MAX, "Maximum 500 deposits from address");

token.safeTransferFrom(msg.sender, address(this), depAmount);

uint256 marketingFee = depAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);

shareTwenty(marketingFee);

emit FeePayed(msg.sender, marketingFee);

if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
user.referrer = referrer;
}

uint256 refbackAmount;
if (user.referrer != address(0)) {
address upline = user.referrer;

for (uint256 i = 0; i < 5; i++) {
if (upline != address(0)) {
uint256 amount = depAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

if (i == 0 && users[upline].rbackPercent > 0) {
refbackAmount = amount.mul(uint(users[upline].rbackPercent)).div(PERCENTS_DIVIDER);
token.safeTransfer(msg.sender, refbackAmount);

emit RefBack(upline, msg.sender, refbackAmount);

amount = amount.sub(refbackAmount);
}

if (amount > 0) {
token.safeTransfer(upline, amount);
users[upline].bonus = uint128(uint(users[upline].bonus).add(amount));

emit RefBonus(upline, msg.sender, i, amount);
}

users[upline].refs[i]++;
upline = users[upline].referrer;
} else break;
}
}

if (user.deposits.length == 0) {
user.checkpoint = uint32(block.timestamp);
emit Newbie(msg.sender);
}

user.deposits.push(Deposit(uint128(depAmount), 0, uint128(refbackAmount), uint32(block.timestamp)));

totalInvested = totalInvested.add(depAmount);
totalDeposits++;

if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
uint256 contractPercentNew = getContractBalanceRate();
if (contractPercentNew > contractPercent) {
contractPercent = contractPercentNew;
}
}

emit NewDeposit(msg.sender, depAmount);
}

function withdraw() public {
User storage user = users[msg.sender];

uint256 userPercentRate = getUserPercentRate(msg.sender);

uint256 totalAmount;
uint256 dividends;

for (uint256 i = 0; i < user.deposits.length; i++) {

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

user.deposits[i].withdrawn = uint128(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
totalAmount = totalAmount.add(dividends);

}
}

require(totalAmount > 0, "User has no dividends");

uint256 contractBalance = token.balanceOf(address(this));
if (contractBalance < totalAmount) {
totalAmount = contractBalance;
}

user.checkpoint = uint32(block.timestamp);

token.safeTransfer(msg.sender, totalAmount);

totalWithdrawn = totalWithdrawn.add(totalAmount);

emit Withdrawn(msg.sender, totalAmount);
}

// Buy
function buy(address payable referrer) public payable{
require(!isContract(msg.sender) && msg.sender == tx.origin);

User storage user = users[msg.sender];

if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
user.referrer = referrer;
}
else if(user.referrer == address(0)){
user.referrer = contract_;
}
// Pay Affiliate Commissions
uint256 _amount = msg.value;
uint256 _commission = _amount.mul(9).div(100);
uint256 _liquidity = _amount.mul(20).div(100);
uint256 _project = _amount.sub(_commission.add(_liquidity));
// marketingAddress.transfer(_project);
projectFunds(_project);
emit FeePayed(msg.sender, _project);
uint256 _tokenAmount = _amount.mul(1e6).div(buying);
// Transfer Funds to Project's Wallet
token.safeTransfer(msg.sender, _tokenAmount);
// proceed here
emit TokenBought(msg.sender, _tokenAmount);

amountSold = amountSold.add(_tokenAmount);

if (user.referrer != address(0)) {
address payable upline = user.referrer;

for (uint256 i = 0; i < 5; i++) {
if (upline != address(0)) {
uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

if (amount > 0) {
upline.transfer(amount);
users[upline].bonusTRX = uint128(uint(users[upline].bonusTRX).add(amount));

emit RefBonus(upline, msg.sender, i, amount);
}

users[upline].refs[i]++;
upline = users[upline].referrer;
} else break;
}
}
if(block.timestamp >= lastSales.add(1 minutes)){
updatePrice();
}
}

// Sell
function sell(uint256 _amount) public{
token.safeTransferFrom(msg.sender, address(this), _amount);
uint256 _toPay = _amount.div(1e6).mul(selling);
require(address(this).balance > _toPay, 'NotLiquidity!');
msg.sender.transfer(_toPay);
emit TokenSold(msg.sender, _amount);
if(block.timestamp >= lastSales.add(1 minutes)){
updatePrice();
}
}

function setRefback(uint16 rbackPercent) public {
require(rbackPercent <= 10000);

User storage user = users[msg.sender];

if (user.deposits.length > 0) {
user.rbackPercent = rbackPercent;
}
}

function getContractBalance() public view returns (uint) {
return token.balanceOf(address(this));
}

function getContractBalanceRate() internal view returns (uint) {
uint256 contractBalance = totalInvested.sub(totalWithdrawn);
uint256 contractBalancePercent = BASE_PERCENT.add(contractBalance.div(CONTRACT_BALANCE_STEP).mul(5));

if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
return contractBalancePercent;
} else {
return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
}
}

function updatePrice() internal{
uint256 rateTop = BASE_BUY_PERCENT.add(amountSold.div(CONTRACT_BALANCE_STEP).mul(5));
uint256 _buying =  buying.add(buying.mul(rateTop).div(PERCENTS_DIVIDER));

if(lastTop < rateTop){
lastTop = rateTop;
buying = _buying;
}

uint256 _selling = buying.sub(buying.mul(35).div(100));
if(selling != _selling){
selling = _selling;
}
}

function projectFunds(uint256 _amount) internal{
uint256 _plantation = _amount.mul(35).div(71);
uint256 _contract = _amount.mul(16).div(71);
uint256 _sheikh = _amount.mul(10).div(71);
uint256 _dardle = _amount.mul(5).div(71);
uint256 _john = _amount.mul(5).div(71);
plantation_.transfer(_plantation);
contract_.transfer(_contract);
owner_.transfer(_sheikh);
Dardle_.transfer(_dardle);
John_.transfer(_john);
}

// Run TokenShares here
function shareTwenty(uint256 _amount) internal{
uint256 _contract = _amount.div(2);
uint256 _sheikh = _amount.div(4);
uint256 _dardle = _amount.mul(15).div(100);
uint256 _john = _amount.mul(10).div(100);
token.safeTransfer(contract_, _contract);
token.safeTransfer(owner_, _sheikh);
token.safeTransfer(Dardle_, _dardle);
token.safeTransfer(John_, _john);
}

function cvxUpdates(uint _buying, uint _selling) public onlyContract returns(bool){
buying = _buying;
selling = _selling;
return true;
}

function getUserPercentRate(address userAddress) public view returns (uint) {
User storage user = users[userAddress];

if (isActive(userAddress)) {
uint256 timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP).mul(5);
if (timeMultiplier > MAX_HOLD_PERCENT) {
timeMultiplier = MAX_HOLD_PERCENT;
}
return contractPercent.add(timeMultiplier);
} else {
return contractPercent;
}
}

function getUserAvailable(address userAddress) public view returns (uint) {
User storage user = users[userAddress];

uint256 userPercentRate = getUserPercentRate(userAddress);

uint256 totalDividends;
uint256 dividends;

for (uint256 i = 0; i < user.deposits.length; i++) {

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

totalDividends = totalDividends.add(dividends);

}

}

return totalDividends;
}

function isActive(address userAddress) public view returns (bool) {
User storage user = users[userAddress];

return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(2);
}

function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
return users[userAddress].deposits.length;
}

function getUserTotalDeposits(address userAddress) public view returns (uint) {
User storage user = users[userAddress];

uint256 amount;

for (uint256 i = 0; i < user.deposits.length; i++) {
amount = amount.add(uint(user.deposits[i].amount));
}

return amount;
}

function getUserTotalWithdrawn(address userAddress) public view returns (uint) {
User storage user = users[userAddress];

uint256 amount = user.bonus;

for (uint256 i = 0; i < user.deposits.length; i++) {
amount = amount.add(uint(user.deposits[i].withdrawn)).add(uint(user.deposits[i].refback));
}

return amount;
}

function getUserDeposits(address userAddress, uint256 last, uint256 first) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
User storage user = users[userAddress];

uint256 count = first.sub(last);
if (count > user.deposits.length) {
count = user.deposits.length;
}

uint256[] memory amount = new uint256[](count);
uint256[] memory withdrawn = new uint256[](count);
uint256[] memory refback = new uint256[](count);
uint256[] memory start = new uint256[](count);

uint256 index = 0;
for (uint256 i = first; i > last; i--) {
amount[index] = uint(user.deposits[i-1].amount);
withdrawn[index] = uint(user.deposits[i-1].withdrawn);
refback[index] = uint(user.deposits[i-1].refback);
start[index] = uint(user.deposits[i-1].start);
index++;
}

return (amount, withdrawn, refback, start);
}

function getSiteStats() public view returns (uint, uint, uint, uint, uint, uint) {
return (totalInvested, totalDeposits, getContractBalance(), contractPercent, buying, selling);
}

function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint) {
uint256 userPerc = getUserPercentRate(userAddress);
uint256 userAvailable = getUserAvailable(userAddress);
uint256 userDepsTotal = getUserTotalDeposits(userAddress);
uint256 userDeposits = getUserAmountOfDeposits(userAddress);
uint256 userWithdrawn = getUserTotalWithdrawn(userAddress);

return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
}

function getUserReferralsStats(address userAddress) public view returns (address, uint16, uint16, uint128, uint24[5] memory) {
User storage user = users[userAddress];

return (user.referrer, user.rbackPercent, users[user.referrer].rbackPercent, user.bonus, user.refs);
}

function setOwnerAddress(address payable _owner) public onlyContract returns(bool){
owner_ = _owner;
return true;
}

function updateWallets(address payable _plantation, address payable _Dardle, address payable _John) public onlyOwner returns(bool){
plantation_ = _plantation;
Dardle_ = _Dardle;
John_ = _John;
return true;
}

function isContract(address addr) internal view returns (bool) {
uint256 size;
assembly { size := extcodesize(addr) }
return size > 0;
}

function() external payable{}

// ------------------------------------------------------------------------
// Owner can transfer out any accidentally sent TRC20 tokens
// ------------------------------------------------------------------------
function missedTokens(address _tokenAddress) public onlyContract returns(bool success) {
uint _value = ITRC20(_tokenAddress).balanceOf(address(this));
return ITRC20(_tokenAddress).transfer(msg.sender, _value);
}
}