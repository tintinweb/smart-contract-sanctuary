//SourceUnit: NonStopTRXv3.sol

/**
* https://nonstoptron.io [Best 2021 TRX Fund Raising Program]
* SPDX-License-Identifier:  MIT License
*/
pragma solidity ^0.5.12;

contract NonStopTRX {

    using SafeMath for uint;

    address payable public owner; //
    address payable public team1; // shk
    address payable public team2; // mrs
    address payable internal contract_;
    address payable public refunds_;

    uint internal constant cycleReward_ = 10;
    uint internal constant uniLevelReward_ = 13;

    uint internal constant divider = 100;

    uint internal globalPoolShare = 0; // 4%
    uint internal LeadershipPool = 0; // 7%

    uint internal globalPoolShared = 0;
    uint internal LeadershipPoolPaid = 0;

    uint internal gobalEarnings = 0;
    uint internal gobalPayouts = 0;

    uint public gobalBalance = 0;

uint public refundBalance = 200000 trx;

uint[] public unilevel;

DataStructs.LRewards[] public leadership;

mapping(uint => mapping(address => DataStructs.Activations)) internal activations;

mapping(address => DataStructs.Players) public players;

mapping(uint => DataStructs.poolEntries[]) public nonstopPool;

mapping(address => mapping(uint => DataStructs.myEntries[])) public paths;

mapping(uint => address) public getPlayerbyId;

DataStructs.Plans[] internal packs;

mapping(uint => address payable[]) public qualified; // For Weekly Shares

uint internal lastUid = 1;

uint internal joinedToday = 0;

uint internal lastJoined = block.timestamp;

uint public currentWeek = 1;
uint internal lasWeek = block.timestamp;

bool public systemInit = false;

// uint openMillionaires = 1610924400; // Sunday, January 17, 2021 11:00:00 PM (GMT)

modifier onlyContract(){
require(msg.sender == contract_);
_;
}

modifier onlyOwner() {
require(msg.sender == owner);
_;
}

constructor() public{

contract_ = msg.sender;

packs.push(DataStructs.Plans(100 trx, 5, 1000, 0, 0)); // Value in trx
packs.push(DataStructs.Plans(500 trx, 5, 2000, 0, 0));
packs.push(DataStructs.Plans(1000 trx, 5, 3000, 0, 0));
packs.push(DataStructs.Plans(5000 trx, 20, 4000, 0, 0));
packs.push(DataStructs.Plans(10000 trx, 20, 1e4, 0, 0));
packs.push(DataStructs.Plans(50000 trx, 20, 25e64, 0, 0));

unilevel.push(5);
unilevel.push(2);
unilevel.push(1);
unilevel.push(5);

leadership.push(DataStructs.LRewards(5e11, 7e9));
leadership.push(DataStructs.LRewards(25e11, 35e9));
leadership.push(DataStructs.LRewards(9e13, 12e11));
leadership.push(DataStructs.LRewards(18e13, 25e11));
leadership.push(DataStructs.LRewards(36e13, 5e12));

DataStructs.Players storage _player = players[contract_];
_player.id = lastUid;
getPlayerbyId[lastUid] = contract_;

qualified[currentWeek].push(contract_);

lastUid++;

DataStructs.Players storage _player2 = players[refunds_];
_player2.id = lastUid;
getPlayerbyId[lastUid] = refunds_;

lastUid++;

joinedToday++;
}

// ############################### //
//       Private Functions         //
// ############################### //

// Register user
function _Register(address payable _userId, address payable _affAddr) private{

address payable _refBy = _affAddr;

if(_refBy == _userId || _refBy == address(0) || players[_refBy].id == 0){
_refBy = contract_;
}

DataStructs.Players storage _player = players[_userId];

_player.refBy = _refBy;

players[_refBy].summary[0].refs++;
players[_refBy].refscount[0]++;
players[_refBy].referrals[0].push(_userId);
players[_refBy].summary[0].team++;

address _upline = players[_refBy].refBy;

for(uint i = 1; i < 10; i++){

if(_upline == address(0)) break;

players[_upline].refscount[i]++;
players[_upline].referrals[i].push(_userId);
players[_upline].summary[0].team++;

_upline = players[_upline].refBy;
}

_player.id = lastUid;
getPlayerbyId[lastUid] = _userId;
_player.weeklyrefs[0].lastUpdate = block.timestamp;

lastUid++;

if(block.timestamp >= lastJoined.add(1 days)){
lastJoined = block.timestamp;
joinedToday = 0;
}

joinedToday++;
}

// Update Weekly Referral Counts
function updateWeeklyReferrals(address payable _userId) private{
DataStructs.Players storage _player = players[_userId];
if(block.timestamp >= _player.weeklyrefs[0].lastUpdate.add(7 days)){
_player.weeklyrefs[0].count = 0;
_player.weeklyrefs[0].lastUpdate = block.timestamp;
_player.weeklyrefs[0].qualified = false;
}
_player.weeklyrefs[0].count++;
if(_player.weeklyrefs[0].count >= 5 && !_player.weeklyrefs[0].qualified){
_player.weeklyrefs[0].qualified = true;
qualified[currentWeek].push(_userId);
}
}

// Enter Cycle Pool
function enterCycle(address _userId, uint _planId, uint _pathId, uint _enteryId, uint _amount) private{
// Internal Reserves 18%
internalReserves(_amount);
// pay Commissions [13%]
unilevelCommission(_userId, _amount.mul(uniLevelReward_).div(divider), _planId);

// Update Team Volume
updateTeamVolume(_userId, _amount);

packs[_planId.sub(1)].poolSize++;

// DataStructs.Positions storage _path = gobalpool[_planId.sub(1)];
nonstopPool[_pathId].push(DataStructs.poolEntries({
planId: _planId,
entryId: _enteryId,
userId: _userId
}));

// check Cycling Members.
uint _positions = nonstopPool[_pathId].length;

if(_positions.mod(2) == 0){
uint _positionId = _positions.div(2);
address _cycler = nonstopPool[_pathId][_positionId.sub(1)].userId;
uint entryId_ = nonstopPool[_pathId][_positionId.sub(1)].entryId;
uint planId_ = nonstopPool[_pathId][_positionId.sub(1)].planId;
// Pay reEntry Reward 10%
cycleReward(_cycler, _amount, entryId_, planId_);
// Cycle [Re-enters]
enterCycle(_cycler, planId_, _pathId, entryId_, _amount);
}
}

// Activate Path
function activatePath(address payable _userId, uint _amount, uint _planId) private{
// Insert Path
DataStructs.Players storage _player = players[_userId];

DataStructs.Activations storage _activation = activations[_planId][_userId];

_activation.entries.push(DataStructs.Entries({
amount: _amount,
earnings: 0,
dailyPayCounts: 0,
totalCycles: 0,
lastUpdate: uint(block.timestamp),
active: true
}));

_player.summary[0].activations++;
packs[_planId.sub(1)].activations++;
_player.packstat[_planId.sub(1)].activations++;
_player.summary[0].spent += _amount;

// Track Individual Entries
paths[_userId][_planId].push(DataStructs.myEntries({
amount: _amount,
earnings: 0,
dailyPayCounts: 0,
totalCycles: 0
}));

uint _entries = 1;

uint _pathId = 1;

if(_planId == 2){
_entries = 5;
}
else if(_planId == 3){
_entries = 10;
}
else if(_planId == 4){
_entries = 1;
_pathId = 2;
}
else if(_planId == 5){
_entries = 2;
_pathId = 2;
}
else if(_planId == 6){
_entries = 10;
_pathId = 2;
}

for(uint i = 1; i <= _entries; i++){
// Update Team Volume
enterCycle(_userId, _planId, _pathId, _activation.entries.length, _amount.div(_entries));
}
}

// Pay commissions [Unilevel] & Update TeamVolume
function unilevelCommission(address _userId, uint _amount, uint _planId) private{
address payable _upline = players[_userId].refBy;
gobalEarnings += _amount;
gobalBalance += _amount;
uint _comm;
uint _paid;
for(uint i = 0; i < 10; i++){
if(_upline == address(0)) break;

if(i == 0){
_comm = _amount.mul(unilevel[i]).div(uniLevelReward_);
}
else if(i == 1){
_comm = _amount.mul(unilevel[i]).div(uniLevelReward_);
}
else if(i >= 2 && i <= 5){
_comm = _amount.mul(unilevel[2]).div(uniLevelReward_);
}
else if(i >= 6){
_comm = _amount.mul(unilevel[3].div(10)).div(uniLevelReward_);
}

players[_upline].finance[0].balance += _comm;
players[_upline].summary[0].earnings += _comm;
players[_upline].summary[0].commissions += _comm;
players[_upline].packstat[_planId.sub(1)].earnings += _comm;
_upline = players[_upline].refBy;
_paid += _comm;
}

uint _commL = _amount.sub(_paid);

if(_commL > 0){
players[contract_].finance[0].balance += _commL;
}
}

// Update Team Volume
function updateTeamVolume(address _userId, uint _amount) private {
address _upline = players[_userId].refBy;
for(uint i = 0; i < 10; i++){
if(_upline == address(0)) break;

players[_upline].finance[0].teamvolume += _amount;
players[_upline].summary[0].teamVolume += _amount;

_upline = players[_upline].refBy;
}
}

// Pay Cycle Reward 10% [5 Daily or Unlimited for planId 6]
function cycleReward(address _userId, uint _amount, uint _enteryId, uint _planId) private{
DataStructs.Players storage _player = players[_userId];

DataStructs.Activations storage _activation = activations[_planId][_userId];

bool _credit = false;
uint _comm = _amount.mul(cycleReward_).div(divider);

if(_activation.entries[_enteryId.sub(1)].dailyPayCounts < packs[_planId.sub(1)].dailyCycle && block.timestamp < _activation.entries[_enteryId.sub(1)].lastUpdate.add(1 days)){
_activation.entries[_enteryId.sub(1)].dailyPayCounts++;
paths[_userId][_planId][_enteryId.sub(1)].dailyPayCounts++;
_credit = true;
}
else if(block.timestamp >= _activation.entries[_enteryId.sub(1)].lastUpdate.add(1 days)){
_activation.entries[_enteryId.sub(1)].lastUpdate = block.timestamp;
_activation.entries[_enteryId.sub(1)].dailyPayCounts = 1;
paths[_userId][_planId][_enteryId.sub(1)].dailyPayCounts = 1;
_credit = true;
}

if(_credit || _player.id <= 4){
_activation.entries[_enteryId.sub(1)].earnings += _comm;
_player.finance[0].balance += _comm;
_player.summary[0].earnings += _comm;
_player.packstat[_planId.sub(1)].earnings += _comm;
paths[_userId][_planId][_enteryId.sub(1)].earnings += _comm;
gobalEarnings += _comm;
gobalBalance += _comm;
}

_activation.entries[_enteryId.sub(1)].totalCycles++;
paths[_userId][_planId][_enteryId.sub(1)].totalCycles++;
_player.summary[0].cycles++;
_player.packstat[_planId.sub(1)].totalcycle++;
}

// Share GlobalResource
function internalReserves(uint _amount) private{

uint _reserve = _amount.mul(3).div(divider);

uint _reserveAll = _reserve.mul(6);

if(refundBalance > _reserveAll){
refundBalance -= _reserveAll;
players[refunds_].finance[0].balance += _reserveAll;
}
else{
players[owner].finance[0].balance += _reserve.mul(2);
players[contract_].finance[0].balance += _reserve.mul(2);
players[team1].finance[0].balance += _reserve;
players[team2].finance[0].balance += _reserve;
}

globalPoolShare += _amount.mul(4).div(divider);
LeadershipPool += _amount.mul(7).div(divider);

gobalBalance += _reserveAll;
}

// Indentify PathId
function getPathId(uint _amount) private view returns(uint){
if(_amount == packs[0].cost){
return 1;
}
else if(_amount == packs[1].cost){
return 2;
}
else if(_amount == packs[2].cost){
return 3;
}
else if(_amount == packs[3].cost){
return 4;
}
else if(_amount == packs[4].cost){
return 5;
}
else if(_amount == packs[5].cost){
return 6;
}
}

// ############################### //
//    External Functions CALLS     //
// ############################### //

// Activate Path [can Activate as Many as possible]
function joinPath(address payable _refBy) public payable returns(bool){

require(systemInit, 'WaitingSystemLaunnch');

address payable _userId = msg.sender;
uint _amount = msg.value;

uint _planId = getPathId(_amount);

/*if(_planId == 6){
    require(block.timestamp >= openMillionaires, 'NotOpen!');
}*/

require(_amount >= packs[0].cost && _amount <= packs[5].cost, 'Wrong Amount');
// Register User

DataStructs.Players memory _player = players[_userId];

if(_player.refBy == address(0) && _player.id == 0){
_Register(_userId, _refBy);
}

// Activate Path
activatePath(_userId, _amount, _planId);

return true;
}

// Withdraw Earnings
function withdraw(uint _amount) public returns(bool){
require(systemInit, 'WaitingSystemLaunnch');

address payable _userId = msg.sender;
DataStructs.Players storage _player = players[_userId];

if(_amount > _player.finance[0].balance){
_amount = _player.finance[0].balance;
}

require(_amount > 0, 'NoEarnings');

require(address(this).balance > _amount, 'NoFunds');

require(_userId.send(_amount),"Transfer failed");

_player.finance[0].balance -= _amount;

_player.finance[0].withdrawn += _amount;

gobalPayouts += _amount;

gobalBalance -= _amount;

return true;
}

// Re-invest Earnings
function reInvest(uint _amount) public returns(bool){
require(systemInit, 'WaitingSystemLaunnch');

address payable _userId = msg.sender;

require(isUserExists(_userId), 'NotAllowed');
DataStructs.Players storage _player = players[_userId];

uint _balance = _player.finance[0].balance;

require(_balance >= _amount, 'NoEarnings');

require(_amount >= 100 trx, 'Wrong Amount');

uint _planId = getPathId(_amount);

/*if(_planId == 6){
    require(block.timestamp >= openMillionaires, 'NotOpen!');
}*/

_player.finance[0].balance -= _amount;
_player.finance[0].withdrawn += _amount;

gobalPayouts += _amount;

gobalBalance -= _amount;

// Activate Path
activatePath(_userId, _amount, _planId);
}

// Credit Global Weekly poolShare Reward
function awardGlobalPool() public returns(bool){
require(block.timestamp >= lasWeek.add(7 days), 'NotAllowed');

require(qualified[currentWeek].length > 0, 'NoQualified');

uint _comm = globalPoolShare.div(qualified[currentWeek].length);

for(uint i = 0; i < qualified[currentWeek].length; i++){
players[qualified[currentWeek][i]].finance[0].balance += _comm;
players[qualified[currentWeek][i]].summary[0].earnings += _comm;
players[qualified[currentWeek][i]].summary[0].globalPool += _comm;
gobalEarnings += _comm;
globalPoolShared += _comm;
gobalBalance += _comm;
}

currentWeek++;
qualified[currentWeek].push(contract_);

lasWeek = block.timestamp;
globalPoolShare = 0;

return true;
}

// Claim Rewards
// Leadership Incentive Rewards
function awardLeadershPool() public returns(bool){
address payable _userId = msg.sender;
require(isUserExists(_userId), 'NoAllowed');

DataStructs.Players storage _player = players[_userId];

uint _myVolume = _player.finance[0].teamvolume;

require(_myVolume >= leadership[0].target, 'NotQualified');

// GetQualified Award
for(uint i = 0; i < 5; i++){
if(_myVolume >= leadership[i].target && _player.rank == i){
_player.rank++;
// Award First Rank [Phone]
uint _reward = leadership[i].reward;
_player.finance[0].balance += _reward;
_player.summary[0].earnings += _reward;
_player.summary[0].sponsorPool += _reward;
// _player.packstat[_planId.sub(1)].earnings += _comm;
gobalEarnings += _reward;
LeadershipPoolPaid += _reward;
LeadershipPool -= _reward;
gobalBalance += _reward;
}
}
}

// Signup only
function freeSignup(address payable _refBy) public returns(bool){
require(systemInit, 'WaitingSystemLaunnch');
address payable _userId = msg.sender;
require(!isUserExists(_userId), 'UserExists');
_Register(_userId, _refBy);
}

//###############################//
//   External Functions View     //
//###############################//
// View Global Data
function globalData() public view returns(uint _players, uint _joinedToday, uint _earnings, uint _payouts,
uint _weeklyPool, uint _weeklyPoolPaid, uint _leadersPool, uint _leadersPoolPaid, uint _balance){
_players = lastUid.sub(1);
_joinedToday = joinedToday;
_earnings = gobalEarnings;
_payouts = gobalPayouts;
_weeklyPool = globalPoolShare;
_weeklyPoolPaid = globalPoolShared;
_leadersPool = LeadershipPool;
_leadersPoolPaid = LeadershipPoolPaid;
_balance = address(this).balance;
}

// view Pool Ranks per packs
function viewTotalPositions(uint _pathId) public view returns(uint _length){
_length = nonstopPool[_pathId].length;
}

// View Users Data
function userInfo(address _userId) public view returns(uint _activations, uint _totalTRX, uint _totalEarnings, uint _uniLevelEarnings,
uint _gProfitShare, uint _leadershipEarnings,  uint _withdrawan, uint _balance, uint _refs, uint _teamVolume, uint _cycles, uint _teamSize){
DataStructs.Players memory _player = players[_userId];
_activations = _player.summary[0].activations;
_totalTRX = _player.summary[0].spent;
_totalEarnings = _player.summary[0].earnings;
_uniLevelEarnings = _player.summary[0].commissions;
_gProfitShare = _player.summary[0].globalPool;
_leadershipEarnings = _player.summary[0].sponsorPool;
_withdrawan = _player.finance[0].withdrawn;
_balance = _player.finance[0].balance;
_refs = _player.summary[0].refs;
_teamSize = _player.summary[0].team;
_teamVolume = _player.summary[0].teamVolume;
_cycles = _player.summary[0].cycles;
}

// Using PlanId with 0 Index
function getUserPathsRecords(address _userId, uint _planId) public view returns(uint _activations, uint _earnings, uint _cycles){
DataStructs.Players memory _player = players[_userId];
_activations = _player.packstat[_planId].activations;
_earnings = _player.packstat[_planId].earnings;
_cycles = _player.packstat[_planId].totalcycle;
}

// View All Referrals
function myReferrals(address _userId, uint _level) public view returns(address payable[] memory){
return(
players[_userId].referrals[_level.sub(1)]
);
}

// ------------------------------------------------------------------------
// Owner can transfer out any accidentally sent TRC20 tokens
// ------------------------------------------------------------------------
function missedTokens(address _tokenAddress) public onlyContract returns(bool success) {
uint _value = ITRC20(_tokenAddress).balanceOf(address(this));
return ITRC20(_tokenAddress).transfer(msg.sender, _value);
}

function setTeam(address payable _owner, address payable _team1, address payable _team2, address payable _refunds) public onlyContract returns(bool){
owner = _owner;
team1 = _team1;
team2 = _team2;
refunds_ = _refunds;
return true;
}

function toggleSystemInit() public onlyContract returns(bool){
systemInit = !systemInit ? true:false;
return systemInit;
}


function isUserExists(address _userId) internal view returns (bool) {
return (players[_userId].id != 0);
}
}


