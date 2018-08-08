pragma solidity ^0.4.19;
/*
Game: CryptoPokemon
Domain: CryptoPokemon.com
Dev: CryptoPokemon Team
*/

library SafeMath {

/**
* @dev Multiplies two numbers, throws on overflow.
*/
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
if (a == 0) {
return 0;
}
uint256 c = a * b;
assert(c / a == b);
return c;
}

/**
* @dev Integer division of two numbers, truncating the quotient.
*/
function div(uint256 a, uint256 b) internal pure returns (uint256) {
// assert(b > 0); // Solidity automatically throws when dividing by 0
uint256 c = a / b;
// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
return c;
}

/**
* @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
*/
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
assert(b <= a);
return a - b;
}

/**
* @dev Adds two numbers, throws on overflow.
*/
function add(uint256 a, uint256 b) internal pure returns (uint256) {
uint256 c = a + b;
assert(c >= a);
return c;
}
}

contract PokemonInterface {
function levels(uint256 _pokemonId) external view returns (
uint256 level
);

function getPokemonOwner(uint _pokemonId)external view returns (
address currentOwner
);
}

contract PublicBattle {
using SafeMath for uint256;
//Guess parameter
uint public totalGuess;
uint public totalPool;
uint public publicBattlepm1;
uint public publicBattlepm2;
address guesser;
bool public publicbattlestart;
mapping(uint => address[]) pokemonGuessPlayers;
mapping(uint => uint) pokemonGuessNumber;
mapping(uint => uint) pokemonGuessPrize;
mapping(address => uint) playerGuessPM1Number;
mapping(address => uint) playerGuessPM2Number;
mapping(uint => uint) battleCD;
uint public pbWinner;

address cpAddress = 0x77fA1D1Ded3F4bed737e9aE870a6f3605445df9c;
PokemonInterface pokemonContract = PokemonInterface(cpAddress);

address contractCreator;
address devFeeAddress;

function PublicBattle () public {

contractCreator = msg.sender;
devFeeAddress = 0xFb2D26b0caa4C331bd0e101460ec9dbE0A4783A4;
publicbattlestart = false;
publicBattlepm1 = 99999;
publicBattlepm2 = 99999;
pbWinner = 99999;
isPaused = false;
totalPool = 0;
initialPokemonInfo();
}

struct Battlelog {
uint pokemonId1;
uint pokemonId2;
uint result;

}
Battlelog[] battleresults;

struct PokemonDetails {
string pokemonName;
uint pokemonType;
uint total;
}
PokemonDetails[] pokemoninfo;

//modifiers
modifier onlyContractCreator() {
require (msg.sender == contractCreator);
_;
}


//Owners and admins

/* Owner */
function setOwner (address _owner) onlyContractCreator() public {
contractCreator = _owner;
}


// Adresses
function setdevFeeAddress (address _devFeeAddress) onlyContractCreator() public {
devFeeAddress = _devFeeAddress;
}

bool isPaused;
/*
When countdowns and events happening, use the checker.
*/
function pauseGame() public onlyContractCreator {
isPaused = true;
}
function unPauseGame() public onlyContractCreator {
isPaused = false;
}
function GetGamestatus() public view returns(bool) {
return(isPaused);
}

//set withdraw only use when bugs happned.
function withdrawAmount (uint256 _amount) onlyContractCreator() public {
msg.sender.transfer(_amount);
totalPool = totalPool - _amount;
}

function initialBattle(uint _pokemonId1,uint _pokemonId2) public{
require(pokemonContract.getPokemonOwner(_pokemonId1) == msg.sender);
require(isPaused == false);
require(_pokemonId1 != _pokemonId2);
require(getPokemonCD(_pokemonId1) == 0);
assert(publicbattlestart != true);
publicBattlepm1 = _pokemonId1;
publicBattlepm2 = _pokemonId2;
publicbattlestart = true;
pokemonGuessNumber[publicBattlepm1]=0;
pokemonGuessNumber[publicBattlepm2]=0;
pokemonGuessPrize[publicBattlepm1]=0;
pokemonGuessPrize[publicBattlepm2]=0;
isPaused = false;
battleCD[_pokemonId1] = now + 12 * 1 hours;
// add 1% of balance to contract
totalGuess = totalPool.div(100);
//trigger time

}
function donateToPool() public payable{
// The pool will make this game maintain forever, 1% of prize goto each publicbattle and
// gain 1% of each publicbattle back before distributePrizes
require(msg.value >= 0);
totalPool = totalPool + msg.value;

}

function guess(uint _pokemonId) public payable{
require(isPaused == false);
assert(msg.value > 0);
assert(_pokemonId == publicBattlepm1 || _pokemonId == publicBattlepm2);

uint256 calcValue = msg.value;
uint256 cutFee = calcValue.div(16);

calcValue = calcValue - cutFee;

// %3 to the Owner of the card and %3 to dev
pokemonContract.getPokemonOwner(_pokemonId).transfer(cutFee.div(2));
devFeeAddress.transfer(cutFee.div(2));

// Total amount
totalGuess += calcValue;

// Each guess time
pokemonGuessNumber[_pokemonId]++;


// Each amount
pokemonGuessPrize[_pokemonId] = pokemonGuessPrize[_pokemonId] + calcValue;


// mapping sender and amount

if(_pokemonId == publicBattlepm1){

if(playerGuessPM1Number[msg.sender] != 0){

playerGuessPM1Number[msg.sender] = playerGuessPM1Number[msg.sender] + calcValue;

}else{

pokemonGuessPlayers[_pokemonId].push(msg.sender);
playerGuessPM1Number[msg.sender]  = calcValue;
}

}else{


if(playerGuessPM2Number[msg.sender] != 0){

playerGuessPM2Number[msg.sender] = playerGuessPM2Number[msg.sender] + calcValue;

}else{

pokemonGuessPlayers[_pokemonId].push(msg.sender);
playerGuessPM2Number[msg.sender]  = calcValue;
}

}

if(pokemonGuessNumber[publicBattlepm1] + pokemonGuessNumber[publicBattlepm2] > 20){
startpublicBattle(publicBattlepm1, publicBattlepm2);
}

}

function startpublicBattle(uint _pokemon1, uint _pokemon2) internal {
require(publicBattlepm1 != 99999 && publicBattlepm2 != 99999);
uint256 i = uint256(sha256(block.timestamp, block.number-i-1)) % 100 +1;
uint256 threshold = dataCalc(_pokemon1, _pokemon2);

if(i <= threshold){
pbWinner = publicBattlepm1;
}else{
pbWinner = publicBattlepm2;
}
battleresults.push(Battlelog(_pokemon1,_pokemon2,pbWinner));
distributePrizes();

}

function distributePrizes() internal{
// return 1% to the balance to keep public battle forever
totalGuess = totalGuess - totalGuess.div(100);
for(uint counter=0; counter < pokemonGuessPlayers[pbWinner].length; counter++){
guesser = pokemonGuessPlayers[pbWinner][counter];
if(pbWinner == publicBattlepm1){
guesser.transfer(playerGuessPM1Number[guesser].mul(totalGuess).div(pokemonGuessPrize[pbWinner]));
//delete playerGuessPM1Number[guesser];

}else{

guesser.transfer(playerGuessPM2Number[guesser].mul(totalGuess).div(pokemonGuessPrize[pbWinner]));


}
}
uint del;
if(pbWinner == publicBattlepm1){
del = publicBattlepm2;
}else{
del = publicBattlepm1;
}

for(uint cdel1=0; cdel1 < pokemonGuessPlayers[pbWinner].length; cdel1++){
guesser = pokemonGuessPlayers[pbWinner][cdel1];
if(pbWinner == publicBattlepm1){
delete playerGuessPM1Number[guesser];
}else{
delete playerGuessPM2Number[guesser];
}
}

for(uint cdel=0; cdel < pokemonGuessPlayers[del].length; cdel++){
guesser = pokemonGuessPlayers[del][cdel];
if(del == publicBattlepm1){
delete playerGuessPM1Number[guesser];
}else{
delete playerGuessPM2Number[guesser];
}
}


pokemonGuessNumber[publicBattlepm1]=0;
pokemonGuessNumber[publicBattlepm2]=0;

pokemonGuessPrize[publicBattlepm1]=0;
pokemonGuessPrize[publicBattlepm2]=0;
delete pokemonGuessPlayers[publicBattlepm2];
delete pokemonGuessPlayers[publicBattlepm1];
//for(counter=0; counter < pokemonGuessPlayers[pbWinner].length; counter++){
//pokemonGuessPlayers[counter].length = 0;
//}
counter = 0;
publicBattlepm1 = 99999;
publicBattlepm2 = 99999;
pbWinner = 99999;
totalGuess = 0;
publicbattlestart = false;
}

function dataCalc(uint _pokemon1, uint _pokemon2) public view returns (uint256 _threshold){
uint _pokemontotal1;
uint _pokemontotal2;

// We can just leave the other fields blank:
(,,_pokemontotal1) = getPokemonDetails(_pokemon1);
(,,_pokemontotal2) = getPokemonDetails(_pokemon2);
uint256 threshold = _pokemontotal1.mul(100).div(_pokemontotal1+_pokemontotal2);
uint256 pokemonlevel1 = pokemonContract.levels(_pokemon1);
uint256 pokemonlevel2 = pokemonContract.levels(_pokemon2);
uint leveldiff = pokemonlevel1 - pokemonlevel2;
if(pokemonlevel1 >= pokemonlevel2){
threshold = threshold.mul(11**leveldiff).div(10**leveldiff);

}else{
//return (100 - dataCalc(_pokemon2, _pokemon1));
threshold = 100 - dataCalc(_pokemon2, _pokemon1);
}
if(threshold > 90){
threshold = 90;
}
if(threshold < 10){
threshold = 10;
}

return threshold;

}



// This function will return all of the details of the pokemons
function getBattleDetails(uint _battleId) public view returns (
uint _pokemon1,
uint _pokemon2,
uint256 _result
) {
Battlelog storage _battle = battleresults[_battleId];

_pokemon1 = _battle.pokemonId1;
_pokemon2 = _battle.pokemonId2;
_result = _battle.result;
}

function addPokemonDetails(string _pokemonName, uint _pokemonType, uint _total) public onlyContractCreator{

pokemoninfo.push(PokemonDetails(_pokemonName,_pokemonType,_total));
}

// This function will return all of the details of the pokemons
function getPokemonDetails(uint _pokemonId) public view returns (
string _pokemonName,
uint _pokemonType,
uint _total
) {
PokemonDetails storage _pokemoninfomation = pokemoninfo[_pokemonId];

_pokemonName = _pokemoninfomation.pokemonName;
_pokemonType = _pokemoninfomation.pokemonType;
_total = _pokemoninfomation.total;
}

function totalBattles() public view returns (uint256 _totalSupply) {
return battleresults.length;
}

function getPokemonBet(uint _pokemonId) public view returns (uint256 _pokemonBet){
return pokemonGuessPrize[_pokemonId];
}

function getPokemonOwner(uint _pokemonId) public view returns (
address _owner
) {

_owner = pokemonContract.getPokemonOwner(_pokemonId);

}

function getPublicBattlePokemon1() public view returns(uint _pokemonId1){

return publicBattlepm1;
}
function getPublicBattlePokemon2() public view returns(uint _pokemonId1){

return publicBattlepm2;
}

function getPokemonBetTimes(uint _pokemonId) public view returns(uint _pokemonBetTimes){

return pokemonGuessNumber[_pokemonId];
}

function getPokemonCD(uint _pokemonId) public view returns(uint _pokemonCD){
if(battleCD[_pokemonId] <= now){
return 0;
}else{
return battleCD[_pokemonId] - now;
}
}

function initialPokemonInfo() public onlyContractCreator{
addPokemonDetails("PikaChu" ,1, 300);
addPokemonDetails("Ninetales",1,505);
addPokemonDetails("Charizard" ,2, 534);
addPokemonDetails("Eevee",0,325);
addPokemonDetails("Jigglypuff" ,0, 270);
addPokemonDetails("Pidgeot",2,469);
addPokemonDetails("Aerodactyl" ,2, 515);
addPokemonDetails("Bulbasaur",0,318);
addPokemonDetails("Abra" ,0, 310);
addPokemonDetails("Gengar",2,500);
addPokemonDetails("Hoothoot" ,0, 262);
addPokemonDetails("Goldeen",0,320);

}

}