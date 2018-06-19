/**
* The contract defining the contest, allowing participation and voting.
* Participation is only possible before the participation deadline.
* Voting is only allowed after the participation deadline was met and before the voting deadline expires.
* As soon as voting is over, the contest may be closed, resultig in the distribution od the prizes.
* The referee may disable certain participants, if their content is inappropiate.
*
* Copyright (c) 2016 Jam Data, Julia Altenried
* */
pragma solidity ^0.4.7;
contract Contest {
/** An ID derived from the contest meta data, so users can verify which contract belongs to which contest **/
uint public id;
/** The contest creator**/
address owner;
/** The referee deciding if content is appropiate **/
address public referee;
/** The providers address **/
address public c4c;
/** List of all participants **/
address[] public participants;
/** List of all voters **/
address[] public voters;
/** List of the winning participants */
address[] public winners;
/** List of the voters that won a prize */
address[] public luckyVoters;
/** The sum of the prizes paid out */
uint public totalPrize;
/** to efficiently check if somebody already participated **/
mapping(address=>bool) public participated;
/** to efficiently check if somebody already voted **/
mapping(address=>bool) public voted;
/** number of votes per candidate (think about it, maybe it’s better to count afterwards) **/
mapping(address=>uint) public numVotes;
/** disqualified participants**/
mapping(address => bool) public disqualified;
/** timestamp of the participation deadline**/
uint public deadlineParticipation;
/** timestamp of the voting deadline**/
uint public deadlineVoting;
/** participation fee **/
uint128 public participationFee;
/** voting fee**/
uint128 public votingFee;
/** provider fee **/
uint16 public c4cfee;
/** prize distribution **/
uint16 public prizeOwner;
uint16 public prizeReferee;
uint16[] public prizeWinners;
//rest for voters, how many?
uint8 public nLuckyVoters;

/** fired when contest is closed **/
event ContestClosed(uint prize, address[] winners, address[] votingWinners);

/** sets owner, referee, c4c, prizes (in percent with two decimals), deadlines **/
function Contest() payable{
c4c = 0x87b0de512502f3e86fd22654b72a640c8e0f59cc;
c4cfee = 1000;
owner = msg.sender;

deadlineParticipation=1513903980;
deadlineVoting=1514854380;
participationFee=1000000000000000;
votingFee=1000000000000000;
prizeOwner=955;
prizeReferee=0;
prizeWinners.push(6045);
nLuckyVoters=1;


uint16 sumPrizes = prizeOwner;
for(uint i = 0; i < prizeWinners.length; i++) {
sumPrizes += prizeWinners[i];
}
if(sumPrizes>10000)
throw;
else if(sumPrizes < 10000 && nLuckyVoters == 0)//make sure everything is paid out
throw;
}

/**
* adds msg.sender to the list of participants if the deadline was not yet met and the participation fee is paid
* */
function participate() payable {
if(msg.value < participationFee)
throw;
else if (now >= deadlineParticipation)
throw;
else if (participated[msg.sender])
throw;
else if (msg.sender!=tx.origin) //contract could decline money sending or have an expensive fallback function, only wallets should be able to participate
throw;
else {
participants.push(msg.sender);
participated[msg.sender]=true;
//if the winners list is smaller than the prize list, push the candidate
if(winners.length < prizeWinners.length) winners.push(msg.sender);
}
}

/**
* adds msg.sender to the voter list and updates vote related mappings if msg.value is enough, the vote is done between the deadlines and the voter didn&#39;t vote already
*/
function vote(address candidate) payable{
if(msg.value < votingFee)
throw;
else if(now < deadlineParticipation || now >=deadlineVoting)
throw;
else if(voted[msg.sender])//voter did already vote
throw;
else if (msg.sender!=tx.origin) //contract could decline money sending or have an expensive fallback function, only wallets should be able to vote
throw;
else if(!participated[candidate]) //only voting for actual participants
throw;
else{
voters.push(msg.sender);
voted[msg.sender] = true;
numVotes[candidate]++;

for(var i = 0; i < winners.length; i++){//from the first to the last
if(winners[i]==candidate) break;//the candidate remains on the same position
if(numVotes[candidate]>numVotes[winners[i]]){//candidate is better
//else, usually winners[i+1]==candidate, because usually a candidate just improves by one ranking
//however, if there are multiple candidates with the same amount of votes, it might be otherwise
for(var j = getCandidatePosition(candidate, i+1); j>i; j--){
winners[j]=winners[j-1];
}
winners[i]=candidate;
break;
}
}
}
}

function getCandidatePosition(address candidate, uint startindex) internal returns (uint){
for(uint i = startindex; i < winners.length; i++){
if(winners[i]==candidate) return i;
}
return winners.length-1;
}

/**
* only called by referee, does not delete the participant from the list, but keeps him from winning (because of inappropiate content), only in contract if a referee exists
* */
function disqualify(address candidate){
if(msg.sender==referee)
disqualified[candidate]=true;
}

/**
* only callable by referee. in case he disqualified the wrong participant
* */
function requalify(address candidate){
if(msg.sender==referee)
disqualified[candidate]=false;
}

/**
* only callable after voting deadline, distributes the prizes, fires event?
* */
function close(){
// if voting already ended and the contract has not been closed yet
if(now>=deadlineVoting&&totalPrize==0){
determineLuckyVoters();
if(this.balance>10000) distributePrizes(); //more than 10000 wei so every party gets at least 1 wei (if s.b. gets 0.01%)
ContestClosed(totalPrize, winners, luckyVoters);
}
}

/**
* Determines the winning voters
* */
function determineLuckyVoters() constant {
if(nLuckyVoters>=voters.length)
luckyVoters = voters;
else{
mapping (uint => bool) chosen;
uint nonce=1;

uint rand;
for(uint i = 0; i < nLuckyVoters; i++){
do{
rand = randomNumberGen(nonce, voters.length);
nonce++;
}while (chosen[rand]);

chosen[rand] = true;
luckyVoters.push(voters[rand]);
}
}
}

/**
* creates a random number in [0,range)
* */
function randomNumberGen(uint nonce, uint range) internal constant returns(uint){
return uint(block.blockhash(block.number-nonce))%range;
}

/**
* distribites the contract balance amongst the creator, wthe winners, the lucky voters, the referee and the provider
* */
function distributePrizes() internal{

if(!c4c.send(this.balance/10000*c4cfee)) throw;
totalPrize = this.balance;
if(prizeOwner!=0 && !owner.send(totalPrize/10000*prizeOwner)) throw;
if(prizeReferee!=0 && !referee.send(totalPrize/10000*prizeReferee)) throw;
for (uint8 i = 0; i < winners.length; i++)
if(prizeWinners[i]!=0 && !winners[i].send(totalPrize/10000*prizeWinners[i])) throw;
if (luckyVoters.length>0){//if anybody voted
if(this.balance>luckyVoters.length){//if there is ether left to be distributed amongst the lucky voters
uint amount = this.balance/luckyVoters.length;
for(uint8 j = 0; j < luckyVoters.length; j++)
if(!luckyVoters[j].send(amount)) throw;
}
}
else if(!owner.send(this.balance)) throw;//if there is no lucky voter, give remainder to the owner
}

/**
* returns the total vote count
* */
function getTotalVotes() constant returns(uint){
return voters.length;
}
}