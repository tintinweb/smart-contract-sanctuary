//SourceUnit: network.sol

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
contract ETRON_dNetworkApp {
ETR20 public ETRON;
address public SELLER;
address public DAPPS;
constructor() public {
ETRON = ETR20(0x41723b9a69d73e2b9d0a61ba2341610294f0addc53);
SELLER = address(0x418ecee341e2f71ac279bf18342587a82ed896159c);
DAPPS = address(0x41a879d5b0a68c08c4b7854f6d52af6ca04ff06ba5);
}
function safeTransferFrom(
ETR20 token, address sender, address recipient, uint256 amount
) private {
bool sent = token.transferFrom(sender, recipient, amount);
require(sent, "ETRON transfer failed");
}
uint256 private ContractAccounts;
uint256 private ContractVerified;
uint256 private ContractPurchase;
uint256 private ContractOnFreeze;
uint256 private ContractEarnings;
uint256 private ContractTransfer;
uint256 private ContractWithdraw;
uint256 private SellerPricing = 10;
uint256 private SellerTakeTRX = 0;
uint256 private SellerGiveETR = 0;
mapping (address => address) private AccountReferrer;
mapping (address => uint256) private AccountActivate;
mapping (address => uint256) private AccountPurchase;
mapping (address => uint256) private AccountOnFreeze;
mapping (address => uint256) private AccountDateLock;
mapping (address => uint256) private Account24Lowest;
mapping (address => uint256) private AccountLastSend;
mapping (address => uint256) private AccountEarnings;
mapping (address => uint256) private AccountBalances;
mapping (address => uint256) private AccountTransfer;
mapping (address => uint256) private AccountWithdraw;
mapping (address => uint256) private AccountNetwork1;
mapping (address => uint256) private AccountNetwork2;
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
function rContractVerified() public view returns(uint256) {
return ContractVerified;
}
function rContractPurchase() public view returns(uint256) {
return ContractPurchase;
}
function rContractOnFreeze() public view returns(uint256) {
return ContractOnFreeze;
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
function rLastZeroUTC(uint256 Time) public view returns(uint256) {
if (Time == 0) {
Time = block.timestamp;
}
if (Time > 1601510400 && Time < 1917043200) {
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
if (Time > 1601510400 && Time < 1917043200) {
return (Time - (Time % 86400)) + 86400;
} else {
return 0;
}
}
function rAccountReferrer() public view returns(address) {
return AccountReferrer[msg.sender];
}
function rAccountActivate() public view returns(uint256) {
return AccountActivate[msg.sender];
}
function rAccountPurchase() public view returns(uint256) {
return AccountPurchase[msg.sender];
}
function rAccountOnFreeze() public view returns(uint256) {
return AccountOnFreeze[msg.sender];
}
function rAccountDateLock() public view returns(uint256) {
return AccountDateLock[msg.sender];
}
function rAccount24Lowest() public view returns(uint256) {
return Account24Lowest[msg.sender];
}
function rAccountLastSend() public view returns(uint256) {
return AccountLastSend[msg.sender];
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
function rAccountNetwork1() public view returns(uint256) {
return AccountNetwork1[msg.sender];
}
function rAccountNetwork2() public view returns(uint256) {
return AccountNetwork2[msg.sender];
}
function wAssignSeller(address NEW) public returns(address) {
if (msg.sender == SELLER) {
SELLER = NEW;
return NEW;
} else {
return SELLER;
}
}
function rSellerPricing() public view returns(uint256) {
return SellerPricing;
}
function wSellerPricing(uint256 TRX) public returns(uint256) {
if (msg.sender == SELLER) {
SellerPricing = TRX;
return TRX;
} else {
return SellerPricing;
}
}
function rSellerTakeTRX() public view returns(uint256) {
if (msg.sender == SELLER) {
return SellerTakeTRX;
} else {
return 0;
}
}
function wSellerReceiveTRX(uint256 TRX) public returns(uint256) {
if (msg.sender == SELLER) {
uint256 ReceiveTRX = address(this).balance;
uint256 AmountTRX = 0;
if (TRX > 0 && TRX < ReceiveTRX) {
AmountTRX = TRX;
} else {
AmountTRX = ReceiveTRX;
}
if (AmountTRX > 0) {
msg.sender.transfer(AmountTRX);
}
return AmountTRX;
} else {
return 0;
}
}
function rSellerGiveETR() public view returns(uint256) {
if (msg.sender == SELLER) {
return SellerGiveETR;
} else {
return 0;
}
}
function wSellerReceiveETR(uint256 ETR) public returns(uint256) {
if (msg.sender == SELLER) {
uint256 ReceiveETR = ETRON.balanceOf(address(this));
uint256 AmountETR = 0;
if (ETR > 0 && ETR < ReceiveETR) {
AmountETR = ETR;
} else {
AmountETR = ReceiveETR;
}
if (AmountETR > 0) {
ETRON.transfer(msg.sender, AmountETR);
}
return AmountETR;
} else {
return 0;
}
}
function rSomeoneReferrer(address ADDR) public view returns(address) {
return AccountReferrer[ADDR];
}
function rSomeoneActivate(address ADDR) public view returns(uint256) {
return AccountActivate[ADDR];
}
function rSomeonePurchase(address ADDR) public view returns(uint256) {
return AccountPurchase[ADDR];
}
function rSomeoneOnFreeze(address ADDR) public view returns(uint256) {
return AccountOnFreeze[ADDR];
}
function rSomeoneDateLock(address ADDR) public view returns(uint256) {
return AccountDateLock[ADDR];
}
function rSomeone24Lowest(address ADDR) public view returns(uint256) {
return Account24Lowest[ADDR];
}
function rSomeoneLastSend(address ADDR) public view returns(uint256) {
return AccountLastSend[ADDR];
}
function rSomeoneEarnings(address ADDR) public view returns(uint256) {
return AccountEarnings[ADDR];
}
function rSomeoneBalances(address ADDR) public view returns(uint256) {
return AccountBalances[ADDR];
}
function rSomeoneTransfer(address ADDR) public view returns(uint256) {
return AccountTransfer[ADDR];
}
function rSomeoneWithdraw(address ADDR) public view returns(uint256) {
return AccountWithdraw[ADDR];
}
function rSomeoneNetwork1(address ADDR) public view returns(uint256) {
return AccountNetwork1[ADDR];
}
function rSomeoneNetwork2(address ADDR) public view returns(uint256) {
return AccountNetwork2[ADDR];
}
function () external payable {}
function wActivate1(address REF) public payable returns(uint256) {
if (AccountActivate[msg.sender] == 0) {
uint256 GiveTRX = msg.value;
uint256 TakeETR = uint256(msg.value / SellerPricing);
if (GiveTRX >= 200000000 && TakeETR >= 200000000) {
SellerTakeTRX += GiveTRX;
SellerGiveETR += TakeETR;
ContractAccounts += 1;
ContractPurchase += TakeETR;
AccountPurchase[msg.sender] += TakeETR;
AccountActivate[msg.sender] = 1;
if (AccountReferrer[msg.sender] == address(0x0) && REF != address(0x0)) {
AccountReferrer[msg.sender] = REF;
} else {
AccountReferrer[msg.sender] = DAPPS;
}
ETRON.transfer(msg.sender, TakeETR);
return TakeETR;
} else {
return 0;
}
}
}
function wActivate2(uint256 ETR) public payable returns(uint256) {
if (AccountActivate[msg.sender] == 1) {
if (ETR >= 200000000) {
require(ETRON.allowance(msg.sender, address(this)) >= ETR, "Allowance too low");
safeTransferFrom(ETRON, msg.sender, address(this), ETR);
ContractOnFreeze += ETR;
AccountOnFreeze[msg.sender] += ETR;
AccountDateLock[msg.sender] = block.timestamp;
Account24Lowest[msg.sender] = AccountOnFreeze[msg.sender];
AccountActivate[msg.sender] = 2;
return ETR;
} else {
return 0;
}
}
}
function wActivate3() public returns(uint256) {
if (AccountActivate[msg.sender] == 2) {
address REF = AccountReferrer[msg.sender];
AccountNetwork1[REF] += 1;
if (AccountReferrer[REF] != address(0x0)) {
address REFF = AccountReferrer[REF];
AccountNetwork2[REFF] += 1;
}
ContractVerified += 1;
AccountActivate[msg.sender] = 3;
AccountBalances[msg.sender] = 2000000;
return 3;
}
}
function rAccountEstimate() public view returns(uint256) {
uint256 LastDay = rLastZeroUTC(block.timestamp - 86400);
uint256 NextDay = rNextZeroUTC(block.timestamp - 86400);
if (AccountLastSend[msg.sender] >= LastDay && AccountLastSend[msg.sender] <= NextDay && AccountOnFreeze[msg.sender] >= 1000000) {
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
function rSomeoneEstimate(address ADDR) public view returns(uint256) {
uint256 LastDay = rLastZeroUTC(block.timestamp - 86400);
uint256 NextDay = rNextZeroUTC(block.timestamp - 86400);
if (AccountLastSend[ADDR] >= LastDay && AccountLastSend[ADDR] <= NextDay && AccountOnFreeze[ADDR] >= 1000000) {
uint256 Estimate = 0;
uint256 Earnings = 0;
Estimate = uint256(Account24Lowest[ADDR] * 65 / 10000);
uint256 Date1 = rLastZeroUTC(AccountDateLock[ADDR]);
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
function wAccountSyncToDapp() public returns(uint256) {
uint256 LastDay = rLastZeroUTC(block.timestamp - 86400);
uint256 NextDay = rNextZeroUTC(block.timestamp - 86400);
if (AccountLastSend[msg.sender] >= LastDay && AccountLastSend[msg.sender] <= NextDay && AccountOnFreeze[msg.sender] >= 1000000) {
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
function wFreezeETR(uint256 ETR) public payable returns(uint256) {
if (ETR >= 1000000) {
require(ETRON.allowance(msg.sender, address(this)) >= ETR, "Allowance too low");
safeTransferFrom(ETRON, msg.sender, address(this), ETR);
ContractOnFreeze += ETR;
AccountOnFreeze[msg.sender] += ETR;
if (AccountOnFreeze[msg.sender] >= 200000000) {
AccountActivate[msg.sender] = 3;
}
return ETR;
} else {
return 0;
}
}
function wUnfreezeETR(uint256 ETR) public returns(uint256) {
if (ETR >= 1000000 && ETR <= AccountOnFreeze[msg.sender]) {
ContractOnFreeze -= ETR;
AccountOnFreeze[msg.sender] -= ETR;
if (Account24Lowest[msg.sender] > AccountOnFreeze[msg.sender]) {
Account24Lowest[msg.sender] = AccountOnFreeze[msg.sender];
}
if (AccountOnFreeze[msg.sender] < 200000000) {
AccountActivate[msg.sender] = 4;
}
ETRON.transfer(msg.sender, ETR);
return ETR;
} else {
return 0;
}
}
function wDepositETR(uint256 ETR) public payable returns(uint256) {
if (ETR >= 1000000) {
require(ETRON.allowance(msg.sender, address(this)) >= ETR, "Allowance too low");
safeTransferFrom(ETRON, msg.sender, address(this), ETR);
AccountBalances[msg.sender] += ETR;
return ETR;
} else {
return 0;
}
}
function wTransferETR(uint256 ETR, address WLT) public returns(uint256) {
if (ETR >= 1000000 && ETR <= AccountBalances[msg.sender] && WLT != msg.sender) {
ContractTransfer += ETR;
AccountTransfer[msg.sender] += ETR;
AccountBalances[msg.sender] -= ETR;
AccountLastSend[msg.sender] = block.timestamp;
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