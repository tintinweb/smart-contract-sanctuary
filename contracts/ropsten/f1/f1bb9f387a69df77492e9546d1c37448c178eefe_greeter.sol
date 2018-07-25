pragma solidity ^0.4.24;

contract mortal {
    /* Define variable owner of the type address */
    address owner;

    /* This function is executed at initialization and sets the owner of the contract */
    function mortal() public { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() public { if (msg.sender == owner) selfdestruct(owner); }
}

contract greeter is mortal {
	/* Define variable greeting of the type string */
	string greeting;
		
	/* This runs when the contract is executed */
	function greeter(string _greeting) public {
	    
		greeting = _greeting;
	}

	/* Main function */
	function greet()  view returns (string) {
		return greeting;
	}
}