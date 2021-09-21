/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

contract PokeMeReady {
    address payable public immutable pokeMe;

    constructor(address payable _pokeMe) {
        pokeMe = _pokeMe;
    }

    modifier onlyPokeMe() {
        require(msg.sender == pokeMe, "PokeMeReady: onlyPokeMe");
        _;
    }
}

// Creating a contract
contract Types is PokeMeReady {
	uint256 public count;
    uint256 public lastExecuted;
    uint256 amount;
	// Declaring a dynamic array
	uint[] data;
	constructor(address payable _pokeMe) PokeMeReady(_pokeMe) {}

	// Defining a function
	// to demonstrate 'For loop'
	function loop(uint256 amount) external returns(uint[] memory){
	    require(((block.timestamp - lastExecuted) > 180), "Counter: increaseCount: Time not elapsed");
        
	for(uint i=0; i<5; i++){
		data.push(i);
	}
	count += amount;
    lastExecuted = block.timestamp;
	return data;
	
	}
	

}