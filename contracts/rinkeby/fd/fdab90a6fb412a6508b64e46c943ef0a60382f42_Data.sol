/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity ^0.4.23;



contract Mortal {
    /* Define variable owner of the type address */
    address owner;

    /* This function is executed at initialization and sets the owner of the contract */
    constructor() public { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() public {
        if (msg.sender == owner) 
            selfdestruct(owner); 
    }
}

contract Data is Mortal {
    /* Define variable Data of the type string */
    string data;

    /* This runs when the contract is executed */
    constructor(string _data) public {
        data = _data;
    }

    /* change data */
    function changeGreeting(string _data) public {
        data = _data;
    }
    
    /* Main function */
    function greet() public view returns (string) {
        return data;
    }
}