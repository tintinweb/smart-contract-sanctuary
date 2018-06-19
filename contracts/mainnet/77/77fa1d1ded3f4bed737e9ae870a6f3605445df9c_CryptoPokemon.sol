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

contract CryptoPokemon {
using SafeMath for uint256;
mapping (address => bool) private admins;
mapping (uint => uint256) public levels;
mapping (uint => bool) private lock;
address contractCreator;
address devFeeAddress;
address tournamentPrizeAddress;

function CryptoPokemon () public {

contractCreator = msg.sender;
devFeeAddress = 0xFb2D26b0caa4C331bd0e101460ec9dbE0A4783A4;
tournamentPrizeAddress = 0xC6784e712229087fC91E0c77fcCb6b2F1fDE2Dc2;
admins[contractCreator] = true;
}

struct Pokemon {
string pokemonName;
address ownerAddress;
uint256 currentPrice;
}
Pokemon[] pokemons;

//modifiers
modifier onlyContractCreator() {
require (msg.sender == contractCreator);
_;
}
modifier onlyAdmins() {
require(admins[msg.sender]);
_;
}

//Owners and admins

/* Owner */
function setOwner (address _owner) onlyContractCreator() public {
contractCreator = _owner;
}

function addAdmin (address _admin) onlyContractCreator() public {
admins[_admin] = true;
}

function removeAdmin (address _admin) onlyContractCreator() public {
delete admins[_admin];
}

// Adresses
function setdevFeeAddress (address _devFeeAddress) onlyContractCreator() public {
devFeeAddress = _devFeeAddress;
}

function settournamentPrizeAddress (address _tournamentPrizeAddress) onlyContractCreator() public {
tournamentPrizeAddress = _tournamentPrizeAddress;
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

function addLock (uint _pokemonId) onlyContractCreator() public {
lock[_pokemonId] = true;
}

function removeLock (uint _pokemonId) onlyContractCreator() public {
lock[_pokemonId] = false;
}

function getPokemonLock(uint _pokemonId) public view returns(bool) {
return(lock[_pokemonId]);
}

/*
This function allows users to purchase PokeMon.
The price is automatically multiplied by 1.5 after each purchase.
Users can purchase multiple PokeMon.
*/
function purchasePokemon(uint _pokemonId) public payable {

// Check new price >= currentPrice & gameStatus
require(msg.value >= pokemons[_pokemonId].currentPrice);
require(pokemons[_pokemonId].ownerAddress != address(0));
require(pokemons[_pokemonId].ownerAddress != msg.sender);
require(lock[_pokemonId] == false);
require(msg.sender != address(0));
require(isPaused == false);

// Calculate the excess
address newOwner = msg.sender;
uint256 price = pokemons[_pokemonId].currentPrice;
uint256 excess = msg.value.sub(price);
uint256 realValue = pokemons[_pokemonId].currentPrice;

// If excess>0 send back the amount
if (excess > 0) {
newOwner.transfer(excess);
}

// Calculate the 10% value as tournment prize and dev fee
uint256 cutFee = realValue.div(10);


// Calculate the pokemon owner commission on this sale & transfer the commission to the owner.
uint256 commissionOwner = realValue - cutFee; // => 90%
pokemons[_pokemonId].ownerAddress.transfer(commissionOwner);

// Transfer the 5% commission to the developer & %5 to tournamentPrizeAddress
devFeeAddress.transfer(cutFee.div(2)); // => 10%
tournamentPrizeAddress.transfer(cutFee.div(2));

// Update the hero owner and set the new price
pokemons[_pokemonId].ownerAddress = msg.sender;
pokemons[_pokemonId].currentPrice = pokemons[_pokemonId].currentPrice.mul(3).div(2);
levels[_pokemonId] = levels[_pokemonId] + 1;
}

// This function will return all of the details of the pokemons
function getPokemonDetails(uint _pokemonId) public view returns (
string pokemonName,
address ownerAddress,
uint256 currentPrice
) {
Pokemon storage _pokemon = pokemons[_pokemonId];

pokemonName = _pokemon.pokemonName;
ownerAddress = _pokemon.ownerAddress;
currentPrice = _pokemon.currentPrice;
}

// This function will return only the price of a specific pokemon
function getPokemonCurrentPrice(uint _pokemonId) public view returns(uint256) {
return(pokemons[_pokemonId].currentPrice);
}

// This function will return only the owner address of a specific pokemon
function getPokemonOwner(uint _pokemonId) public view returns(address) {
return(pokemons[_pokemonId].ownerAddress);
}

// This function will return only the levels of pokemons
function getPokemonLevel(uint _pokemonId) public view returns(uint256) {
return(levels[_pokemonId]);
}

// delete function, used when bugs comeout
function deletePokemon(uint _pokemonId) public onlyContractCreator() {
delete pokemons[_pokemonId];
delete pokemons[_pokemonId];
delete lock[_pokemonId];
}

// Set function, used when bugs comeout
function setPokemon(uint _pokemonId, string _pokemonName, address _ownerAddress, uint256 _currentPrice, uint256 _levels) public onlyContractCreator() {
pokemons[_pokemonId].ownerAddress = _ownerAddress;
pokemons[_pokemonId].pokemonName = _pokemonName;
pokemons[_pokemonId].currentPrice = _currentPrice;

levels[_pokemonId] = _levels;
lock[_pokemonId] = false;
}

// This function will be used to add a new hero by the contract creator
function addPokemon(string pokemonName, address ownerAddress, uint256 currentPrice) public onlyAdmins {
pokemons.push(Pokemon(pokemonName,ownerAddress,currentPrice));
levels[pokemons.length - 1] = 0;
lock[pokemons.length - 1] = false;
}

function totalSupply() public view returns (uint256 _totalSupply) {
return pokemons.length;
}

}