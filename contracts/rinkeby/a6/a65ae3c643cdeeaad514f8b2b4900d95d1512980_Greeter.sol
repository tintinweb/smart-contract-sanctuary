/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17;

contract Mortal {
    /* Define variable owner of the type address */
    address payable owner;

    /* This function is executed at initialization and sets the owner of the contract */
    constructor() public { owner = payable(msg.sender); }

    /* Function to recover the funds on the contract */
    function kill() public {
        if (msg.sender == owner) 
            selfdestruct(owner); 
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