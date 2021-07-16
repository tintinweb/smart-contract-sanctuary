//SourceUnit: stakewallet.sol

pragma solidity >=0.4.0 <0.7.0;
interface ETR20 {
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract ETRON_StakeWallet {
ETR20 public ETRON;
constructor() public {
ETRON = ETR20(0x41723b9a69d73e2b9d0a61ba2341610294f0addc53);
}
function safeTransferFrom(
ETR20 token, address sender, address recipient, uint256 amount
) private {
bool sent = token.transferFrom(sender, recipient, amount);
require(sent, "ETRON transfer failed");
}
uint256 private ContractAccounts;
uint256 private ContractGoFreeze;
uint256 private ContractOnFreeze;
uint256 private ContractUnFreeze;
uint256 private ContractEarnings;
uint256 private ContractTransfer;
uint256 private ContractWithdraw;
mapping (address => uint256) private AccountGoFreeze;
mapping (address => uint256) private AccountOnFreeze;
mapping (address => uint256) private AccountUnFreeze;
mapping (address => uint256) private AccountDateLock;
mapping (address => uint256) private Account24Lowest;
mapping (address => uint256) private AccountEarnings;
mapping (address => uint256) private AccountBalances;
mapping (address => uint256) private AccountTransfer;
mapping (address => uint256) private AccountWithdraw;
function rContract() public view returns(address) {
return address(this);
}
function rContractTRX() public view returns(uint256) {
return address(this).balance;
}
function rContractETR() public view returns(uint256) {
return ETRON.balanceOf(address(this));
}
function rContractAccounts() public view returns(uint256) {
return ContractAccounts;
}
function rContractGoFreeze() public view returns(uint256) {
return ContractGoFreeze;
}
function rContractOnFreeze() public view returns(uint256) {
return ContractOnFreeze;
}
function rContractUnFreeze() public view returns(uint256) {
return ContractUnFreeze;
}
function rContractEarnings() public view returns(uint256) {
return ContractEarnings;
}
function rContractTransfer() public view returns(uint256) {
return ContractTransfer;
}
function rContractWithdraw() public view returns(uint256) {
return ContractWithdraw;
}
function rAccountGoFreeze() public view returns(uint256) {
return AccountGoFreeze[msg.sender];
}
function rAccountOnFreeze() public view returns(uint256) {
return AccountOnFreeze[msg.sender];
}
function rAccountUnFreeze() public view returns(uint256) {
return AccountUnFreeze[msg.sender];
}
function rAccountDateLock() public view returns(uint256) {
return AccountDateLock[msg.sender];
}
function rAccount24Lowest() public view returns(uint256) {
return Account24Lowest[msg.sender];
}
function rAccountEarnings() public view returns(uint256) {
return AccountEarnings[msg.sender];
}
function rAccountBalances() public view returns(uint256) {
return AccountBalances[msg.sender];
}
function rAccountTransfer() public view returns(uint256) {
return AccountTransfer[msg.sender];
}
function rAccountWithdraw() public view returns(uint256) {
return AccountWithdraw[msg.sender];
}
function rLastZeroUTC(uint256 Time) public view returns(uint256) {
if (Time == 0) {
Time = block.timestamp;
}
if (Time > 1601510400 && Time < 1696118400) {
return Time - (Time % 86400);
} else {
return 0;
}
}
function rCurrentUTC() public view returns(uint256) {
return block.timestamp;
}
function rNextZeroUTC(uint256 Time) public view returns(uint256) {
if (Time == 0) {
Time = block.timestamp;
}
if (Time > 1601510400 && Time < 1696118400) {
return (Time - (Time % 86400)) + 86400;
} else {
return 0;
}
}
function rCheckEarnings() public view returns(uint256) {
if (AccountOnFreeze[msg.sender] >= 1) {
uint256 Estimate = 0;
uint256 Earnings = 0;
Estimate = uint256(Account24Lowest[msg.sender] * 65 / 10000);
uint256 Date1 = rLastZeroUTC(AccountDateLock[msg.sender]);
uint256 Date2 = rLastZeroUTC(block.timestamp);
uint256 DateDiff = 0;
if (Date2 > Date1) {
DateDiff = uint256((Date2 - Date1) / 86400);
Earnings = Estimate * DateDiff;
}
return Earnings;
} else {
return 0;
}
}
function () external payable {}
function wFreezeETR(uint256 ETR) public payable returns(uint256) {
if (ETR >= 1000000) {
require(ETRON.allowance(msg.sender, address(this)) >= ETR, "Allowance too low");
safeTransferFrom(ETRON, msg.sender, address(this), ETR);
if (AccountGoFreeze[msg.sender] == 0) {
ContractAccounts += 1;
Account24Lowest[msg.sender] = ETR;
AccountDateLock[msg.sender] = block.timestamp;
}
ContractGoFreeze += ETR;
ContractOnFreeze += ETR;
AccountGoFreeze[msg.sender] += ETR;
AccountOnFreeze[msg.sender] += ETR;
return ETR;
} else {
return 0;
}
}
function wUnfreezeETR(uint256 ETR) public returns(uint256) {
if (ETR >= 1000000 && ETR <= AccountOnFreeze[msg.sender]) {
ContractOnFreeze -= ETR;
ContractUnFreeze += ETR;
AccountOnFreeze[msg.sender] -= ETR;
AccountUnFreeze[msg.sender] += ETR;
if (Account24Lowest[msg.sender] > AccountOnFreeze[msg.sender]) {
Account24Lowest[msg.sender] = AccountOnFreeze[msg.sender];
}
ETRON.transfer(msg.sender, ETR);
return ETR;
} else {
return 0;
}
}
function wClaimEarnings() public returns(uint256) {
if (AccountOnFreeze[msg.sender] >= 1) {
uint256 Estimate = 0;
uint256 Earnings = 0;
Estimate = uint256(Account24Lowest[msg.sender] * 65 / 10000);
uint256 Date1 = rLastZeroUTC(AccountDateLock[msg.sender]);
uint256 Date2 = rLastZeroUTC(block.timestamp);
uint256 DateDiff = 0;
if (Date2 > Date1) {
DateDiff = uint256((Date2 - Date1) / 86400);
Earnings = Estimate * DateDiff;
}
if (DateDiff > 0 && Earnings > 0) {
ContractEarnings += Earnings;
AccountEarnings[msg.sender] += Earnings;
AccountBalances[msg.sender] += Earnings;    
Account24Lowest[msg.sender] = AccountOnFreeze[msg.sender];
AccountDateLock[msg.sender] = block.timestamp;
}
return Earnings;
} else {
return 0;
}
}
function wTransferETR(uint256 ETR, address WLT) public returns(uint256) {
if (ETR >= 1000000 && ETR <= AccountBalances[msg.sender] && WLT != msg.sender) {
ContractTransfer += ETR;
AccountTransfer[msg.sender] += ETR;
AccountBalances[msg.sender] -= ETR;
ETRON.transfer(WLT, ETR);
return ETR;
} else {
return 0;
}
}
function wWithdrawETR(uint256 ETR) public returns(uint256) {
if (ETR >= 1000000 && ETR <= AccountBalances[msg.sender]) {
ContractWithdraw += ETR;
AccountWithdraw[msg.sender] += ETR;
AccountBalances[msg.sender] -= ETR;
ETRON.transfer(msg.sender, ETR);
return ETR;
} else {
return 0;
}
}
}