library DataStructs{

struct Players{
uint id;
uint rank;
address payable refBy;
bool synched;
Finance[1] finance;
Packdata[6] packstat;
mapping(uint => address payable[]) referrals;
uint [10] refscount;
WeeklyRefs[1] weeklyrefs;
Summary[1] summary;
}

struct Finance{
uint balance; // Total Avaiable
uint withdrawn; // Total Payouts
uint teamvolume; // Total TeamVoulme to 10th level
}

struct Activations{
Entries[] entries;
}

struct Summary{
uint spent; // Total TRX spent [Direct Input]
uint earnings; // Total TRX earned + commissions
uint commissions; // Total commissions Earned
uint globalPool; // Total Earned from Golbal ProfitSharing Pool
uint sponsorPool; // Total Earned from Sponsor's Pool Reward
uint cycles; // Total Cycle Counts [on All packs]
uint activations; // Total Activations [regardless of plan]
uint refs; // Total Referrals
uint team; // Total Team size
uint teamVolume; // Total Team Volume
}

struct Packdata{
uint activations;
uint totalcycle;
uint earnings;
}

struct Entries{
uint amount;
uint earnings;
uint dailyPayCounts; // 5 daily [and Unlimited for planId 4 and 5]
uint totalCycles; // 1000 to 4000 [and Unlimited for planId 4 and 5]
uint lastUpdate; // Last Update time [Every 24hrs]
bool active;
}

struct myEntries{
uint amount;
uint earnings;
uint dailyPayCounts;
uint totalCycles;
}

struct poolEntries{
uint planId;
uint entryId;
address userId;
}

struct Plans{
uint cost;
uint dailyCycle;
uint maxCycle;
uint activations; // Count Total Activations
uint poolSize; // Count Total Entries
}

struct LRewards{
uint target;
uint reward;
}

struct WeeklyRefs{
uint count; // 5 to qualify
bool qualified;
uint lastUpdate; // Resets Every 7days
}
}

