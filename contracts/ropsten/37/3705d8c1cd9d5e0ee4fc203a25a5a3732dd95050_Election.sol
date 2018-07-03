pragma solidity ^0.4.21;
contract owned {
address owner;
function owned() public {
owner == msg.sender;
}
modifier onlyowner() {
if (msg.sender == owner) {
_;
}
}
}
contract mortal is owned {
function kill() public onlyowner {
selfdestruct(owner);
}
}
contract Election is mortal {
struct Candidate {
uint number;
string passportID;
string name;
address candidateAddress;
uint votes;
}
struct Voter {
address _address;
bool _voted;
}
uint numberOfRepresentatives = 10;
uint40 totalVotes;
uint numberOfCandidates;
uint[] candidatesVotes;
Candidate[] public candidates;
Candidate[] public winners;
Voter[] voters;
function Voting() public {
totalVotes = 0;
numberOfCandidates = 0;
winners.length = 0;
}
function apply(string _name, string _passportID) public returns(bool){
require(bytes(_name).length > 0 && bytes(_passportID).length > 0);
for (uint i = 0; i < candidates.length; i++) {
require (stringsEqual(candidates[i].passportID, _passportID) == false);
}
candidates.push(Candidate(numberOfCandidates++, _passportID, _name, msg.sender, 0));
return true;
}
function stringsEqual(string storage _a, string memory _b) internal pure returns(bool) {
bytes storage a = bytes(_a);
bytes memory b = bytes(_b);
if (keccak256(a) != keccak256(b)) {
return false;
}
return true;
}
function vote(uint number) public returns(bool){
require(number <= candidates.length);
require(hasAddressVoted() == false);
candidates[number].votes++;
totalVotes++;
voters.push(Voter(msg.sender, true));
return true;
}
function hasAddressVoted() internal view returns(bool) {
for (uint i = 0; i < voters.length; i++) {
if (voters[i]._address == msg.sender) {
if (voters[i]._voted == true) {
return true;
}
}
}
return false;
}
function resetNumberOfCandidates() internal onlyowner {
numberOfCandidates = 0;
}
function getNumberOfCandidates() public view returns(uint) {
return numberOfCandidates;
}
function resetTotalVotes() internal onlyowner {
totalVotes = 0;
}
function getTotalVotes() public view returns(uint40) {
return totalVotes;
}
function getHowManyWinners() public view returns(uint) {
return winners.length;
}
// get the currently representatives
function getWinners() public {
require(totalVotes > 0);
for (uint i = 0; i < winners.length; i++) {
delete winners[i];
}
winners.length = 0;
for (i = 0; i < candidates.length; i++) {
candidatesVotes.push(candidates[i].votes);
}
for (i = 0; i < numberOfRepresentatives; i++) {
uint p;
uint aux;
p = 0;
aux = 0;
for (uint j = 0; j < candidatesVotes.length; j++) {
if (candidatesVotes[j] > aux) {
aux = candidatesVotes[j];
p = j;
}
}
if (candidatesVotes[p] > 0) {
winners.push(candidates[p]);
delete candidatesVotes[p];
}
}
for (i = 0; i < candidatesVotes.length; i++) {
delete candidatesVotes[i];
}
candidatesVotes.length = 0;
}
// allows contract owner to restart the election at any time
function restartElection() public onlyowner {
resetTotalVotes();
resetNumberOfCandidates();
for (uint i = 0; i < candidates.length; i++) {
delete candidates[i];
}
candidates.length = 0;
for (i = 0; i < winners.length; i++) {
delete winners[i];
}
winners.length = 0;
for (i = 0; i < voters.length; i++) {
delete voters[i];
}
voters.length = 0;
}
}