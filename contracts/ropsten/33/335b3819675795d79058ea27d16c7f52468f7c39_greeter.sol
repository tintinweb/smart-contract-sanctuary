/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity ^0.4.18;

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
	function greeter(string _greeting) public {
		greeting = _greeting;
	}
	function greet() public constant returns (string) {
		return greeting;
	}
}