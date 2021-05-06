/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.8.0;



contract Mortal {
    /* Define variable owner of the type address */
    address owner;

    /* This function is executed at initialization and sets the owner of the contract */
    constructor() public { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() public {
        if (msg.sender == owner) 
            selfdestruct(payable(owner)); 
    }
}

contract Greeter is Mortal {
    /* Define variable greeting of the type string */
    string greeting;

    /* This runs when the contract is executed */
    constructor(string memory _greeting) public {
        greeting = _greeting;
    }

    /* change greeting */
    function changeGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
    
    /* Main function */
    function greet() public view returns (string memory) {
        return greeting;
    }
}