interface ITRC20 {
function balanceOf(address tokenOwner) external pure returns (uint balance);
function transfer(address to, uint value) external returns (bool);
}

library SafeMath {
/**
 * @dev Returns the addition of two unsigned integers, reverting on
 * overflow.
 *
 * Counterpart to Solidity's `+` operator.
 *
 * Requirements:
 * - Addition cannot overflow.
 */
function add(uint a, uint b) internal pure returns (uint) {
uint c = a + b;
require(c >= a, "SafeMath: addition overflow");

return c;
}

/**
 * @dev Returns the subtraction of two unsigned integers, reverting on
 * overflow (when the result is negative).
 *
 * Counterpart to Solidity's `-` operator.
 *
 * Requirements:
 * - Subtraction cannot overflow.
 */
function sub(uint a, uint b) internal pure returns (uint) {
return sub(a, b, "SafeMath: subtraction overflow");
}

/**
 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
 * overflow (when the result is negative).
 *
 * Counterpart to Solidity's `-` operator.
 *
 * Requirements:
 * - Subtraction cannot overflow.
 *
 * _Available since v2.4.0._
 */
function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
require(b <= a, errorMessage);
uint c = a - b;

return c;
}

/**
 * @dev Returns the multiplication of two unsigned integers, reverting on
 * overflow.
 *
 * Counterpart to Solidity's `*` operator.
 *
 * Requirements:
 * - Multiplication cannot overflow.
 */
function mul(uint a, uint b) internal pure returns (uint) {
// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
// benefit is lost if 'b' is also tested.
// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
if (a == 0) {
return 0;
}

uint c = a * b;
require(c / a == b, "SafeMath: multiplication overflow");

return c;
}

/**
 * @dev Returns the integer division of two unsigned integers. Reverts on
 * division by zero. The result is rounded towards zero.
 *
 * Counterpart to Solidity's `/` operator. Note: this function uses a
 * `revert` opcode (which leaves remaining gas untouched) while Solidity
 * uses an invalid opcode to revert (consuming all remaining gas).
 *
 * Requirements:
 * - The divisor cannot be zero.
 */
function div(uint a, uint b) internal pure returns (uint) {
return div(a, b, "SafeMath: division by zero");
}

/**
 * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
 * division by zero. The result is rounded towards zero.
 *
 * Counterpart to Solidity's `/` operator. Note: this function uses a
 * `revert` opcode (which leaves remaining gas untouched) while Solidity
 * uses an invalid opcode to revert (consuming all remaining gas).
 *
 * Requirements:
 * - The divisor cannot be zero.
 *
 * _Available since v2.4.0._
 */
function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
// Solidity only automatically asserts when dividing by 0
require(b > 0, errorMessage);
uint c = a / b;
// assert(a == b * c + a % b); // There is no case in which this doesn't hold

return c;
}

/**
 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
 * Reverts when dividing by zero.
 *
 * Counterpart to Solidity's `%` operator. This function uses a `revert`
 * opcode (which leaves remaining gas untouched) while Solidity uses an
 * invalid opcode to revert (consuming all remaining gas).
 *
 * Requirements:
 * - The divisor cannot be zero.
 */
function mod(uint a, uint b) internal pure returns (uint) {
return mod(a, b, "SafeMath: modulo by zero");
}

/**
 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
 * Reverts with custom message when dividing by zero.
 *
 * Counterpart to Solidity's `%` operator. This function uses a `revert`
 * opcode (which leaves remaining gas untouched) while Solidity uses an
 * invalid opcode to revert (consuming all remaining gas).
 *
 * Requirements:
 * - The divisor cannot be zero.
 *
 * _Available since v2.4.0._
 */
function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
require(b != 0, errorMessage);
return a % b;
}
}